//
//  EncounterViewModel.swift
//  Quote Crossing
//
//  Drives the turn-based Sales Encounter (GDD §5). Player chains Jargon Cards,
//  status debuffs alter combat stats, and the deal closes when Skepticism hits
//  zero and the E-Sign Sphere capture sequence fires.
//

import SwiftUI
import Combine

@MainActor
final class EncounterViewModel: ObservableObject {

    enum Outcome: Equatable { case win(reward: Int), lose, fled }
    enum PlayerMove: Equatable {
        case playCard(JargonCard)
        case listen
        case item
        case flee
        case deployQuote(ContractWeapon)
    }

    private enum Combatant {
        case player
        case prospect
    }

    // State reference for compiled quotes
    var gameState: GameState? = nil

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
    @Published private(set) var playerStatuses: [ActiveStatusEffect] = []
    @Published private(set) var prospectStatuses: [ActiveStatusEffect] = []
    @Published private(set) var comboOpener: JargonCard?

    // Flow
    @Published private(set) var isPlayerTurn = true
    @Published private(set) var isBusy = false
    @Published private(set) var logMessage: String
    @Published private(set) var outcome: Outcome?
    @Published private(set) var isThrowingSphere = false

    let playerElement: JargonElement = .cloud
    let jargonCards = JargonCard.coreDeck

    private var didFinish = false
    private let onComplete: (Outcome) -> Void

    init(prospect: EnemyProspect, maxPatience: Int, maxJargon: Int,
         gameState: GameState? = nil,
         onComplete: @escaping (Outcome) -> Void) {
        self.prospect = prospect
        self.maxSkepticism = prospect.maxSkepticism
        self.skepticism = prospect.maxSkepticism
        self.maxPatience = max(1, maxPatience)
        self.patience = max(1, maxPatience)
        self.maxJargon = max(0, maxJargon)
        self.jargon = max(0, maxJargon)
        self.gameState = gameState
        self.onComplete = onComplete
        self.logMessage = "\(prospect.name) folds their arms. \"Impress me.\""
    }

    // MARK: Derived

    /// The E-Sign Sphere captures the contract only after Skepticism hits 0.
    var canThrowSphere: Bool {
        outcome == nil && !isThrowingSphere && skepticism <= 0
    }
    var skepticismFraction: Double { fraction(skepticism, maxSkepticism) }
    var patienceFraction: Double { fraction(patience, maxPatience) }
    var jargonFraction: Double { fraction(jargon, maxJargon) }
    var actionsDisabled: Bool { isBusy || outcome != nil || isThrowingSphere }
    var canCommitComboOpener: Bool { comboOpener != nil && isPlayerTurn && !actionsDisabled }

    /// Player's overall Jargon stat multiplier for card chains.
    var alphaSynergy: Double {
        1.0 + (Double(maxJargon) / 100.0)
    }

    var alphaSynergyLabel: String {
        String(format: "x%.2f", alphaSynergy)
    }

    private func fraction(_ v: Int, _ m: Int) -> Double {
        m <= 0 ? 0 : max(0, min(1, Double(v) / Double(m)))
    }

    func canPlay(_ card: JargonCard) -> Bool {
        guard isPlayerTurn, !actionsDisabled, jargon >= card.cost else { return false }
        guard comboOpener != nil else { return true }
        return card.isOffensive
    }

    func canDeployQuote(_ weapon: ContractWeapon) -> Bool {
        comboOpener == nil && canPlay(JargonCard(contractWeapon: weapon))
    }

    // MARK: Player moves

    func perform(_ move: PlayerMove) {
        guard isPlayerTurn, !actionsDisabled else { return }
        switch move {
        case .playCard(let card): playCard(card)
        case .listen: listen()
        case .item:   useItem()
        case .flee:   flee()
        case .deployQuote(let weapon): deployQuote(weapon)
        }
    }

    private func playCard(_ card: JargonCard) {
        guard canPlay(card) else {
            logMessage = "Not enough Jargon or the current chain needs a damage catalyst."
            return
        }
        guard spendJargon(card.cost, for: card.name) else { return }

        if card.isHealing {
            resolveHealingCard(card)
        } else if let opener = comboOpener {
            resolveCombo(opener: opener, catalyst: card)
        } else {
            comboOpener = card
            logMessage = "\(card.name) opens the chain. Add a catalyst or commit the pitch."
        }
    }

    func commitComboOpener() {
        guard canCommitComboOpener, let opener = comboOpener else { return }
        comboOpener = nil
        resolveSingleAttack(opener)
    }

    private func deployQuote(_ weapon: ContractWeapon) {
        guard comboOpener == nil else {
            logMessage = "Finish the current Jargon chain before deploying a compiled quote."
            return
        }

        let card = JargonCard(contractWeapon: weapon)
        guard canPlay(card), spendJargon(card.cost, for: card.name) else {
            logMessage = "Not enough Jargon to deploy \(weapon.name)."
            return
        }

        resolveSingleAttack(card, shouldEndTurn: false)

        if let state = gameState {
            state.compiledQuotes.removeAll(where: { $0.id == weapon.id })
            state.saveQuotes()
        }

        if outcome == nil && !isThrowingSphere {
            endPlayerTurn()
        }
    }

