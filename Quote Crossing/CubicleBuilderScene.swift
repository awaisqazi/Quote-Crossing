//
//  CubicleBuilderScene.swift
//  Quote Crossing
//
//  SpriteKit-backed cubicle base builder embedded in SwiftUI.
//

import SwiftUI
import SpriteKit

enum CubicleRoomType: String, CaseIterable, Identifiable, Codable {
    case premiumCoffeeBar
    case saasTestingLab
    case itHelpDesk
    case executiveLounge
    case supplyArchive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .premiumCoffeeBar: "Premium Coffee Bar"
        case .saasTestingLab: "SaaS Testing Lab"
        case .itHelpDesk: "IT Help Desk"
        case .executiveLounge: "Executive Lounge"
        case .supplyArchive: "Supply Archive"
        }
    }

    var shortName: String {
        switch self {
        case .premiumCoffeeBar: "Coffee"
        case .saasTestingLab: "SaaS Lab"
        case .itHelpDesk: "IT Desk"
        case .executiveLounge: "Lounge"
        case .supplyArchive: "Archive"
        }
    }

    var footprint: GridSize {
        switch self {
        case .premiumCoffeeBar: GridSize(width: 1, height: 3)
        case .saasTestingLab: GridSize(width: 2, height: 3)
        case .itHelpDesk: GridSize(width: 1, height: 2)
        case .executiveLounge: GridSize(width: 2, height: 2)
        case .supplyArchive: GridSize(width: 1, height: 1)
        }
    }

    var aestheticValue: Int {
        switch self {
        case .premiumCoffeeBar: 36
        case .saasTestingLab: 48
        case .itHelpDesk: 28
        case .executiveLounge: 54
        case .supplyArchive: 12
        }
    }

    var agilityBoost: Int {
        switch self {
        case .premiumCoffeeBar: 2
        case .executiveLounge: 1
        case .saasTestingLab, .itHelpDesk, .supplyArchive: 0
        }
    }

    var jargonRecovery: Int {
        switch self {
        case .saasTestingLab: 10
        case .executiveLounge: 4
        case .premiumCoffeeBar, .itHelpDesk, .supplyArchive: 0
        }
    }

    var symbolName: String {
        switch self {
        case .premiumCoffeeBar: "cup.and.saucer.fill"
        case .saasTestingLab: "testtube.2"
        case .itHelpDesk: "desktopcomputer"
        case .executiveLounge: "sofa.fill"
        case .supplyArchive: "archivebox.fill"
        }
    }

    var color: SKColor {
        switch self {
        case .premiumCoffeeBar: SKColor(red: 0.79, green: 0.48, blue: 0.23, alpha: 1)
        case .saasTestingLab: SKColor(red: 0.24, green: 0.56, blue: 0.88, alpha: 1)
        case .itHelpDesk: SKColor(red: 0.24, green: 0.70, blue: 0.52, alpha: 1)
        case .executiveLounge: SKColor(red: 0.64, green: 0.44, blue: 0.88, alpha: 1)
        case .supplyArchive: SKColor(red: 0.46, green: 0.48, blue: 0.52, alpha: 1)
        }
    }
}

struct GridSize: Equatable {
    let width: Int
    let height: Int
}

struct CubicleGridPoint: Hashable, Codable {
    let column: Int
    let row: Int

    func offset(column dc: Int, row dr: Int) -> CubicleGridPoint {
        CubicleGridPoint(column: column + dc, row: row + dr)
    }
}

final class CubicleBuilderScene: SKScene {
    struct StateSnapshot: Equatable {
        var fengShuiScore: Double
        var roomCount: Int
        var suiteCount: Int
        var agilityBoost: Int
        var jargonRecovery: Int
        var incidentMessage: String

        static let empty = StateSnapshot(
            fengShuiScore: 0,
            roomCount: 0,
            suiteCount: 0,
            agilityBoost: 0,
            jargonRecovery: 0,
            incidentMessage: "Place rooms on the floor plan."
        )
    }

    private struct RoomPlacement: Identifiable, Equatable, Codable {
        let id: UUID
        let type: CubicleRoomType
        let origin: CubicleGridPoint
        var durability: Int = 100

        init(id: UUID = UUID(), type: CubicleRoomType, origin: CubicleGridPoint, durability: Int = 100) {
            self.id = id
            self.type = type
            self.origin = origin
            self.durability = durability
        }

        var cells: Set<CubicleGridPoint> {
            var result = Set<CubicleGridPoint>()
            for dc in 0..<type.footprint.width {
                for dr in 0..<type.footprint.height {
                    result.insert(origin.offset(column: dc, row: dr))
                }
            }
            return result
        }
    }

    private struct RoomSuite {
        let type: CubicleRoomType
        let placementIDs: [UUID]
        let cells: Set<CubicleGridPoint>

        var suiteMultiplier: Double {
            Double(min(placementIDs.count, 3))
        }

        var displayName: String {
            switch placementIDs.count {
            case 1: type.shortName
            case 2: "Double \(type.shortName)"
            default: "Triple \(type.shortName)"
            }
        }
    }

    private enum IncidentKind: CaseIterable {
        case officeAudit
        case coffeeSpill
        case vendorFireDrill

        var displayName: String {
            switch self {
            case .officeAudit: "Office Audit"
            case .coffeeSpill: "Coffee Spill"
            case .vendorFireDrill: "Vendor Fire Drill"
            }
        }

        var damage: Int {
            switch self {
            case .officeAudit: 36
            case .coffeeSpill: 28
            case .vendorFireDrill: 32
            }
        }

        var color: SKColor {
            switch self {
            case .officeAudit: SKColor(red: 0.92, green: 0.24, blue: 0.25, alpha: 1)
            case .coffeeSpill: SKColor(red: 0.65, green: 0.40, blue: 0.20, alpha: 1)
            case .vendorFireDrill: SKColor(red: 0.95, green: 0.62, blue: 0.20, alpha: 1)
            }
        }
    }

    var onStateChanged: ((StateSnapshot) -> Void)?

    private let gridColumns = OfficeBoard.columns
    private let gridRows = OfficeBoard.rows
    private var tileWidth: CGFloat {
        max(23, min(33, (size.width - 36) / 13.7))
    }
    private var tileHeight: CGFloat { tileWidth }
    private let supplyArchivePenaltyMultiplier = 1.6
    private let saveKey = CubicleLayoutSummary.saveKey

