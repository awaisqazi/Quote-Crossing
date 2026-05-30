//
//  EncounterViewModel.swift
//  Quote Crossing
//
//  Drives the turn-based Sales Encounter (GDD §5). Player acts → 1s delay →
//  enemy acts. Wear the Prospect's Skepticism below 20% to reveal the E-Sign
//  Sphere, then close the deal for Commish-Cash.
//

import SwiftUI
import Combine

@MainActor
final class EncounterViewModel: ObservableObject {

    enum Outcome: Equatable { case win(reward: Int), lose, fled }
    enum PlayerMove { case pitch, listen, item, flee }

    // Enemy
    let prospect: EnemyProspect
    let maxSkepticism: Int
    @Published private(set) var skepticism: Int

    // Player (Patience = HP, Jargon = MP). Max Patience is captured from the
    // stats model at encounter start, so it reflects equipped wearable boosts.
    let maxPatience: Int
    let maxJargon: Int
    @Published private(set) var patience: Int
    @Published private(set) var jargon: Int
    @Published private(set) var items: Int = 2

    // Flow
    @Published private(set) var isPlayerTurn = true
    @Published private(set) var isBusy = false
    @Published private(set) var logMessage: String
    @Published private(set) var outcome: Outcome?
    @Published private(set) var isThrowingSphere = false

    private let pitchCost = 6
    private var didFinish = false
    private let onComplete: (Outcome) -> Void

    init(prospect: EnemyProspect, maxPatience: Int, maxJargon: Int,
         onComplete: @escaping (Outcome) -> Void) {
        self.prospect = prospect
        self.maxSkepticism = prospect.maxSkepticism
        self.skepticism = prospect.maxSkepticism
        self.maxPatience = max(1, maxPatience)
        self.patience = max(1, maxPatience)
        self.maxJargon = max(0, maxJargon)
        self.jargon = max(0, maxJargon)
        self.onComplete = onComplete
        self.logMessage = "\(prospect.name) folds their arms. \u{201C}Impress me.\u{201D}"
    }

    // MARK: Derived

    /// The E-Sign Sphere becomes throwable once Skepticism drops below 20%.
    var canThrowSphere: Bool {
        outcome == nil && skepticism <= Int((Double(maxSkepticism) * 0.2).rounded(.up))
    }
    var skepticismFraction: Double { fraction(skepticism, maxSkepticism) }
    var patienceFraction: Double { fraction(patience, maxPatience) }
    var jargonFraction: Double { fraction(jargon, maxJargon) }
    var actionsDisabled: Bool { isBusy || outcome != nil || isThrowingSphere }

    private func fraction(_ v: Int, _ m: Int) -> Double {
        m <= 0 ? 0 : max(0, min(1, Double(v) / Double(m)))
    }

    // MARK: Player moves

    func perform(_ move: PlayerMove) {
        guard isPlayerTurn, !actionsDisabled else { return }
        switch move {
        case .pitch:  pitchSynergy()
        case .listen: listen()
        case .item:   useItem()
        case .flee:   flee()
        }
    }

    private func pitchSynergy() {
        let underfunded = jargon < pitchCost
        let base = Int.random(in: 16...24)
        let damage = underfunded ? base / 2 : base
        jargon = max(0, jargon - pitchCost)
        skepticism = max(0, skepticism - damage)
        logMessage = underfunded
            ? "Out of buzzwords — a weak pitch. (−\(damage) Skepticism)"
            : "Pitch Synergy lands! (−\(damage) Skepticism)"
        endPlayerTurn()
    }

    private func listen() {
        let heal = Int.random(in: 12...18)
        patience = min(maxPatience, patience + heal)
        jargon = min(maxJargon, jargon + 8)
        logMessage = "You Listen intently. (+\(heal) Patience, +8 Jargon)"
        endPlayerTurn()
    }

    private func useItem() {
        guard items > 0 else { return }
        items -= 1
        patience = min(maxPatience, patience + 25)
        jargon = min(maxJargon, jargon + 10)
        logMessage = "Chugged an Espresso Shot! (+25 Patience, +10 Jargon)"
        endPlayerTurn()
    }

    private func flee() {
        if Double.random(in: 0..<1) < 0.75 {
            finish(.fled, message: "You slip back into the Bullpen…")
        } else {
            logMessage = "Couldn't escape the conversation!"
            beginEnemyTurn()
        }
    }

    // MARK: Turn flow

    private func endPlayerTurn() {
        // The enemy still takes its turn even if now catchable — closing the
        // deal only happens by throwing the E-Sign Sphere.
        beginEnemyTurn()
    }

    private func beginEnemyTurn() {
        isPlayerTurn = false
        isBusy = true
        Task {
            try? await Task.sleep(for: .seconds(1))
            guard outcome == nil, !didFinish else { return }
            enemyTurn()
        }
    }

    private func enemyTurn() {
        let attack = prospect.attacks.randomElement()!
        let damage = attack.rollDamage()
        patience = max(0, patience - damage)
        logMessage = "\(prospect.name) used \(attack.name)! (−\(damage) Patience)"
        if patience <= 0 {
            finish(.lose, message: "Out of Patience. The deal collapses.")
        } else {
            isBusy = false
            isPlayerTurn = true
        }
    }

    // MARK: E-Sign Sphere / win

    func throwESignSphere() {
        guard canThrowSphere, !isThrowingSphere, outcome == nil else { return }
        isThrowingSphere = true
        isBusy = true
        logMessage = "You lob the E-Sign Sphere…"
        Task {
            try? await Task.sleep(for: .milliseconds(1200))
            finish(.win(reward: prospect.reward),
                   message: "✍️ Deal closed! +\(prospect.reward) Commish-Cash")
        }
    }

    // MARK: Completion

    private func finish(_ result: Outcome, message: String) {
        guard !didFinish else { return }
        didFinish = true
        outcome = result
        logMessage = message
        isBusy = true
        isPlayerTurn = false
        Task {
            let pause: Duration = (result == .fled) ? .milliseconds(700) : .milliseconds(1500)
            try? await Task.sleep(for: pause)
            onComplete(result)
        }
    }
}
