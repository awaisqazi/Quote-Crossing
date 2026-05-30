//
//  DigitalBusinessCardView.swift
//  Quote Crossing
//
//  The QBR "Digital Business Card" (GDD section 3): a high-end trading card
//  showing the player's live avatar, name, title, lifetime earnings, and W/L
//  record. The background finish (matte -> glossy -> holographic -> diamond)
//  and its animated foil sheen are driven by the player's wealth tier.
//
//  `foilPhase` (0...1) drives the animation. On screen it is animated via a
//  TimelineView; when captured with ImageRenderer a fixed phase is passed so
//  the exported image is deterministic.
//

import SwiftUI

struct DigitalBusinessCardView: View {
    @ObservedObject var avatar: PlayerAvatar
    var wearables: [WearableItem]
    var stats: QBRStats
    var foilPhase: Double = 0.25

    private var playerName: String { stats.name.isEmpty ? "New Hire" : stats.name }
    private var accent: Color { stats.tier.accent }

    private var sharePayload: QBRSharePayload {
        QBRSharePayload(name: stats.name,
                        title: stats.title,
                        lifetimeCash: stats.lifetimeCash,
                        wins: stats.wins,
                        losses: stats.losses,
                        badgeTier: stats.tier,
                        outfitIDs: wearables.map(\.id))
    }

    var body: some View {
        VStack(spacing: 12) {
            brandRibbon
            portraitStage
            identityBlock
            metricRow
            footer
        }
        .padding(18)
        .background(CardFoilBackground(tier: stats.tier, phase: foilPhase))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(cardBorder)
        .overlay(cardGloss)
        .shadow(color: QuotaOS.Colors.logoInk.opacity(0.24), radius: 20, y: 12)
    }

    private var brandRibbon: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.82))
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(QuotaOS.Colors.blue)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text("QUOTA CROSSING")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk)
                    .lineLimit(1)
                Text("Executive Status Card")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.50))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(stats.tier.displayName.uppercased())
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(QuotaOS.Colors.logoInk)
                .lineLimit(1)
                .minimumScaleFactor(0.58)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(
                    LinearGradient(colors: [.white.opacity(0.94), accent.opacity(0.28)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    in: Capsule()
                )
                .overlay(Capsule().stroke(accent.opacity(0.34), lineWidth: 1))
        }
    }

    private var portraitStage: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(colors: [
                        Color.white.opacity(0.74),
                        QuotaOS.Colors.campusBlue.opacity(0.28),
                        QuotaOS.Colors.campusPink.opacity(0.20)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.86), lineWidth: 1)
                )

            CardCampusIllustration()
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .opacity(0.92)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                AvatarView(avatar: avatar, wearables: wearables)
                    .scaleEffect(0.60)
                    .shadow(color: QuotaOS.Colors.logoInk.opacity(0.14), radius: 12, y: 7)
                    .frame(width: 180, height: 202)
                    .offset(y: 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                statusBubble(icon: "calendar", value: stats.fiscalLabel, tint: QuotaOS.Colors.blue)
                Spacer()
                statusBubble(icon: "leaf.fill", value: stats.deskPlantStatus, tint: QuotaOS.Colors.green)
            }
            .padding(10)
        }
        .frame(height: 224)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func statusBubble(icon: String, value: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .black))
            Text(value)
                .font(.system(size: 8.5, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .foregroundStyle(QuotaOS.Colors.logoInk)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.82), in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.22), lineWidth: 1))
    }

    private var identityBlock: some View {
        VStack(spacing: 4) {
            Text(playerName)
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundStyle(QuotaOS.Colors.logoInk)
                .lineLimit(1)
                .minimumScaleFactor(0.56)

            Text(stats.title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.62)

            QuotaProgressBar(fraction: min(1, Double(stats.lifetimeCash) / 20_000), tint: accent, tone: .campus)
                .padding(.horizontal, 24)
                .padding(.top, 5)
        }
    }

    private var metricRow: some View {
        HStack(spacing: 8) {
            statBlock(icon: "dollarsign.circle.fill",
                      label: "Lifetime",
                      value: "$" + stats.lifetimeCash.formatted(.number.grouping(.automatic)),
                      tint: QuotaOS.Colors.green)
            statBlock(icon: "trophy.fill",
                      label: "Record",
                      value: stats.record,
                      tint: QuotaOS.Colors.gold)
            statBlock(icon: "chart.line.uptrend.xyaxis",
                      label: "Win Rate",
                      value: stats.winRateText,
                      tint: QuotaOS.Colors.blue)
        }
    }

    private func statBlock(icon: String, label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(QuotaOS.Colors.logoInk)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Text(label.uppercased())
                .font(.system(size: 7.5, weight: .black, design: .rounded))
                .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.46))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(tint.opacity(0.18), lineWidth: 1))
    }

    private var footer: some View {
        HStack(spacing: 10) {
            QRCodeView(text: sharePayload.encodedString)
                .frame(width: 42, height: 42)
                .padding(5)
                .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(QuotaOS.Colors.logoInk.opacity(0.12), lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                Text("LOCAL SHARE PAYLOAD")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.48))
                Text(stats.friendString)
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundStyle(QuotaOS.Colors.logoInk)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: stats.tier == .diamond ? "diamond.fill" : "seal.fill")
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(accent)
                .shadow(color: accent.opacity(0.30), radius: 8, y: 4)
        }
        .padding(.top, 1)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .stroke(
                LinearGradient(colors: [
                    .white.opacity(0.92),
                    accent.opacity(0.75),
                    QuotaOS.Colors.campusPink.opacity(0.56),
                    .white.opacity(0.78)
                ], startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 3
            )
    }

    private var cardGloss: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(
                LinearGradient(colors: [
                    .white.opacity(0.18),
                    .clear,
                    .white.opacity(0.04)
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
    }
}

private struct CardCampusIllustration: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RibbonLine(color: QuotaOS.Colors.campusPink.opacity(0.38), y: 0.22, amplitude: 16)
                RibbonLine(color: QuotaOS.Colors.campusBlue.opacity(0.32), y: 0.53, amplitude: -12)
                building(width: proxy.size.width * 0.42,
                         height: proxy.size.height * 0.58,
                         color: QuotaOS.Colors.campusPink,
                         rows: 3,
                         columns: 2)
                    .offset(x: -proxy.size.width * 0.22, y: 6)
                building(width: proxy.size.width * 0.58,
                         height: proxy.size.height * 0.66,
                         color: QuotaOS.Colors.campusBlue,
                         rows: 4,
                         columns: 3)
                    .offset(x: proxy.size.width * 0.14, y: -10)
                building(width: proxy.size.width * 0.34,
                         height: proxy.size.height * 0.46,
                         color: QuotaOS.Colors.campusMint,
                         rows: 2,
                         columns: 2)
                    .offset(x: proxy.size.width * 0.34, y: 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func building(width: CGFloat, height: CGFloat, color: Color, rows: Int, columns: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color.opacity(0.30))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(QuotaOS.Colors.logoInk.opacity(0.16), lineWidth: 2))

            VStack(spacing: 5) {
                ForEach(0..<rows, id: \.self) { _ in
                    HStack(spacing: 5) {
                        ForEach(0..<columns, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(index.isMultiple(of: 2) ? Color.white.opacity(0.54) : QuotaOS.Colors.campusMint.opacity(0.38))
                                .overlay(
                                    LinearGradient(colors: [.white.opacity(0.45), .clear],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing)
                                )
                        }
                    }
                }
            }
            .padding(12)
        }
        .frame(width: width, height: height)
    }
}

