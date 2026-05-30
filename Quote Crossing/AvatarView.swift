//
//  AvatarView.swift
//  Quote Crossing
//
//  Live, front-facing 2D vector "paper-doll" of the player avatar, assembled
//  from stacked SwiftUI shapes + SF Symbols (no images / no pixel art). Drives
//  the character-creator preview and the ID badge.
//
//  Coordinates: everything is positioned by `.offset` relative to the ZStack
//  centre. The head is centred slightly above centre; the torso below it.
//

import SwiftUI

struct AvatarView: View {
    @ObservedObject var avatar: PlayerAvatar

    /// Wearables to layer on the figure. When nil, falls back to the creator's
    /// starter accessories (mapped to catalog wearables) so the creator preview
    /// works unchanged; the wardrobe passes the live equipped list instead.
    var wearables: [WearableItem]? = nil

    /// Reference canvas; use `.scaleEffect` on the parent to resize.
    private var headDiameter: CGFloat {
        96 * avatar.bodyType.headScale
    }
    private var headSize: CGSize {
        CGSize(width: headDiameter * avatar.faceShape.widthScale,
               height: headDiameter * avatar.faceShape.heightScale)
    }
    private var headCornerRadius: CGFloat {
        min(headSize.width, headSize.height) * avatar.faceShape.cornerRadius
    }
    private var headCenterY: CGFloat {
        switch avatar.presentation {
        case .masculine: -64
        case .feminine: -70
        case .androgynous: -67
        }
    }

    private var renderedWearables: [WearableItem] {
        if let wearables { return wearables }
        return []
    }

    var body: some View {
        ZStack {
            legs
            torso
            neck
            head
            HairView(style: avatar.hairStyle, color: avatar.hairColor, headDiameter: headDiameter)
                .offset(y: headCenterY)
            FaceView(
                presentation: avatar.presentation,
                faceShape: avatar.faceShape,
                aesthetic: avatar.aesthetic,
                smile: avatar.corporateSmile,
                facialHair: avatar.facialHair,
                eyeColor: avatar.eyeColor,
                hairColor: avatar.hairColor,
                eyeBags: avatar.eyeBagsLevel
            )
                .offset(y: headCenterY)
            wearableLayer
        }
        .frame(width: 220, height: 300)
    }

    // MARK: Body parts

    private var torso: some View {
        OutfitView(outfit: avatar.starterOutfit,
                   skin: avatar.skinTone,
                   presentation: avatar.presentation,
                   bodyType: avatar.bodyType)
            .offset(y: 42)
    }

    private var legs: some View {
        LegsView(outfit: avatar.starterOutfit,
                 presentation: avatar.presentation,
                 bodyType: avatar.bodyType)
            .offset(y: 104)
    }

    private var neck: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(avatar.skinTone)
            .frame(width: 36, height: 34)
            .offset(y: headCenterY + 40)
    }

    private var head: some View {
        RoundedRectangle(cornerRadius: headCornerRadius, style: .continuous)
            .fill(avatar.skinTone)
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: headDiameter * 0.46, height: headDiameter * 0.46)
                    .offset(x: headDiameter * 0.14, y: headDiameter * 0.12)
            }
            .overlay(
                RoundedRectangle(cornerRadius: headCornerRadius, style: .continuous)
                    .stroke(Color(red: 0.15, green: 0.08, blue: 0.18), lineWidth: 4)
            )
            .frame(width: headSize.width, height: headSize.height)
            .offset(y: headCenterY)
    }

    private var wearableLayer: some View {
        ZStack {
            ForEach(renderedWearables) { item in
                WearableLayer(item: item, headCenterY: headCenterY)
            }
        }
    }
}

// MARK: - Face (eyes, eye-bags, mouth)

private struct FaceView: View {
    var presentation: AvatarPresentation
    var faceShape: FaceShape
    var aesthetic: AvatarAesthetic
    var smile: CorporateSmile
    var facialHair: FacialHairStyle
    var eyeColor: Color
    var hairColor: Color
    var eyeBags: CGFloat

    var body: some View {
        ZStack {
            if presentation == .feminine || aesthetic == .pastelCampus {
                HStack(spacing: 34) {
                    cheek
                    cheek
                }
                .offset(y: 11)
            }

            // Under-eye bags — purple, opacity scales with the slider (GDD §1).
            HStack(spacing: 16) {
                bag
                bag
            }
            .offset(y: 6)

            // Eyes.
            HStack(spacing: 16) {
                eye
                eye
            }
            .offset(y: -6)

            HStack(spacing: 22) {
                brow(left: true)
                brow(left: false)
            }
            .offset(y: -20)

            if presentation == .feminine {
                HStack(spacing: 17) {
                    lash.rotationEffect(.degrees(-18))
                    lash.rotationEffect(.degrees(18))
                }
                .offset(y: -10)
            }

            if presentation != .feminine {
                facialHairLayer
            }
            mouth
        }
    }

