//
//  InventoryManager.swift
//  Quote Crossing
//
//  Owns the player's wearables and the equip logic (one item per slot).
//  Equipped items drive both the live avatar art and the dynamic RPG stat
//  totals (see GameState's computed stats).
//

import SwiftUI
import Combine

final class InventoryManager: ObservableObject {
    @Published private(set) var ownedItems: [WearableItem] = []
    @Published private(set) var equippedBySlot: [EquipSlot: WearableItem] = [:]

    private let storeKey = "player.inventory.v1"
    private let defaults: UserDefaults
    private var didSeed = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    // MARK: Queries

    /// Equipped items in a stable slot order.
    var equippedItems: [WearableItem] {
        EquipSlot.allCases.compactMap { equippedBySlot[$0] }
    }

    func items(in slot: EquipSlot) -> [WearableItem] {
        ownedItems.filter { $0.slot == slot }
    }

    func isEquipped(_ item: WearableItem) -> Bool {
        equippedBySlot[item.slot]?.id == item.id
    }

    func ownsItem(id: String) -> Bool {
        ownedItems.contains { $0.id == id }
    }

    /// Sum of equipped boosts of a given type — used by GameState to recompute
    /// total stats dynamically.
    func totalBoost(for type: StatBoostType) -> Int {
        equippedItems.reduce(0) { $0 + ($1.statBoostType == type ? $1.statBoostValue : 0) }
    }

    // MARK: Equip logic

    /// Tap behaviour: equip the item into its slot, or unequip it if it was
    /// already the one equipped there.
    func toggle(_ item: WearableItem) {
        guard ownedItems.contains(where: { $0.id == item.id }) else { return }
        if isEquipped(item) {
            equippedBySlot[item.slot] = nil
        } else {
            equippedBySlot[item.slot] = item
        }
        save()
    }

    @discardableResult
    func grant(_ item: WearableItem) -> Bool {
        guard !ownsItem(id: item.id) else { return false }
        ownedItems.append(item)
        save()
        return true
    }

    func unequip(_ slot: EquipSlot) {
        equippedBySlot[slot] = nil
        save()
    }

    // MARK: Seeding

    /// First-run loadout: starts empty so wearables enter through the Outfitter,
    /// Swag Vending, or rewards instead of being free during badging.
    func configureForNewGameIfNeeded(starters: [Accessory]) {
        guard !didSeed else { return }
        didSeed = true
        ownedItems = []
        equippedBySlot = [:]
        save()
    }

    // MARK: Persistence

    private struct Snapshot: Codable {
        var owned: [WearableItem]
        var equipped: [String: WearableItem]   // keyed by slot.rawValue
    }

    private func save() {
        let byRaw = Dictionary(uniqueKeysWithValues: equippedBySlot.map { ($0.key.rawValue, $0.value) })
        let snap = Snapshot(owned: ownedItems, equipped: byRaw)
        if let data = try? JSONEncoder().encode(snap) {
            defaults.set(data, forKey: storeKey)
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: storeKey),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        ownedItems = snap.owned
        equippedBySlot = Dictionary(uniqueKeysWithValues:
            snap.equipped.compactMap { raw, item in
                EquipSlot(rawValue: raw).map { ($0, item) }
            })
        didSeed = true   // saved data wins over re-seeding
    }
}