    private var selectedRoomType: CubicleRoomType = .premiumCoffeeBar
    private var placements: [RoomPlacement] = []
    private var suites: [RoomSuite] = []
    private var hoverOrigin: CubicleGridPoint?
    private var touchStartScenePoint: CGPoint?
    private var touchStartRootPosition: CGPoint?
    private var didPanBoard = false
    private var incidentMessage = "Place rooms on the floor plan."
    private var nextIncidentTime: TimeInterval = 0
    private var incidentInFlight = false

    private let elevator = OfficeBoard.elevator
    private let supplyArchives = OfficeBoard.supplyArchives

    private let sceneChromeLayer = SKNode()
    private let boardCropNode = SKCropNode()
    private let rootNode = SKNode()
    private let boardChromeLayer = SKNode()
    private let floorLayer = SKNode()
    private let landmarkLayer = SKNode()
    private let roomLayer = SKNode()
    private let suiteLayer = SKNode()
    private let previewLayer = SKNode()
    private let incidentLayer = SKNode()

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = Palette.sceneBackground
    }

    override convenience init() {
        self.init(size: CGSize(width: 1024, height: 768))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        guard rootNode.parent == nil else { return }
        sceneChromeLayer.zPosition = -8
        boardCropNode.zPosition = 2
        addChild(sceneChromeLayer)
        addChild(boardCropNode)
        boardCropNode.addChild(rootNode)
        rootNode.addChild(boardChromeLayer)
        rootNode.addChild(floorLayer)
        rootNode.addChild(landmarkLayer)
        rootNode.addChild(roomLayer)
        rootNode.addChild(suiteLayer)
        rootNode.addChild(previewLayer)
        rootNode.addChild(incidentLayer)
        loadLayout()
        updateSceneChrome()
        updateBoardMask()
        buildFloorPlan()
        layoutRoot()
        redrawRooms()
        recomputeSuitesAndScore()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        updateSceneChrome()
        updateBoardMask()
        layoutRoot()
        buildFloorPlan()
        redrawRooms()
        redrawSuiteOverlays()
        redrawPreview()
    }

    override func update(_ currentTime: TimeInterval) {
        if nextIncidentTime == 0 {
            nextIncidentTime = currentTime + Double.random(in: 8...14)
            return
        }

        guard currentTime >= nextIncidentTime, !incidentInFlight else { return }
        nextIncidentTime = currentTime + Double.random(in: 8...14)
        spawnIncident()
    }

    func setSelectedRoomType(_ type: CubicleRoomType) {
        selectedRoomType = type
        redrawPreview()
    }

    func clearLayout() {
        placements.removeAll()
        incidentMessage = "Floor plan cleared."
        saveLayout()
        redrawRooms()
        recomputeSuitesAndScore()
    }

    func requestStateRefresh() {
        publishState()
    }

    func spawnIncident() {
        guard !incidentInFlight else { return }
        incidentInFlight = true

        let kind = IncidentKind.allCases.randomElement() ?? .officeAudit
        incidentMessage = "\(kind.displayName) sweeping from elevator."
        publishState()

        let start = isoPoint(for: elevator) + CGPoint(x: -tileWidth * 0.55, y: 0)
        let end = isoPoint(for: CubicleGridPoint(column: gridColumns - 1, row: elevator.row)) + CGPoint(x: tileWidth * 0.55, y: 0)

        let wave = SKShapeNode(rectOf: CGSize(width: tileWidth * 0.74, height: tileHeight * 1.18), cornerRadius: max(3, tileWidth * 0.18))
        wave.fillColor = kind.color
        wave.strokeColor = .white.withAlphaComponent(0.75)
        wave.lineWidth = 2
        wave.alpha = 0.92
        wave.position = start
        wave.zPosition = 90
        incidentLayer.addChild(wave)

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "!"
        label.fontSize = 24
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        wave.addChild(label)

        wave.run(.sequence([
            .move(to: end, duration: 1.3),
            .fadeOut(withDuration: 0.15),
            .removeFromParent(),
            .run { [weak self] in
                self?.incidentInFlight = false
            }
        ]))

        run(.sequence([
            .wait(forDuration: 0.46),
            .run { [weak self] in
                self?.applyIncidentDamage(kind)
            }
        ]))
    }

    private func updateSceneChrome() {
        sceneChromeLayer.removeAllChildren()

        let background = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        background.fillColor = SKColor(red: 0.035, green: 0.043, blue: 0.052, alpha: 1)
        background.strokeColor = .clear
        background.zPosition = -30
        sceneChromeLayer.addChild(background)

        let viewport = mapViewport
        let tableShadow = SKShapeNode(rect: viewport.insetBy(dx: -10, dy: -10), cornerRadius: 32)
        tableShadow.fillColor = .black.withAlphaComponent(0.30)
        tableShadow.strokeColor = .clear
        tableShadow.position = CGPoint(x: 0, y: -4)
        tableShadow.zPosition = -22
        sceneChromeLayer.addChild(tableShadow)

        let table = SKShapeNode(rect: viewport.insetBy(dx: -5, dy: -5), cornerRadius: 28)
        table.fillColor = SKColor(red: 0.070, green: 0.086, blue: 0.096, alpha: 0.98)
        table.strokeColor = Palette.wallBrass.withAlphaComponent(0.24)
        table.lineWidth = 1.0
        table.zPosition = -21
        sceneChromeLayer.addChild(table)

        let inset = SKShapeNode(rect: viewport.insetBy(dx: 3, dy: 3), cornerRadius: 23)
        inset.fillColor = .clear
        inset.strokeColor = Palette.carpetGold.withAlphaComponent(0.28)
        inset.lineWidth = 1.1
        inset.glowWidth = 4
        inset.zPosition = -19
        sceneChromeLayer.addChild(inset)

        for index in 0..<5 {
            let line = SKShapeNode(rectOf: CGSize(width: size.width * 0.72, height: 1))
            line.position = CGPoint(x: size.width * 0.5, y: viewport.minY - CGFloat(index * 18) - 24)
            line.fillColor = SKColor.white.withAlphaComponent(0.025)
            line.strokeColor = .clear
            line.zPosition = -25
            sceneChromeLayer.addChild(line)
        }
    }

    private func updateBoardMask() {
        let mask = SKShapeNode(rect: mapViewport, cornerRadius: 24)
        mask.fillColor = .white
        mask.strokeColor = .clear
        boardCropNode.maskNode = mask
    }

    private func buildFloorPlan() {
        boardChromeLayer.removeAllChildren()
        floorLayer.removeAllChildren()
        landmarkLayer.removeAllChildren()
        addBoardChrome()

        for row in 0..<gridRows {
            for column in 0..<gridColumns {
                let point = CubicleGridPoint(column: column, row: row)
                let tile = SKShapeNode(path: diamondPath().cgPath)
                tile.position = isoPoint(for: point)
                tile.fillColor = tileFill(for: point)
                tile.strokeColor = tileStroke(for: point)
                tile.lineWidth = OfficeBoard.isBuildable(point) ? 0.55 : 0.8
                tile.zPosition = CGFloat(row + column)
                floorLayer.addChild(tile)

                if OfficeBoard.isBuildable(point) {
                    addPlacementGuide(at: point, baseZ: tile.zPosition + 0.01)
                }

                if point == elevator {
                    addMarker("ELEV", at: point, color: SKColor(red: 0.95, green: 0.72, blue: 0.18, alpha: 1))
                } else if point == OfficeBoard.cubicleBuilderAnchor {
                    addMarker("BASE", at: point, color: SKColor(red: 0.35, green: 0.82, blue: 0.88, alpha: 1))
                } else if point == OfficeBoard.pipeDexAnchor {
                    addMarker("CRM", at: point, color: SKColor(red: 0.28, green: 0.90, blue: 0.54, alpha: 1))
                } else if point == OfficeBoard.networkingAnchor {
                    addMarker("NET", at: point, color: SKColor(red: 0.38, green: 0.94, blue: 0.64, alpha: 1))
                } else if supplyArchives.contains(point) {
                    addMarker("SUP", at: point, color: SKColor(red: 0.48, green: 0.50, blue: 0.56, alpha: 1))
                }
            }
        }
    }

    private func addBoardChrome() {
        let boardSize = CGSize(width: CGFloat(gridColumns) * tileWidth,
                               height: CGFloat(gridRows) * tileHeight)
        let center = CGPoint(x: boardSize.width * 0.5, y: boardSize.height * 0.5)

        let shadow = SKShapeNode(rectOf: CGSize(width: boardSize.width + 32, height: boardSize.height + 32),
                                 cornerRadius: 34)
        shadow.position = center + CGPoint(x: 0, y: -8)
        shadow.fillColor = .black.withAlphaComponent(0.28)
        shadow.strokeColor = .clear
        shadow.zPosition = -20
        boardChromeLayer.addChild(shadow)

        let plate = SKShapeNode(rectOf: CGSize(width: boardSize.width + 24, height: boardSize.height + 24),
                                cornerRadius: 30)
        plate.position = center
        plate.fillColor = SKColor(red: 0.090, green: 0.108, blue: 0.116, alpha: 0.98)
        plate.strokeColor = SKColor.white.withAlphaComponent(0.13)
        plate.lineWidth = 1.2
        plate.zPosition = -18
        boardChromeLayer.addChild(plate)

        let innerGlow = SKShapeNode(rectOf: CGSize(width: boardSize.width + 8, height: boardSize.height + 8),
                                    cornerRadius: 24)
        innerGlow.position = center
        innerGlow.fillColor = .clear
        innerGlow.strokeColor = SKColor(red: 0.40, green: 0.66, blue: 0.78, alpha: 0.16)
        innerGlow.lineWidth = 2
        innerGlow.glowWidth = 5
        innerGlow.zPosition = -17
        boardChromeLayer.addChild(innerGlow)
    }

    private func addPlacementGuide(at point: CubicleGridPoint, baseZ: CGFloat) {
        let guide = SKShapeNode(rectOf: CGSize(width: tileWidth * 0.36, height: tileHeight * 0.36),
                                cornerRadius: max(3, tileWidth * 0.08))
        guide.position = isoPoint(for: point)
        guide.fillColor = SKColor.white.withAlphaComponent(0.035)
        guide.strokeColor = Palette.wallBrass.withAlphaComponent(0.10)
        guide.lineWidth = 0.7
        guide.zPosition = baseZ
        floorLayer.addChild(guide)
    }

    private func addMarker(_ text: String, at point: CubicleGridPoint, color: SKColor) {
        let node = SKNode()
        node.position = isoPoint(for: point)
        node.zPosition = 42

        let width = max(tileWidth * 1.68, 34)
        let badge = SKShapeNode(rectOf: CGSize(width: width, height: tileHeight * 0.86),
                                cornerRadius: max(5, tileWidth * 0.24))
        badge.fillColor = color.withAlphaComponent(0.22)
        badge.strokeColor = color.withAlphaComponent(0.82)
        badge.lineWidth = 1.2
        badge.glowWidth = 2.5
        node.addChild(badge)

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = min(11, max(7, tileWidth * 0.36))
        label.fontColor = .white.withAlphaComponent(0.92)
        label.position = .zero
        label.verticalAlignmentMode = .center
        node.addChild(label)

        landmarkLayer.addChild(node)
    }

    private func tileFill(for point: CubicleGridPoint) -> SKColor {
        if point == OfficeBoard.cubicleBuilderAnchor {
            return SKColor(red: 0.09, green: 0.36, blue: 0.43, alpha: 1)
        }
        if point == OfficeBoard.pipeDexAnchor {
            return SKColor(red: 0.08, green: 0.36, blue: 0.23, alpha: 1)
        }
        if point == OfficeBoard.networkingAnchor {
            return SKColor(red: 0.11, green: 0.42, blue: 0.27, alpha: 1)
        }

        switch OfficeBoard.tile(at: point) {
        case .elevator:
            return Palette.carpetGold.withAlphaComponent(0.54)
        case .supplyArchive:
            return SKColor(red: 0.33, green: 0.32, blue: 0.29, alpha: 1)
        case .wall:
            return SKColor(red: 0.12, green: 0.14, blue: 0.15, alpha: 1)
        case .lounge:
            return Palette.lounge.withAlphaComponent(0.88)
        case .carpet:
            return Palette.carpet.withAlphaComponent(0.94)
        case .floor:
            return (point.column + point.row).isMultiple(of: 2)
                ? SKColor(red: 0.54, green: 0.60, blue: 0.59, alpha: 1)
                : SKColor(red: 0.45, green: 0.51, blue: 0.51, alpha: 1)
        }
    }

    private func tileStroke(for point: CubicleGridPoint) -> SKColor {
        switch OfficeBoard.tile(at: point) {
        case .wall:
            return SKColor.white.withAlphaComponent(0.06)
        case .lounge:
            return Palette.plantLight.withAlphaComponent(0.20)
        case .carpet, .elevator:
            return Palette.carpetGold.withAlphaComponent(0.18)
        case .supplyArchive:
            return Palette.wallBrass.withAlphaComponent(0.18)
        case .floor:
            return SKColor.white.withAlphaComponent(0.10)
        }
    }

    private func layoutRoot() {
        let focus = placements.last?.origin ?? CubicleGridPoint(column: 15, row: 15)
        let focusPoint = isoPoint(for: focus)
        let viewport = mapViewport
        rootNode.position = clampedRootPosition(
            CGPoint(x: viewport.midX - focusPoint.x, y: viewport.midY - focusPoint.y)
        )
    }

    private var mapViewport: CGRect {
        let bottomInset = max(202, size.height * 0.235)
        let topInset = max(166, size.height * 0.19)
        return CGRect(
            x: 18,
            y: bottomInset,
            width: max(260, size.width - 36),
            height: max(280, size.height - bottomInset - topInset)
        )
    }

    private func clampedRootPosition(_ proposed: CGPoint) -> CGPoint {
        let boardSize = CGSize(width: CGFloat(gridColumns) * tileWidth,
                               height: CGFloat(gridRows) * tileHeight)
        let viewport = mapViewport
        var x = proposed.x
        var y = proposed.y

        if boardSize.width <= viewport.width {
            x = viewport.midX - boardSize.width * 0.5
        } else {
            x = min(viewport.minX, max(viewport.maxX - boardSize.width, x))
        }

        if boardSize.height <= viewport.height {
            y = viewport.midY - boardSize.height * 0.5
        } else {
            y = min(viewport.minY, max(viewport.maxY - boardSize.height, y))
        }

        return CGPoint(x: x, y: y)
    }

    private func placeRoom(at origin: CubicleGridPoint) {
        if let index = placements.firstIndex(where: { $0.cells.contains(origin) }) {
            incidentMessage = "Removed \(placements[index].type.displayName)."
            placements.remove(at: index)
            saveLayout()
            redrawRooms()
            recomputeSuitesAndScore()
            return
        }

        let candidate = RoomPlacement(type: selectedRoomType, origin: origin)
        guard canPlace(candidate) else {
            incidentMessage = "Cannot place \(selectedRoomType.shortName) there."
            publishState()
            flashInvalid(at: origin)
            return
        }

        placements.append(candidate)
        incidentMessage = "\(selectedRoomType.displayName) snapped to grid."
        saveLayout()
        redrawRooms()
        recomputeSuitesAndScore()
    }

    private func canPlace(_ placement: RoomPlacement) -> Bool {
        for cell in placement.cells {
            guard cell.column >= 0, cell.column < gridColumns,
                  cell.row >= 0, cell.row < gridRows else { return false }
            guard OfficeBoard.isBuildable(cell) else { return false }
            guard !placements.contains(where: { $0.cells.contains(cell) }) else { return false }
        }
        return true
    }

    private func redrawRooms() {
        roomLayer.removeAllChildren()

        for placement in placements {
            let node = SKNode()
            node.zPosition = CGFloat(placement.origin.column + placement.origin.row) + 30

            let frame = roomFrame(for: placement)
            let shadow = SKShapeNode(rectOf: frame.size, cornerRadius: max(8, tileWidth * 0.32))
            shadow.position = CGPoint(x: frame.midX, y: frame.midY - tileHeight * 0.16)
            shadow.fillColor = .black.withAlphaComponent(0.34)
            shadow.strokeColor = .clear
            node.addChild(shadow)

            let base = SKShapeNode(rectOf: frame.size, cornerRadius: max(8, tileWidth * 0.32))
            base.position = CGPoint(x: frame.midX, y: frame.midY)
            base.fillColor = placement.type.color.withAlphaComponent(0.70)
            base.strokeColor = SKColor.white.withAlphaComponent(0.46)
            base.lineWidth = 1.4
            base.glowWidth = 2.5
            node.addChild(base)

            for cell in placement.cells {
                let tile = SKShapeNode(path: diamondPath().cgPath)
                tile.position = isoPoint(for: cell)
                tile.fillColor = .clear
                tile.strokeColor = SKColor.white.withAlphaComponent(0.18)
                tile.lineWidth = 0.8
                node.addChild(tile)
            }

            addRoomFurnishings(to: node, placement: placement, frame: frame)

            let center = centerPoint(for: placement.cells)
            let icon = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            icon.text = symbol(for: placement.type)
            icon.fontSize = min(18, max(6, tileWidth * 0.76))
            icon.fontColor = .white
            icon.position = center + CGPoint(x: 0, y: tileHeight * 0.18)
            icon.verticalAlignmentMode = .center
            node.addChild(icon)

            let hp = SKLabelNode(fontNamed: "AvenirNext-Bold")
            hp.text = "\(placement.durability)%"
            hp.fontSize = min(10, max(4, tileWidth * 0.38))
            hp.fontColor = .white.withAlphaComponent(0.86)
            hp.position = center + CGPoint(x: 0, y: -tileHeight * 0.24)
            hp.verticalAlignmentMode = .center
            node.addChild(hp)

            roomLayer.addChild(node)
        }
    }

    private func roomFrame(for placement: RoomPlacement) -> CGRect {
        let footprint = placement.type.footprint
        let width = CGFloat(footprint.width) * tileWidth * 0.92
        let height = CGFloat(footprint.height) * tileHeight * 0.92
        let center = CGPoint(
            x: (CGFloat(placement.origin.column) + CGFloat(footprint.width) * 0.5) * tileWidth,
            y: (CGFloat(placement.origin.row) + CGFloat(footprint.height) * 0.5) * tileHeight
        )
        return CGRect(x: center.x - width * 0.5, y: center.y - height * 0.5, width: width, height: height)
    }

    private func addRoomFurnishings(to node: SKNode, placement: RoomPlacement, frame: CGRect) {
        let tint = placement.type.color
        switch placement.type {
        case .premiumCoffeeBar:
            addMiniBar(to: node, frame: frame, tint: tint)
        case .saasTestingLab:
            addMiniLab(to: node, frame: frame, tint: tint)
        case .itHelpDesk:
            addMiniHelpDesk(to: node, frame: frame, tint: tint)
        case .executiveLounge:
            addMiniLounge(to: node, frame: frame, tint: tint)
        case .supplyArchive:
            addMiniArchive(to: node, frame: frame, tint: tint)
        }
    }

    private func addMiniBar(to node: SKNode, frame: CGRect, tint: SKColor) {
        let counter = SKShapeNode(rectOf: CGSize(width: frame.width * 0.70, height: min(16, frame.height * 0.18)),
                                  cornerRadius: 5)
        counter.position = CGPoint(x: frame.midX, y: frame.midY + frame.height * 0.18)
        counter.fillColor = .black.withAlphaComponent(0.26)
        counter.strokeColor = SKColor.white.withAlphaComponent(0.18)
        node.addChild(counter)
        for offset in [-0.22, 0, 0.22] {
            let cup = SKShapeNode(circleOfRadius: max(2.2, tileWidth * 0.12))
            cup.position = CGPoint(x: frame.midX + frame.width * CGFloat(offset),
                                   y: frame.midY - frame.height * 0.12)
            cup.fillColor = SKColor.white.withAlphaComponent(0.78)
            cup.strokeColor = tint.withAlphaComponent(0.95)
            cup.lineWidth = 0.8
            node.addChild(cup)
        }
    }

    private func addMiniLab(to node: SKNode, frame: CGRect, tint: SKColor) {
        let bench = SKShapeNode(rectOf: CGSize(width: frame.width * 0.72, height: min(18, frame.height * 0.18)),
                                cornerRadius: 6)
        bench.position = CGPoint(x: frame.midX, y: frame.midY)
        bench.fillColor = .black.withAlphaComponent(0.24)
        bench.strokeColor = SKColor.white.withAlphaComponent(0.16)
        node.addChild(bench)
        for index in 0..<3 {
            let tube = SKShapeNode(rectOf: CGSize(width: max(4, tileWidth * 0.20), height: min(22, frame.height * 0.30)),
                                   cornerRadius: max(2, tileWidth * 0.10))
            tube.position = CGPoint(x: frame.midX + CGFloat(index - 1) * frame.width * 0.20,
                                    y: frame.midY + frame.height * 0.24)
            tube.fillColor = SKColor.white.withAlphaComponent(0.14)
            tube.strokeColor = SKColor.white.withAlphaComponent(0.55)
            tube.lineWidth = 0.9
            node.addChild(tube)
        }
    }

    private func addMiniHelpDesk(to node: SKNode, frame: CGRect, tint: SKColor) {
        let monitor = SKShapeNode(rectOf: CGSize(width: frame.width * 0.58, height: frame.height * 0.36),
                                  cornerRadius: 6)
        monitor.position = CGPoint(x: frame.midX, y: frame.midY + frame.height * 0.12)
        monitor.fillColor = SKColor(red: 0.03, green: 0.05, blue: 0.06, alpha: 0.92)
        monitor.strokeColor = SKColor.white.withAlphaComponent(0.36)
        monitor.lineWidth = 1
        node.addChild(monitor)

        let desk = SKShapeNode(rectOf: CGSize(width: frame.width * 0.68, height: max(6, frame.height * 0.14)),
                               cornerRadius: 4)
        desk.position = CGPoint(x: frame.midX, y: frame.midY - frame.height * 0.20)
        desk.fillColor = .black.withAlphaComponent(0.22)
        desk.strokeColor = SKColor.white.withAlphaComponent(0.14)
        node.addChild(desk)
        _ = tint
    }

    private func addMiniLounge(to node: SKNode, frame: CGRect, tint: SKColor) {
        for offset in [-0.20, 0.20] {
            let seat = SKShapeNode(rectOf: CGSize(width: frame.width * 0.26, height: frame.height * 0.58),
                                   cornerRadius: 8)
            seat.position = CGPoint(x: frame.midX + frame.width * CGFloat(offset), y: frame.midY + frame.height * 0.04)
            seat.fillColor = .black.withAlphaComponent(0.22)
            seat.strokeColor = SKColor.white.withAlphaComponent(0.18)
            node.addChild(seat)
        }
        _ = tint
    }

    private func addMiniArchive(to node: SKNode, frame: CGRect, tint: SKColor) {
        for row in 0..<2 {
            for column in 0..<2 {
                let box = SKShapeNode(rectOf: CGSize(width: frame.width * 0.33, height: frame.height * 0.30),
                                      cornerRadius: 4)
                box.position = CGPoint(x: frame.minX + frame.width * (0.32 + CGFloat(column) * 0.34),
                                       y: frame.minY + frame.height * (0.34 + CGFloat(row) * 0.32))
                box.fillColor = .black.withAlphaComponent(0.20)
                box.strokeColor = SKColor.white.withAlphaComponent(0.18)
                node.addChild(box)
            }
        }
        _ = tint
    }

    private func redrawSuiteOverlays() {
        suiteLayer.removeAllChildren()

        for suite in suites where suite.placementIDs.count > 1 {
            let hull = convexHull(points: suite.cells.flatMap { diamondPoints(for: $0) })
            guard hull.count >= 3 else { continue }

            let path = CGMutablePath()
            path.move(to: hull[0])
            for point in hull.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()

            let outline = SKShapeNode(path: path)
            outline.fillColor = .clear
            outline.strokeColor = SKColor(red: 0.96, green: 0.78, blue: 0.25, alpha: 1)
            outline.lineWidth = suite.placementIDs.count >= 3 ? 4 : 3
            outline.glowWidth = 5
            outline.zPosition = 75
            suiteLayer.addChild(outline)

            let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            label.text = suite.displayName.uppercased()
            label.fontSize = min(12, max(5, tileWidth * 0.50))
            label.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.28, alpha: 1)
            label.position = centerPoint(for: suite.cells) + CGPoint(x: 0, y: tileHeight * 1.25)
            label.verticalAlignmentMode = .center
            label.zPosition = 76
            suiteLayer.addChild(label)
        }
    }

    private func recomputeSuitesAndScore() {
        suites = buildSuites()
        redrawSuiteOverlays()
        publishState()
    }

    private func buildSuites() -> [RoomSuite] {
        var remaining = Set(placements.map(\.id))
        var result: [RoomSuite] = []

        while let startID = remaining.first,
              let start = placements.first(where: { $0.id == startID }) {
            remaining.remove(startID)
            var stack = [start]
            var cluster = [start]

            while let current = stack.popLast() {
                let neighbors = placements.filter { other in
                    remaining.contains(other.id)
                        && other.type == current.type
                        && footprintsTouch(current.cells, other.cells)
                }

                for neighbor in neighbors {
                    remaining.remove(neighbor.id)
                    stack.append(neighbor)
                    cluster.append(neighbor)
                }
            }

            result.append(RoomSuite(
                type: start.type,
                placementIDs: cluster.map(\.id),
                cells: cluster.reduce(into: Set<CubicleGridPoint>()) { $0.formUnion($1.cells) }
            ))
        }

        return result
    }

    private func footprintsTouch(_ lhs: Set<CubicleGridPoint>, _ rhs: Set<CubicleGridPoint>) -> Bool {
        for cell in lhs {
            if rhs.contains(cell.offset(column: 1, row: 0))
                || rhs.contains(cell.offset(column: -1, row: 0))
                || rhs.contains(cell.offset(column: 0, row: 1))
                || rhs.contains(cell.offset(column: 0, row: -1)) {
                return true
            }
        }
        return false
    }

    private func publishState() {
        var agility = 0
        var jargon = 0
        for suite in suites {
            let count = suite.placementIDs.count
            agility += Int(Double(suite.type.agilityBoost * count) * suite.suiteMultiplier)
            jargon += Int(Double(suite.type.jargonRecovery * count) * suite.suiteMultiplier)
        }

        onStateChanged?(StateSnapshot(
            fengShuiScore: calculateFengShuiScore(),
            roomCount: placements.count,
            suiteCount: suites.filter { $0.placementIDs.count > 1 }.count,
            agilityBoost: agility,
            jargonRecovery: jargon,
            incidentMessage: incidentMessage
        ))
    }

    private func calculateFengShuiScore() -> Double {
        // Phi_office = SUM( ln(D_j + 1) / (delta_j * mu_j) )
        suites.reduce(0) { partial, suite in
            let aesthetic = Double(suite.type.aestheticValue * suite.placementIDs.count) * suite.suiteMultiplier
            let delta = Double(max(1, distanceFromElevator(for: suite.cells)))
            let mu = isAdjacentToSupplyArchives(suite.cells) ? supplyArchivePenaltyMultiplier : 1.0
            return partial + (log(aesthetic + 1) / (delta * mu))
        }
    }

    private func distanceFromElevator(for cells: Set<CubicleGridPoint>) -> Int {
        cells.map { abs($0.column - elevator.column) + abs($0.row - elevator.row) }.min() ?? 1
    }

    private func isAdjacentToSupplyArchives(_ cells: Set<CubicleGridPoint>) -> Bool {
        for cell in cells {
            if supplyArchives.contains(cell.offset(column: 1, row: 0))
                || supplyArchives.contains(cell.offset(column: -1, row: 0))
                || supplyArchives.contains(cell.offset(column: 0, row: 1))
                || supplyArchives.contains(cell.offset(column: 0, row: -1)) {
                return true
            }
        }
        return false
    }

    private func applyIncidentDamage(_ kind: IncidentKind) {
        var incomingDamage = Double(kind.damage)
        var touched = Set<UUID>()
        var report = "\(kind.displayName): "
        var helpDeskTriggered = false

        for column in 0..<gridColumns {
            let pathCell = CubicleGridPoint(column: column, row: elevator.row)
            let impacted = placements
                .filter { $0.cells.contains(pathCell) && !touched.contains($0.id) }
                .sorted { $0.origin.column < $1.origin.column }

            for room in impacted {
                touched.insert(room.id)
                guard let index = placements.firstIndex(where: { $0.id == room.id }) else { continue }

                if room.type == .supplyArchive {
                    incomingDamage = 0
                    report += "Archive firewall stopped the sweep. "
                } else if room.type == .itHelpDesk {
                    let absorbedDamage = Int((incomingDamage * 0.5).rounded())
                    placements[index].durability = max(0, placements[index].durability - absorbedDamage)
                    incomingDamage *= 0.5
                    helpDeskTriggered = true
                    report += "IT Desk absorbed 50%. "
                } else {
                    let damage = Int(incomingDamage.rounded())
                    placements[index].durability = max(0, placements[index].durability - damage)
                    report += "\(room.type.shortName) -\(damage). "
                }
            }
        }

        if touched.isEmpty {
            report += "no rooms in path."
        } else if helpDeskTriggered {
            report += "Rooms behind were shielded."
        }

        let destroyed = placements.filter { $0.durability <= 0 }
        if !destroyed.isEmpty {
            report += " \(destroyed.count) room lost."
            placements.removeAll { $0.durability <= 0 }
        }

        incidentMessage = report
        saveLayout()
        redrawRooms()
        recomputeSuitesAndScore()
    }

    private func saveLayout() {
        guard let data = try? JSONEncoder().encode(placements) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
        UserDefaults.standard.set(true, forKey: OfficeBoard.mapAlignedLayoutKey)
    }

    private func loadLayout() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([RoomPlacement].self, from: data) else { return }
        let shouldMapLegacyLayout = !decoded.isEmpty
            && !UserDefaults.standard.bool(forKey: OfficeBoard.mapAlignedLayoutKey)
            && decoded.allSatisfy { OfficeBoard.isLegacyBuilderOrigin($0.origin) }

        if shouldMapLegacyLayout {
            placements = decoded.map { placement in
                RoomPlacement(
                    id: placement.id,
                    type: placement.type,
                    origin: OfficeBoard.mapAlignedOrigin(fromLegacy: placement.origin),
                    durability: placement.durability
                )
            }
            saveLayout()
        } else {
            placements = decoded
        }
    }

    private func redrawPreview() {
        previewLayer.removeAllChildren()
        guard let hoverOrigin else { return }

        let placement = RoomPlacement(type: selectedRoomType, origin: hoverOrigin)
        let valid = canPlace(placement)
        let frame = roomFrame(for: placement)

        let halo = SKShapeNode(rectOf: CGSize(width: frame.width + tileWidth * 0.22,
                                              height: frame.height + tileHeight * 0.22),
                               cornerRadius: max(9, tileWidth * 0.34))
        halo.position = CGPoint(x: frame.midX, y: frame.midY)
        halo.fillColor = valid
            ? selectedRoomType.color.withAlphaComponent(0.12)
            : SKColor(red: 0.94, green: 0.20, blue: 0.22, alpha: 0.14)
        halo.strokeColor = valid
            ? selectedRoomType.color.withAlphaComponent(0.86)
            : SKColor(red: 1.0, green: 0.25, blue: 0.30, alpha: 0.92)
        halo.lineWidth = 2.2
        halo.glowWidth = valid ? 5 : 3
        halo.zPosition = 101
        previewLayer.addChild(halo)

        for cell in placement.cells {
            let tile = SKShapeNode(path: diamondPath().cgPath)
            tile.position = isoPoint(for: cell)
            tile.fillColor = valid
                ? selectedRoomType.color.withAlphaComponent(0.18)
                : SKColor(red: 0.94, green: 0.20, blue: 0.22, alpha: 0.26)
            tile.strokeColor = valid ? .white.withAlphaComponent(0.72) : .red
            tile.lineWidth = 1.2
            tile.zPosition = 100
            previewLayer.addChild(tile)
        }
    }

    private func flashInvalid(at origin: CubicleGridPoint) {
        let node = SKShapeNode(path: diamondPath().cgPath)
        node.position = isoPoint(for: origin)
        node.fillColor = SKColor(red: 0.94, green: 0.20, blue: 0.22, alpha: 0.45)
        node.strokeColor = .white
        node.lineWidth = 2
        node.zPosition = 120
        previewLayer.addChild(node)
        node.run(.sequence([.fadeOut(withDuration: 0.35), .removeFromParent()]))
    }

    private func symbol(for type: CubicleRoomType) -> String {
        switch type {
        case .premiumCoffeeBar: "COF"
        case .saasTestingLab: "LAB"
        case .itHelpDesk: "IT"
        case .executiveLounge: "VIP"
        case .supplyArchive: "SUP"
        }
    }

    private func isoPoint(for point: CubicleGridPoint) -> CGPoint {
        CGPoint(
            x: (CGFloat(point.column) + 0.5) * tileWidth,
            y: (CGFloat(point.row) + 0.5) * tileHeight
        )
    }

    private func gridPoint(forScenePoint point: CGPoint) -> CubicleGridPoint? {
        let local = point - rootNode.position
        let column = Int(floor(local.x / tileWidth))
        let row = Int(floor(local.y / tileHeight))
        guard column >= 0, column < gridColumns, row >= 0, row < gridRows else { return nil }
        return CubicleGridPoint(column: column, row: row)
    }

    private func centerPoint(for cells: Set<CubicleGridPoint>) -> CGPoint {
        guard !cells.isEmpty else { return .zero }
        let points = cells.map { isoPoint(for: $0) }
        let x = points.reduce(0) { $0 + $1.x } / CGFloat(points.count)
        let y = points.reduce(0) { $0 + $1.y } / CGFloat(points.count)
        return CGPoint(x: x, y: y)
    }

    private func diamondPath() -> UIBezierPath {
        UIBezierPath(
            roundedRect: CGRect(
                x: -tileWidth * 0.47,
                y: -tileHeight * 0.47,
                width: tileWidth * 0.94,
                height: tileHeight * 0.94
            ),
            cornerRadius: max(1.5, tileWidth * 0.16)
        )
    }

    private func diamondPoints(for point: CubicleGridPoint) -> [CGPoint] {
        let center = isoPoint(for: point)
        return [
            center + CGPoint(x: -tileWidth * 0.47, y: -tileHeight * 0.47),
            center + CGPoint(x: tileWidth * 0.47, y: -tileHeight * 0.47),
            center + CGPoint(x: tileWidth * 0.47, y: tileHeight * 0.47),
            center + CGPoint(x: -tileWidth * 0.47, y: tileHeight * 0.47)
        ]
    }

    private func convexHull(points: [CGPoint]) -> [CGPoint] {
        let sorted = points.sorted {
            $0.x == $1.x ? $0.y < $1.y : $0.x < $1.x
        }
        guard sorted.count > 2 else { return sorted }

        func cross(_ origin: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
            (a.x - origin.x) * (b.y - origin.y) - (a.y - origin.y) * (b.x - origin.x)
        }

        var lower: [CGPoint] = []
        for point in sorted {
            while lower.count >= 2 && cross(lower[lower.count - 2], lower[lower.count - 1], point) <= 0 {
                lower.removeLast()
            }
            lower.append(point)
        }

        var upper: [CGPoint] = []
        for point in sorted.reversed() {
            while upper.count >= 2 && cross(upper[upper.count - 2], upper[upper.count - 1], point) <= 0 {
                upper.removeLast()
            }
            upper.append(point)
        }

        lower.removeLast()
        upper.removeLast()
        return lower + upper
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        guard mapViewport.contains(point) else {
            touchStartScenePoint = nil
            touchStartRootPosition = nil
            hoverOrigin = nil
            redrawPreview()
            return
        }
        touchStartScenePoint = point
        touchStartRootPosition = rootNode.position
        didPanBoard = false
        updateHover(from: touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let start = touchStartScenePoint,
              let rootStart = touchStartRootPosition else {
            updateHover(from: touches)
            return
        }

        let current = touch.location(in: self)
        let translation = CGPoint(x: current.x - start.x, y: current.y - start.y)
        let distance = hypot(translation.x, translation.y)
        if didPanBoard || distance > 9 {
            didPanBoard = true
            hoverOrigin = nil
            rootNode.position = clampedRootPosition(rootStart + translation)
            redrawPreview()
            return
        }

        updateHover(from: touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            touchStartScenePoint = nil
            touchStartRootPosition = nil
            didPanBoard = false
        }

        guard !didPanBoard else {
            hoverOrigin = nil
            redrawPreview()
            return
        }

        guard let touch = touches.first,
              mapViewport.contains(touch.location(in: self)),
              let point = gridPoint(forScenePoint: touch.location(in: self)) else {
            hoverOrigin = nil
            redrawPreview()
            return
        }

        hoverOrigin = point
        placeRoom(at: point)
        redrawPreview()
    }

    private func updateHover(from touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        hoverOrigin = mapViewport.contains(point) ? gridPoint(forScenePoint: point) : nil
        redrawPreview()
    }
}