    private var eye: some View {
        Circle()
            .fill(eyeColor)
            .overlay(Circle().fill(.white.opacity(0.30)).frame(width: 3, height: 3).offset(x: -2, y: -2))
            .frame(width: 11, height: 11)
    }

    private func brow(left: Bool) -> some View {
        Capsule()
            .fill(Color(red: 0.15, green: 0.08, blue: 0.18).opacity(0.88))
            .frame(width: faceShape == .square || faceShape == .angular ? 19 : 17, height: 4)
            .rotationEffect(.degrees(left ? -8 : 8))
    }

    private var lash: some View {
        Capsule()
            .fill(Color(red: 0.15, green: 0.08, blue: 0.18).opacity(0.78))
            .frame(width: 9, height: 2.4)
    }

    private var cheek: some View {
        Ellipse()
            .fill(Color(red: 0.95, green: 0.48, blue: 0.58).opacity(0.22))
            .frame(width: 18, height: 9)
    }

    private var bag: some View {
        Ellipse()
            .fill(Color(red: 0.46, green: 0.34, blue: 0.56).opacity(Double(eyeBags) * 0.85))
            .frame(width: 22, height: 11)
    }

    @ViewBuilder private var mouth: some View {
        switch smile {
        case .genuineJoy:
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.white)
                .frame(width: 34, height: 15)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.15, green: 0.08, blue: 0.18), lineWidth: 2.4)
                )
                .mask(
                    Rectangle()
                        .frame(width: 40, height: 12)
                        .offset(y: 6)
                )
                .offset(y: 24)
        case .serviceSmirk:
            Capsule()
                .fill(Color(red: 0.55, green: 0.22, blue: 0.28))
                .frame(width: 27, height: 5)
                .rotationEffect(.degrees(-4))
                .offset(y: 24)
        case .deadInside:
            Capsule()
                .fill(Color(red: 0.40, green: 0.25, blue: 0.30))
                .frame(width: 22, height: 4)
                .offset(y: 24)
        }
    }

    @ViewBuilder private var facialHairLayer: some View {
        switch facialHair {
        case .none:
            EmptyView()
        case .stubble:
            Ellipse()
                .fill(hairColor.opacity(0.22))
                .frame(width: 42, height: 26)
                .offset(y: 20)
        case .mustache:
            HStack(spacing: -2) {
                Capsule().fill(hairColor).frame(width: 18, height: 8).rotationEffect(.degrees(8))
                Capsule().fill(hairColor).frame(width: 18, height: 8).rotationEffect(.degrees(-8))
            }
            .offset(y: 13)
        case .fullBeard:
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(hairColor)
                .frame(width: 62, height: 42)
                .mask(
                    VStack(spacing: 0) {
                        Spacer()
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .frame(width: 62, height: 34)
                    }
                )
                .offset(y: 22)
        }
    }
}

// MARK: - Hair

private struct HairView: View {
    let style: HairStyle
    let color: Color
    let headDiameter: CGFloat

    private let hairline: CGFloat = -14   // bottom of hair, relative to head centre
    private let ink = Color(red: 0.15, green: 0.08, blue: 0.18)
    private let shine = Color.white.opacity(0.18)

