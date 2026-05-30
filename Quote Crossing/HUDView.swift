//
//  HUDView.swift
//  Quote Crossing
//
//  SwiftUI heads-up display overlaid on the SpriteKit scene. Shows Bandwidth
//  (stamina) and Commish-Cash (wealth). Bound to the observable GameState, so
//  it refreshes automatically as those values change.
//

import SwiftUI

struct HUDView: View {
    var state: GameState
    /// Observed so the HUD refreshes when equipment changes the boosted max.
    @ObservedObject var inventory: InventoryManager

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                fiscalLine
                bandwidthLine
            }
            Divider()
                .frame(height: 36)
                .overlay(.white.opacity(0.18))
            cashLine
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 12, y: 7)
    }

    // MARK: Bandwidth

    private var bandwidthFraction: Double {
        guard state.maxBandwidth > 0 else { return 0 }
        return Double(state.bandwidth) / Double(state.maxBandwidth)
    }

    private var bandwidthLine: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 18)
            StatBar(fraction: bandwidthFraction)
                .frame(width: 92, height: 5)
            Text("\(state.bandwidth)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .monospacedDigit()
        }
    }

    // MARK: Commish-Cash

    private var cashLine: some View {
        HStack(spacing: 7) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(QuotaOS.Colors.green)
            Text(state.commishCash.formatted(.number.grouping(.automatic)))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
    }

    // MARK: Fiscal clock

    private var fiscalLine: some View {
        let moment = state.fiscalMoment
        return HStack(spacing: 8) {
            Image(systemName: moment.isEOQBlizzard ? "snowflake" : "calendar")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(moment.isEOQBlizzard ? QuotaOS.Colors.red : QuotaOS.Colors.gold)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(moment.hudLabel)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(moment.isEOQBlizzard ? "\(moment.quarter.title) - 1.5x Commish" : "\(moment.clockText) - \(moment.quarter.title)")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            if moment.isEOQBlizzard {
                Text("Q4")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.40, green: 0.08, blue: 0.12))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.92), in: Capsule())
            }
        }
    }
}

/// A simple rounded fill bar (0...1).
private struct StatBar: View {
    var fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.16))
                Capsule()
                    .fill(
                        LinearGradient(colors: [QuotaOS.Colors.mint, QuotaOS.Colors.blue],
                                       startPoint: .leading,
                                       endPoint: .trailing)
                    )
                    .frame(width: max(0, min(1, fraction)) * geo.size.width)
            }
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.91, green: 0.92, blue: 0.95)
        VStack {
            HUDView(state: GameState(), inventory: InventoryManager())
                .padding()
            Spacer()
        }
    }
    .ignoresSafeArea()
}