private struct RibbonLine: View {
    let color: Color
    let y: CGFloat
    let amplitude: CGFloat

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                let baseY = proxy.size.height * y
                path.move(to: CGPoint(x: -20, y: baseY))
                path.addCurve(
                    to: CGPoint(x: proxy.size.width + 20, y: baseY + amplitude),
                    control1: CGPoint(x: proxy.size.width * 0.25, y: baseY - amplitude * 2.1),
                    control2: CGPoint(x: proxy.size.width * 0.72, y: baseY + amplitude * 2.0)
                )
            }
            .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
        }
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
                logoGrid

                if tier.isFoil {
                    LinearGradient(
                        colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .hueRotation(.degrees(phase * 360))
                    .blendMode(.plusLighter)
                    .opacity(tier == .diamond ? 0.28 : 0.20)
                }

                sheen(width: geo.size.width)

                if tier == .diamond {
                    sparkles(in: geo.size)
                }
            }
        }
    }

    private var baseGradient: some View {
        let colors: [Color]
        switch tier {
        case .matte:
            colors = [
                QuotaOS.Colors.campusPaper,
                QuotaOS.Colors.porcelain,
                QuotaOS.Colors.campusLavender.opacity(0.42)
            ]
        case .glossy:
            colors = [
                Color.white,
                QuotaOS.Colors.campusBlue.opacity(0.68),
                QuotaOS.Colors.campusMint.opacity(0.46)
            ]
        case .holographic:
            colors = [
                Color.white,
                QuotaOS.Colors.campusPink.opacity(0.58),
                QuotaOS.Colors.campusLavender.opacity(0.56),
                QuotaOS.Colors.campusMint.opacity(0.40)
            ]
        case .diamond:
            colors = [
                Color.white,
                Color(red: 0.86, green: 0.97, blue: 1.00),
                QuotaOS.Colors.campusLavender.opacity(0.48),
                Color(red: 1.00, green: 0.94, blue: 0.99)
            ]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var logoGrid: some View {
        Canvas { context, size in
            let step: CGFloat = 34
            for y in stride(from: 24, through: size.height, by: step) {
                var path = Path()
                path.move(to: CGPoint(x: -20, y: y))
                path.addLine(to: CGPoint(x: size.width + 40, y: y + size.width * 0.08))
                context.stroke(path, with: .color(QuotaOS.Colors.logoInk.opacity(0.018)), lineWidth: 1)
            }
            for x in stride(from: -size.width, through: size.width * 1.6, by: step) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + size.height * 0.18, y: size.height))
                context.stroke(path, with: .color(.white.opacity(0.20)), lineWidth: 1)
            }
        }
    }

    private func sheen(width: CGFloat) -> some View {
        let travel = (CGFloat(phase) * 2 - 1) * width * 1.35
        return LinearGradient(
            colors: [.clear, .white.opacity(tier == .matte ? 0.26 : 0.48), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: width * 0.44)
        .blur(radius: 5)
        .rotationEffect(.degrees(-22))
        .offset(x: travel)
        .blendMode(.plusLighter)
    }

    private func sparkles(in size: CGSize) -> some View {
        let spots: [CGPoint] = [
            CGPoint(x: 0.18, y: 0.15), CGPoint(x: 0.80, y: 0.20),
            CGPoint(x: 0.25, y: 0.72), CGPoint(x: 0.76, y: 0.66),
            CGPoint(x: 0.53, y: 0.09)
        ]
        return ZStack {
            ForEach(Array(spots.enumerated()), id: \.offset) { i, p in
                Image(systemName: "sparkle")
                    .font(.system(size: i == 4 ? 15 : 12, weight: .black))
                    .foregroundStyle(.white)
                    .opacity(0.44 + 0.42 * abs(sin(phase * .pi * 2 + Double(i))))
                    .position(x: p.x * size.width, y: p.y * size.height)
            }
        }
    }
}