    var body: some View {
        ZStack {
            switch style {
            case .bald:
                EmptyView()
            case .buzz:
                cap(diameter: headDiameter)
                hairlineBand(width: headDiameter * 0.78, y: -17)
            case .croppedFade:
                cap(diameter: headDiameter)
                lock(width: 16, height: 44, x: -42, y: -6, rotation: 0, opacity: 0.70)
                lock(width: 16, height: 44, x: 42, y: -6, rotation: 0, opacity: 0.70)
                swoop(width: 62, height: 18, x: 2, y: -36, rotation: -7)
            case .sideSwept:
                cap(diameter: headDiameter + 6)
                swoop(width: 82, height: 30, x: 11, y: -31, rotation: -15)
                lock(width: 26, height: 52, x: -39, y: -8, rotation: 9)
                highlight(width: 34, height: 5, x: 18, y: -39, rotation: -15)
            case .curtainSweep:
                cap(diameter: headDiameter + 6)
                lock(width: 38, height: 82, x: -24, y: -13, rotation: -18)
                lock(width: 38, height: 82, x: 24, y: -13, rotation: 18)
                partLine(height: 42, y: -31)
                highlight(width: 24, height: 5, x: -22, y: -36, rotation: -22)
                highlight(width: 24, height: 5, x: 22, y: -36, rotation: 22)
            case .shag:
                cap(diameter: headDiameter + 8)
                ForEach(Array(shagOffsets.enumerated()), id: \.offset) { _, offset in
                    lock(width: 24, height: 48, x: offset.width, y: offset.height, rotation: Double(offset.width) * 0.42)
                }
                hairlineBand(width: headDiameter * 0.82, y: -11)
            case .centerPart:
                cap(diameter: headDiameter + 8)
                lock(width: 42, height: 84, x: -30, y: -2, rotation: 15)
                lock(width: 42, height: 84, x: 30, y: -2, rotation: -15)
                partLine(height: 48, y: -30)
                highlight(width: 28, height: 5, x: -28, y: -22, rotation: 13)
                highlight(width: 28, height: 5, x: 28, y: -22, rotation: -13)
            case .longWaves:
                waveColumn(side: -1, length: 136, x: -40, y: 10)
                waveColumn(side: 1, length: 136, x: 40, y: 10)
                cap(diameter: headDiameter + 8)
                partLine(height: 42, y: -32)
                highlight(width: 26, height: 5, x: -34, y: -12, rotation: 18)
                highlight(width: 26, height: 5, x: 34, y: -12, rotation: -18)
            case .looseWaves:
                waveColumn(side: -1, length: 118, x: -37, y: 7)
                waveColumn(side: 1, length: 118, x: 37, y: 7)
                cap(diameter: headDiameter + 10)
                ForEach(Array(waveOffsets.enumerated()), id: \.offset) { _, offset in
                    curl(size: 24, x: offset.width, y: offset.height, opacity: 0.96)
                }
                swoop(width: 66, height: 22, x: -5, y: -35, rotation: -4)
            case .wavyLob:
                waveColumn(side: -1, length: 90, x: -35, y: -2)
                waveColumn(side: 1, length: 90, x: 35, y: -2)
                cap(diameter: headDiameter + 8)
                swoop(width: 64, height: 22, x: 2, y: -34, rotation: -8)
                hairlineBand(width: headDiameter * 0.72, y: -10)
            case .bluntBob:
                BobHairShape()
                    .fill(color)
                    .overlay(
                        BobHairShape()
                            .stroke(ink, lineWidth: 4)
                    )
                    .overlay(alignment: .topLeading) {
                        Capsule()
                            .fill(shine)
                            .frame(width: 12, height: 58)
                            .offset(x: 30, y: 18)
                    }
                    .frame(width: headDiameter + 24, height: 112)
                    .offset(y: 4)
                cap(diameter: headDiameter + 6)
                swoop(width: 78, height: 24, x: -1, y: -33, rotation: 0)
                hairlineBand(width: headDiameter + 10, y: 42)
            case .pixie:
                cap(diameter: headDiameter + 4)
                ForEach(Array(pixieOffsets.enumerated()), id: \.offset) { _, offset in
                    lock(width: 22, height: 38, x: offset.width, y: offset.height, rotation: Double(offset.width) * -0.55)
                }
                swoop(width: 54, height: 20, x: 12, y: -35, rotation: -14)
            case .highPonytail:
                lock(width: 42, height: 110, x: 47, y: -2, rotation: -7)
                    .zIndex(-1)
                cap(diameter: headDiameter + 6)
                curl(size: 34, x: 39, y: -53)
                swoop(width: 72, height: 24, x: -7, y: -35, rotation: -7)
                highlight(width: 7, height: 62, x: 53, y: 0, rotation: -7)
            case .softBraid:
                cap(diameter: headDiameter + 6)
                lock(width: 36, height: 86, x: -39, y: 3, rotation: 8)
                    .zIndex(-1)
                ForEach(0..<5, id: \.self) { i in
                    braidLink(index: i)
                }
                partLine(height: 36, y: -34)
            case .topKnot:
                cap(diameter: headDiameter)
                curl(size: 32, x: 0, y: -62)
                swoop(width: 58, height: 18, x: -4, y: -34, rotation: -6)
            case .curly:
                ForEach(Array(curlOffsets.enumerated()), id: \.offset) { _, p in
                    curl(size: 37, x: p.width, y: p.height)
                }
                curl(size: 29, x: 0, y: -18, opacity: 0.94)
            case .texturedCurls:
                ForEach(Array(texturedCurlOffsets.enumerated()), id: \.offset) { _, p in
                    curl(size: 31, x: p.width, y: p.height)
                }
                hairlineBand(width: headDiameter * 0.72, y: -14)
            case .beanie:
                beanieCap(diameter: headDiameter + 8)
                Capsule()
                    .fill(Color(red: 0.74, green: 0.30, blue: 0.38))
                    .overlay(Capsule().stroke(ink, lineWidth: 3))
                    .frame(width: 92, height: 16)
                    .offset(y: -18)
            }
        }
    }

