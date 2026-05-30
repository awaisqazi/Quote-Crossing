//
//  SwagVendingView.swift
//  Quote Crossing
//
//  SwiftUI presentation for the Swag Vending Machine gacha.
//

import SwiftUI
import UIKit

struct SwagVendingView: View {
    var gameState: GameState
    @ObservedObject var inventory: InventoryManager
    var onClose: () -> Void

    @State private var isPulling = false
    @State private var latestResult: GachaEngine.PullResult?
    @State private var machineScale = 1.0
    @State private var leverAngle = 0.0
    @State private var capsuleDrop = false
    @State private var goldFlash = false
    @State private var statusLine = "READY"

    private var pityState: GachaEngine.PityState {
        GachaEngine.PityState(
            pullsSinceFiveStar: gameState.gachaPullsSinceFiveStar,
            featuredGuaranteed: gameState.gachaFeaturedGuaranteed
        )
    }

    private var effectiveDropTable: [GachaEngine.DropRate] {
        GachaEngine.effectiveDropTable(for: pityState)
    }

    private var canPull: Bool {
        !isPulling && gameState.spiffCoins >= GachaEngine.singlePullCost
    }

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    header
                    walletRow

                    machine
                        .scaleEffect(machineScale)
                        .overlay(machineGoldFlash)

