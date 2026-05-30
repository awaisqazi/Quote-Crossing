//
//  OverworldScene.swift
//  Quote Crossing
//
//  The top-down overworld. Hosts the tile map, the player, and a camera that
//  smoothly follows the player. Movement is physics-driven: the joystick sets a
//  target velocity each frame and the physics engine resolves wall collisions.
//

import SpriteKit

final class OverworldScene: SKScene {

    // Injected from the SwiftUI layer.
    private let gameState: GameState
    private let gameInput: GameInput
    private let baseAppearance: AvatarAppearance
    private var equippedWearables: [WearableItem]

    private let player = PlayerNode()
    private let cameraNode = SKCameraNode()
    private var tileMap: SKTileMapNode?

    private var didBuildWorld = false
    private var isInLounge = false

    /// Called when a random encounter fires while wandering the Networking
    /// Lounge. Set by the owner (GameSession) to start a Sales Encounter.
    var onEncounterTriggered: (() -> Void)?

    // Encounter probing: accumulate movement while in tall grass; every
    // `stepLength` points moved, roll the encounter chance.
    private var lastProbePosition: CGPoint?
    private var loungeDistance: CGFloat = 0
    private let stepLength: CGFloat = 64
    private let encounterChance = 0.16

    // Frame timing — used to keep movement/camera smoothing frame-rate
    // independent (identical feel on 60 Hz and 120 Hz ProMotion displays).
    private var lastUpdateTime: TimeInterval = 0
    private var frameDelta: TimeInterval = 1.0 / 60.0

    // MARK: - Init

    init(gameState: GameState, gameInput: GameInput,
         avatar: AvatarSnapshot, wearables: [WearableItem]) {
        self.gameState = gameState
        self.gameInput = gameInput
        self.baseAppearance = AvatarAppearance(avatar)
        self.equippedWearables = wearables
        // Provisional size; `.resizeFill` makes SpriteView match this to the view.
        super.init(size: CGSize(width: 1024, height: 768))
        scaleMode = .resizeFill
        backgroundColor = Palette.sceneBackground
    }

