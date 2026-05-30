//
//  WardrobeView.swift
//  Quote Crossing
//
//  The slide-up wardrobe (GDD §2). Shows the player's live avatar + total RPG
//  stats, plus the owned wearables grouped by slot. Tapping an item equips /
//  unequips it, instantly updating the preview, the stats, and (via the
//  session) the SpriteKit player node underneath.
//

import SwiftUI

struct WardrobeView: View {
    @ObservedObject var inventory: InventoryManager
    @ObservedObject var avatar: PlayerAvatar
    var stats: GameState
    var onEquip: (WearableItem) -> Void
    var onClose: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 158), spacing: 10)]

    var body: some View {
        VStack(spacing: 0) {
            grabber
            header
            previewRow
            Divider().padding(.horizontal, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(EquipSlot.allCases) { slot in
                        slotSection(slot)
                    }
                }
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(red: 0.96, green: 0.97, blue: 0.99))
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 16, y: -4)
    }

    // MARK: Chrome

    private var grabber: some View {
        Capsule()
            .fill(.secondary.opacity(0.35))
            .frame(width: 40, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("WARDROBE")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(Color(red: 0.30, green: 0.40, blue: 0.62))
                Text("Accessorize to the nines")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(Color(white: 0.92), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private var previewRow: some View {
        HStack(spacing: 14) {
            AvatarView(avatar: avatar, wearables: inventory.equippedItems)
                .scaleEffect(0.66)
                .frame(width: 138, height: 160)
                .background(
                    LinearGradient(colors: [Color(red: 0.93, green: 0.95, blue: 0.99),
                                            Color(red: 0.85, green: 0.89, blue: 0.97)],
                                   startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.black.opacity(0.06), lineWidth: 1))

            StatsPanel(stats: stats, inventory: inventory)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    // MARK: Sections

    private func slotSection(_ slot: EquipSlot) -> some View {
        let items = inventory.items(in: slot)
        return VStack(alignment: .leading, spacing: 10) {
            Label(slot.label, systemImage: slot.symbol)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.secondary)

            if items.isEmpty {
                Text("None owned yet — earn these from SPIFF gacha & boss drops.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(items) { item in
                        WardrobeItemCell(item: item, equipped: inventory.isEquipped(item)) {
                            onEquip(item)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Stats panel

private struct StatsPanel: View {
    var stats: GameState
    /// Observed so the panel re-renders when equipment changes the boosted
    /// totals — GameState's computed stats read the inventory across the
    /// @Observable→ObservableObject boundary, which Observation can't see alone.
    @ObservedObject var inventory: InventoryManager

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            row(.maxPatience, total: stats.maxPatience, base: stats.baseMaxPatience)
            row(.maxBandwidth, total: stats.maxBandwidth, base: stats.baseMaxBandwidth)
            row(.jargon, total: stats.jargon, base: stats.baseJargon)
            row(.rep, total: stats.rep, base: stats.baseRep)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(.black.opacity(0.05), lineWidth: 1))
    }

    private func row(_ type: StatBoostType, total: Int, base: Int) -> some View {
        let delta = total - base
        return HStack(spacing: 8) {
            Image(systemName: type.symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(type.tint)
                .frame(width: 18)
            Text(type.label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            Text("\(total)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .contentTransition(.numericText())
            if delta != 0 {
                Text("+\(delta)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.16, green: 0.62, blue: 0.36))
            }
        }
    }
}

// MARK: - Item cell

private struct WardrobeItemCell: View {
    let item: WearableItem
    let equipped: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(item.tint.color.opacity(0.16))
                        .frame(width: 44, height: 44)
                    Image(systemName: item.imageIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(item.tint.color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(item.boostText)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(item.hasBoost ? (item.statBoostType?.tint ?? .secondary) : .secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: equipped ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(equipped ? Color(red: 0.16, green: 0.62, blue: 0.36) : .secondary.opacity(0.4))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(equipped ? Color(red: 0.16, green: 0.62, blue: 0.36).opacity(0.10) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(equipped ? Color(red: 0.16, green: 0.62, blue: 0.36).opacity(0.55) : .black.opacity(0.06),
                            lineWidth: equipped ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