    /// Hair circle masked to a band from the crown down to the hairline.
    private func cap(diameter: CGFloat) -> some View {
        let top = -diameter / 2
        let height = hairline - top
        return CrownCapShape()
            .fill(color)
            .overlay(CrownCapShape().stroke(ink, lineWidth: 4))
            .frame(width: diameter, height: diameter)
            .mask(
                Rectangle()
                    .frame(width: diameter + 24, height: max(0, height))
                    .offset(y: top + height / 2)
            )
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(shine)
                    .frame(width: diameter * 0.26, height: diameter * 0.26)
                    .offset(x: diameter * 0.30, y: diameter * 0.08)
                    .mask(
                        Rectangle()
                            .frame(width: diameter + 24, height: max(0, height))
                            .offset(y: top + height / 2)
                    )
            }
    }

    private func beanieCap(diameter: CGFloat) -> some View {
        let top = -diameter / 2
        let height = hairline - top
        return CrownCapShape()
            .fill(Color(red: 0.90, green: 0.48, blue: 0.45))
            .overlay(CrownCapShape().stroke(ink, lineWidth: 4))
            .frame(width: diameter, height: diameter)
            .mask(
                Rectangle()
                    .frame(width: diameter + 24, height: max(0, height))
                    .offset(y: top + height / 2)
            )
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(.white.opacity(0.16))
                    .frame(width: diameter * 0.34, height: diameter * 0.34)
                    .offset(x: diameter * 0.24, y: diameter * 0.09)
            }
    }

    private func lock(width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat, rotation: Double, opacity: Double = 1) -> some View {
        OrganicHairLockShape(sway: CGFloat(rotation) / 16, taper: 0.18)
            .fill(color.opacity(opacity))
            .overlay(
                OrganicHairLockShape(sway: CGFloat(rotation) / 16, taper: 0.18)
                    .stroke(ink.opacity(0.88), lineWidth: 3)
            )
            .overlay(alignment: .topLeading) {
                Capsule()
                    .fill(shine)
                    .frame(width: max(4, width * 0.20), height: max(12, height * 0.48))
                    .offset(x: width * 0.33, y: height * 0.14)
            }
            .frame(width: width, height: height)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
    }

    private func swoop(width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat, rotation: Double) -> some View {
        HairSwoopShape()
            .fill(color)
            .overlay(HairSwoopShape().stroke(ink, lineWidth: 3.4))
            .overlay(alignment: .topLeading) {
                Capsule()
                    .fill(shine)
                    .frame(width: width * 0.42, height: 4)
                    .offset(x: width * 0.22, y: height * 0.25)
            }
            .frame(width: width, height: height)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
    }

    private func curl(size: CGFloat, x: CGFloat, y: CGFloat, opacity: Double = 1) -> some View {
        Circle()
            .fill(color.opacity(opacity))
            .overlay(Circle().stroke(ink.opacity(0.84), lineWidth: 3))
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(shine)
                    .frame(width: size * 0.26, height: size * 0.26)
                    .offset(x: size * 0.28, y: size * 0.20)
            }
            .frame(width: size, height: size)
            .offset(x: x, y: y)
    }

    private func highlight(width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat, rotation: Double) -> some View {
        Capsule()
            .fill(shine)
            .frame(width: width, height: height)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
    }

    private func partLine(height: CGFloat, y: CGFloat) -> some View {
        Capsule()
            .fill(Color.white.opacity(0.38))
            .frame(width: 3, height: height)
            .offset(y: y)
    }

    private func hairlineBand(width: CGFloat, y: CGFloat) -> some View {
        Capsule()
            .fill(ink.opacity(0.28))
            .frame(width: width, height: 4)
            .offset(y: y)
    }

    private func waveColumn(side: CGFloat, length: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            WaveHairLockShape(side: side)
                .fill(color)
                .overlay(WaveHairLockShape(side: side).stroke(ink.opacity(0.88), lineWidth: 3.2))
                .overlay(alignment: .topLeading) {
                    Capsule()
                        .fill(shine)
                        .frame(width: 7, height: length * 0.46)
                        .offset(x: side < 0 ? 25 : 11, y: length * 0.13)
                }
                .frame(width: 46, height: length)
                .rotationEffect(.degrees(Double(side) * -4))
            curl(size: 30, x: side * 8, y: length * 0.34, opacity: 0.96)
            highlight(width: 7, height: length * 0.48, x: side * -7, y: -length * 0.05, rotation: Double(side) * -7)
        }
        .offset(x: x, y: y)
    }

    private func braidLink(index: Int) -> some View {
        let side: CGFloat = index.isMultiple(of: 2) ? -1 : 1
        return RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(color.opacity(index.isMultiple(of: 2) ? 1 : 0.90))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(ink.opacity(0.86), lineWidth: 3))
            .overlay(alignment: .topLeading) {
                Capsule()
                    .fill(shine)
                    .frame(width: 6, height: 12)
                    .offset(x: 9, y: 5)
            }
            .frame(width: 30, height: 25)
            .rotationEffect(.degrees(index.isMultiple(of: 2) ? -18 : 18))
            .offset(x: -43 + side * 3, y: CGFloat(index) * 20 - 4)
    }

    private var curlOffsets: [CGSize] {
        [
            .init(width: -34, height: -28), .init(width: -18, height: -44),
            .init(width: 0, height: -50),   .init(width: 18, height: -44),
            .init(width: 34, height: -28),  .init(width: -30, height: -12),
            .init(width: 30, height: -12),
        ]
    }

    private var texturedCurlOffsets: [CGSize] {
        [
            .init(width: -36, height: -24), .init(width: -20, height: -42),
            .init(width: -2, height: -48), .init(width: 16, height: -42),
            .init(width: 34, height: -24), .init(width: -24, height: -12),
            .init(width: 8, height: -18), .init(width: 26, height: -8),
        ]
    }

    private var shagOffsets: [CGSize] {
        [
            .init(width: -34, height: -20), .init(width: -16, height: -31),
            .init(width: 7, height: -33), .init(width: 28, height: -18),
            .init(width: -40, height: 3), .init(width: 40, height: 4),
        ]
    }

    private var waveOffsets: [CGSize] {
        [
            .init(width: -38, height: 34), .init(width: 38, height: 34),
            .init(width: -34, height: 58), .init(width: 34, height: 58),
        ]
    }

    private var pixieOffsets: [CGSize] {
        [
            .init(width: -28, height: -24), .init(width: -10, height: -38),
            .init(width: 12, height: -37), .init(width: 30, height: -20),
        ]
    }
}