    /// Live-update the player's equipped wearables (called when the wardrobe
    /// changes equipment) — refreshes the SpriteKit figure immediately.
    func applyWearables(_ items: [WearableItem]) {
        equippedWearables = items
        if didBuildWorld {
            player.apply(baseAppearance, wearables: items)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        guard !didBuildWorld else { return }   // build exactly once
        didBuildWorld = true
        buildWorld()
    }

    private func buildWorld() {
        physicsWorld.gravity = .zero           // top-down: no gravity

        // Tile map — positioned so the world spans (0,0)...(worldWidth, worldHeight).
        let map = TileMapFactory.makeOverworld()
        map.position = CGPoint(x: GameMetrics.worldWidth / 2, y: GameMetrics.worldHeight / 2)
        map.zPosition = 0
        addChild(map)
        TileMapFactory.addWallPhysics(to: map)
        tileMap = map

        // Player starts in the open centre of the office, wearing the look
        // chosen during the Badging Process plus any equipped wearables.
        player.apply(baseAppearance, wearables: equippedWearables)
        player.position = CGPoint(x: GameMetrics.worldWidth / 2, y: GameMetrics.worldHeight / 2)
        addChild(player)

        // Camera follows the player.
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = player.position
    }

    // MARK: - Per-frame update

    override func update(_ currentTime: TimeInterval) {
        guard didBuildWorld, let body = player.physicsBody else { return }

        // Delta-time since last frame, clamped so a hitch/resume doesn't teleport.
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        frameDelta = min(currentTime - lastUpdateTime, 1.0 / 30.0)
        lastUpdateTime = currentTime

        isInLounge = playerIsInLounge()
        let speed = isInLounge
            ? GameMetrics.playerSpeed * GameMetrics.loungeSlowFactor
            : GameMetrics.playerSpeed

        // Joystick vector is already in SpriteKit space (Y-up), magnitude 0...1.
        let input = gameInput.movement
        let target = CGVector(dx: input.dx * speed, dy: input.dy * speed)

        // Ease current velocity toward target → smooth acceleration & stop.
        // The easing factor is rebased from "per 60 Hz frame" to actual dt so
        // the feel is identical regardless of display refresh rate.
        let k = smoothingFactor(GameMetrics.moveLerp)
        let v = body.velocity
        body.velocity = CGVector(
            dx: v.dx + (target.dx - v.dx) * k,
            dy: v.dy + (target.dy - v.dy) * k
        )

        probeForEncounter()
    }

    /// Converts a "fraction per 60 Hz frame" smoothing constant into a
    /// frame-rate-independent factor for the current `frameDelta`.
    private func smoothingFactor(_ per60: CGFloat) -> CGFloat {
        CGFloat(1 - pow(1 - Double(per60), frameDelta * 60))
    }

    // MARK: - Random encounters

    /// While moving through the Networking Lounge, accumulate distance and roll
    /// the encounter chance every `stepLength` points (Pokémon-style grass).
    private func probeForEncounter() {
        defer { lastProbePosition = player.position }
        guard let last = lastProbePosition else { return }

        // Reset in-grass progress when on a floor tile, but never clobber a
        // pending negative grace buffer from a just-finished battle.
        guard isInLounge else { loungeDistance = min(loungeDistance, 0); return }

        let moved = hypot(player.position.x - last.x, player.position.y - last.y)
        guard moved > 0.5 else { return }                      // only while actually moving
        loungeDistance += moved

        if loungeDistance >= stepLength {
            loungeDistance = 0
            if Double.random(in: 0..<1) < encounterChance {
                onEncounterTriggered?()
            }
        }
    }

    /// Called after an encounter ends so it doesn't immediately re-trigger on
    /// the same patch of grass.
    func resetEncounterProbe() {
        loungeDistance = -stepLength
        lastProbePosition = nil
    }

    /// Stops the player dead and resets frame timing — call before pausing for
    /// a menu/encounter so the world doesn't glide or lurch on resume.
    func haltPlayer() {
        player.physicsBody?.velocity = .zero
        lastUpdateTime = 0
        lastProbePosition = nil
    }

    override func didFinishUpdate() {
        // Run camera follow after physics so it tracks the resolved position.
        guard didBuildWorld else { return }
        followCamera()
    }

    // MARK: - Camera

    private func followCamera() {
        let k = smoothingFactor(GameMetrics.cameraLerp)
        var x = cameraNode.position.x + (player.position.x - cameraNode.position.x) * k
        var y = cameraNode.position.y + (player.position.y - cameraNode.position.y) * k

        // Clamp so the viewport never reveals beyond the map edges. Viewport
        // size in scene units == scene.size × camera scale (scale is 1 today,
        // but folding it in keeps the clamp correct if zoom is ever added).
        let halfW = size.width / 2 * cameraNode.xScale
        let halfH = size.height / 2 * cameraNode.yScale

        let minX = halfW, maxX = GameMetrics.worldWidth - halfW
        let minY = halfH, maxY = GameMetrics.worldHeight - halfH

        x = (minX <= maxX) ? min(max(x, minX), maxX) : GameMetrics.worldWidth / 2
        y = (minY <= maxY) ? min(max(y, minY), maxY) : GameMetrics.worldHeight / 2

        cameraNode.position = CGPoint(x: x, y: y)
    }

    // MARK: - Biome

    /// True when the player's centre sits on a Networking Lounge (tall grass) tile.
    private func playerIsInLounge() -> Bool {
        guard let map = tileMap else { return false }
        let p = map.convert(player.position, from: self)
        let col = map.tileColumnIndex(fromPosition: p)
        let row = map.tileRowIndex(fromPosition: p)
        guard col >= 0, col < map.numberOfColumns,
              row >= 0, row < map.numberOfRows else { return false }
        return map.tileGroup(atColumn: col, row: row)?.name == TileMapFactory.loungeName
    }
}
