//
//  Encounter.swift
//  Quote Crossing
//
//  Data for the Sales Encounter (turn-based combat, GDD §5). A Prospect is the
//  "enemy": you wear down their Skepticism (HP) and close with an E-Sign Sphere.
//

import Foundation
import SwiftUI

enum JargonElement: String, Codable, CaseIterable, Equatable {
    case cloud = "Cloud"
    case hardware = "Hardware"
    case onPrem = "On-Prem"
    case saas = "SaaS"
    case legacy = "Legacy"

    var symbolName: String {
        switch self {
        case .cloud: "cloud.fill"
        case .hardware: "cpu.fill"
        case .onPrem: "server.rack"
        case .saas: "doc.plaintext.fill"
        case .legacy: "externaldrive.fill"
        }
    }

    var color: Color {
        switch self {
        case .cloud: Color(red: 0.30, green: 0.76, blue: 0.92)
        case .hardware: Color(red: 0.94, green: 0.46, blue: 0.40)
        case .onPrem: Color(red: 0.66, green: 0.62, blue: 0.52)
        case .saas: Color(red: 0.62, green: 0.50, blue: 0.95)
        case .legacy: Color(red: 0.48, green: 0.50, blue: 0.56)
        }
    }

    func hasAdvantage(over defender: JargonElement) -> Bool {
        switch (self, defender) {
        case (.cloud, .hardware),
             (.hardware, .onPrem),
             (.onPrem, .cloud):
            true
        default:
            false
        }
    }
}

enum DamageType: String, Codable, Equatable {
    case jargon = "Jargon"
    case electrical = "Electrical"
    case physical = "Physical"

    var symbolName: String {
        switch self {
        case .jargon: "text.bubble.fill"
        case .electrical: "bolt.fill"
        case .physical: "hammer.fill"
        }
    }
}

enum BattleStatusEffect: String, Codable, CaseIterable, Equatable {
    case wet = "Wet"
    case overencumbered = "Overencumbered"
    case drunk = "Drunk"

    var symbolName: String {
        switch self {
        case .wet: "drop.fill"
        case .overencumbered: "shippingbox.fill"
        case .drunk: "wineglass.fill"
        }
    }

    var color: Color {
        switch self {
        case .wet: Color(red: 0.35, green: 0.72, blue: 0.95)
        case .overencumbered: Color(red: 0.86, green: 0.64, blue: 0.28)
        case .drunk: Color(red: 0.88, green: 0.42, blue: 0.72)
        }
    }
}

struct StatusApplication: Codable, Equatable {
    let effect: BattleStatusEffect
    let turns: Int
}

struct ActiveStatusEffect: Identifiable, Equatable {
    let effect: BattleStatusEffect
    var turnsRemaining: Int

    var id: BattleStatusEffect { effect }
}

struct JargonCard: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let cost: Int
    let damage: Int
    let healing: Int
    let element: JargonElement
    let damageType: DamageType
    let inflictedStatuses: [StatusApplication]

    init(id: UUID = UUID(),
         name: String,
         cost: Int,
         damage: Int = 0,
         healing: Int = 0,
         element: JargonElement,
         damageType: DamageType = .jargon,
         inflictedStatuses: [StatusApplication] = []) {
        self.id = id
        self.name = name
        self.cost = cost
        self.damage = damage
        self.healing = healing
        self.element = element
        self.damageType = damageType
        self.inflictedStatuses = inflictedStatuses
    }

    var isOffensive: Bool { damage > 0 }
    var isHealing: Bool { healing > 0 }

    static let coreDeck: [JargonCard] = [
        JargonCard(name: "Move the Needle",
                   cost: 10,
                   damage: 40,
                   element: .cloud),
        JargonCard(name: "Boil the Ocean",
                   cost: 25,
                   damage: 95,
                   element: .saas,
                   damageType: .electrical,
                   inflictedStatuses: [StatusApplication(effect: .wet, turns: 2)]),
        JargonCard(name: "Circle Back",
                   cost: 12,
                   healing: 60,
                   element: .hardware),
        JargonCard(name: "Open the Kimono",
                   cost: 15,
                   damage: 20,
                   element: .onPrem,
                   damageType: .physical,
                   inflictedStatuses: [StatusApplication(effect: .overencumbered, turns: 1)]),
        JargonCard(name: "30,000-Foot View",
                   cost: 20,
                   damage: 55,
                   element: .cloud,
                   damageType: .electrical),
        JargonCard(name: "Rightsizing",
                   cost: 35,
                   damage: 160,
                   element: .legacy,
                   damageType: .physical)
    ]

    init(contractWeapon weapon: ContractWeapon) {
        let inferredElement = JargonElement.inferred(from: weapon.name)
        self.init(
            id: weapon.id,
            name: weapon.name,
            cost: weapon.jargonCost,
            damage: weapon.baseDamage,
            element: inferredElement,
            damageType: inferredElement == .hardware ? .physical : .jargon
        )
    }
}

