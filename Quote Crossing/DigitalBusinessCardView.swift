//
//  DigitalBusinessCardView.swift
//  Quote Crossing
//
//  The QBR "Digital Business Card" (GDD §3): a high-end trading card showing
//  the player's live avatar, name, title, lifetime earnings, and W/L record.
//  The background finish (matte → glossy → holographic → diamond) and its
//  animated foil sheen are driven by the player's wealth tier.
//
//  `foilPhase` (0...1) drives the animation. On screen it's animated via a
//  TimelineView; when captured with ImageRenderer a fixed phase is passed so
//  the exported image is deterministic.
//

import SwiftUI

struct DigitalBusinessCardView: View {
    @ObservedObject var avatar: PlayerAvatar
    var wearables: [WearableItem]
    var stats: QBRStats
    var foilPhase: Double = 0.25

    var body: some View {
        VStack(spacing: 0) {
            header
            avatarWindow
            identity
            metadataRow
            statsRow
            footer
        }
        .padding(16)
        .background(CardFoilBackground(tier: stats.tier, phase: foilPhase))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(colors: [stats.tier.accent.opacity(0.9), .white.opacity(0.3), stats.tier.accent.opacity(0.7)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            HStack(spacing: 5) {
                Image(systemName: "building.2.crop.circle.fill")
                Text("OmniTech")
                    .font(.system(size: 13, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.95))
            Spacer()
            Text(stats.tier.displayName.uppercased())
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.black.opacity(0.8))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(stats.tier.accent, in: Capsule())
        }
    }

    // MARK: Avatar portrait

    private var avatarWindow: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(colors: [.white.opacity(0.22), .white.opacity(0.05)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.25), lineWidth: 1))
            AvatarView(avatar: avatar, wearables: wearables)
                .scaleEffect(0.78)
        }
        .frame(height: 196)
        .padding(.vertical, 12)
    }

    // MARK: Identity

    private var identity: some View {
        VStack(spacing: 3) {
            Text(stats.name.isEmpty ? "New Hire" : stats.name)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(stats.title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(stats.tier.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var metadataRow: some View {
        HStack(spacing: 8) {
            metadataPill(icon: "calendar", value: stats.fiscalLabel)
            metadataPill(icon: "leaf.fill", value: "Desk Plant: \(stats.deskPlantStatus)")
        }
        .padding(.top, 10)
    }

    private func metadataPill(icon: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(value)
                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .foregroundStyle(.white.opacity(0.9))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(.white.opacity(0.10), in: Capsule())
    }

    // MARK: Stats

    private var statsRow: some View {
        HStack(spacing: 10) {
            statBlock(icon: "dollarsign.circle.fill",
                      label: "LIFETIME",
                      value: "$" + stats.lifetimeCash.formatted(.number.grouping(.automatic)),
                      tint: Color(red: 0.30, green: 0.85, blue: 0.55))
            statBlock(icon: "trophy.fill",
                      label: "W / L",
                      value: stats.record,
                      tint: Color(red: 0.98, green: 0.78, blue: 0.30))
            statBlock(icon: "chart.line.uptrend.xyaxis",
                      label: "WIN RATE",
                      value: stats.winRateText,
                      tint: Color(red: 0.45, green: 0.78, blue: 0.98))
        }
        .padding(.top, 12)
    }

    private func statBlock(icon: String, label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "seal.fill")
                .font(.system(size: 10))
                .foregroundStyle(stats.tier.accent)
            Text("QUARTERLY BRAG REPORT")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(.white.opacity(0.75))
            Spacer()
            Text("OTS")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            Text(stats.friendString)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.top, 12)
    }
}

// MARK: - Foil background

struct CardFoilBackground: View {
    let tier: CardTier
    var phase: Double

    var body: some View {
        GeometryReader { geo in
            ZStack {
                baseGradient

                // Holographic rainbow wash for foil tiers.
                if tier.isFoil {
                    LinearGradient(
                        colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .hueRotation(.degrees(phase * 360))
                    .blendMode(.plusLighter)
                    .opacity(tier == .diamond ? 0.5 : 0.32)
                }

                // Moving diagonal sheen.
                sheen(width: geo.size.width)

                // Diamond sparkles.
                if tier == .diamond {
                    sparkles(in: geo.size)
                }
            }
        }
    }

    private var baseGradient: some View {
        let pair: [Color]
        switch tier {
        case .matte:
            pair = [Color(red: 0.24, green: 0.26, blue: 0.32), Color(red: 0.16, green: 0.18, blue: 0.24)]
        case .glossy:
            pair = [Color(red: 0.17, green: 0.32, blue: 0.55), Color(red: 0.10, green: 0.17, blue: 0.33)]
        case .holographic:
            pair = [Color(red: 0.12, green: 0.10, blue: 0.22), Color(red: 0.20, green: 0.11, blue: 0.26)]
        case .diamond:
            pair = [Color(red: 0.07, green: 0.09, blue: 0.16), Color(red: 0.13, green: 0.10, blue: 0.22)]
        }
        return LinearGradient(colors: pair, startPoint: .top, endPoint: .bottom)
    }

    private func sheen(width: CGFloat) -> some View {
        let travel = (CGFloat(phase) * 2 - 1) * width * 1.4
        return LinearGradient(
            colors: [.clear, .white.opacity(tier == .matte ? 0.10 : 0.30), .clear],
            startPoint: .leading, endPoint: .trailing
        )
        .frame(width: width * 0.45)
        .blur(radius: 4)
        .rotationEffect(.degrees(-22))
        .offset(x: travel)
        .blendMode(.plusLighter)
    }

    private func sparkles(in size: CGSize) -> some View {
        let spots: [CGPoint] = [
            CGPoint(x: 0.18, y: 0.16), CGPoint(x: 0.82, y: 0.24),
            CGPoint(x: 0.30, y: 0.74), CGPoint(x: 0.72, y: 0.66),
        ]
        return ZStack {
            ForEach(Array(spots.enumerated()), id: \.offset) { i, p in
                Image(systemName: "sparkle")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .opacity(0.4 + 0.5 * abs(sin(phase * .pi * 2 + Double(i))))
                    .position(x: p.x * size.width, y: p.y * size.height)
            }
        }
    }
}
