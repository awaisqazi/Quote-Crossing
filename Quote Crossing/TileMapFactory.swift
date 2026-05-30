//
//  TileMapFactory.swift
//  Quote Crossing
//
//  Builds the 30×30 overworld as an SKTileMapNode with three tile types —
//  Floor, Wall, and the "Networking Lounge" (tall-grass biome, GDD §5).
//
//  Tile artwork is generated procedurally so the world stays lightweight.
//

import SpriteKit
import UIKit

enum TileMapFactory {

    // Group names double as biome identifiers (looked up at runtime).
    static let floorName  = "Floor"
    static let wallName   = "Wall"
    static let carpetName = "Quota Carpet"
    static let loungeName = "Networking Lounge"

    // MARK: - Map assembly

    /// Returns a fully-populated, centred-at-origin tile map. The caller is
    /// responsible for positioning it and (optionally) calling `addWallPhysics`.
    static func makeOverworld() -> SKTileMapNode {
        let tileSize = CGSize(width: GameMetrics.tileSize, height: GameMetrics.tileSize)

        let floor  = tileGroup(named: floorName,  texture: floorTexture(tileSize),  size: tileSize)
        let wall   = tileGroup(named: wallName,   texture: wallTexture(tileSize),   size: tileSize)
        let carpet = tileGroup(named: carpetName, texture: carpetTexture(tileSize), size: tileSize)
        let lounge = tileGroup(named: loungeName, texture: loungeTexture(tileSize), size: tileSize)

        let tileSet = SKTileSet(tileGroups: [floor, wall, carpet, lounge])
        let map = SKTileMapNode(
            tileSet: tileSet,
            columns: GameMetrics.mapColumns,
            rows: GameMetrics.mapRows,
            tileSize: tileSize
        )
        map.enableAutomapping = false
        map.name = "overworld"

        for column in 0..<OfficeBoard.columns {
            for row in 0..<OfficeBoard.rows {
                let point = CubicleGridPoint(column: column, row: row)
                let group: SKTileGroup
                switch OfficeBoard.tile(at: point) {
                case .wall:
                    group = wall
                case .carpet, .elevator:
                    group = carpet
                case .lounge:
                    group = lounge
                case .floor, .supplyArchive:
                    group = floor
                }
                map.setTileGroup(group, forColumn: column, row: row)
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
        tex.filteringMode = .linear
        return tex
    }

    private static func fillGradient(in rect: CGRect,
                                     context: CGContext,
                                     colors: [SKColor],
                                     start: CGPoint,
                                     end: CGPoint) {
        let cgColors = colors.map(\.cgColor) as CFArray
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: cgColors,
                                        locations: nil) else { return }
        context.drawLinearGradient(gradient, start: start, end: end, options: [])
    }

    private static func floorTexture(_ size: CGSize) -> SKTexture {
        texture(size) { context, rect in
            fillGradient(
                in: rect,
                context: context,
                colors: [
                    Palette.floorGlow,
                    Palette.floorGlow.withAlphaComponent(0.98),
                    Palette.floor,
                    Palette.floorWarm.withAlphaComponent(0.76)
                ],
                start: CGPoint(x: rect.minX, y: rect.minY),
                end: CGPoint(x: rect.maxX, y: rect.maxY)
            )

            Palette.floorGlow.setFill()
            UIBezierPath(
                roundedRect: rect.insetBy(dx: rect.width * 0.17, dy: rect.height * 0.17),
                cornerRadius: rect.width * 0.20
            ).fill(with: .normal, alpha: 0.20)

            Palette.glass.setFill()
            let glassSweep = UIBezierPath()
            glassSweep.move(to: CGPoint(x: rect.minX - 4, y: rect.maxY * 0.18))
            glassSweep.addLine(to: CGPoint(x: rect.maxX * 0.40, y: rect.maxY + 4))
            glassSweep.addLine(to: CGPoint(x: rect.maxX * 0.62, y: rect.maxY + 4))
            glassSweep.addLine(to: CGPoint(x: rect.maxX * 0.16, y: rect.maxY * 0.12))
            glassSweep.close()
            glassSweep.fill(with: .normal, alpha: 0.07)

            Palette.floorLine.setStroke()
            let grout = UIBezierPath()
            grout.lineWidth = 1
            grout.move(to: CGPoint(x: rect.maxX - 0.5, y: rect.minY))
            grout.addLine(to: CGPoint(x: rect.maxX - 0.5, y: rect.maxY))
            grout.move(to: CGPoint(x: rect.minX, y: rect.maxY - 0.5))
            grout.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 0.5))
            grout.stroke(with: .normal, alpha: 0.13)

            Palette.floorLine.setStroke()
            let hairline = UIBezierPath()
            hairline.lineWidth = 0.6
            hairline.move(to: CGPoint(x: rect.minX + 8, y: rect.minY + 9))
            hairline.addLine(to: CGPoint(x: rect.maxX - 9, y: rect.maxY - 8))
            hairline.stroke(with: .normal, alpha: 0.035)
        }
    }

    private static func wallTexture(_ size: CGSize) -> SKTexture {
        texture(size) { context, rect in
            fillGradient(
                in: rect,
                context: context,
                colors: [Palette.wallTop, Palette.wall, Palette.wallShadow],
                start: CGPoint(x: rect.midX, y: rect.minY),
                end: CGPoint(x: rect.midX, y: rect.maxY)
            )

            Palette.wallTop.setFill()
            let band = CGRect(x: rect.minX, y: rect.minY,
                              width: rect.width, height: rect.height * 0.22)
            UIBezierPath(roundedRect: band, cornerRadius: rect.width * 0.08).fill(with: .normal, alpha: 0.72)

            Palette.wallShadow.setFill()
            let shadow = CGRect(x: rect.minX, y: rect.maxY - rect.height * 0.14,
                                width: rect.width, height: rect.height * 0.14)
            UIBezierPath(rect: shadow).fill()

            Palette.wallBrass.setStroke()
            let trim = UIBezierPath()
            trim.lineWidth = 2
            trim.move(to: CGPoint(x: rect.minX + 7, y: rect.minY + rect.height * 0.26))
            trim.addLine(to: CGPoint(x: rect.maxX - 7, y: rect.minY + rect.height * 0.26))
            trim.stroke(with: .normal, alpha: 0.34)
        }
    }

    private static func carpetTexture(_ size: CGSize) -> SKTexture {
        texture(size) { context, rect in
            fillGradient(
                in: rect,
                context: context,
                colors: [
                    Palette.floorGlow.withAlphaComponent(0.92),
                    Palette.carpet.withAlphaComponent(0.82),
                    Palette.glass.withAlphaComponent(0.70),
                    Palette.carpetWine.withAlphaComponent(0.46)
                ],
                start: CGPoint(x: rect.minX, y: rect.minY),
                end: CGPoint(x: rect.maxX, y: rect.maxY)
            )

            Palette.glass.setFill()
            UIBezierPath(roundedRect: rect.insetBy(dx: 6, dy: 6), cornerRadius: 11)
                .fill(with: .normal, alpha: 0.12)

            Palette.carpetLine.setStroke()
            let inner = UIBezierPath(roundedRect: rect.insetBy(dx: 8, dy: 8), cornerRadius: 8)
            inner.lineWidth = 1.6
            inner.stroke(with: .normal, alpha: 0.20)

            Palette.carpetGold.setStroke()
            let centerline = UIBezierPath()
            centerline.lineWidth = 1.3
            centerline.move(to: CGPoint(x: rect.midX, y: rect.minY + 7))
            centerline.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 7))
            centerline.stroke(with: .normal, alpha: 0.13)

            Palette.carpetGold.setFill()
            UIBezierPath(ovalIn: CGRect(x: rect.midX - 3, y: rect.midY - 3, width: 6, height: 6))
                .fill(with: .normal, alpha: 0.30)
        }
    }

    private static func loungeTexture(_ size: CGSize) -> SKTexture {
        texture(size) { context, rect in
            fillGradient(
                in: rect,
                context: context,
                colors: [
                    Palette.floorGlow.withAlphaComponent(0.82),
                    Palette.plantLight.withAlphaComponent(0.84),
                    Palette.lounge.withAlphaComponent(0.86),
                    Palette.carpetGold.withAlphaComponent(0.22)
                ],
                start: CGPoint(x: rect.minX, y: rect.minY),
                end: CGPoint(x: rect.maxX, y: rect.maxY)
            )

            // A few simple blades suggest tall grass without busy detail.
            Palette.loungeBlade.setFill()
            let blades = 5
            for i in 0..<blades {
                let x = rect.width * (CGFloat(i) + 0.5) / CGFloat(blades)
                let blade = UIBezierPath()
                blade.move(to: CGPoint(x: x - 4, y: rect.maxY))
                blade.addLine(to: CGPoint(x: x + CGFloat(i % 2 == 0 ? -2 : 2),
                                          y: rect.maxY - rect.height * 0.58))
                blade.addLine(to: CGPoint(x: x + 4, y: rect.maxY))
                blade.close()
                blade.fill(with: .normal, alpha: i.isMultiple(of: 2) ? 0.34 : 0.22)
            }

            Palette.carpetGold.setStroke()
            let softGrid = UIBezierPath(roundedRect: rect.insetBy(dx: 6, dy: 6), cornerRadius: 7)
            softGrid.lineWidth = 1
            softGrid.stroke(with: .normal, alpha: 0.10)
        }
    }
}