                    resultPanel
                    dropRateRow
                    vendButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .ignoresSafeArea()
    }

    private var background: some View {
        QuotaBackdrop(tint: QuotaOS.Colors.gold, tone: .campus)
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Swag Vending")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk)
                Text("Pity \(gameState.gachaPullsSinceFiveStar)/\(GachaEngine.hardPityPull) · SPIFF-only capsules")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.58))
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(QuotaOS.Colors.gold)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.82), in: Circle())
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(QuotaOS.Colors.logoInk.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 36)
    }

    private var walletRow: some View {
        HStack(spacing: 8) {
            CurrencyChip(symbol: "s.circle.fill",
                         label: "SPIFF",
                         value: gameState.spiffCoins,
                         tint: Color(red: 0.95, green: 0.72, blue: 0.18))
            CurrencyChip(symbol: "wrench.and.screwdriver.fill",
                         label: "SCRAP",
                         value: gameState.scrapBasePay,
                         tint: Color(red: 0.58, green: 0.64, blue: 0.68))
            CurrencyChip(symbol: "dollarsign.circle.fill",
                         label: "COMMISH",
                         value: gameState.commishCash,
                         tint: Color(red: 0.22, green: 0.78, blue: 0.50))
        }
    }

    private var machine: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 10) {
                    machineDisplay
                    capsuleWindow
                    pityMeter
                }
                lever
            }
            statusStrip
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.00, green: 0.97, blue: 0.99),
                            Color(red: 0.99, green: 0.82, blue: 0.91),
                            Color(red: 1.00, green: 0.91, blue: 0.58),
                            Color(red: 0.82, green: 0.93, blue: 1.00)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(QuotaOS.Colors.logoInk.opacity(0.12), lineWidth: 2))
        .shadow(color: QuotaOS.Colors.logoInk.opacity(0.12), radius: 18, y: 10)
    }

    private var machineDisplay: some View {
        HStack(spacing: 10) {
            Image(systemName: GachaEngine.featuredBannerItem.wearable.imageIcon)
                .font(.system(size: 23, weight: .black))
                .foregroundStyle(Color(red: 0.98, green: 0.76, blue: 0.20))
                .frame(width: 44, height: 44)
                .background(QuotaOS.Colors.gold.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(GachaEngine.featuredBannerItem.name)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(gameState.gachaFeaturedGuaranteed ? "FEATURED LOCKED" : "50/50 LIVE")
                    .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(gameState.gachaFeaturedGuaranteed ? Color(red: 0.86, green: 0.54, blue: 0.10) : QuotaOS.Colors.logoInk.opacity(0.58))
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(QuotaOS.Colors.gold.opacity(0.22), lineWidth: 1))
    }

    private var capsuleWindow: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            QuotaOS.Colors.campusBlue.opacity(0.52),
                            QuotaOS.Colors.campusMint.opacity(0.58),
                            Color.white.opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(QuotaOS.Colors.logoInk.opacity(0.12), lineWidth: 2))

            Circle()
                .fill(
                    RadialGradient(
                        colors: capsuleColors,
                        center: .topLeading,
                        startRadius: 3,
                        endRadius: 62
                    )
                )
                .frame(width: 86, height: 86)
                .overlay(Circle().stroke(.white.opacity(0.72), lineWidth: 3))
                .shadow(color: capsuleGlow, radius: latestResult?.isFiveStar == true ? 18 : 8)
                .offset(y: capsuleDrop ? 12 : -10)
                .rotationEffect(.degrees(capsuleDrop ? 16 : -8))
                .animation(.spring(response: 0.28, dampingFraction: 0.42), value: capsuleDrop)

            Image(systemName: latestResult?.item.wearable.imageIcon ?? "gift.fill")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.86))
                .scaleEffect(isPulling ? 0.65 : 1.0)
                .opacity(isPulling ? 0.35 : 1.0)
                .animation(.spring(response: 0.26, dampingFraction: 0.62), value: isPulling)
        }
        .frame(height: 150)
    }

    private var pityMeter: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("5-STAR \(rateText(effectiveDropTable.first { $0.rarity == .fiveStar }?.probability ?? 0))")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.80))
                Spacer()
                Text(gameState.gachaPullsSinceFiveStar + 1 >= GachaEngine.softPityStart ? "SOFT PITY" : "BASE RATE")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.86, green: 0.54, blue: 0.10))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(QuotaOS.Colors.logoInk.opacity(0.10))
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(red: 0.95, green: 0.72, blue: 0.18), Color(red: 0.18, green: 0.80, blue: 0.60)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: max(0, min(1, Double(gameState.gachaPullsSinceFiveStar) / Double(GachaEngine.hardPityPull))) * geo.size.width)
                }
            }
            .frame(height: 9)
        }
        .padding(10)
        .background(Color.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(QuotaOS.Colors.logoInk.opacity(0.08), lineWidth: 1))
    }

    private var lever: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(Color(red: 0.96, green: 0.76, blue: 0.20))
                .frame(width: 28, height: 28)
                .shadow(color: QuotaOS.Colors.logoInk.opacity(0.18), radius: 5, y: 3)
            Capsule()
                .fill(QuotaOS.Colors.logoInk.opacity(0.74))
                .frame(width: 10, height: 92)
            Circle()
                .fill(QuotaOS.Colors.logoInk.opacity(0.24))
                .frame(width: 34, height: 18)
        }
        .rotationEffect(.degrees(leverAngle), anchor: .bottom)
        .frame(width: 44, height: 150)
        .animation(.spring(response: 0.24, dampingFraction: 0.36), value: leverAngle)
    }

    private var statusStrip: some View {
        HStack {
            Text(statusLine)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(QuotaOS.Colors.logoInk)
                .monospaced()
            Spacer()
            Text("\(GachaEngine.singlePullCost) SPIFF")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.86, green: 0.54, blue: 0.10))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.72), in: Capsule())
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(QuotaOS.Colors.logoInk.opacity(0.08), lineWidth: 1))
    }

    private var resultPanel: some View {
        Group {
            if let latestResult {
                HStack(spacing: 12) {
                    Image(systemName: latestResult.item.wearable.imageIcon)
                        .font(.system(size: 25, weight: .black))
                        .foregroundStyle(rarityTint(latestResult.rarity))
                        .frame(width: 52, height: 52)
                        .background(rarityTint(latestResult.rarity).opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(latestResult.item.name)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(QuotaOS.Colors.logoInk)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text(resultSubtitle(latestResult))
                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.58))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    Spacer(minLength: 0)

                    Text(stars(latestResult.rarity))
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(rarityTint(latestResult.rarity))
                }
                .padding(12)
                .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(latestResult.isFiveStar ? Color(red: 0.98, green: 0.78, blue: 0.24) : QuotaOS.Colors.logoInk.opacity(0.08),
                            lineWidth: latestResult.isFiveStar ? 2 : 1))
                .transition(.scale(scale: 0.84).combined(with: .opacity))
            } else {
                HStack {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 22, weight: .black))
                    Text("NO CAPSULE LOADED")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                    Spacer()
                }
                .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.46))
                .padding(12)
                .background(Color.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(QuotaOS.Colors.logoInk.opacity(0.07), lineWidth: 1))
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.62), value: latestResult?.id)
    }

    private var dropRateRow: some View {
        HStack(spacing: 6) {
            ForEach(effectiveDropTable) { entry in
                VStack(spacing: 2) {
                    Text(stars(entry.rarity))
                        .font(.system(size: 11, weight: .black, design: .rounded))
                    Text(rateText(entry.probability))
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundStyle(entry.rarity == .fiveStar ? Color(red: 0.86, green: 0.54, blue: 0.10) : QuotaOS.Colors.logoInk.opacity(0.64))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(entry.rarity == .fiveStar ? QuotaOS.Colors.gold.opacity(0.26) : QuotaOS.Colors.logoInk.opacity(0.07), lineWidth: 1))
            }
        }
    }

    private var vendButton: some View {
        Button(action: vend) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .black))
                Text(isPulling ? "VENDING" : "VEND")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                Text("\(GachaEngine.singlePullCost)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(Color(red: 0.12, green: 0.09, blue: 0.02))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: canPull
                        ? [Color(red: 1.0, green: 0.86, blue: 0.28), Color(red: 0.95, green: 0.56, blue: 0.16)]
                        : [Color(red: 0.50, green: 0.50, blue: 0.50), Color(red: 0.32, green: 0.32, blue: 0.32)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: Capsule()
            )
            .overlay(Capsule().stroke(Color.white.opacity(canPull ? 0.70 : 0.24), lineWidth: 2))
            .shadow(color: QuotaOS.Colors.logoInk.opacity(canPull ? 0.14 : 0.04), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!canPull)
        .scaleEffect(isPulling ? 0.97 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.55), value: isPulling)
    }

    private var machineGoldFlash: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(Color(red: 1.0, green: 0.78, blue: 0.18), lineWidth: goldFlash ? 7 : 0)
            .shadow(color: Color(red: 1.0, green: 0.78, blue: 0.18).opacity(goldFlash ? 0.95 : 0), radius: 22)
            .opacity(goldFlash ? 1 : 0)
    }

    private var capsuleColors: [Color] {
        guard let rarity = latestResult?.rarity else {
            return [.white, Color(red: 0.25, green: 0.70, blue: 0.84)]
        }

        return [.white, rarityTint(rarity)]
    }

    private var capsuleGlow: Color {
        latestResult.map { rarityTint($0.rarity).opacity(0.72) } ?? Color.black.opacity(0.18)
    }

    private func vend() {
        guard canPull else {
            statusLine = gameState.spiffCoins < GachaEngine.singlePullCost ? "LOW SPIFF" : "BUSY"
            return
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        impact.impactOccurred(intensity: 0.65)

        isPulling = true
        latestResult = nil
        goldFlash = false
        statusLine = "PROCESSING"

        withAnimation(.spring(response: 0.18, dampingFraction: 0.42)) {
            machineScale = 1.045
            leverAngle = 24
            capsuleDrop.toggle()
        }

        gameState.spiffCoins -= GachaEngine.singlePullCost
        let result = GachaEngine.pull(
            pityState: pityState,
            ownedItemIDs: Set(inventory.ownedItems.map(\.id))
        )
        apply(result)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.50)) {
                latestResult = result
                machineScale = 1.0
                leverAngle = 0
                isPulling = false
                statusLine = result.rarity.label.uppercased()
            }

            if result.isFiveStar {
                triggerFiveStarFeedback()
            }
        }
    }

    private func apply(_ result: GachaEngine.PullResult) {
        gameState.gachaPullsSinceFiveStar = result.newPityState.pullsSinceFiveStar
        gameState.gachaFeaturedGuaranteed = result.newPityState.featuredGuaranteed

        if let refund = result.duplicateRefund {
            apply(refund)
        } else {
            inventory.grant(result.item.wearable)
        }

        StatsStore.save(gameState.statsSnapshot)
    }

    private func apply(_ refund: GachaRefund) {
        switch refund.currency {
        case .scrapBasePay:
            gameState.scrapBasePay += refund.amount
        case .commishCash:
            gameState.commishCash += refund.amount
        case .spiffCoins:
            gameState.spiffCoins += refund.amount
        }
    }

    private func triggerFiveStarFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.prepare()
        impact.impactOccurred(intensity: 1.0)

        withAnimation(.easeInOut(duration: 0.12).repeatCount(6, autoreverses: true)) {
            goldFlash = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            goldFlash = false
        }
    }

    private func resultSubtitle(_ result: GachaEngine.PullResult) -> String {
        if let refund = result.duplicateRefund {
            return "Duplicate refund: \(refund.displayText)"
        }
        if result.item.isFeaturedBannerItem {
            return result.wonFeaturedFlip == true ? "Featured banner won" : "Featured guarantee"
        }
        if result.isFiveStar && result.wonFeaturedFlip == false {
            return "50/50 lost. Next 5-Star is featured."
        }
        if result.triggeredHardPity {
            return "Hard pity payout"
        }
        return result.item.wearable.boostText
    }

    private func rarityTint(_ rarity: GachaRarity) -> Color {
        switch rarity {
        case .oneStar: Color(red: 0.72, green: 0.75, blue: 0.78)
        case .twoStar: Color(red: 0.32, green: 0.82, blue: 0.54)
        case .threeStar: Color(red: 0.32, green: 0.66, blue: 0.96)
        case .fourStar: Color(red: 0.78, green: 0.48, blue: 0.94)
        case .fiveStar: Color(red: 1.0, green: 0.76, blue: 0.18)
        }
    }

    private func stars(_ rarity: GachaRarity) -> String {
        String(repeating: "*", count: rarity.rawValue)
    }

    private func rateText(_ probability: Double) -> String {
        String(format: "%.1f%%", probability * 100)
    }
}

private struct CurrencyChip: View {
    let symbol: String
    let label: String
    let value: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.52))
                Text(value.formatted(.number.grouping(.automatic)))
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(QuotaOS.Colors.logoInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(tint.opacity(0.24), lineWidth: 1))
    }
}

#Preview {
    SwagVendingView(
        gameState: GameState(),
        inventory: InventoryManager(),
        onClose: {}
    )
}
