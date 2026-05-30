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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                bandwidthPill
                commishPill
            }
            fiscalPill
        }
    }

    // MARK: Bandwidth

    private var bandwidthFraction: Double {
        guard state.maxBandwidth > 0 else { return 0 }
        return Double(state.bandwidth) / Double(state.maxBandwidth)
    }

    private var bandwidthPill: some View {
        HStack(spacing: 9) {
            Image(systemName: "wifi")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 4) {
                Text("BANDWIDTH")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(.white.opacity(0.9))
                StatBar(fraction: bandwidthFraction)
                    .frame(width: 96, height: 7)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(pillBackground(
            top: Color(red: 0.30, green: 0.55, blue: 0.95),
            bottom: Color(red: 0.21, green: 0.42, blue: 0.86)
        ))
    }

    // MARK: Commish-Cash

    private var commishPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
            Text(state.commishCash.formatted(.number.grouping(.automatic)))
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(pillBackground(
            top: Color(red: 0.22, green: 0.80, blue: 0.56),
            bottom: Color(red: 0.13, green: 0.66, blue: 0.45)
        ))
    }

    // MARK: Fiscal clock

    private var fiscalPill: some View {
        let moment = state.fiscalMoment
        return HStack(spacing: 8) {
            Image(systemName: moment.isEOQBlizzard ? "snowflake" : "calendar")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(moment.hudLabel)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(moment.isEOQBlizzard ? "\(moment.quarter.title) - 1.5x Commish" : "\(moment.clockText) - \(moment.quarter.title)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(pillBackground(
            top: moment.isEOQBlizzard ? Color(red: 0.86, green: 0.28, blue: 0.36) : Color(red: 0.55, green: 0.42, blue: 0.92),
            bottom: moment.isEOQBlizzard ? Color(red: 0.58, green: 0.16, blue: 0.28) : Color(red: 0.40, green: 0.30, blue: 0.78)
        ))
    }

    // MARK: Shared styling

    private func pillBackground(top: Color, bottom: Color) -> some View {
        Capsule()
            .fill(LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom))
            .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
            .shadow(color: .black.opacity(0.18), radius: 5, y: 3)
    }
}

/// A simple rounded fill bar (0...1).
private struct StatBar: View {
    var fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.black.opacity(0.22))
                Capsule()
                    .fill(.white)
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