    private func listen() {
        guard comboOpener == nil else {
            logMessage = "Commit or catalyze the current Jargon chain first."
            return
        }
        let heal = Int.random(in: 12...18)
        patience = min(maxPatience, patience + heal)
        jargon = min(maxJargon, jargon + 8)
        logMessage = "You Listen intently. (+\(heal) Patience, +8 Jargon)"
        endPlayerTurn()
    }

    private func useItem() {
        guard comboOpener == nil else {
            logMessage = "Commit or catalyze the current Jargon chain first."
            return
        }
        guard items > 0 else { return }
        items -= 1
        patience = min(maxPatience, patience + 25)
        jargon = min(maxJargon, jargon + 10)
        logMessage = "Chugged an Espresso Shot! (+25 Patience, +10 Jargon)"
        endPlayerTurn()
    }

    private func flee() {
        guard comboOpener == nil else {
            logMessage = "Commit or catalyze the current Jargon chain first."
            return
        }
        if Double.random(in: 0..<1) < 0.75 {
            finish(.fled, message: "You slip back into the Bullpen…")
        } else {
            logMessage = "Couldn't escape the conversation!"
            beginEnemyTurn()
        }
    }

    // MARK: Card resolution

    private func resolveHealingCard(_ card: JargonCard) {
        let healed = min(card.healing, maxPatience - patience)
        patience = min(maxPatience, patience + card.healing)
        logMessage = "\(card.name) restores the room. (+\(healed) Patience)"
        endPlayerTurn()
    }

    private func resolveSingleAttack(_ card: JargonCard, shouldEndTurn: Bool = true) {
        let target = target(forAttackFrom: .player)
        let damage = modifiedDamage(base: card.damage,
                                    element: card.element,
                                    damageType: card.damageType,
                                    attacker: .player,
                                    target: target)
        let message = attackLog(cardName: card.name, damage: damage, target: target, combo: nil)
        apply(card.inflictedStatuses, to: target)
        let ended = applyDamage(damage, to: target)
        if !ended {
            logMessage = message
        }

        if shouldEndTurn && !ended {
            endPlayerTurn()
        }
    }

    private func resolveCombo(opener: JargonCard, catalyst: JargonCard) {
        comboOpener = nil

        let target = target(forAttackFrom: .player)
        let openerDamage = modifiedDamage(base: opener.damage,
                                          element: opener.element,
                                          damageType: opener.damageType,
                                          attacker: .player,
                                          target: target)
        let catalystDamage = modifiedDamage(base: catalyst.damage,
                                            element: catalyst.element,
                                            damageType: catalyst.damageType,
                                            attacker: .player,
                                            target: target)
        let comboDamage = max(1, Int((Double(openerDamage + catalystDamage) * alphaSynergy).rounded()))

        apply(opener.inflictedStatuses + catalyst.inflictedStatuses, to: target)
        let message = attackLog(cardName: "\(opener.name) + \(catalyst.name)",
                                damage: comboDamage,
                                target: target,
                                combo: "\(comboName(opener: opener, catalyst: catalyst)) \(alphaSynergyLabel)")
        let ended = applyDamage(comboDamage, to: target)
        if !ended {
            logMessage = message
        }

        if !ended {
            endPlayerTurn()
        }
    }

    private func spendJargon(_ amount: Int, for cardName: String) -> Bool {
        guard jargon >= amount else {
            logMessage = "\(cardName) needs \(amount) Jargon."
            return false
        }
        jargon -= amount
        return true
    }

    // MARK: Turn flow

    private func endPlayerTurn() {
        decrementStatuses(for: .player)
        guard outcome == nil, !didFinish, !isThrowingSphere else { return }
        beginEnemyTurn()
    }

    private func beginEnemyTurn() {
        isPlayerTurn = false
        isBusy = true
        Task {
            try? await Task.sleep(for: turnDelay(for: .prospect))
            guard outcome == nil, !didFinish else { return }
            enemyTurn()
        }
    }

    private func enemyTurn() {
        let attack = prospect.attacks.randomElement()!
        let target = target(forAttackFrom: .prospect)
        let damage = modifiedDamage(base: attack.rollDamage(),
                                    element: attack.element,
                                    damageType: attack.damageType,
                                    attacker: .prospect,
                                    target: target)

        apply(attack.inflictedStatuses, to: target)
        let message = enemyAttackLog(attack: attack, damage: damage, target: target)
        let ended = applyDamage(damage, to: target)
        if !ended {
            logMessage = message
        }

        guard !ended else { return }

        decrementStatuses(for: .prospect)
        beginPlayerTurn()
    }

    private func beginPlayerTurn() {
        guard outcome == nil, !didFinish else { return }

        if hasStatus(.overencumbered, for: .player) {
            isBusy = true
            logMessage += " Overencumbered slows your response."
            Task {
                try? await Task.sleep(for: .milliseconds(750))
                guard outcome == nil, !didFinish else { return }
                isBusy = false
                isPlayerTurn = true
            }
        } else {
            isBusy = false
            isPlayerTurn = true
        }
    }