extension JargonElement {
    static func inferred(from weaponName: String) -> JargonElement {
        let name = weaponName.lowercased()
        if name.contains("cloud") || name.contains("serverless") {
            return .cloud
        }
        if name.contains("server") || name.contains("blade") || name.contains("hardware") || name.contains("ironclad") {
            return .hardware
        }
        if name.contains("legacy") || name.contains("monolith") || name.contains("database") || name.contains("db") {
            return .onPrem
        }
        return .saas
    }
}

struct EnemyAttack {
    let name: String
    let minDamage: Int
    let maxDamage: Int
    let element: JargonElement
    let damageType: DamageType
    let inflictedStatuses: [StatusApplication]

    init(name: String,
         minDamage: Int,
         maxDamage: Int,
         element: JargonElement = .saas,
         damageType: DamageType = .jargon,
         inflictedStatuses: [StatusApplication] = []) {
        self.name = name
        self.minDamage = minDamage
        self.maxDamage = maxDamage
        self.element = element
        self.damageType = damageType
        self.inflictedStatuses = inflictedStatuses
    }

    func rollDamage() -> Int { Int.random(in: minDamage...maxDamage) }
}

struct EnemyProspect: Identifiable {
    let id = UUID()
    let name: String
    let maxSkepticism: Int      // enemy HP
    let reward: Int             // Commish-Cash on a closed deal
    let element: JargonElement
    let attacks: [EnemyAttack]
    let tint: RGBAColor
    let symbol: String          // mood / archetype SF Symbol

    static let catalog: [EnemyProspect] = [
        EnemyProspect(
            name: "Skeptical CTO", maxSkepticism: 60, reward: 280, element: .hardware,
            attacks: [
                EnemyAttack(name: "Budget Cut", minDamage: 8, maxDamage: 14,
                            element: .hardware, damageType: .physical),
                EnemyAttack(name: "Procurement Delay", minDamage: 5, maxDamage: 10,
                            element: .onPrem,
                            inflictedStatuses: [StatusApplication(effect: .overencumbered, turns: 1)]),
                EnemyAttack(name: "\u{201C}Send Me a Deck\u{201D}", minDamage: 6, maxDamage: 12,
                            element: .cloud, damageType: .electrical,
                            inflictedStatuses: [StatusApplication(effect: .wet, turns: 2)]),
            ],
            tint: RGBAColor(0.30, 0.36, 0.52), symbol: "person.fill.questionmark"),
        EnemyProspect(
            name: "Bargain-Hunter Buyer", maxSkepticism: 48, reward: 220, element: .onPrem,
            attacks: [
                EnemyAttack(name: "Lowball Counter", minDamage: 6, maxDamage: 12,
                            element: .hardware, damageType: .physical),
                EnemyAttack(name: "Steakhouse Lunch", minDamage: 4, maxDamage: 8,
                            element: .saas,
                            inflictedStatuses: [StatusApplication(effect: .drunk, turns: 1)]),
                EnemyAttack(name: "Competitor Quote", minDamage: 7, maxDamage: 13,
                            element: .cloud, damageType: .electrical),
            ],
            tint: RGBAColor(0.50, 0.42, 0.24), symbol: "cart.fill"),
        EnemyProspect(
            name: "Ghosting Procurement Lead", maxSkepticism: 72, reward: 360, element: .cloud,
            attacks: [
                EnemyAttack(name: "Radio Silence", minDamage: 9, maxDamage: 15,
                            element: .onPrem),
                EnemyAttack(name: "Out of Office", minDamage: 4, maxDamage: 9,
                            element: .cloud,
                            inflictedStatuses: [StatusApplication(effect: .overencumbered, turns: 1)]),
                EnemyAttack(name: "Budget Cut", minDamage: 8, maxDamage: 14,
                            element: .hardware, damageType: .physical),
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
            element: element,
            attacks: attacks + [
                EnemyAttack(name: "Legal Review Avalanche", minDamage: 10, maxDamage: 18,
                            element: .onPrem,
                            inflictedStatuses: [StatusApplication(effect: .overencumbered, turns: 1)]),
            ],
            tint: RGBAColor(0.55, 0.28, 0.36),
            symbol: symbol
        )
    }
}