private struct CrownCapShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: rect.minX + w * 0.08, y: rect.midY + h * 0.04))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.23, y: rect.minY + h * 0.18),
                      control1: CGPoint(x: rect.minX + w * 0.08, y: rect.minY + h * 0.35),
                      control2: CGPoint(x: rect.minX + w * 0.13, y: rect.minY + h * 0.22))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.54, y: rect.minY + h * 0.05),
                      control1: CGPoint(x: rect.minX + w * 0.32, y: rect.minY + h * 0.08),
                      control2: CGPoint(x: rect.minX + w * 0.43, y: rect.minY + h * 0.04))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.86, y: rect.minY + h * 0.22),
                      control1: CGPoint(x: rect.minX + w * 0.68, y: rect.minY + h * 0.06),
                      control2: CGPoint(x: rect.minX + w * 0.79, y: rect.minY + h * 0.12))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.94, y: rect.midY + h * 0.05),
                      control1: CGPoint(x: rect.minX + w * 0.93, y: rect.minY + h * 0.32),
                      control2: CGPoint(x: rect.minX + w * 0.96, y: rect.minY + h * 0.44))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.08, y: rect.midY + h * 0.04),
                      control1: CGPoint(x: rect.minX + w * 0.70, y: rect.midY + h * 0.18),
                      control2: CGPoint(x: rect.minX + w * 0.30, y: rect.midY + h * 0.16))
        path.closeSubpath()
        return path
    }
}

private struct OrganicHairLockShape: Shape {
    let sway: CGFloat
    let taper: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let drift = max(-0.28, min(0.28, sway)) * w
        let bottomInset = w * (0.14 + taper * 0.08)
        path.move(to: CGPoint(x: rect.minX + w * 0.34, y: rect.minY + h * 0.02))
        path.addCurve(to: CGPoint(x: rect.maxX - w * 0.20, y: rect.minY + h * 0.22),
                      control1: CGPoint(x: rect.minX + w * 0.54, y: rect.minY - h * 0.02),
                      control2: CGPoint(x: rect.maxX - w * 0.18, y: rect.minY + h * 0.05))
        path.addCurve(to: CGPoint(x: rect.maxX - bottomInset + drift, y: rect.maxY - h * 0.10),
                      control1: CGPoint(x: rect.maxX + drift * 0.20, y: rect.minY + h * 0.46),
                      control2: CGPoint(x: rect.maxX + drift * 0.45, y: rect.maxY - h * 0.10))
        path.addCurve(to: CGPoint(x: rect.minX + bottomInset + drift * 0.18, y: rect.maxY - h * 0.03),
                      control1: CGPoint(x: rect.midX + drift, y: rect.maxY + h * 0.08),
                      control2: CGPoint(x: rect.minX + bottomInset + drift * 0.42, y: rect.maxY + h * 0.04))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.21, y: rect.minY + h * 0.20),
                      control1: CGPoint(x: rect.minX - w * 0.04 + drift * 0.24, y: rect.maxY - h * 0.24),
                      control2: CGPoint(x: rect.minX + w * 0.02, y: rect.minY + h * 0.36))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.34, y: rect.minY + h * 0.02),
                      control1: CGPoint(x: rect.minX + w * 0.24, y: rect.minY + h * 0.12),
                      control2: CGPoint(x: rect.minX + w * 0.28, y: rect.minY + h * 0.06))
        path.closeSubpath()
        return path
    }
}

