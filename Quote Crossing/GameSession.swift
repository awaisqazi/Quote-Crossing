//
//  GameSession.swift
//  Quote Crossing
//
//  Single owner of the live game objects (stats, input, inventory, avatar,
//  scene). Bundling them into one type held as @State keeps their wiring
//  consistent and keeps the View's init side-effect-free (the scene's heavy
//  world-building is deferred to didMove).
//

import SwiftUI
import Observation
import SpriteKit

@Observable
final class GameSession {
    let state = GameState()
    let input = GameInput()
    let inventory = InventoryManager()

    /// Live editing model for the avatar's base look, reconstructed from the
    /// saved badge so the wardrobe can show a live preview.
    let avatar: PlayerAvatar
    let scene: OverworldScene

    /// Non-nil while a Sales Encounter is active; observed by ContentView to
    /// present the battle screen.
    var activeEncounter: EncounterViewModel?

    init() {
        // Base look chosen during the Badging Process.
        let snapshot = AvatarStore.load() ?? .placeholder
        avatar = PlayerAvatar(snapshot: snapshot)

        // Seed the wardrobe (first run) and equip the badge's starter accessories.
        inventory.configureForNewGameIfNeeded(starters: snapshot.equippedAccessories)

        // Stats recompute from the equipped wearables.
        state.inventory = inventory

        // Restore career stats (lifetime cash, W/L, fiscal clock) for the QBR.
        if let saved = StatsStore.load() {
            state.applyStats(saved)
        } else {
            StatsStore.save(state.statsSnapshot)
        }

        scene = OverworldScene(gameState: state, gameInput: input,
                               avatar: snapshot, wearables: inventory.equippedItems)

        // Hook the overworld's random-encounter trigger up to the battle flow.
        scene.onEncounterTriggered = { [weak self] in self?.startEncounter() }
    }

    // MARK: - Pause control

    /// Freezes the overworld for a full-screen UI (battle, wardrobe): drops
    /// input, halts the player's physics body, and pauses the scene so it can't
    /// glide or roll encounters underneath.
    func pauseWorld() {
        input.movement = .zero
        scene.haltPlayer()
        scene.isPaused = true
    }

    /// Resumes the overworld with a clean slate so it doesn't lurch.
    func resumeWorld() {
        input.movement = .zero
        scene.isPaused = false
        scene.resetEncounterProbe()
    }

    // MARK: - Sales Encounter flow

    private func startEncounter() {
        guard activeEncounter == nil else { return }

        pauseWorld()                    // freeze SpriteKit during the battle

        // Max Patience / Jargon are pulled live from the stats model, which
        // already folds in the player's equipped wearable boosts.
        let vm = EncounterViewModel(
            prospect: EnemyProspect.random().adjusted(for: state.fiscalMoment),
            maxPatience: state.maxPatience,
            maxJargon: state.jargon
        ) { [weak self] outcome in
            self?.finishEncounter(outcome)
        }

        withAnimation(.easeInOut(duration: 0.3)) { activeEncounter = vm }
    }

    private func finishEncounter(_ outcome: EncounterViewModel.Outcome) {
        switch outcome {
        case .win(let reward):
            state.commishCash += reward
            state.lifetimeCommishCash += reward   // lifetime never decreases
            state.wins += 1
        case .lose:
            state.losses += 1
        case .fled:
            break
        }
        StatsStore.save(state.statsSnapshot)
        resumeWorld()
        withAnimation(.easeInOut(duration: 0.3)) { activeEncounter = nil }
    }

    /// Equip/unequip from the wardrobe: update inventory (drives the SwiftUI
    /// preview + stat totals) and refresh the SpriteKit figure in lockstep.
    func toggleEquip(_ item: WearableItem) {
        inventory.toggle(item)
        scene.applyWearables(inventory.equippedItems)
    }
}