    private func turnDelay(for combatant: Combatant) -> Duration {
        hasStatus(.overencumbered, for: combatant) ? .milliseconds(1750) : .seconds(1)
    }

    // MARK: Damage, elements, statuses

    private func modifiedDamage(base: Int,
                                element: JargonElement,
                                damageType: DamageType,
                                attacker: Combatant,
                                target: Combatant) -> Int {
        var multiplier = element.hasAdvantage(over: elementFor(target)) ? 1.5 : 1.0

        if hasStatus(.wet, for: target), damageType == .electrical {
            multiplier *= 1.5
        }

        if hasStatus(.drunk, for: attacker), damageType == .physical {
            multiplier *= 3.0
        }

        return max(1, Int((Double(base) * multiplier).rounded()))
    }

    private func applyDamage(_ amount: Int, to target: Combatant) -> Bool {
        switch target {
        case .player:
            patience = max(0, patience - amount)
            if patience <= 0 {
                finish(.lose, message: "Out of Patience. The deal collapses.")
                return true
            }
        case .prospect:
            skepticism = max(0, skepticism - amount)
            if skepticism <= 0 {
                throwESignSphere()
                return true
            }
        }
        return false
    }

    private func apply(_ applications: [StatusApplication], to target: Combatant) {
        for application in applications where application.turns > 0 {
            switch target {
            case .player:
                upsert(application, in: &playerStatuses)
            case .prospect:
                upsert(application, in: &prospectStatuses)
            }
        }
    }

    private func upsert(_ application: StatusApplication, in statuses: inout [ActiveStatusEffect]) {
        if let index = statuses.firstIndex(where: { $0.effect == application.effect }) {
            statuses[index].turnsRemaining = max(statuses[index].turnsRemaining, application.turns)
        } else {
            statuses.append(ActiveStatusEffect(effect: application.effect,
                                               turnsRemaining: application.turns))
        }
    }

    private func decrementStatuses(for combatant: Combatant) {
        switch combatant {
        case .player:
            playerStatuses = decremented(playerStatuses)
        case .prospect:
            prospectStatuses = decremented(prospectStatuses)
        }
    }

    private func decremented(_ statuses: [ActiveStatusEffect]) -> [ActiveStatusEffect] {
        statuses.compactMap { status in
            let remaining = status.turnsRemaining - 1
            return remaining > 0 ? ActiveStatusEffect(effect: status.effect,
                                                       turnsRemaining: remaining) : nil
        }
    }

    private func hasStatus(_ effect: BattleStatusEffect, for combatant: Combatant) -> Bool {
        switch combatant {
        case .player:
            playerStatuses.contains(where: { $0.effect == effect })
        case .prospect:
            prospectStatuses.contains(where: { $0.effect == effect })
        }
    }

    private func target(forAttackFrom attacker: Combatant) -> Combatant {
        if hasStatus(.drunk, for: attacker) {
            return Bool.random() ? .player : .prospect
        }
        switch attacker {
        case .player:
            return .prospect
        case .prospect:
            return .player
        }
    }

    private func elementFor(_ combatant: Combatant) -> JargonElement {
        switch combatant {
        case .player:
            return playerElement
        case .prospect:
            return prospect.element
        }
    }

    private func attackLog(cardName: String,
                           damage: Int,
                           target: Combatant,
                           combo: String?) -> String {
        let prefix = combo.map { "\($0): " } ?? ""
        switch target {
        case .prospect:
            return "\(prefix)\(cardName) lands! (-\(damage) Skepticism)"
        case .player:
            return "\(prefix)\(cardName) backfires through Drunk targeting! (-\(damage) Patience)"
        }
    }

    private func comboName(opener: JargonCard, catalyst: JargonCard) -> String {
        let names = Set([opener.name, catalyst.name])
        if names == Set(["Move the Needle", "Boil the Ocean"]) {
            return "Synergy Blast"
        }
        return "Combo"
    }

    private func enemyAttackLog(attack: EnemyAttack, damage: Int, target: Combatant) -> String {
        let statusText = attack.inflictedStatuses.isEmpty
            ? ""
            : " \(attack.inflictedStatuses.map { $0.effect.rawValue }.joined(separator: ", ")) applied."

        switch target {
        case .player:
            return "\(prospect.name) used \(attack.name)! (-\(damage) Patience)\(statusText)"
        case .prospect:
            return "\(prospect.name)'s \(attack.name) backfires! (-\(damage) Skepticism)\(statusText)"
        }
    }

    // MARK: E-Sign Sphere / win

    func throwESignSphere() {
        guard canThrowSphere, !isThrowingSphere, outcome == nil else { return }
        isThrowingSphere = true
        isBusy = true
        isPlayerTurn = false
        comboOpener = nil
        logMessage = "Skepticism hits 0. You throw the E-Sign Sphere..."
        Task {
            try? await Task.sleep(for: .milliseconds(1200))
            finish(.win(reward: prospect.reward),
                   message: "Deal closed! +\(prospect.reward) Commish-Cash")
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