private struct HairSwoopShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: rect.minX + w * 0.06, y: rect.maxY - h * 0.36))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.38, y: rect.minY + h * 0.08),
                      control1: CGPoint(x: rect.minX + w * 0.08, y: rect.minY + h * 0.34),
                      control2: CGPoint(x: rect.minX + w * 0.20, y: rect.minY + h * 0.09))
        path.addCurve(to: CGPoint(x: rect.maxX - w * 0.05, y: rect.minY + h * 0.32),
                      control1: CGPoint(x: rect.minX + w * 0.66, y: rect.minY - h * 0.10),
                      control2: CGPoint(x: rect.maxX - w * 0.05, y: rect.minY + h * 0.05))
        path.addCurve(to: CGPoint(x: rect.maxX - w * 0.18, y: rect.maxY - h * 0.12),
                      control1: CGPoint(x: rect.maxX + w * 0.02, y: rect.minY + h * 0.58),
                      control2: CGPoint(x: rect.maxX - w * 0.05, y: rect.maxY - h * 0.02))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.06, y: rect.maxY - h * 0.36),
                      control1: CGPoint(x: rect.minX + w * 0.62, y: rect.maxY + h * 0.06),
                      control2: CGPoint(x: rect.minX + w * 0.24, y: rect.maxY + h * 0.02))
        path.closeSubpath()
        return path
    }
}

private struct WaveHairLockShape: Shape {
    let side: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let s = side < 0 ? -1.0 : 1.0
        let outerX = s < 0 ? rect.minX + w * 0.16 : rect.maxX - w * 0.16
        let innerX = s < 0 ? rect.maxX - w * 0.16 : rect.minX + w * 0.16
        let midOuter = s < 0 ? rect.minX + w * 0.06 : rect.maxX - w * 0.06
        let midInner = s < 0 ? rect.maxX - w * 0.05 : rect.minX + w * 0.05

        path.move(to: CGPoint(x: outerX, y: rect.minY + h * 0.04))
        path.addCurve(to: CGPoint(x: midOuter, y: rect.minY + h * 0.52),
                      control1: CGPoint(x: outerX - w * 0.20 * s, y: rect.minY + h * 0.18),
                      control2: CGPoint(x: midInner, y: rect.minY + h * 0.34))
        path.addCurve(to: CGPoint(x: outerX + w * 0.18 * s, y: rect.maxY - h * 0.04),
                      control1: CGPoint(x: midOuter, y: rect.minY + h * 0.74),
                      control2: CGPoint(x: outerX + w * 0.34 * s, y: rect.maxY - h * 0.20))
        path.addCurve(to: CGPoint(x: innerX, y: rect.maxY - h * 0.10),
                      control1: CGPoint(x: rect.midX, y: rect.maxY + h * 0.07),
                      control2: CGPoint(x: innerX, y: rect.maxY + h * 0.02))
        path.addCurve(to: CGPoint(x: innerX - w * 0.05 * s, y: rect.minY + h * 0.12),
                      control1: CGPoint(x: innerX + w * 0.13 * s, y: rect.minY + h * 0.62),
                      control2: CGPoint(x: innerX - w * 0.16 * s, y: rect.minY + h * 0.34))
        path.addCurve(to: CGPoint(x: outerX, y: rect.minY + h * 0.04),
                      control1: CGPoint(x: innerX - w * 0.12 * s, y: rect.minY + h * 0.02),
                      control2: CGPoint(x: outerX + w * 0.12 * s, y: rect.minY - h * 0.02))
        path.closeSubpath()
        return path
    }
}

private struct BobHairShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: rect.minX + w * 0.18, y: rect.minY + h * 0.28))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.47, y: rect.minY + h * 0.04),
                      control1: CGPoint(x: rect.minX + w * 0.22, y: rect.minY + h * 0.10),
                      control2: CGPoint(x: rect.minX + w * 0.32, y: rect.minY + h * 0.02))
        path.addCurve(to: CGPoint(x: rect.maxX - w * 0.18, y: rect.minY + h * 0.28),
                      control1: CGPoint(x: rect.minX + w * 0.64, y: rect.minY + h * 0.02),
                      control2: CGPoint(x: rect.maxX - w * 0.24, y: rect.minY + h * 0.11))
        path.addCurve(to: CGPoint(x: rect.maxX - w * 0.09, y: rect.maxY - h * 0.08),
                      control1: CGPoint(x: rect.maxX - w * 0.05, y: rect.minY + h * 0.50),
                      control2: CGPoint(x: rect.maxX - w * 0.05, y: rect.maxY - h * 0.22))
        path.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.11, y: rect.maxY - h * 0.08),
                          control: CGPoint(x: rect.midX, y: rect.maxY + h * 0.09))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.18, y: rect.minY + h * 0.28),
                      control1: CGPoint(x: rect.minX + w * 0.05, y: rect.maxY - h * 0.22),
                      control2: CGPoint(x: rect.minX + w * 0.05, y: rect.minY + h * 0.50))
        path.closeSubpath()
        return path
    }
}

