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
    private let officeDecorLayer = SKNode()
    private let officeMarkerLayer = SKNode()
    private var officeMarkers: [OfficeMapMarker] = []
    private var currentEntrance: OfficeEntrance?

    private var didBuildWorld = false
    private var isInLounge = false

    /// Called when a random encounter fires while wandering the Networking
    /// Lounge. Set by the owner (GameSession) to start a Sales Encounter.
    var onEncounterTriggered: (() -> Void)?
    var onEntranceChanged: ((OfficeEntrance?) -> Void)?

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
        officeDecorLayer.zPosition = 10
        addChild(officeDecorLayer)
        buildOfficeSetDressing()
        officeMarkerLayer.zPosition = 22
        addChild(officeMarkerLayer)
        refreshOfficeMarkers()

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

    func refreshOfficeMarkers() {
        officeMarkerLayer.removeAllChildren()
        let layout = CubicleLayoutSummary.load()
        let entrances = OfficeEntrance.mapEntrances(layout: layout)

        officeMarkers = entrances.compactMap { entrance in
            let position: CGPoint
            let footprint = entrance.roomType?.footprint
            if let origin = entrance.gridOrigin, let footprint {
                position = OfficeBoard.worldPosition(for: origin, footprint: footprint)
            } else if let fixedPosition = fixedMarkerPosition(for: entrance.route) {
                position = fixedPosition
            } else {
                return nil
            }
            let longestRoomSide = max(CGFloat(footprint?.width ?? 1) * GameMetrics.tileSize,
                                      CGFloat(footprint?.height ?? 1) * GameMetrics.tileSize)
            let radius = entrance.isRoomFixture ? max(112, longestRoomSide * 0.58) : 118
            return OfficeMapMarker(entrance: entrance,
                                   position: position,
                                   color: entrance.roomType?.color ?? markerColor(for: entrance.route),
                                   footprint: footprint,
                                   interactionRadius: radius)
        }
        officeMarkers.forEach(addOfficeMarker)
        updateNearbyEntrance(forceNotify: true)
    }

    private func fixedMarkerPosition(for route: GameRoute) -> CGPoint? {
        switch route {
        case .prospecting:
            OfficeBoard.worldPosition(for: OfficeBoard.networkingAnchor, footprint: GridSize(width: 1, height: 1))
        case .cubicleBuilder:
            OfficeBoard.worldPosition(for: OfficeBoard.cubicleBuilderAnchor, footprint: GridSize(width: 1, height: 1))
        case .pipeDex:
            OfficeBoard.worldPosition(for: OfficeBoard.pipeDexAnchor, footprint: GridSize(width: 1, height: 1))
        default:
            nil
        }
    }

    private func buildOfficeSetDressing() {
        officeDecorLayer.removeAllChildren()
        addCeilingLightStrips()
        addLogoStyleFloorAccents()
        addLobbyMedallion()
        addElevatorBackdrop()
        addWayfindingInlays()
        addDeskNeighborhoods()
        addLobbyKiosks()
        addGlassConferenceRooms()
        addPlanters()
        addSupplyArchiveWall()
    }

    private func boardPoint(column: Int, row: Int, width: Int = 1, height: Int = 1) -> CGPoint {
        OfficeBoard.worldPosition(for: CubicleGridPoint(column: column, row: row),
                                  footprint: GridSize(width: width, height: height))
    }

    private func addLobbyMedallion() {
        let center = boardPoint(column: 13, row: 13, width: 5, height: 5)
        let rug = SKShapeNode(ellipseOf: CGSize(width: 230, height: 168))
        rug.position = center
        rug.fillColor = Palette.carpetGold.withAlphaComponent(0.035)
        rug.strokeColor = Palette.carpetGold.withAlphaComponent(0.12)
        rug.lineWidth = 1.2
        rug.glowWidth = 2
        rug.zPosition = 1
        officeDecorLayer.addChild(rug)

        let inner = SKShapeNode(ellipseOf: CGSize(width: 112, height: 78))
        inner.position = center
        inner.fillColor = Palette.glass.withAlphaComponent(0.055)
        inner.strokeColor = SKColor.white.withAlphaComponent(0.08)
        inner.lineWidth = 0.8
        inner.zPosition = 2
        officeDecorLayer.addChild(inner)
    }

    private func addCeilingLightStrips() {
        let lightRows = [6, 12, 18, 24]
        for row in lightRows {
            let left = boardPoint(column: 5, row: row)
            let right = boardPoint(column: 24, row: row)
            let path = CGMutablePath()
            path.move(to: left)
            path.addLine(to: right)

            let glow = SKShapeNode(path: path)
            glow.strokeColor = Palette.glass.withAlphaComponent(0.11)
            glow.lineWidth = 20
            glow.lineCap = .round
            glow.glowWidth = 8
            glow.zPosition = 0.6
            officeDecorLayer.addChild(glow)

            let core = SKShapeNode(path: path)
            core.strokeColor = SKColor.white.withAlphaComponent(0.12)
            core.lineWidth = 2
            core.lineCap = .round
            core.zPosition = 0.8
            officeDecorLayer.addChild(core)
        }
    }

    private func addLogoStyleFloorAccents() {
        let ribbons: [(CGPoint, CGPoint, CGPoint, CGPoint, SKColor)] = [
            (
                boardPoint(column: 3, row: 23),
                boardPoint(column: 7, row: 28),
                boardPoint(column: 12, row: 24),
                boardPoint(column: 15, row: 27),
                Palette.wallTop
            ),
            (
                boardPoint(column: 9, row: 8),
                boardPoint(column: 12, row: 12),
                boardPoint(column: 17, row: 9),
                boardPoint(column: 22, row: 13),
                Palette.glass
            ),
            (
                boardPoint(column: 19, row: 22),
                boardPoint(column: 23, row: 26),
                boardPoint(column: 26, row: 20),
                boardPoint(column: 28, row: 23),
                Palette.carpetWine
            )
        ]

        for ribbon in ribbons {
            let path = CGMutablePath()
            path.move(to: ribbon.0)
            path.addCurve(to: ribbon.3, control1: ribbon.1, control2: ribbon.2)

            let glow = SKShapeNode(path: path)
            glow.strokeColor = ribbon.4.withAlphaComponent(0.14)
            glow.lineWidth = 15
            glow.lineCap = .round
            glow.glowWidth = 6
            glow.zPosition = 1.0
            officeDecorLayer.addChild(glow)

            let highlight = SKShapeNode(path: path)
            highlight.strokeColor = SKColor.white.withAlphaComponent(0.18)
            highlight.lineWidth = 3
            highlight.lineCap = .round
            highlight.zPosition = 1.1
            officeDecorLayer.addChild(highlight)
        }

        [
            (boardPoint(column: 4, row: 6), Palette.glass, 0.78),
            (boardPoint(column: 8, row: 26), Palette.floorGlow, 0.64),
            (boardPoint(column: 12, row: 18), Palette.wallTop, 0.54),
            (boardPoint(column: 20, row: 5), Palette.carpetGold, 0.58),
            (boardPoint(column: 25, row: 18), Palette.plantLight, 0.68),
            (boardPoint(column: 27, row: 25), Palette.carpetWine, 0.58)
        ].forEach { position, color, scale in
            addFloorSparkle(at: position, color: color, scale: scale)
        }

        [
            (boardPoint(column: 6, row: 3), Palette.glass, 30.0),
            (boardPoint(column: 14, row: 24), Palette.wallTop, 21.0),
            (boardPoint(column: 23, row: 11), Palette.carpetGold, 24.0)
        ].forEach { position, color, diameter in
            let bubble = SKShapeNode(ellipseOf: CGSize(width: diameter, height: diameter * 0.76))
            bubble.position = position
            bubble.fillColor = color.withAlphaComponent(0.08)
            bubble.strokeColor = color.withAlphaComponent(0.18)
            bubble.lineWidth = 1.4
            bubble.zPosition = 1.05
            officeDecorLayer.addChild(bubble)
        }
    }

    private func addFloorSparkle(at position: CGPoint, color: SKColor, scale: CGFloat) {
        let path = CGMutablePath()
        let armLength = 26 * scale
        let branchLength = 7 * scale

        for index in 0..<6 {
            let angle = CGFloat(index) * .pi / 3
            let end = CGPoint(x: cos(angle) * armLength, y: sin(angle) * armLength)
            path.move(to: .zero)
            path.addLine(to: end)

            let branchBase = CGPoint(x: cos(angle) * armLength * 0.58,
                                     y: sin(angle) * armLength * 0.58)
            for branchAngle in [angle + .pi * 0.72, angle - .pi * 0.72] {
                path.move(to: branchBase)
                path.addLine(to: CGPoint(x: branchBase.x + cos(branchAngle) * branchLength,
                                         y: branchBase.y + sin(branchAngle) * branchLength))
            }
        }

        let sparkle = SKShapeNode(path: path)
        sparkle.position = position
        sparkle.strokeColor = color.withAlphaComponent(0.18)
        sparkle.lineWidth = max(1.4, 2.2 * scale)
        sparkle.lineCap = .round
        sparkle.lineJoin = .round
        sparkle.glowWidth = 2
        sparkle.zPosition = 1.15
        officeDecorLayer.addChild(sparkle)

        let core = SKShapeNode(circleOfRadius: max(2.4, 4 * scale))
        core.position = position
        core.fillColor = SKColor.white.withAlphaComponent(0.18)
        core.strokeColor = color.withAlphaComponent(0.18)
        core.lineWidth = 0.8
        core.zPosition = 1.2
        officeDecorLayer.addChild(core)
    }

    private func addElevatorBackdrop() {
        let position = boardPoint(column: OfficeBoard.elevator.column, row: OfficeBoard.elevator.row)

        let glow = SKShapeNode(ellipseOf: CGSize(width: 130, height: 92))
        glow.position = position
        glow.fillColor = Palette.carpetGold.withAlphaComponent(0.20)
        glow.strokeColor = Palette.carpetGold.withAlphaComponent(0.42)
        glow.lineWidth = 2
        glow.glowWidth = 10
        glow.zPosition = 3
        officeDecorLayer.addChild(glow)

        let doors = SKShapeNode(rectOf: CGSize(width: 62, height: 76), cornerRadius: 12)
        doors.position = position + CGPoint(x: -12, y: 2)
        doors.fillColor = Palette.floorGlow.withAlphaComponent(0.96)
        doors.strokeColor = Palette.fixtureInk.withAlphaComponent(0.42)
        doors.lineWidth = 2.4
        doors.zPosition = 4
        officeDecorLayer.addChild(doors)

        let seam = SKShapeNode(rectOf: CGSize(width: 2, height: 58), cornerRadius: 1)
        seam.position = doors.position
        seam.fillColor = Palette.wallBrass.withAlphaComponent(0.72)
        seam.strokeColor = .clear
        seam.zPosition = 5
        officeDecorLayer.addChild(seam)
    }

    private func addWayfindingInlays() {
        let paths = [
            [boardPoint(column: 3, row: 15), boardPoint(column: 14, row: 15), boardPoint(column: 14, row: 25), boardPoint(column: 6, row: 25)],
            [boardPoint(column: 14, row: 15), boardPoint(column: 14, row: 17), boardPoint(column: 18, row: 17)],
            [boardPoint(column: 14, row: 15), boardPoint(column: 24, row: 15)]
        ]

        for points in paths {
            let path = CGMutablePath()
            guard let first = points.first else { continue }
            path.move(to: first)
            points.dropFirst().forEach { path.addLine(to: $0) }

            let glow = SKShapeNode(path: path)
            glow.strokeColor = Palette.carpetGold.withAlphaComponent(0.17)
            glow.lineWidth = 12
            glow.lineCap = .round
            glow.lineJoin = .round
            glow.glowWidth = 7
            glow.zPosition = 1.2
            officeDecorLayer.addChild(glow)

            let rail = SKShapeNode(path: path)
            rail.strokeColor = SKColor.white.withAlphaComponent(0.16)
            rail.lineWidth = 2
            rail.lineCap = .round
            rail.lineJoin = .round
            rail.zPosition = 1.4
            officeDecorLayer.addChild(rail)
        }

        [
            (OfficeBoard.networkingAnchor, "SCAN"),
            (OfficeBoard.cubicleBuilderAnchor, "BASE"),
            (OfficeBoard.pipeDexAnchor, "CRM")
        ].forEach { anchor, label in
            addFloorInlay(label, at: OfficeBoard.worldPosition(for: anchor, footprint: GridSize(width: 1, height: 1)))
        }
    }

    private func addFloorInlay(_ text: String, at position: CGPoint) {
        let plate = SKShapeNode(rectOf: CGSize(width: 74, height: 28), cornerRadius: 10)
        plate.position = position + CGPoint(x: 0, y: -42)
        plate.fillColor = Palette.fixtureTop.withAlphaComponent(0.70)
        plate.strokeColor = Palette.fixtureInk.withAlphaComponent(0.20)
        plate.lineWidth = 1.2
        plate.zPosition = 3
        officeDecorLayer.addChild(plate)

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 11
        label.fontColor = Palette.fixtureInk.withAlphaComponent(0.72)
        label.verticalAlignmentMode = .center
        label.position = plate.position
        label.zPosition = 4
        officeDecorLayer.addChild(label)
    }

    private func addDeskNeighborhoods() {
        [
            (CubicleGridPoint(column: 6, row: 11), 3, 2),
            (CubicleGridPoint(column: 19, row: 11), 3, 2),
            (CubicleGridPoint(column: 7, row: 17), 2, 2),
            (CubicleGridPoint(column: 20, row: 17), 2, 2),
            (CubicleGridPoint(column: 9, row: 22), 2, 2),
            (CubicleGridPoint(column: 17, row: 4), 2, 3)
        ].forEach { origin, columns, rows in
            addDeskNeighborhood(origin: origin, columns: columns, rows: rows)
        }
    }

    private func addDeskNeighborhood(origin: CubicleGridPoint, columns: Int, rows: Int) {
        for dc in 0..<columns {
            for dr in 0..<rows {
                let point = origin.offset(column: dc * 2, row: dr * 2)
                guard OfficeBoard.isBuildable(point) else { continue }
                addWorkstation(at: OfficeBoard.worldPosition(for: point, footprint: GridSize(width: 1, height: 1)),
                               alternate: (dc + dr).isMultiple(of: 2))
            }
        }
    }

    private func addWorkstation(at position: CGPoint, alternate: Bool) {
        let node = SKNode()
        node.position = position
        node.zPosition = 6

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 78, height: 44))
        shadow.position = CGPoint(x: 0, y: -12)
        shadow.fillColor = Palette.shadow.withAlphaComponent(0.16)
        shadow.strokeColor = .clear
        node.addChild(shadow)

        let desk = SKShapeNode(rectOf: CGSize(width: 64, height: 34), cornerRadius: 9)
        desk.position = CGPoint(x: 0, y: -2)
        desk.fillColor = (alternate ? Palette.fixtureTop : Palette.floorWarm).withAlphaComponent(0.84)
        desk.strokeColor = Palette.wallBrass.withAlphaComponent(0.22)
        desk.lineWidth = 1
        node.addChild(desk)

        let screen = SKShapeNode(rectOf: CGSize(width: 27, height: 18), cornerRadius: 4)
        screen.position = CGPoint(x: -10, y: 10)
        screen.fillColor = Palette.glass.withAlphaComponent(0.68)
        screen.strokeColor = Palette.fixtureInk.withAlphaComponent(0.36)
        screen.lineWidth = 1.2
        node.addChild(screen)

        let chair = SKShapeNode(rectOf: CGSize(width: 30, height: 22), cornerRadius: 8)
        chair.position = CGPoint(x: 18, y: -26)
        chair.fillColor = (alternate ? Palette.carpetWine : Palette.glass).withAlphaComponent(0.60)
        chair.strokeColor = Palette.fixtureInk.withAlphaComponent(0.22)
        chair.lineWidth = 1.1
        node.addChild(chair)

        officeDecorLayer.addChild(node)
    }

    private func addLobbyKiosks() {
        [
            CubicleGridPoint(column: 12, row: 13),
            CubicleGridPoint(column: 17, row: 13),
            CubicleGridPoint(column: 12, row: 17),
            CubicleGridPoint(column: 17, row: 17)
        ].forEach { point in
            guard OfficeBoard.isBuildable(point) else { return }
            addStatusKiosk(at: OfficeBoard.worldPosition(for: point, footprint: GridSize(width: 1, height: 1)),
                           accent: (point.column + point.row).isMultiple(of: 2) ? Palette.carpetGold : Palette.glass)
        }
    }

    private func addStatusKiosk(at position: CGPoint, accent: SKColor) {
        let node = SKNode()
        node.position = position
        node.zPosition = 7

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 58, height: 34))
        shadow.position = CGPoint(x: 0, y: -16)
        shadow.fillColor = Palette.shadow.withAlphaComponent(0.18)
        shadow.strokeColor = .clear
        node.addChild(shadow)

        let pedestal = SKShapeNode(rectOf: CGSize(width: 34, height: 28), cornerRadius: 11)
        pedestal.position = CGPoint(x: 0, y: -8)
        pedestal.fillColor = Palette.fixtureTop.withAlphaComponent(0.96)
        pedestal.strokeColor = Palette.fixtureInk.withAlphaComponent(0.24)
        pedestal.lineWidth = 1.4
        node.addChild(pedestal)

        let screen = SKShapeNode(rectOf: CGSize(width: 42, height: 32), cornerRadius: 9)
        screen.position = CGPoint(x: 0, y: 12)
        screen.fillColor = Palette.glass.withAlphaComponent(0.72)
        screen.strokeColor = accent.withAlphaComponent(0.86)
        screen.lineWidth = 1.4
        screen.glowWidth = 2
        node.addChild(screen)

        for y in [-2, 7, 16] {
            let line = SKShapeNode(rectOf: CGSize(width: y == 7 ? 26 : 18, height: 3), cornerRadius: 1.5)
            line.position = CGPoint(x: 0, y: CGFloat(y))
            line.fillColor = accent.withAlphaComponent(y == 7 ? 0.74 : 0.46)
            line.strokeColor = .clear
            node.addChild(line)
        }

        officeDecorLayer.addChild(node)
    }

    private func addGlassConferenceRooms() {
        addGlassConferenceRoom(origin: CubicleGridPoint(column: 5, row: 5), width: 4, height: 3)
        addGlassConferenceRoom(origin: CubicleGridPoint(column: 21, row: 21), width: 4, height: 3)
    }

    private func addGlassConferenceRoom(origin: CubicleGridPoint, width: Int, height: Int) {
        let position = OfficeBoard.worldPosition(for: origin, footprint: GridSize(width: width, height: height))
        let size = CGSize(width: CGFloat(width) * GameMetrics.tileSize - 10,
                          height: CGFloat(height) * GameMetrics.tileSize - 10)
        let node = SKNode()
        node.position = position
        node.zPosition = 5

        let glass = SKShapeNode(rectOf: size, cornerRadius: 22)
        glass.fillColor = Palette.glass.withAlphaComponent(0.12)
        glass.strokeColor = Palette.glass.withAlphaComponent(0.40)
        glass.lineWidth = 2
        glass.glowWidth = 4
        node.addChild(glass)

        let table = SKShapeNode(rectOf: CGSize(width: size.width * 0.58, height: 42), cornerRadius: 15)
        table.position = CGPoint(x: 0, y: 0)
        table.fillColor = Palette.floorWarm.withAlphaComponent(0.82)
        table.strokeColor = Palette.fixtureInk.withAlphaComponent(0.22)
        table.lineWidth = 1.2
        node.addChild(table)

        for x in stride(from: -size.width * 0.34, through: size.width * 0.34, by: 42) {
            let chairTop = SKShapeNode(ellipseOf: CGSize(width: 20, height: 14))
            chairTop.position = CGPoint(x: x, y: 34)
            chairTop.fillColor = Palette.fixtureTop.withAlphaComponent(0.62)
            chairTop.strokeColor = SKColor.white.withAlphaComponent(0.12)
            chairTop.lineWidth = 0.8
            node.addChild(chairTop)

            let chairBottom = SKShapeNode(ellipseOf: CGSize(width: 20, height: 14))
            chairBottom.position = CGPoint(x: x, y: -34)
            chairBottom.fillColor = Palette.fixtureTop.withAlphaComponent(0.50)
            chairBottom.strokeColor = SKColor.white.withAlphaComponent(0.10)
            chairBottom.lineWidth = 0.8
            node.addChild(chairBottom)
        }

        officeDecorLayer.addChild(node)
    }

    private func addPlanters() {
        [
            boardPoint(column: 5, row: 21),
            boardPoint(column: 9, row: 27),
            boardPoint(column: 18, row: 16),
            boardPoint(column: 21, row: 7)
        ].forEach { addPlanter(at: $0) }
    }

    private func addPlanter(at position: CGPoint) {
        let pot = SKShapeNode(rectOf: CGSize(width: 34, height: 24), cornerRadius: 8)
        pot.position = position + CGPoint(x: 0, y: -5)
        pot.fillColor = Palette.wallBrass.withAlphaComponent(0.82)
        pot.strokeColor = SKColor.white.withAlphaComponent(0.20)
        pot.lineWidth = 1
        pot.zPosition = 4
        officeDecorLayer.addChild(pot)

        for offset in [-13, 0, 13] {
            let leaf = SKShapeNode(ellipseOf: CGSize(width: 22, height: 38))
            leaf.position = position + CGPoint(x: CGFloat(offset), y: 10)
            leaf.zRotation = CGFloat(offset) * 0.018
            leaf.fillColor = (offset == 0 ? Palette.plantLight : Palette.plantDark).withAlphaComponent(0.86)
            leaf.strokeColor = SKColor.white.withAlphaComponent(0.12)
            leaf.lineWidth = 0.6
            leaf.zPosition = 5
            officeDecorLayer.addChild(leaf)
        }
    }

    private func addSupplyArchiveWall() {
        let position = boardPoint(column: 23, row: 3, width: 4, height: 4)
        let wall = SKShapeNode(rectOf: CGSize(width: 236, height: 236), cornerRadius: 18)
        wall.position = position
        wall.fillColor = Palette.fixtureTop.withAlphaComponent(0.54)
        wall.strokeColor = Palette.fixtureInk.withAlphaComponent(0.16)
        wall.lineWidth = 1.4
        wall.zPosition = 2
        officeDecorLayer.addChild(wall)

        for row in 0..<3 {
            for column in 0..<3 {
                let box = SKShapeNode(rectOf: CGSize(width: 42, height: 30), cornerRadius: 5)
                box.position = position + CGPoint(x: CGFloat(column - 1) * 54, y: CGFloat(row - 1) * 46)
                box.fillColor = (row + column).isMultiple(of: 2)
                    ? Palette.floorWarm.withAlphaComponent(0.72)
                    : Palette.carpetWine.withAlphaComponent(0.42)
                box.strokeColor = Palette.fixtureInk.withAlphaComponent(0.18)
                box.lineWidth = 1.1
                box.zPosition = 3
                officeDecorLayer.addChild(box)
            }
        }
    }

    private func addOfficeMarker(_ marker: OfficeMapMarker) {
        if let roomType = marker.entrance.roomType {
            addRoomFixtureMarker(marker, roomType: roomType)
        } else {
            addSignpostMarker(marker)
        }
    }

    private func addSignpostMarker(_ marker: OfficeMapMarker) {
        let node = SKNode()
        node.position = marker.position
        node.alpha = marker.entrance.isLocked ? 0.60 : 0.98

        let size = CGSize(width: 128, height: 96)
        let shadow = SKShapeNode(ellipseOf: CGSize(width: size.width + 22, height: size.height * 0.52))
        shadow.position = CGPoint(x: 0, y: -22)
        shadow.fillColor = Palette.shadow.withAlphaComponent(0.16)
        shadow.strokeColor = .clear
        node.addChild(shadow)

        let pad = SKShapeNode(rectOf: size, cornerRadius: 22)
        pad.fillColor = marker.color.withAlphaComponent(0.18)
        pad.strokeColor = marker.entrance.isLocked
            ? Palette.fixtureInk.withAlphaComponent(0.16)
            : marker.color.withAlphaComponent(0.58)
        pad.lineWidth = 2
        pad.glowWidth = marker.entrance.isLocked ? 0 : 3
        node.addChild(pad)

        let plinth = SKShapeNode(rectOf: CGSize(width: size.width - 18, height: size.height - 18), cornerRadius: 17)
        plinth.fillColor = Palette.fixtureTop.withAlphaComponent(0.94)
        plinth.strokeColor = Palette.fixtureInk.withAlphaComponent(0.28)
        plinth.lineWidth = 1.6
        node.addChild(plinth)

        addLandmarkDetails(to: node, route: marker.entrance.route, color: marker.color, size: size)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = marker.entrance.title.uppercased()
        titleLabel.fontSize = 10.5
        titleLabel.fontColor = Palette.fixtureInk.withAlphaComponent(0.92)
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: -size.height * 0.5 + 18)
        node.addChild(titleLabel)

        let subtitleLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        subtitleLabel.text = marker.entrance.route.compactTitle.uppercased()
        subtitleLabel.fontSize = 7.5
        subtitleLabel.fontColor = marker.entrance.isLocked
            ? Palette.fixtureInk.withAlphaComponent(0.38)
            : marker.color.withAlphaComponent(0.95)
        subtitleLabel.horizontalAlignmentMode = .center
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.position = CGPoint(x: 0, y: -size.height * 0.5 + 6)
        node.addChild(subtitleLabel)

        officeMarkerLayer.addChild(node)
    }

    private func addLandmarkDetails(to node: SKNode, route: GameRoute, color: SKColor, size: CGSize) {
        switch route {
        case .prospecting:
            for x in [-28, 0, 28] {
                let leaf = SKShapeNode(ellipseOf: CGSize(width: 20, height: 38))
                leaf.position = CGPoint(x: CGFloat(x), y: 18)
                leaf.zRotation = CGFloat(x) * 0.014
                leaf.fillColor = (x == 0 ? Palette.plantLight : Palette.plantDark).withAlphaComponent(0.86)
                leaf.strokeColor = SKColor.white.withAlphaComponent(0.16)
                leaf.lineWidth = 0.8
                node.addChild(leaf)
            }
            addMiniLabel("NET", to: node, color: color, y: 0)
        case .cubicleBuilder:
            let table = SKShapeNode(rectOf: CGSize(width: size.width * 0.54, height: 28), cornerRadius: 8)
            table.position = CGPoint(x: 0, y: 16)
            table.fillColor = Palette.fixtureTop.withAlphaComponent(0.88)
            table.strokeColor = color.withAlphaComponent(0.62)
            table.lineWidth = 1.4
            node.addChild(table)

            for x in [-22, 0, 22] {
                let mark = SKShapeNode(rectOf: CGSize(width: 3, height: 17), cornerRadius: 1.5)
                mark.position = CGPoint(x: CGFloat(x), y: 16)
                mark.fillColor = color.withAlphaComponent(0.74)
                mark.strokeColor = .clear
                node.addChild(mark)
            }
            addMiniLabel("BASE", to: node, color: color, y: -4)
        case .pipeDex:
            let board = SKShapeNode(rectOf: CGSize(width: size.width * 0.58, height: 44), cornerRadius: 9)
            board.position = CGPoint(x: 0, y: 14)
            board.fillColor = Palette.glass.withAlphaComponent(0.76)
            board.strokeColor = color.withAlphaComponent(0.70)
            board.lineWidth = 1.6
            node.addChild(board)

            for index in 0..<3 {
                let slot = SKShapeNode(rectOf: CGSize(width: 42, height: 7), cornerRadius: 3.5)
                slot.position = CGPoint(x: 0, y: CGFloat(index) * 12 + 2)
                slot.fillColor = color.withAlphaComponent(0.52)
                slot.strokeColor = .clear
                node.addChild(slot)
            }
            addMiniLabel("CRM", to: node, color: color, y: -15)
        default:
            addMiniLabel(route.compactTitle.uppercased(), to: node, color: color, y: 5)
        }
    }

    private func addMiniLabel(_ text: String, to node: SKNode, color: SKColor, y: CGFloat) {
        let badge = SKShapeNode(rectOf: CGSize(width: 52, height: 22), cornerRadius: 9)
        badge.position = CGPoint(x: 0, y: y)
        badge.fillColor = color.withAlphaComponent(0.72)
        badge.strokeColor = SKColor.white.withAlphaComponent(0.22)
        badge.lineWidth = 1
        node.addChild(badge)

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 10
        label.fontColor = Palette.fixtureInk.withAlphaComponent(0.86)
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: y)
        node.addChild(label)
    }

    private func addRoomFixtureMarker(_ marker: OfficeMapMarker, roomType: CubicleRoomType) {
        let footprint = marker.footprint ?? roomType.footprint
        let size = CGSize(
            width: max(54, CGFloat(footprint.width) * GameMetrics.tileSize - 8),
            height: max(86, CGFloat(footprint.height) * GameMetrics.tileSize - 8)
        )

        let node = SKNode()
        node.position = marker.position
        node.alpha = 0.98

        let shadow = SKShapeNode(ellipseOf: CGSize(width: size.width + 24, height: max(34, size.height * 0.34)))
        shadow.position = CGPoint(x: 0, y: -size.height * 0.48)
        shadow.fillColor = Palette.shadow.withAlphaComponent(0.18)
        shadow.strokeColor = .clear
        node.addChild(shadow)

        let base = SKShapeNode(rectOf: size, cornerRadius: 20)
        base.fillColor = roomType.color.withAlphaComponent(0.18)
        base.strokeColor = Palette.fixtureInk.withAlphaComponent(0.26)
        base.lineWidth = 2.0
        base.glowWidth = 2
        node.addChild(base)

        let roomFill = SKShapeNode(rectOf: CGSize(width: size.width - 10, height: size.height - 10), cornerRadius: 16)
        roomFill.fillColor = Palette.fixtureTop.withAlphaComponent(0.94)
        roomFill.strokeColor = roomType.color.withAlphaComponent(0.38)
        roomFill.lineWidth = 1.6
        node.addChild(roomFill)

        let header = SKShapeNode(rectOf: CGSize(width: max(34, size.width - 20), height: 12), cornerRadius: 6)
        header.position = CGPoint(x: 0, y: size.height * 0.5 - 16)
        header.fillColor = roomType.color.withAlphaComponent(0.68)
        header.strokeColor = Palette.fixtureInk.withAlphaComponent(0.12)
        header.lineWidth = 0.8
        node.addChild(header)

        let sheen = SKShapeNode(rectOf: CGSize(width: max(30, size.width - 24), height: max(18, size.height * 0.18)), cornerRadius: 10)
        sheen.position = CGPoint(x: 0, y: size.height * 0.22)
        sheen.fillColor = Palette.glass.withAlphaComponent(0.24)
        sheen.strokeColor = .clear
        node.addChild(sheen)

        addFixtureDetails(to: node, roomType: roomType, size: size)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = roomType.shortName.uppercased()
        titleLabel.fontSize = min(10.5, max(7.4, size.width / 8.5))
        titleLabel.fontColor = Palette.fixtureInk.withAlphaComponent(0.90)
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: -size.height * 0.5 + 18)
        node.addChild(titleLabel)

        let routeLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        routeLabel.text = marker.entrance.route.compactTitle.uppercased()
        routeLabel.fontSize = min(7.5, max(6, size.width / 11))
        routeLabel.fontColor = roomType.color.withAlphaComponent(0.92)
        routeLabel.horizontalAlignmentMode = .center
        routeLabel.verticalAlignmentMode = .center
        routeLabel.position = CGPoint(x: 0, y: -size.height * 0.5 + 6)
        node.addChild(routeLabel)

        let doorway = SKShapeNode(rectOf: CGSize(width: min(48, size.width * 0.44), height: 7), cornerRadius: 3.5)
        doorway.position = CGPoint(x: 0, y: -size.height * 0.5 - 1)
        doorway.fillColor = roomType.color.withAlphaComponent(0.82)
        doorway.strokeColor = .clear
        node.addChild(doorway)

        officeMarkerLayer.addChild(node)
    }

    private func addFixtureDetails(to node: SKNode, roomType: CubicleRoomType, size: CGSize) {
        switch roomType {
        case .premiumCoffeeBar:
            addCounter(to: node, size: CGSize(width: size.width * 0.58, height: 17), y: 18, color: roomType.color)
            for index in -1...1 {
                let cup = SKShapeNode(circleOfRadius: 5)
                cup.position = CGPoint(x: CGFloat(index) * 18, y: -6)
                cup.fillColor = SKColor.white.withAlphaComponent(0.78)
                cup.strokeColor = roomType.color.withAlphaComponent(0.95)
                cup.lineWidth = 1
                node.addChild(cup)
            }
        case .saasTestingLab:
            addCounter(to: node, size: CGSize(width: size.width * 0.68, height: 22), y: 4, color: roomType.color)
            for index in 0..<3 {
                let tube = SKShapeNode(rectOf: CGSize(width: 9, height: 30), cornerRadius: 4.5)
                tube.position = CGPoint(x: CGFloat(index - 1) * 20, y: 22)
                tube.fillColor = SKColor.white.withAlphaComponent(0.16)
                tube.strokeColor = roomType.color.withAlphaComponent(0.95)
                tube.lineWidth = 1.4
                node.addChild(tube)
            }
        case .itHelpDesk:
            let monitor = SKShapeNode(rectOf: CGSize(width: min(54, size.width * 0.58), height: 32), cornerRadius: 6)
            monitor.position = CGPoint(x: 0, y: 14)
            monitor.fillColor = Palette.glass.withAlphaComponent(0.74)
            monitor.strokeColor = roomType.color.withAlphaComponent(0.95)
            monitor.lineWidth = 1.5
            node.addChild(monitor)
            addCounter(to: node, size: CGSize(width: size.width * 0.64, height: 10), y: -12, color: roomType.color)
        case .executiveLounge:
            addCounter(to: node, size: CGSize(width: size.width * 0.62, height: 18), y: -6, color: roomType.color)
            for x in [-22, 22] {
                let couch = SKShapeNode(rectOf: CGSize(width: 28, height: 42), cornerRadius: 10)
                couch.position = CGPoint(x: CGFloat(x), y: 18)
                couch.fillColor = roomType.color.withAlphaComponent(0.48)
                couch.strokeColor = SKColor.white.withAlphaComponent(0.28)
                couch.lineWidth = 1
                node.addChild(couch)
            }
        case .supplyArchive:
            for row in 0..<2 {
                for column in 0..<2 {
                    let box = SKShapeNode(rectOf: CGSize(width: 24, height: 18), cornerRadius: 4)
                    box.position = CGPoint(x: CGFloat(column) * 28 - 14, y: CGFloat(row) * 22 - 2)
                    box.fillColor = roomType.color.withAlphaComponent(0.58)
                    box.strokeColor = SKColor.white.withAlphaComponent(0.22)
                    box.lineWidth = 1
                    node.addChild(box)
                }
            }
        }
    }

    private func addCounter(to node: SKNode, size: CGSize, y: CGFloat, color: SKColor) {
        let counter = SKShapeNode(rectOf: size, cornerRadius: 8)
        counter.position = CGPoint(x: 0, y: y)
        counter.fillColor = color.withAlphaComponent(0.44)
        counter.strokeColor = SKColor.white.withAlphaComponent(0.24)
        counter.lineWidth = 1
        node.addChild(counter)
    }

    private func markerColor(for route: GameRoute) -> SKColor {
        switch route {
        case .prospecting: SKColor(red: 0.20, green: 0.62, blue: 0.44, alpha: 1)
        case .cubicleBuilder: SKColor(red: 0.20, green: 0.55, blue: 0.62, alpha: 1)
        case .pipeDex: SKColor(red: 0.14, green: 0.58, blue: 0.36, alpha: 1)
        case .qBot: SKColor(red: 0.88, green: 0.46, blue: 0.18, alpha: 1)
        case .bidDesk: SKColor(red: 0.82, green: 0.20, blue: 0.26, alpha: 1)
        default: SKColor(red: 0.50, green: 0.55, blue: 0.62, alpha: 1)
        }
    }

    private func updateNearbyEntrance(forceNotify: Bool = false) {
        let nearby = officeMarkers
            .map { marker in
                (marker: marker, distance: hypot(player.position.x - marker.position.x,
                                                 player.position.y - marker.position.y))
            }
            .filter { $0.distance <= $0.marker.interactionRadius }
            .min { $0.distance < $1.distance }?
            .marker
            .entrance

        guard forceNotify || nearby != currentEntrance else { return }
        currentEntrance = nearby
        onEntranceChanged?(nearby)
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
        player.updateMotion(velocity: body.velocity)

        probeForEncounter()
        updateNearbyEntrance()
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

private struct OfficeMapMarker {
    let entrance: OfficeEntrance
    let position: CGPoint
    let color: SKColor
    let footprint: GridSize?
    let interactionRadius: CGFloat
}

private func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}
