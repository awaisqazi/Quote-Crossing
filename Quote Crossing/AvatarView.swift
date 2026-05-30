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
    private let headDiameter: CGFloat = 96
    private let headCenterY: CGFloat = -30

    private var renderedWearables: [WearableItem] {
        if let wearables { return wearables }
        // Fallback (creator preview): map starter accessories → catalog items,
        // keeping at most one per slot so two same-slot picks can't stack.
        var bySlot: [EquipSlot: WearableItem] = [:]
        for accessory in avatar.equippedAccessories {
            let item = WearableCatalog.item(for: accessory)
            bySlot[item.slot] = item
        }
        return EquipSlot.allCases.compactMap { bySlot[$0] }
    }

    var body: some View {
        ZStack {
            torso
            neck
            head
            HairView(style: avatar.hairStyle, color: AvatarAppearance.hairColor.color)
                .offset(y: headCenterY)
            FaceView(eyeBags: avatar.eyeBagsLevel)
                .offset(y: headCenterY)
            wearableLayer
        }
        .frame(width: 200, height: 240)
    }

    // MARK: Body parts

    private var torso: some View {
        OutfitView(outfit: avatar.starterOutfit, skin: avatar.skinTone)
            .offset(y: 76)
    }

    private var neck: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(avatar.skinTone)
            .frame(width: 36, height: 34)
            .offset(y: headCenterY + 40)
    }

    private var head: some View {
        Circle()
            .fill(avatar.skinTone)
            .overlay(Circle().stroke(.black.opacity(0.08), lineWidth: 2))
            .frame(width: headDiameter, height: headDiameter)
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
    var eyeBags: CGFloat

    var body: some View {
        ZStack {
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

            // Neutral mouth.
            Capsule()
                .fill(Color(red: 0.55, green: 0.34, blue: 0.34))
                .frame(width: 24, height: 5)
                .offset(y: 24)
        }
    }

    private var eye: some View {
        Circle()
            .fill(Color(red: 0.16, green: 0.17, blue: 0.22))
            .frame(width: 11, height: 11)
    }

    private var bag: some View {
        Ellipse()
            .fill(Color(red: 0.46, green: 0.34, blue: 0.56).opacity(Double(eyeBags) * 0.85))
            .frame(width: 22, height: 11)
    }
}

// MARK: - Hair

private struct HairView: View {
    let style: HairStyle
    let color: Color

    private let headD: CGFloat = 96
    private let hairline: CGFloat = -14   // bottom of hair, relative to head centre

    var body: some View {
        ZStack {
            switch style {
            case .bald:
                EmptyView()
            case .buzz:
                cap(diameter: headD)
            case .sideSwept:
                cap(diameter: headD + 6)
                Capsule()
                    .fill(color)
                    .frame(width: 74, height: 24)
                    .rotationEffect(.degrees(-16))
                    .offset(x: 8, y: -26)
            case .topKnot:
                cap(diameter: headD)
                Circle().fill(color).frame(width: 30, height: 30).offset(y: -62)
            case .curly:
                ForEach(Array(curlOffsets.enumerated()), id: \.offset) { _, p in
                    Circle().fill(color).frame(width: 36, height: 36).offset(p)
                }
            }
        }
    }

    /// Hair circle masked to a band from the crown down to the hairline.
    private func cap(diameter: CGFloat) -> some View {
        let top = -diameter / 2
        let height = hairline - top
        return Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
            .mask(
                Rectangle()
                    .frame(width: diameter + 24, height: max(0, height))
                    .offset(y: top + height / 2)
            )
    }

    private var curlOffsets: [CGSize] {
        [
            .init(width: -34, height: -28), .init(width: -18, height: -44),
            .init(width: 0, height: -50),   .init(width: 18, height: -44),
            .init(width: 34, height: -28),  .init(width: -30, height: -12),
            .init(width: 30, height: -12),
        ]
    }
}

// MARK: - Outfit (torso + collar)

private struct OutfitView: View {
    let outfit: StarterOutfit
    let skin: Color

    var body: some View {
        ZStack {
            // Shoulders / torso.
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(outfit.torso.color)
                .overlay(
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .stroke(.black.opacity(0.08), lineWidth: 2)
                )
                .frame(width: 154, height: 120)

            collar
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
        }
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