// MARK: - Outfit (torso + collar)

private struct TorsoSilhouette: Shape {
    let shoulderWidth: CGFloat
    let waistWidth: CGFloat
    let hipWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let centerX = rect.midX
        let topY = rect.minY + rect.height * 0.04
        let shoulderY = rect.minY + rect.height * 0.14
        let waistY = rect.minY + rect.height * 0.56
        let hipY = rect.maxY - rect.height * 0.08

        let shoulder = min(rect.width, shoulderWidth) / 2
        let waist = min(rect.width, waistWidth) / 2
        let hip = min(rect.width, hipWidth) / 2

        var path = Path()
        path.move(to: CGPoint(x: centerX - shoulder * 0.72, y: topY))
        path.addQuadCurve(to: CGPoint(x: centerX - shoulder, y: shoulderY),
                          control: CGPoint(x: centerX - shoulder, y: topY))
        path.addCurve(to: CGPoint(x: centerX - waist, y: waistY),
                      control1: CGPoint(x: centerX - shoulder * 0.96, y: rect.minY + rect.height * 0.28),
                      control2: CGPoint(x: centerX - waist * 1.10, y: rect.minY + rect.height * 0.42))
        path.addCurve(to: CGPoint(x: centerX - hip, y: hipY),
                      control1: CGPoint(x: centerX - waist * 0.92, y: rect.minY + rect.height * 0.70),
                      control2: CGPoint(x: centerX - hip, y: rect.minY + rect.height * 0.76))
        path.addQuadCurve(to: CGPoint(x: centerX, y: rect.maxY),
                          control: CGPoint(x: centerX - hip * 0.56, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: centerX + hip, y: hipY),
                          control: CGPoint(x: centerX + hip * 0.56, y: rect.maxY))
        path.addCurve(to: CGPoint(x: centerX + waist, y: waistY),
                      control1: CGPoint(x: centerX + hip, y: rect.minY + rect.height * 0.76),
                      control2: CGPoint(x: centerX + waist * 0.92, y: rect.minY + rect.height * 0.70))
        path.addCurve(to: CGPoint(x: centerX + shoulder, y: shoulderY),
                      control1: CGPoint(x: centerX + waist * 1.10, y: rect.minY + rect.height * 0.42),
                      control2: CGPoint(x: centerX + shoulder * 0.96, y: rect.minY + rect.height * 0.28))
        path.addQuadCurve(to: CGPoint(x: centerX + shoulder * 0.72, y: topY),
                          control: CGPoint(x: centerX + shoulder, y: topY))
        path.closeSubpath()
        return path
    }
}

private struct OutfitView: View {
    let outfit: StarterOutfit
    let skin: Color
    let presentation: AvatarPresentation
    let bodyType: BodyType

    private var torsoWidth: CGFloat { 126 * max(bodyType.shoulderScale, bodyType.hipScale) }
    private var torsoHeight: CGFloat { 96 * bodyType.heightScale }
    private var shoulderWidth: CGFloat { 126 * bodyType.shoulderScale }
    private var waistWidth: CGFloat { 126 * bodyType.waistScale }
    private var hipWidth: CGFloat { 126 * bodyType.hipScale }

    var body: some View {
        ZStack {
            HStack(spacing: max(50, shoulderWidth * 0.62)) {
                arm(rotation: armRotation)
                arm(rotation: -armRotation)
            }
            .offset(y: -4)

            TorsoSilhouette(shoulderWidth: shoulderWidth,
                            waistWidth: waistWidth,
                            hipWidth: hipWidth)
                .fill(outfit.torso.color)
                .overlay(
                    TorsoSilhouette(shoulderWidth: shoulderWidth,
                                    waistWidth: waistWidth,
                                    hipWidth: hipWidth)
                        .stroke(Color(red: 0.15, green: 0.08, blue: 0.18), lineWidth: 4)
                )
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.white.opacity(0.13))
                        .frame(width: torsoWidth * 0.38, height: torsoHeight * 0.74)
                        .offset(x: torsoWidth * 0.16, y: torsoHeight * 0.10)
                }
                .frame(width: torsoWidth, height: torsoHeight)

