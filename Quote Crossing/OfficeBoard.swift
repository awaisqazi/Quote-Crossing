//
//  OfficeBoard.swift
//  Quote Crossing
//
//  Shared board geometry for the overworld and Cubicle Builder. A room's
//  CubicleGridPoint is a real map tile, so builder placement and walkable
//  overworld position stay identical.
//

import CoreGraphics

enum OfficeBoardTile: Equatable {
    case floor
    case wall
    case carpet
    case lounge
    case elevator
    case supplyArchive
}

enum OfficeBoard {
    static let columns = GameMetrics.mapColumns
    static let rows = GameMetrics.mapRows
    static let mapAlignedLayoutKey = "player.cubicle.layout.mapAligned.v1"

    static let elevator = CubicleGridPoint(column: 2, row: rows / 2)
    static let networkingAnchor = CubicleGridPoint(column: 6, row: 25)
    static let cubicleBuilderAnchor = CubicleGridPoint(column: 4, row: rows / 2)
    static let pipeDexAnchor = CubicleGridPoint(column: 24, row: rows / 2)

    static let supplyArchives: Set<CubicleGridPoint> = {
        var cells = Set<CubicleGridPoint>()
        for column in 23...26 {
            for row in 3...6 {
                cells.insert(CubicleGridPoint(column: column, row: row))
            }
        }
        return cells
    }()

    static func tile(at point: CubicleGridPoint) -> OfficeBoardTile {
        guard point.column >= 0, point.column < columns,
              point.row >= 0, point.row < rows else {
            return .wall
        }

        if point == elevator { return .elevator }
        if supplyArchives.contains(point) { return .supplyArchive }
        if isWall(point) { return .wall }
        if isNetworkingLounge(point) { return .lounge }
        if isCarpet(point) { return .carpet }
        return .floor
    }

    static func isBuildable(_ point: CubicleGridPoint) -> Bool {
        guard !isFixedLandmark(point) else { return false }

        switch tile(at: point) {
        case .floor, .carpet:
            return true
        case .wall, .lounge, .elevator, .supplyArchive:
            return false
        }
    }

    static func isFixedLandmark(_ point: CubicleGridPoint) -> Bool {
        point == elevator
            || point == networkingAnchor
            || point == cubicleBuilderAnchor
            || point == pipeDexAnchor
    }

    static func worldPosition(for origin: CubicleGridPoint, footprint: GridSize) -> CGPoint {
        CGPoint(
            x: (CGFloat(origin.column) + CGFloat(footprint.width) * 0.5) * GameMetrics.tileSize,
            y: (CGFloat(origin.row) + CGFloat(footprint.height) * 0.5) * GameMetrics.tileSize
        )
    }

    static func mapAlignedOrigin(fromLegacy origin: CubicleGridPoint) -> CubicleGridPoint {
        CubicleGridPoint(column: origin.column + 10, row: origin.row + 10)
    }

    static func isLegacyBuilderOrigin(_ origin: CubicleGridPoint) -> Bool {
        origin.column >= 0 && origin.column < 10 && origin.row >= 0 && origin.row < 8
    }

    private static func isWall(_ point: CubicleGridPoint) -> Bool {
        if point.column == 0 || point.column == columns - 1 { return true }
        if point.row == 0 || point.row == rows - 1 { return true }
        if (6...12).contains(point.column) && point.row == 20 && point.column != 9 { return true }
        if point.column == 20 && (8...14).contains(point.row) && point.row != 11 { return true }
        if (18...24).contains(point.column) && point.row == 8 && point.column != 21 { return true }
        return false
    }

    private static func isCarpet(_ point: CubicleGridPoint) -> Bool {
        if (2..<(columns - 2)).contains(point.column) && point.row == rows / 2 { return true }
        if point.column == columns / 2 && (2..<(rows - 2)).contains(point.row) { return true }
        if (13...17).contains(point.column) && (13...17).contains(point.row) { return true }
        return false
    }

    private static func isNetworkingLounge(_ point: CubicleGridPoint) -> Bool {
        (3...9).contains(point.column) && (22...27).contains(point.row)
    }
}
