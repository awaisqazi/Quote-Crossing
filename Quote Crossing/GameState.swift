//
//  GameState.swift
//  Quote Crossing
//
//  The player's stats model (GDD §4). Holds base RPG stats and depletable
//  currencies; the *total* stats are computed dynamically by adding the boosts
//  from whatever wearables are currently equipped (via the InventoryManager).
//

import Foundation
import Observation

@Observable
final class GameState {
    // Depletable / spent values.
    var bandwidth: Int = 80          // current stamina
    var commishCash: Int = 1_250     // current wealth currency

    // Career / lifetime stats (persisted; shown on the QBR card).
    var lifetimeCommishCash: Int = 1_250
    var wins: Int = 0
    var losses: Int = 0

    // Fiscal calendar anchor. Persisting the start date lets real time keep
    // moving the in-game clock between launches without saving every minute.
    var fiscalYearStartedAt: Date = Date()
    var fiscalNow: Date = Date()

    // Base RPG stats, before equipment bonuses.
    var baseMaxBandwidth: Int = 100
    var baseMaxPatience: Int = 50
    var baseJargon: Int = 20
    var baseRep: Int = 1

    /// Source of equipped stat boosts. Weak: the GameSession owns both, and the
    /// inventory never points back here, so this avoids any retain cycle.
    weak var inventory: InventoryManager?

    // MARK: - Total stats (base + equipped boosts)
    //
    // ⚠️ These read `inventory` (a Combine ObservableObject) across the
    // @Observable boundary, which the Observation system cannot track. Any
    // SwiftUI view that displays these totals must ALSO observe the same
    // InventoryManager (e.g. `@ObservedObject var inventory`) so it re-renders
    // when equipment changes. See HUDView and WardrobeView.StatsPanel.

    var maxBandwidth: Int { baseMaxBandwidth + boost(.maxBandwidth) }
    var maxPatience: Int { baseMaxPatience + boost(.maxPatience) }
    var jargon: Int { baseJargon + boost(.jargon) }
    var rep: Int { baseRep + boost(.rep) }

    private func boost(_ type: StatBoostType) -> Int {
        inventory?.totalBoost(for: type) ?? 0
    }

    // MARK: - QBR / persistence

    /// Card finish tier, derived from lifetime earnings.
    var cardTier: CardTier { CardTier.tier(forLifetime: lifetimeCommishCash) }

    var fiscalMoment: FiscalMoment {
        FiscalCalendar.moment(startedAt: fiscalYearStartedAt, now: fiscalNow)
    }

    var deskPlantStatus: String {
        if losses >= max(3, wins + 2) { return "Tragically Dead" }
        if lifetimeCommishCash >= 8_000 || (wins >= 3 && wins > losses) { return "Thriving" }
        return "Alive"
    }

    var statsSnapshot: StatsStore.Snapshot {
        .init(commishCash: commishCash, lifetimeCommishCash: lifetimeCommishCash,
              wins: wins, losses: losses, fiscalYearStartedAt: fiscalYearStartedAt)
    }

    func applyStats(_ s: StatsStore.Snapshot) {
        commishCash = s.commishCash
        lifetimeCommishCash = s.lifetimeCommishCash
        wins = s.wins
        losses = s.losses
        fiscalYearStartedAt = s.fiscalYearStartedAt ?? Date()
        fiscalNow = Date()
    }

    func tickFiscalClock(now: Date = Date()) {
        fiscalNow = now
    }
}