            collar
        }
    }

    private var armRotation: Double {
        switch presentation {
        case .masculine: 7
        case .feminine: 4
        case .androgynous: 6
        }
    }

    private func arm(rotation: Double) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(outfit.torso.color)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(red: 0.15, green: 0.08, blue: 0.18), lineWidth: 4)
            )
            .frame(width: 24 + 7 * bodyType.shoulderScale, height: 92 * bodyType.heightScale)
            .rotationEffect(.degrees(rotation))
            .overlay(alignment: .bottom) {
                Circle()
                    .fill(skin)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color(red: 0.15, green: 0.08, blue: 0.18), lineWidth: 3))
                    .offset(y: 14)
            }
    }

    @ViewBuilder private var collar: some View {
        switch outfit {
        case .overdressedRookie:
            // White shirt wedge + red tie.
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(white: 0.96))
                .frame(width: 44, height: 56)
                .offset(y: -34)
            Capsule()
                .fill(outfit.accent.color)
                .frame(width: 12, height: 48)
                .offset(y: -22)
        case .techBro:
            // Fleece zipper line.
            Capsule()
                .fill(outfit.accent.color)
                .frame(width: 6, height: 76)
                .offset(y: -16)
        case .minimalist:
            // High turtleneck collar.
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(outfit.accent.color)
                .frame(width: 58, height: 30)
                .offset(y: -48)
        case .pastelJacket:
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .frame(width: 44, height: 58)
                .offset(y: -34)
            HStack(spacing: 28) {
                Capsule().fill(outfit.accent.color).frame(width: 12, height: 54).rotationEffect(.degrees(16))
                Capsule().fill(outfit.accent.color).frame(width: 12, height: 54).rotationEffect(.degrees(-16))
            }
            .offset(y: -28)
        case .campusCasual:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(outfit.accent.color)
                .frame(width: 82, height: 34)
                .offset(y: -42)
        case .quotaHoodie:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(outfit.accent.color.opacity(0.24))
                .frame(width: 76, height: 40)
                .offset(y: -42)
            Capsule()
                .fill(outfit.accent.color)
                .frame(width: 7, height: 54)
                .offset(y: -18)
        case .executiveBadge:
            Capsule()
                .fill(outfit.accent.color)
                .frame(width: 10, height: 82)
                .rotationEffect(.degrees(22))
                .offset(x: -18, y: -22)
            Capsule()
                .fill(outfit.accent.color)
                .frame(width: 10, height: 82)
                .rotationEffect(.degrees(-22))
                .offset(x: 18, y: -22)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.85, green: 0.97, blue: 1.0))
                .frame(width: 52, height: 42)
                .overlay(
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 19, weight: .heavy))
                        .foregroundStyle(Color(red: 0.30, green: 0.44, blue: 0.62))
                )
                .offset(y: 8)
        }
    }
}

private struct LegsView: View {
    let outfit: StarterOutfit
    let presentation: AvatarPresentation
    let bodyType: BodyType

    private var ink: Color { Color(red: 0.15, green: 0.08, blue: 0.18) }
    private var stance: CGFloat {
        switch presentation {
        case .masculine: 19
        case .feminine: 14
        case .androgynous: 16
        }
    }
    private var legWidth: CGFloat { 31 * max(0.84, bodyType.hipScale) }
    private var legHeight: CGFloat { 78 * bodyType.heightScale }

    var body: some View {
        ZStack {
            HStack(spacing: stance) {
                leg(rotation: 3)
                leg(rotation: -3)
            }
            HStack(spacing: stance + 7) {
                shoe(rotation: -5)
                shoe(rotation: 5)
            }
            .offset(y: legHeight * 0.46)
        }
    }

    private func leg(rotation: Double) -> some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(outfit.pants.color)
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(ink, lineWidth: 4)
            )
            .overlay(alignment: .topLeading) {
                Capsule()
                    .fill(.white.opacity(0.13))
                    .frame(width: legWidth * 0.22, height: legHeight * 0.62)
                    .offset(x: legWidth * 0.24, y: legHeight * 0.10)
            }
            .frame(width: legWidth, height: legHeight)
            .rotationEffect(.degrees(rotation))
    }

    private func shoe(rotation: Double) -> some View {
        Capsule()
            .fill(outfit.shoes.color)
            .overlay(Capsule().stroke(ink, lineWidth: 3))
            .frame(width: 42, height: 18)
            .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Wearables (generic, positioned by slot)

private struct WearableLayer: View {
    let item: WearableItem
    let headCenterY: CGFloat

    var body: some View {
        Image(systemName: item.imageIcon)
            .font(.system(size: size, weight: .regular))
            .symbolRenderingMode(item.slot == .lanyard ? .palette : .monochrome)
            .foregroundStyle(primaryTint, .white)
            .offset(y: anchorY)
    }

    private var primaryTint: Color { item.tint.color }

    private var size: CGFloat {
        switch item.slot {
        case .head:    58
        case .eyewear: 46
        case .torso:   58
        case .lanyard: 46
        }
    }

    private var anchorY: CGFloat {
        switch item.slot {
        case .head:    headCenterY - 38   // sits on top of the head
        case .eyewear: headCenterY - 4    // over the eyes
        case .torso:   66                 // on the chest
        case .lanyard: 58                 // hanging on the chest
        }
    }
}

#Preview {
    AvatarView(avatar: PlayerAvatar())
        .scaleEffect(1.4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.93, green: 0.94, blue: 0.97))
}