private func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

private func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

struct CubicleBuilderView: View {
    var onClose: () -> Void

    @State private var scene = CubicleBuilderScene()
    @State private var selectedRoomType = CubicleRoomType.premiumCoffeeBar
    @State private var snapshot = CubicleBuilderScene.StateSnapshot.empty

    private var selectedTint: Color {
        Color(selectedRoomType.color)
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            VStack(spacing: 10) {
                header
                scoreBar
                Spacer()
                bottomDock
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
        }
        .onAppear {
            scene.onStateChanged = { snapshot = $0 }
            scene.setSelectedRoomType(selectedRoomType)
            scene.requestStateRefresh()
        }
    }

    private var bottomDock: some View {
        VStack(spacing: 11) {
            Capsule()
                .fill(.white.opacity(0.18))
                .frame(width: 42, height: 3)
                .padding(.bottom, 1)
            roomRoleCard
            roomPicker
            actionBar
        }
        .padding(.horizontal, 14)
        .padding(.top, 9)
        .padding(.bottom, 18)
        .background(
            LinearGradient(colors: [
                Color(red: 0.048, green: 0.058, blue: 0.066).opacity(0.98),
                Color(red: 0.070, green: 0.084, blue: 0.094).opacity(0.98),
                Color.black.opacity(0.96)
            ],
            startPoint: .top,
            endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            LinearGradient(colors: [.white.opacity(0.26), selectedTint.opacity(0.18), .clear],
                           startPoint: .leading,
                           endPoint: .trailing)
                .frame(height: 1)
                .padding(.horizontal, 28)
        }
        .shadow(color: .black.opacity(0.22), radius: 18, y: -3)
        .padding(.horizontal, -16)
        .padding(.bottom, -6)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.grid.3x3.topleft.filled")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(selectedTint)
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.08), in: Circle())
                .overlay(Circle().stroke(selectedTint.opacity(0.30), lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text("Cubicle Builder")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(snapshot.incidentMessage)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.10), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.16), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .background(
            LinearGradient(colors: [
                Color.black.opacity(0.34),
                selectedTint.opacity(0.12),
                Color.black.opacity(0.24)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.13), lineWidth: 1)
        )
    }

    private var scoreBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                BuilderMetricChip(label: "PHI", value: String(format: "%.2f", snapshot.fengShuiScore), icon: "leaf.fill", tint: QuotaOS.Colors.green)
                BuilderMetricChip(label: "ROOMS", value: "\(snapshot.roomCount)", icon: "square.grid.3x3.fill", tint: selectedTint)
                BuilderMetricChip(label: "SUITES", value: "\(snapshot.suiteCount)", icon: "rectangle.3.group.fill", tint: QuotaOS.Colors.gold)
                BuilderMetricChip(label: "AGI", value: "+\(snapshot.agilityBoost)", icon: "bolt.fill", tint: QuotaOS.Colors.orange)
                BuilderMetricChip(label: "JARGON", value: "+\(snapshot.jargonRecovery)", icon: "text.bubble.fill", tint: QuotaOS.Colors.blue)
            }
            .padding(.horizontal, 2)
        }
    }

    private var roomPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CubicleRoomType.allCases) { type in
                    Button {
                        selectedRoomType = type
                        scene.setSelectedRoomType(type)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: type.symbolName)
                                .font(.system(size: 13, weight: .black))
                                .frame(width: 26, height: 26)
                                .background(.white.opacity(selectedRoomType == type ? 0.22 : 0.09), in: Circle())
                            VStack(alignment: .leading, spacing: 1) {
                                Text(type.shortName)
                                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                                Text(type.unlockRoute?.compactTitle ?? "\(type.footprint.width)x\(type.footprint.height)")
                                    .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                                    .opacity(0.68)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.64)
                            }
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 114, height: 46)
                        .padding(.horizontal, 9)
                        .background(roomPickerBackground(type))
                        .clipShape(Capsule())
                        .overlay(Capsule()
                            .stroke(selectedRoomType == type ? Color(type.color).opacity(0.70) : .white.opacity(0.13), lineWidth: 1.2))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func roomPickerBackground(_ type: CubicleRoomType) -> some ShapeStyle {
        LinearGradient(
            colors: selectedRoomType == type
                ? [Color(type.color).opacity(0.34), Color(type.color).opacity(0.18), .white.opacity(0.08)]
                : [Color.white.opacity(0.085), Color.white.opacity(0.040)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var roomRoleCard: some View {
        HStack(spacing: 12) {
            Image(systemName: selectedRoomType.symbolName)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(
                    LinearGradient(colors: [selectedTint.opacity(0.92),
                                            selectedTint.opacity(0.50)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    in: Circle()
                )
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(selectedRoomType.displayName)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("\(selectedRoomType.footprint.width)x\(selectedRoomType.footprint.height)")
                        .font(.system(size: 8.5, weight: .black, design: .rounded))
                        .foregroundStyle(selectedTint)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(selectedTint.opacity(0.12), in: Capsule())
                }
                Text(selectedRoomType.officeRole)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if let route = selectedRoomType.unlockRoute {
                VStack(spacing: 2) {
                    Image(systemName: route.systemImage)
                        .font(.system(size: 13, weight: .black))
                    Text(route.compactTitle)
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                }
                .foregroundStyle(selectedTint)
                .frame(width: 46)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(selectedTint.opacity(0.24), lineWidth: 1)
        )
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            Button {
                scene.spawnIncident()
            } label: {
                Label("Audit", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(QuotaOS.Colors.red.opacity(0.86), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                scene.clearLayout()
            } label: {
                Label("Clear", systemImage: "trash.fill")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.095), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.14), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct BuilderMetricChip: View {
    let label: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 9.5, weight: .black))
                .foregroundStyle(tint)
                .frame(width: 20, height: 20)
                .background(tint.opacity(0.11), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 6.6, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                Text(value)
                    .font(.system(size: 10.2, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
        }
        .foregroundStyle(.white)
        .frame(width: 54, alignment: .leading)
        .padding(.horizontal, 6)
        .padding(.vertical, 7)
        .background(.black.opacity(0.23), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
    }
}

#Preview {
    CubicleBuilderView(onClose: {})
}
