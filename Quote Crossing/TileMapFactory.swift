//
//  TileMapFactory.swift
//  Quote Crossing
//
//  Builds the 30×30 overworld as an SKTileMapNode with three tile types —
//  Floor, Wall, and the "Networking Lounge" (tall-grass biome, GDD §5).
//
//  Tile artwork is generated procedurally as flat-vector textures (no image
//  assets / no pixel art), matching the GDD's clean pastel art direction.
//

import SpriteKit
import UIKit

enum TileMapFactory {

    // Group names double as biome identifiers (looked up at runtime).
    static let floorName  = "Floor"
    static let wallName   = "Wall"
    static let loungeName = "Networking Lounge"

    // MARK: - Map assembly

    /// Returns a fully-populated, centred-at-origin tile map. The caller is
    /// responsible for positioning it and (optionally) calling `addWallPhysics`.
    static func makeOverworld() -> SKTileMapNode {
        let tileSize = CGSize(width: GameMetrics.tileSize, height: GameMetrics.tileSize)

        let floor  = tileGroup(named: floorName,  texture: floorTexture(tileSize),  size: tileSize)
        let wall   = tileGroup(named: wallName,   texture: wallTexture(tileSize),   size: tileSize)
        let lounge = tileGroup(named: loungeName, texture: loungeTexture(tileSize), size: tileSize)

        let tileSet = SKTileSet(tileGroups: [floor, wall, lounge])
        let map = SKTileMapNode(
            tileSet: tileSet,
            columns: GameMetrics.mapColumns,
            rows: GameMetrics.mapRows,
            tileSize: tileSize
        )
        map.enableAutomapping = false
        map.name = "overworld"

        let cols = GameMetrics.mapColumns
        let rows = GameMetrics.mapRows

        // 1. Base floor everywhere.
        map.fill(with: floor)

        // 2. Solid perimeter walls.
        for c in 0..<cols {
            map.setTileGroup(wall, forColumn: c, row: 0)
            map.setTileGroup(wall, forColumn: c, row: rows - 1)
        }
        for r in 0..<rows {
            map.setTileGroup(wall, forColumn: 0, row: r)
            map.setTileGroup(wall, forColumn: cols - 1, row: r)
        }

        // 3. Interior "cubicle" partitions, each with a doorway gap to walk through.
        for c in 6...12 where c != 9  { map.setTileGroup(wall, forColumn: c, row: 20) }
        for r in 8...14 where r != 11 { map.setTileGroup(wall, forColumn: 20, row: r) }
        for c in 18...24 where c != 21 { map.setTileGroup(wall, forColumn: c, row: 8) }

        // 4. Networking Lounge (tall grass) patch — upper-left interior.
        for c in 3...9 {
            for r in 22...27 {
                map.setTileGroup(lounge, forColumn: c, row: r)
            }
        }

        return map
    }

    /// Adds one static rectangular physics body per Wall tile, as children of
    /// the map (so positions live in the map's local coordinate space).
    static func addWallPhysics(to map: SKTileMapNode) {
        let tileSize = map.tileSize
        for col in 0..<map.numberOfColumns {
            for row in 0..<map.numberOfRows {
                guard map.tileGroup(atColumn: col, row: row)?.name == wallName else { continue }
                let node = SKNode()
                node.position = map.centerOfTile(atColumn: col, row: row)
                let body = SKPhysicsBody(rectangleOf: tileSize)
                body.isDynamic = false
                body.friction = 0
                body.categoryBitMask = PhysicsCategory.wall
                body.collisionBitMask = PhysicsCategory.player
                body.contactTestBitMask = PhysicsCategory.none
                node.physicsBody = body
                map.addChild(node)
            }
        }
    }

    // MARK: - Tile groups

    private static func tileGroup(named name: String, texture: SKTexture, size: CGSize) -> SKTileGroup {
        let def = SKTileDefinition(texture: texture, size: size)
        def.name = name
        let group = SKTileGroup(tileDefinition: def)
        group.name = name
        return group
    }

    // MARK: - Procedural flat-vector textures

    private static func texture(_ size: CGSize, _ draw: (CGContext, CGRect) -> Void) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            draw(context.cgContext, CGRect(origin: .zero, size: size))
        }
        let tex = SKTexture(image: image)
        tex.filteringMode = .nearest   // crisp edges for the flat look
        return tex
    }

    private static func floorTexture(_ size: CGSize) -> SKTexture {
        texture(size) { _, rect in
            Palette.floor.setFill()
            UIBezierPath(rect: rect).fill()

            // Subtle grid lines on two edges read as clean office floor tiling.
            Palette.floorLine.setStroke()
            let grid = UIBezierPath()
            grid.lineWidth = 2
            grid.move(to: CGPoint(x: rect.maxX - 1, y: rect.minY))
            grid.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.maxY))
            grid.move(to: CGPoint(x: rect.minX, y: rect.maxY - 1))
            grid.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 1))
            grid.stroke()
        }
    }

    private static func wallTexture(_ size: CGSize) -> SKTexture {
        texture(size) { _, rect in
            Palette.wall.setFill()
            UIBezierPath(rect: rect).fill()

            // Lighter top band = a flat "bevel" so walls read as raised partitions.
            Palette.wallTop.setFill()
            let band = CGRect(x: rect.minX, y: rect.minY,
                              width: rect.width, height: rect.height * 0.22)
            UIBezierPath(rect: band).fill()
        }
    }

    private static func loungeTexture(_ size: CGSize) -> SKTexture {
        texture(size) { _, rect in
            Palette.lounge.setFill()
            UIBezierPath(rect: rect).fill()

            // A few simple blades suggest tall grass without busy detail.
            Palette.loungeBlade.setFill()
            let blades = 4
            for i in 0..<blades {
                let x = rect.width * (CGFloat(i) + 0.5) / CGFloat(blades)
                let blade = UIBezierPath()
                blade.move(to: CGPoint(x: x - 4, y: rect.maxY))
                blade.addLine(to: CGPoint(x: x, y: rect.maxY - rect.height * 0.55))
                blade.addLine(to: CGPoint(x: x + 4, y: rect.maxY))
                blade.close()
                blade.fill()
            }
        }
    }
}
