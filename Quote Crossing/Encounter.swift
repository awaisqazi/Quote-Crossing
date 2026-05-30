//
//  Encounter.swift
//  Quote Crossing
//
//  Data for the Sales Encounter (turn-based combat, GDD §5). A Prospect is the
//  "enemy": you wear down their Skepticism (HP) and close with an E-Sign Sphere.
//

import Foundation

struct EnemyAttack {
    let name: String
    let minDamage: Int
    let maxDamage: Int

    func rollDamage() -> Int { Int.random(in: minDamage...maxDamage) }
}

struct EnemyProspect: Identifiable {
    let id = UUID()
    let name: String
    let maxSkepticism: Int      // enemy HP
    let reward: Int             // Commish-Cash on a closed deal
    let attacks: [EnemyAttack]
    let tint: RGBAColor
    let symbol: String          // mood / archetype SF Symbol

    static let catalog: [EnemyProspect] = [
        EnemyProspect(
            name: "Skeptical CTO", maxSkepticism: 60, reward: 280,
            attacks: [
                EnemyAttack(name: "Budget Cut", minDamage: 8, maxDamage: 14),
                EnemyAttack(name: "Procurement Delay", minDamage: 5, maxDamage: 10),
                EnemyAttack(name: "\u{201C}Send Me a Deck\u{201D}", minDamage: 6, maxDamage: 12),
            ],
            tint: RGBAColor(0.30, 0.36, 0.52), symbol: "person.fill.questionmark"),
        EnemyProspect(
            name: "Bargain-Hunter Buyer", maxSkepticism: 48, reward: 220,
            attacks: [
                EnemyAttack(name: "Lowball Counter", minDamage: 6, maxDamage: 12),
                EnemyAttack(name: "Competitor Quote", minDamage: 7, maxDamage: 13),
            ],
            tint: RGBAColor(0.50, 0.42, 0.24), symbol: "cart.fill"),
        EnemyProspect(
            name: "Ghosting Procurement Lead", maxSkepticism: 72, reward: 360,
            attacks: [
                EnemyAttack(name: "Radio Silence", minDamage: 9, maxDamage: 15),
                EnemyAttack(name: "Out of Office", minDamage: 4, maxDamage: 9),
                EnemyAttack(name: "Budget Cut", minDamage: 8, maxDamage: 14),
            ],
            tint: RGBAColor(0.42, 0.30, 0.52), symbol: "person.fill.xmark"),
    ]

    static func random() -> EnemyProspect { catalog.randomElement()! }

    func adjusted(for moment: FiscalMoment) -> EnemyProspect {
        guard moment.isEOQBlizzard else { return self }

        return EnemyProspect(
            name: "EOQ \(name)",
            maxSkepticism: moment.adjustedSkepticism(maxSkepticism),
            reward: moment.adjustedReward(reward),
            attacks: attacks + [
                EnemyAttack(name: "Legal Review Avalanche", minDamage: 10, maxDamage: 18),
            ],
            tint: RGBAColor(0.55, 0.28, 0.36),
            symbol: symbol
        )
    }
}
