//
//  PlayerNode.swift
//  Quote Crossing
//
//  The player avatar in the overworld. A clean vector, top-down-ish figure
//  whose base look mirrors the character-creator choices (GDD §1) and whose
//  equipped wearables (GDD §2) are layered on as tinted SF-Symbol sprites.
//  Calling `apply(_:wearables:)` rebuilds the figure — cheap enough to call
//  live whenever the player equips something in the wardrobe.
//

import SpriteKit
import UIKit

final class PlayerNode: SKNode {

    /// Body (outfit) capsule dimensions, in points.
    static let visualWidth: CGFloat = 44
    static let visualHeight: CGFloat = 64

    /// Container for all artwork so we can rebuild it on any change.
    private var visual: SKNode?

    override init() {
        super.init()
        name = "player"
        zPosition = 50
        configurePhysics()
        apply(.fallback)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Appearance

    /// Rebuilds the avatar artwork: base look + any equipped wearables.
    func apply(_ appearance: AvatarAppearance, wearables: [WearableItem] = []) {
        visual?.removeFromParent()

        let v = SKNode()
        let w = Self.visualWidth
        let h = Self.visualHeight

        // Outfit body capsule.
        let body = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: w / 2)
        body.fillColor = appearance.outfit
        body.strokeColor = Palette.playerStroke
        body.lineWidth = 4
        body.lineJoin = .round
        body.zPosition = 0
        v.addChild(body)

        // Outfit accent stripe (tie / zipper / collar).
        let accent = SKShapeNode(rectOf: CGSize(width: 7, height: h * 0.42), cornerRadius: 3.5)
        accent.fillColor = appearance.outfitAccent
        accent.strokeColor = .clear
        accent.position = CGPoint(x: 0, y: -h * 0.05)
        accent.zPosition = 1
        v.addChild(accent)

        // Head (skin) near the top, with hair tucked behind it.
        let headR = w * 0.42
        let headY = h * 0.46 - headR * 0.25

        if appearance.hairStyle != .bald {
            let hair = SKShapeNode(circleOfRadius: headR * 1.04)
            hair.fillColor = appearance.hair
            hair.strokeColor = .clear
            hair.position = CGPoint(x: 0, y: headY + headR * 0.45)
            hair.zPosition = 2
            v.addChild(hair)
        }

        let head = SKShapeNode(circleOfRadius: headR)
        head.fillColor = appearance.skin
        head.strokeColor = Palette.playerStroke
        head.lineWidth = 3
        head.position = CGPoint(x: 0, y: headY)
        head.zPosition = 3
        v.addChild(head)

        for item in wearables {
            if let sprite = Self.wearableSprite(for: item,
                                                headCenter: CGPoint(x: 0, y: headY),
                                                headRadius: headR,
                                                bodyHeight: h) {
                v.addChild(sprite)
            }
        }

        v.zPosition = 1
        addChild(v)
        visual = v
    }

    /// Renders a wearable's SF Symbol into a tinted sprite, sized/placed by slot.
    private static func wearableSprite(for item: WearableItem,
                                       headCenter: CGPoint,
                                       headRadius r: CGFloat,
                                       bodyHeight h: CGFloat) -> SKSpriteNode? {
        let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
        guard let base = UIImage(systemName: item.imageIcon, withConfiguration: config) else { return nil }
        let image = base.withTintColor(item.tint.sk, renderingMode: .alwaysOriginal)
        let texture = SKTexture(image: image)
        let sprite = SKSpriteNode(texture: texture)

        // Fit the symbol within a per-slot box, preserving aspect ratio. SF
        // Symbols vary wildly in aspect (eyeglasses are wide & short; crown is
        // tall), so scaling by height alone would oversize the wide ones.
        let box: CGSize
        switch item.slot {
        case .eyewear:
            box = CGSize(width: r * 1.8, height: r * 0.8)
            sprite.position = CGPoint(x: 0, y: headCenter.y - r * 0.1)
            sprite.zPosition = 4
        case .head:
            box = CGSize(width: r * 1.7, height: r * 1.2)
            sprite.position = CGPoint(x: 0, y: headCenter.y + r * 0.55)
            sprite.zPosition = 4
        case .torso:
            box = CGSize(width: Self.visualWidth * 0.72, height: h * 0.5)
            sprite.position = CGPoint(x: 0, y: -h * 0.02)
            sprite.zPosition = 1.5
        case .lanyard:
            box = CGSize(width: Self.visualWidth * 0.34, height: h * 0.34)
            sprite.position = CGPoint(x: 0, y: -h * 0.06)
            sprite.zPosition = 2.5
        }

        let texSize = texture.size()
        let scale = min(box.width / max(texSize.width, 1), box.height / max(texSize.height, 1))
        sprite.setScale(scale)
        return sprite
    }

    // MARK: - Physics

    private func configurePhysics() {
        // A circular body slides cleanly along walls in a top-down view (no
        // catching on tile corners that a box body would snag on).
        let body = SKPhysicsBody(circleOfRadius: Self.visualWidth / 2)
        body.affectedByGravity = false
        body.allowsRotation = false
        body.friction = 0
        body.restitution = 0
        body.linearDamping = 0          // velocity is driven explicitly each frame
        body.categoryBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.wall
        body.contactTestBitMask = PhysicsCategory.none
        physicsBody = body
    }
}
