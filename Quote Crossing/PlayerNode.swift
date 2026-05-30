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
        let widthScale = max(appearance.bodyType.shoulderScale, appearance.bodyType.hipScale)
        let heightScale = appearance.bodyType.heightScale
        let w = Self.visualWidth * widthScale
        let h = Self.visualHeight * heightScale
        let shoulderW = Self.visualWidth * appearance.bodyType.shoulderScale
        let hipW = Self.visualWidth * appearance.bodyType.hipScale

        let shadow = SKShapeNode(ellipseOf: CGSize(width: w * 1.36, height: h * 0.28))
        shadow.position = CGPoint(x: 0, y: -h * 0.50)
        shadow.fillColor = Palette.playerStroke.withAlphaComponent(0.16)
        shadow.strokeColor = .clear
        shadow.zPosition = -4
        v.addChild(shadow)

        for x in [-w * 0.22, w * 0.22] {
            let leg = SKShapeNode(rectOf: CGSize(width: 10.5 * min(widthScale, 1.12), height: h * 0.24),
                                  cornerRadius: 5)
            leg.position = CGPoint(x: x * 0.72, y: -h * 0.37)
            leg.fillColor = appearance.outfit.withAlphaComponent(0.82)
            leg.strokeColor = Palette.playerStroke.withAlphaComponent(0.34)
            leg.lineWidth = 1.3
            leg.zPosition = -1.1
            v.addChild(leg)

            let shoe = SKShapeNode(rectOf: CGSize(width: 17, height: 10), cornerRadius: 5)
            shoe.position = CGPoint(x: x, y: -h * 0.51)
            shoe.zRotation = x < 0 ? 0.08 : -0.08
            shoe.fillColor = SKColor(red: 0.90, green: 0.53, blue: 0.46, alpha: 1)
            shoe.strokeColor = Palette.playerStroke.withAlphaComponent(0.46)
            shoe.lineWidth = 1.2
            shoe.zPosition = -0.9
            v.addChild(shoe)
        }

        for side in [-1.0, 1.0] {
            let x = CGFloat(side) * shoulderW * 0.60
            let arm = SKShapeNode(rectOf: CGSize(width: 13 * min(widthScale, 1.14), height: 39 * heightScale),
                                  cornerRadius: 7)
            arm.position = CGPoint(x: x, y: -h * 0.04)
            arm.zRotation = CGFloat(side) * -0.10
            arm.fillColor = appearance.outfit.withAlphaComponent(0.86)
            arm.strokeColor = Palette.playerStroke.withAlphaComponent(0.48)
            arm.lineWidth = 2.2
            arm.zPosition = -0.5
            v.addChild(arm)

            let cuff = SKShapeNode(rectOf: CGSize(width: 13.5, height: 6.5), cornerRadius: 3.25)
            cuff.position = CGPoint(x: x + CGFloat(side) * 1.2, y: -h * 0.26)
            cuff.zRotation = arm.zRotation
            cuff.fillColor = Palette.fixtureTop.withAlphaComponent(0.88)
            cuff.strokeColor = Palette.playerStroke.withAlphaComponent(0.20)
            cuff.lineWidth = 0.8
            cuff.zPosition = 0.1
            v.addChild(cuff)

            let hand = SKShapeNode(ellipseOf: CGSize(width: 12.5, height: 10.5))
            hand.position = CGPoint(x: x + CGFloat(side) * 1.8, y: -h * 0.315)
            hand.fillColor = appearance.skin
            hand.strokeColor = Palette.playerStroke.withAlphaComponent(0.42)
            hand.lineWidth = 1.3
            hand.zPosition = 0.15
            v.addChild(hand)
        }

        let bodyPath = Self.torsoPath(width: w,
                                      height: h,
                                      shoulderWidth: shoulderW,
                                      waistWidth: Self.visualWidth * appearance.bodyType.waistScale,
                                      hipWidth: hipW)
        let body = SKShapeNode(path: bodyPath)
        body.fillColor = appearance.outfit
        body.strokeColor = Palette.playerStroke
        body.lineWidth = 3.4
        body.lineJoin = .round
        body.zPosition = 0
        v.addChild(body)

        let bodyHighlight = SKShapeNode(rectOf: CGSize(width: w * 0.40, height: h * 0.70), cornerRadius: w * 0.18)
        bodyHighlight.position = CGPoint(x: -w * 0.14, y: h * 0.02)
        bodyHighlight.fillColor = SKColor.white.withAlphaComponent(0.12)
        bodyHighlight.strokeColor = .clear
        bodyHighlight.zPosition = 0.5
        v.addChild(bodyHighlight)

        let shirt = SKShapeNode(rectOf: CGSize(width: w * 0.34, height: h * 0.56), cornerRadius: w * 0.13)
        shirt.position = CGPoint(x: 0, y: h * 0.02)
        shirt.fillColor = Palette.fixtureTop.withAlphaComponent(0.92)
        shirt.strokeColor = .clear
        shirt.zPosition = 0.75
        v.addChild(shirt)

        // Outfit accent stripe (tie / zipper / collar).
        let accent = SKShapeNode(rectOf: CGSize(width: 7.5, height: h * 0.42), cornerRadius: 3.8)
        accent.fillColor = appearance.outfitAccent
        accent.strokeColor = Palette.playerStroke.withAlphaComponent(0.10)
        accent.lineWidth = 0.8
        accent.position = CGPoint(x: 0, y: -h * 0.05)
        accent.zPosition = 1
        v.addChild(accent)

        for x in [-shoulderW * 0.17, shoulderW * 0.17] {
            let collar = SKShapeNode(rectOf: CGSize(width: 12, height: 8), cornerRadius: 3)
            collar.position = CGPoint(x: x, y: h * 0.23)
            collar.zRotation = x * -0.05
            collar.fillColor = Palette.fixtureTop.withAlphaComponent(0.96)
            collar.strokeColor = Palette.playerStroke.withAlphaComponent(0.16)
            collar.lineWidth = 0.8
            collar.zPosition = 1.2
            v.addChild(collar)
        }

        // Head (skin) near the top, with hair tucked behind it.
        let headR = Self.visualWidth * 0.42 * appearance.bodyType.headScale * min(max(widthScale, 0.96), 1.12)
        let headY = h * 0.46 - headR * 0.25

        addHair(style: appearance.hairStyle,
                color: appearance.hair,
                headRadius: headR,
                headY: headY,
                to: v)

        let headSize = CGSize(width: headR * 2 * appearance.faceShape.widthScale,
                              height: headR * 2 * appearance.faceShape.heightScale)
        let head = SKShapeNode(rectOf: headSize, cornerRadius: min(headSize.width, headSize.height) * appearance.faceShape.cornerRadius)
        head.fillColor = appearance.skin
        head.strokeColor = Palette.playerStroke
        head.lineWidth = 3.2
        head.position = CGPoint(x: 0, y: headY)
        head.zPosition = 3
        v.addChild(head)

        let faceGlow = SKShapeNode(circleOfRadius: headR * 0.70)
        faceGlow.position = CGPoint(x: -headR * 0.18, y: headY + headR * 0.12)
        faceGlow.fillColor = SKColor.white.withAlphaComponent(0.18)
        faceGlow.strokeColor = .clear
        faceGlow.zPosition = 3.2
        v.addChild(faceGlow)

        for side in [-1.0, 1.0] {
            let cheek = SKShapeNode(ellipseOf: CGSize(width: headR * 0.34, height: headR * 0.18))
            cheek.position = CGPoint(x: CGFloat(side) * headR * 0.38, y: headY - headR * 0.18)
            cheek.fillColor = SKColor(red: 0.98, green: 0.50, blue: 0.58, alpha: 0.22)
            cheek.strokeColor = .clear
            cheek.zPosition = 3.42
            v.addChild(cheek)
        }

        for x in [-6, 6] {
            let bag = SKShapeNode(ellipseOf: CGSize(width: 8.4, height: 4.2))
            bag.position = CGPoint(x: CGFloat(x), y: headY - 1.8)
            bag.fillColor = SKColor(red: 0.46, green: 0.34, blue: 0.56, alpha: max(0.06, appearance.eyeBags * 0.42))
            bag.strokeColor = .clear
            bag.zPosition = 3.45
            v.addChild(bag)

            let browPath = CGMutablePath()
            browPath.move(to: CGPoint(x: CGFloat(x) - 3.4, y: headY + 7.4))
            browPath.addQuadCurve(to: CGPoint(x: CGFloat(x) + 3.4, y: headY + 7.2),
                                  control: CGPoint(x: CGFloat(x), y: headY + 8.8))
            let brow = SKShapeNode(path: browPath)
            brow.fillColor = .clear
            brow.strokeColor = appearance.hair.withAlphaComponent(0.70)
            brow.lineWidth = 1.4
            brow.lineCap = .round
            brow.zPosition = 3.62
            v.addChild(brow)

            let eye = SKShapeNode(ellipseOf: CGSize(width: 4.0, height: 5.0))
            eye.position = CGPoint(x: CGFloat(x), y: headY + 2)
            eye.fillColor = appearance.eye
            eye.strokeColor = .clear
            eye.zPosition = 3.6
            v.addChild(eye)

            let glint = SKShapeNode(circleOfRadius: 0.8)
            glint.position = CGPoint(x: CGFloat(x) + 0.8, y: headY + 3.5)
            glint.fillColor = SKColor.white.withAlphaComponent(0.82)
            glint.strokeColor = .clear
            glint.zPosition = 3.65
            v.addChild(glint)
        }

        let nosePath = CGMutablePath()
        nosePath.move(to: CGPoint(x: 0.8, y: headY + 0.6))
        nosePath.addQuadCurve(to: CGPoint(x: -0.8, y: headY - 2.9),
                              control: CGPoint(x: 3.0, y: headY - 1.8))
        let nose = SKShapeNode(path: nosePath)
        nose.fillColor = .clear
        nose.strokeColor = Palette.playerStroke.withAlphaComponent(0.16)
        nose.lineWidth = 1
        nose.lineCap = .round
        nose.zPosition = 3.55
        v.addChild(nose)

        if appearance.presentation != .feminine {
            addFacialHair(style: appearance.facialHair,
                          color: appearance.hair,
                          headRadius: headR,
                          headY: headY,
                          to: v)
        }
        addSmile(appearance.smile, headY: headY, to: v)

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

    func updateMotion(velocity: CGVector) {
        guard let visual else { return }
        let speed = hypot(velocity.dx, velocity.dy)
        let targetTilt = max(-0.10, min(0.10, -velocity.dx / max(GameMetrics.playerSpeed, 1) * 0.10))
        let targetScaleX: CGFloat = speed > 12 ? 1.035 : 1
        let targetScaleY: CGFloat = speed > 12 ? 0.985 : 1

        visual.zRotation += (targetTilt - visual.zRotation) * 0.22
        visual.xScale += (targetScaleX - visual.xScale) * 0.18
        visual.yScale += (targetScaleY - visual.yScale) * 0.18
    }

    private static func torsoPath(width: CGFloat,
                                  height: CGFloat,
                                  shoulderWidth: CGFloat,
                                  waistWidth: CGFloat,
                                  hipWidth: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let centerX: CGFloat = 0
        let topY = height * 0.46
        let shoulderY = height * 0.36
        let waistY = -height * 0.05
        let hipY = -height * 0.40
        let bottomY = -height * 0.50
        let shoulder = min(width, shoulderWidth) / 2
        let waist = min(width, waistWidth) / 2
        let hip = min(width, hipWidth) / 2

        path.move(to: CGPoint(x: centerX - shoulder * 0.72, y: topY))
        path.addQuadCurve(to: CGPoint(x: centerX - shoulder, y: shoulderY),
                          control: CGPoint(x: centerX - shoulder, y: topY))
        path.addCurve(to: CGPoint(x: centerX - waist, y: waistY),
                      control1: CGPoint(x: centerX - shoulder * 0.96, y: height * 0.18),
                      control2: CGPoint(x: centerX - waist * 1.10, y: height * 0.06))
        path.addCurve(to: CGPoint(x: centerX - hip, y: hipY),
                      control1: CGPoint(x: centerX - waist * 0.92, y: -height * 0.20),
                      control2: CGPoint(x: centerX - hip, y: -height * 0.28))
        path.addQuadCurve(to: CGPoint(x: centerX, y: bottomY),
                          control: CGPoint(x: centerX - hip * 0.56, y: bottomY))
        path.addQuadCurve(to: CGPoint(x: centerX + hip, y: hipY),
                          control: CGPoint(x: centerX + hip * 0.56, y: bottomY))
        path.addCurve(to: CGPoint(x: centerX + waist, y: waistY),
                      control1: CGPoint(x: centerX + hip, y: -height * 0.28),
                      control2: CGPoint(x: centerX + waist * 0.92, y: -height * 0.20))
        path.addCurve(to: CGPoint(x: centerX + shoulder, y: shoulderY),
                      control1: CGPoint(x: centerX + waist * 1.10, y: height * 0.06),
                      control2: CGPoint(x: centerX + shoulder * 0.96, y: height * 0.18))
        path.addQuadCurve(to: CGPoint(x: centerX + shoulder * 0.72, y: topY),
                          control: CGPoint(x: centerX + shoulder, y: topY))
        path.closeSubpath()
        return path
    }

    private func addHair(style: HairStyle,
                         color: SKColor,
                         headRadius r: CGFloat,
        headY: CGFloat,
                         to node: SKNode) {
        func add(_ child: SKNode) {
            node.addChild(child)
        }

        switch style {
        case .bald:
            return
        case .buzz, .croppedFade:
            let cap = SKShapeNode(ellipseOf: CGSize(width: r * 2.06, height: r * 1.05))
            cap.position = CGPoint(x: 0, y: headY + r * 0.42)
            cap.fillColor = color
            cap.strokeColor = .clear
            cap.zPosition = 2
            add(cap)
            if style == .croppedFade {
                for side in [-1.0, 1.0] {
                    let fade = SKShapeNode(rectOf: CGSize(width: r * 0.24, height: r * 0.92), cornerRadius: r * 0.10)
                    fade.position = CGPoint(x: CGFloat(side) * r * 0.84, y: headY + r * 0.16)
                    fade.fillColor = color.withAlphaComponent(0.68)
                    fade.strokeColor = .clear
                    fade.zPosition = 2.1
                    add(fade)
                }
            }
        case .sideSwept:
            let cap = SKShapeNode(ellipseOf: CGSize(width: r * 2.14, height: r * 1.10))
            cap.position = CGPoint(x: 0, y: headY + r * 0.42)
            cap.fillColor = color
            cap.strokeColor = .clear
            cap.zPosition = 2
            add(cap)

            let sweep = SKShapeNode(rectOf: CGSize(width: r * 1.45, height: r * 0.42), cornerRadius: r * 0.20)
            sweep.position = CGPoint(x: r * 0.18, y: headY + r * 0.80)
            sweep.zRotation = -0.28
            sweep.fillColor = color
            sweep.strokeColor = .clear
            sweep.zPosition = 2.2
            add(sweep)
        case .curtainSweep:
            let cap = SKShapeNode(ellipseOf: CGSize(width: r * 2.14, height: r * 1.10))
            cap.position = CGPoint(x: 0, y: headY + r * 0.42)
            cap.fillColor = color
            cap.strokeColor = .clear
            cap.zPosition = 2
            add(cap)
            for side in [-1.0, 1.0] {
                let sweep = SKShapeNode(rectOf: CGSize(width: r * 0.62, height: r * 1.18), cornerRadius: r * 0.22)
                sweep.position = CGPoint(x: CGFloat(side) * r * 0.42, y: headY + r * 0.38)
                sweep.zRotation = CGFloat(side) * 0.34
                sweep.fillColor = color
                sweep.strokeColor = .clear
                sweep.zPosition = 2.2
                add(sweep)
            }
        case .shag, .pixie:
            let cap = SKShapeNode(ellipseOf: CGSize(width: r * 2.12, height: r * 1.08))
            cap.position = CGPoint(x: 0, y: headY + r * 0.40)
            cap.fillColor = color
            cap.strokeColor = .clear
            cap.zPosition = 2
            add(cap)
            let spikeCount = style == .pixie ? 4 : 6
            for i in 0..<spikeCount {
                let x = CGFloat(i - spikeCount / 2) * r * 0.30
                let lock = SKShapeNode(rectOf: CGSize(width: r * 0.28, height: r * 0.58), cornerRadius: r * 0.12)
                lock.position = CGPoint(x: x, y: headY + r * (style == .pixie ? 0.72 : 0.52))
                lock.zRotation = x * -0.018
                lock.fillColor = color
                lock.strokeColor = .clear
                lock.zPosition = 2.25
                add(lock)
            }
        case .centerPart:
            for side in [-1.0, 1.0] {
                let lock = SKShapeNode(rectOf: CGSize(width: r * 0.72, height: r * 1.72), cornerRadius: r * 0.30)
                lock.position = CGPoint(x: CGFloat(side) * r * 0.62, y: headY + r * 0.02)
                lock.zRotation = CGFloat(side) * -0.18
                lock.fillColor = color
                lock.strokeColor = .clear
                lock.zPosition = 2.1
                add(lock)
            }

            let part = SKShapeNode(rectOf: CGSize(width: 2.4, height: r * 0.86), cornerRadius: 1.2)
            part.position = CGPoint(x: 0, y: headY + r * 0.54)
            part.fillColor = SKColor.white.withAlphaComponent(0.34)
            part.strokeColor = .clear
            part.zPosition = 2.4
            add(part)
        case .longWaves, .looseWaves, .wavyLob:
            let length: CGFloat = style == .wavyLob ? 1.50 : (style == .looseWaves ? 2.04 : 2.20)
            for side in [-1.0, 1.0] {
                let lock = SKShapeNode(rectOf: CGSize(width: r * 0.72, height: r * length), cornerRadius: r * 0.32)
                lock.position = CGPoint(x: CGFloat(side) * r * 0.72, y: headY + (style == .wavyLob ? r * 0.18 : -r * 0.02))
                lock.zRotation = CGFloat(side) * -0.12
                lock.fillColor = color
                lock.strokeColor = .clear
                lock.zPosition = 1.9
                add(lock)
            }

            let cap = SKShapeNode(ellipseOf: CGSize(width: r * 2.18, height: r * 1.12))
            cap.position = CGPoint(x: 0, y: headY + r * 0.44)
            cap.fillColor = color
            cap.strokeColor = .clear
            cap.zPosition = 2.2
            add(cap)
        case .bluntBob:
            let bob = SKShapeNode(rectOf: CGSize(width: r * 2.22, height: r * 1.86), cornerRadius: r * 0.44)
            bob.position = CGPoint(x: 0, y: headY + r * 0.02)
            bob.fillColor = color
            bob.strokeColor = .clear
            bob.zPosition = 1.9
            add(bob)
            let cap = SKShapeNode(ellipseOf: CGSize(width: r * 2.12, height: r * 1.08))
            cap.position = CGPoint(x: 0, y: headY + r * 0.44)
            cap.fillColor = color
            cap.strokeColor = .clear
            cap.zPosition = 2.2
            add(cap)
        case .highPonytail:
            let pony = SKShapeNode(rectOf: CGSize(width: r * 0.58, height: r * 1.72), cornerRadius: r * 0.24)
            pony.position = CGPoint(x: r * 0.82, y: headY + r * 0.08)
            pony.zRotation = -0.12
            pony.fillColor = color
            pony.strokeColor = .clear
            pony.zPosition = 1.8
            add(pony)
            let cap = SKShapeNode(ellipseOf: CGSize(width: r * 2.12, height: r * 1.08))
            cap.position = CGPoint(x: 0, y: headY + r * 0.44)
            cap.fillColor = color
            cap.strokeColor = .clear
            cap.zPosition = 2.2
            add(cap)
        case .softBraid:
            let cap = SKShapeNode(ellipseOf: CGSize(width: r * 2.12, height: r * 1.08))
            cap.position = CGPoint(x: 0, y: headY + r * 0.44)
            cap.fillColor = color
            cap.strokeColor = .clear
            cap.zPosition = 2.2
            add(cap)
            for i in 0..<4 {
                let link = SKShapeNode(rectOf: CGSize(width: r * 0.46, height: r * 0.36), cornerRadius: r * 0.16)
                link.position = CGPoint(x: -r * 0.90, y: headY - r * 0.04 - CGFloat(i) * r * 0.36)
                link.zRotation = i.isMultiple(of: 2) ? -0.26 : 0.26
                link.fillColor = color
                link.strokeColor = .clear
                link.zPosition = 1.85
                add(link)
            }
        case .topKnot:
            let cap = SKShapeNode(ellipseOf: CGSize(width: r * 2.05, height: r * 1.02))
            cap.position = CGPoint(x: 0, y: headY + r * 0.44)
            cap.fillColor = color
            cap.strokeColor = .clear
            cap.zPosition = 2
            add(cap)

            let knot = SKShapeNode(circleOfRadius: r * 0.36)
            knot.position = CGPoint(x: 0, y: headY + r * 1.18)
            knot.fillColor = color
            knot.strokeColor = Palette.playerStroke.withAlphaComponent(0.36)
            knot.lineWidth = 1.4
            knot.zPosition = 2.3
            add(knot)
        case .curly, .texturedCurls:
            let offsets = [
                CGPoint(x: -0.80, y: 0.52), CGPoint(x: -0.42, y: 0.86),
                CGPoint(x: 0.0, y: 0.98), CGPoint(x: 0.42, y: 0.86),
                CGPoint(x: 0.80, y: 0.52), CGPoint(x: -0.70, y: 0.20),
                CGPoint(x: 0.70, y: 0.20),
            ]
            for point in offsets {
                let curl = SKShapeNode(circleOfRadius: r * (style == .texturedCurls ? 0.29 : 0.34))
                curl.position = CGPoint(x: point.x * r, y: headY + point.y * r)
                curl.fillColor = color
                curl.strokeColor = Palette.playerStroke.withAlphaComponent(0.18)
                curl.lineWidth = 0.8
                curl.zPosition = 2.2
                add(curl)
            }
        case .beanie:
            let cap = SKShapeNode(rectOf: CGSize(width: r * 2.12, height: r * 1.05), cornerRadius: r * 0.46)
            cap.position = CGPoint(x: 0, y: headY + r * 0.62)
            cap.fillColor = SKColor(red: 0.90, green: 0.48, blue: 0.45, alpha: 1)
            cap.strokeColor = Palette.playerStroke.withAlphaComponent(0.36)
            cap.lineWidth = 1.2
            cap.zPosition = 2.2
            add(cap)

            let band = SKShapeNode(rectOf: CGSize(width: r * 2.12, height: r * 0.24), cornerRadius: r * 0.12)
            band.position = CGPoint(x: 0, y: headY + r * 0.34)
            band.fillColor = SKColor(red: 0.74, green: 0.30, blue: 0.38, alpha: 1)
            band.strokeColor = .clear
            band.zPosition = 2.4
            add(band)
        }
    }

    private func addFacialHair(style: FacialHairStyle,
                               color: SKColor,
                               headRadius r: CGFloat,
                               headY: CGFloat,
                               to node: SKNode) {
        switch style {
        case .none:
            return
        case .stubble:
            let stubble = SKShapeNode(ellipseOf: CGSize(width: r * 1.34, height: r * 0.78))
            stubble.position = CGPoint(x: 0, y: headY - r * 0.35)
            stubble.fillColor = color.withAlphaComponent(0.20)
            stubble.strokeColor = .clear
            stubble.zPosition = 3.42
            node.addChild(stubble)
        case .mustache:
            for side in [-1.0, 1.0] {
                let half = SKShapeNode(rectOf: CGSize(width: r * 0.46, height: r * 0.18), cornerRadius: r * 0.09)
                half.position = CGPoint(x: CGFloat(side) * r * 0.20, y: headY - r * 0.24)
                half.zRotation = CGFloat(side) * -0.18
                half.fillColor = color
                half.strokeColor = .clear
                half.zPosition = 3.62
                node.addChild(half)
            }
        case .fullBeard:
            let beard = SKShapeNode(rectOf: CGSize(width: r * 1.46, height: r * 0.96), cornerRadius: r * 0.40)
            beard.position = CGPoint(x: 0, y: headY - r * 0.38)
            beard.fillColor = color
            beard.strokeColor = .clear
            beard.zPosition = 3.38
            node.addChild(beard)
        }
    }

    private func addSmile(_ smileStyle: CorporateSmile, headY: CGFloat, to node: SKNode) {
        switch smileStyle {
        case .genuineJoy:
            let smile = SKShapeNode(rectOf: CGSize(width: 14, height: 6), cornerRadius: 3)
            smile.position = CGPoint(x: 0, y: headY - 8)
            smile.fillColor = .white
            smile.strokeColor = Palette.playerStroke.withAlphaComponent(0.58)
            smile.lineWidth = 0.9
            smile.zPosition = 3.7
            node.addChild(smile)
        case .serviceSmirk:
            let smilePath = CGMutablePath()
            smilePath.move(to: CGPoint(x: -5.5, y: headY - 7.5))
            smilePath.addQuadCurve(to: CGPoint(x: 6.0, y: headY - 7.0),
                                   control: CGPoint(x: 0.5, y: headY - 10.4))
            let smile = SKShapeNode(path: smilePath)
            smile.fillColor = .clear
            smile.strokeColor = Palette.playerStroke.withAlphaComponent(0.40)
            smile.lineWidth = 1
            smile.lineCap = .round
            smile.zPosition = 3.7
            node.addChild(smile)
        case .deadInside:
            let line = SKShapeNode(rectOf: CGSize(width: 10, height: 1.2), cornerRadius: 0.6)
            line.position = CGPoint(x: 0, y: headY - 8.5)
            line.fillColor = Palette.playerStroke.withAlphaComponent(0.42)
            line.strokeColor = .clear
            line.zPosition = 3.7
            node.addChild(line)
        }
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
