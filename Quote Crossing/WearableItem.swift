//
//  WearableItem.swift
//  Quote Crossing
//
//  The Wearable / Swag economy (GDD §2). A WearableItem occupies one equip
//  slot and may grant an RPG stat boost. Items render generically on the avatar
//  (SwiftUI preview + SpriteKit node) from their slot + SF Symbol icon.
//

import SwiftUI

// MARK: - Equip slots

enum EquipSlot: String, CaseIterable, Codable, Identifiable {
    case head, eyewear, torso, lanyard
    var id: String { rawValue }

    var label: String {
        switch self {
        case .head:    "Headwear"
        case .eyewear: "Eyewear"
        case .torso:   "Torso"
        case .lanyard: "Lanyards & Pins"
        }
    }

    var symbol: String {
        switch self {
        case .head:    "graduationcap.fill"
        case .eyewear: "eyeglasses"
        case .torso:   "tshirt.fill"
        case .lanyard: "lanyardcard.fill"
        }
    }
}

// MARK: - Stat boosts

enum StatBoostType: String, CaseIterable, Codable, Identifiable {
    case maxBandwidth, maxPatience, jargon, rep
    var id: String { rawValue }

    var label: String {
        switch self {
        case .maxBandwidth: "Max Bandwidth"
        case .maxPatience:  "Max Patience"
        case .jargon:       "Jargon"
        case .rep:          "Rep"
        }
    }

    var symbol: String {
        switch self {
        case .maxBandwidth: "wifi"
        case .maxPatience:  "heart.fill"
        case .jargon:       "bubble.left.and.text.bubble.right.fill"
        case .rep:          "star.fill"
        }
    }

    var tint: Color {
        switch self {
        case .maxBandwidth: Color(red: 0.30, green: 0.55, blue: 0.95)
        case .maxPatience:  Color(red: 0.90, green: 0.32, blue: 0.40)
        case .jargon:       Color(red: 0.55, green: 0.40, blue: 0.85)
        case .rep:          Color(red: 0.95, green: 0.72, blue: 0.20)
        }
    }
}

// MARK: - Wearable item

struct WearableItem: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let slot: EquipSlot
    let statBoostType: StatBoostType?
    let statBoostValue: Int
    let imageIcon: String      // SF Symbol name
    let tint: RGBAColor        // render/icon tint

    var hasBoost: Bool { statBoostType != nil && statBoostValue != 0 }

    /// e.g. "+15 Max Patience" — empty for cosmetics.
    var boostText: String {
        guard let type = statBoostType, statBoostValue != 0 else { return "Cosmetic" }
        let sign = statBoostValue > 0 ? "+" : ""
        return "\(sign)\(statBoostValue) \(type.label)"
    }
}

// MARK: - Catalog

/// The master list of wearables in the game, plus the mapping from the
/// character-creator's starter accessories.
enum WearableCatalog {
    static let blueLightGlasses = WearableItem(
        id: "blueLightGlasses", name: "Blue Light Glasses", slot: .eyewear,
        statBoostType: .maxBandwidth, statBoostValue: 8,
        imageIcon: "eyeglasses", tint: RGBAColor(0.20, 0.42, 0.85))

    static let aviators = WearableItem(
        id: "aviators", name: "Mirrored Aviators", slot: .eyewear,
        statBoostType: nil, statBoostValue: 0,
        imageIcon: "sunglasses.fill", tint: RGBAColor(0.12, 0.13, 0.18))

    static let spreadsheetSpecs = WearableItem(
        id: "spreadsheetSpecs", name: "Spreadsheet Specs", slot: .eyewear,
        statBoostType: .jargon, statBoostValue: 5,
        imageIcon: "eyeglasses", tint: RGBAColor(0.20, 0.62, 0.45))

    static let headphones = WearableItem(
        id: "headphones", name: "Noise-Cancelling Cans", slot: .head,
        statBoostType: .maxPatience, statBoostValue: 6,
        imageIcon: "headphones", tint: RGBAColor(0.16, 0.17, 0.22))

    static let gradCap = WearableItem(
        id: "gradCap", name: "MBA Grad Cap", slot: .head,
        statBoostType: .jargon, statBoostValue: 7,
        imageIcon: "graduationcap.fill", tint: RGBAColor(0.16, 0.18, 0.30))

    static let foundersCrown = WearableItem(
        id: "foundersCrown", name: "Founder's Crown", slot: .head,
        statBoostType: .rep, statBoostValue: 12,
        imageIcon: "crown.fill", tint: RGBAColor(0.95, 0.72, 0.20))

    static let vcFleece = WearableItem(
        id: "vcFleece", name: "VC Vest Fleece", slot: .torso,
        statBoostType: .maxPatience, statBoostValue: 15,
        imageIcon: "tshirt.fill", tint: RGBAColor(0.36, 0.45, 0.55))

    static let diamondLanyard = WearableItem(
        id: "diamondLanyard", name: "5-Year Diamond Lanyard", slot: .lanyard,
        statBoostType: .rep, statBoostValue: 10,
        imageIcon: "lanyardcard.fill", tint: RGBAColor(0.10, 0.55, 0.55))

    static let all: [WearableItem] = [
        blueLightGlasses, aviators, spreadsheetSpecs,
        headphones, gradCap, foundersCrown,
        vcFleece, diamondLanyard,
    ]

    static func item(id: String) -> WearableItem? { all.first { $0.id == id } }

    /// Maps a creator starter accessory to its catalog wearable.
    static func item(for accessory: Accessory) -> WearableItem {
        switch accessory {
        case .blueLightGlasses: blueLightGlasses
        case .aviators:         aviators
        case .headphones:       headphones
        case .lanyard:          diamondLanyard
        }
    }
}
