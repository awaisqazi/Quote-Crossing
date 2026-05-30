//
//  AvatarModel.swift
//  Quote Crossing
//
//  The player avatar data model (GDD §1 "The Badging Process") plus the
//  supporting enums, a Codable persistence snapshot, and a SpriteKit-facing
//  appearance struct so the overworld PlayerNode can mirror the player's
//  character-creator choices.
//

import SwiftUI
import SpriteKit
import Combine
import UIKit

// MARK: - Color helper

/// A plain Codable RGBA colour that bridges SwiftUI `Color` and SpriteKit `SKColor`.
/// `Color` itself isn't directly Codable, so we persist this instead.
struct RGBAColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(_ red: Double, _ green: Double, _ blue: Double, _ alpha: Double = 1) {
        self.red = red; self.green = green; self.blue = blue; self.alpha = alpha
    }

    /// Extracts sRGB components from a SwiftUI `Color`.
    init(_ color: Color) {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(Double(r), Double(g), Double(b), Double(a))
    }

    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha) }
    var sk: SKColor { SKColor(red: red, green: green, blue: blue, alpha: alpha) }
}

// MARK: - Customisation enums

enum HairStyle: String, CaseIterable, Codable, Identifiable {
    case buzz, sideSwept, topKnot, curly, bald
    var id: String { rawValue }

    var label: String {
        switch self {
        case .buzz:      "Buzz"
        case .sideSwept: "Side-Swept"
        case .topKnot:   "Top Knot"
        case .curly:     "Curly"
        case .bald:      "Chrome Dome"
        }
    }
}

/// Starter wardrobe origin styles (GDD §1).
enum StarterOutfit: String, CaseIterable, Codable, Identifiable {
    case overdressedRookie, techBro, minimalist
    var id: String { rawValue }

    var label: String {
        switch self {
        case .overdressedRookie: "Overdressed Rookie"
        case .techBro:           "The Tech Bro"
        case .minimalist:        "The Minimalist"
        }
    }

    var blurb: String {
        switch self {
        case .overdressedRookie: "A suit that's slightly too big."
        case .techBro:           "Plaid shirt, standard fleece."
        case .minimalist:        "Black turtleneck. That's it."
        }
    }

    /// Main torso colour.
    var torso: RGBAColor {
        switch self {
        case .overdressedRookie: RGBAColor(0.20, 0.25, 0.42)   // navy suit
        case .techBro:           RGBAColor(0.32, 0.50, 0.44)   // fleece green
        case .minimalist:        RGBAColor(0.13, 0.13, 0.16)   // black turtleneck
        }
    }

    /// Collar / tie / zipper accent colour.
    var accent: RGBAColor {
        switch self {
        case .overdressedRookie: RGBAColor(0.86, 0.27, 0.30)   // red tie
        case .techBro:           RGBAColor(0.90, 0.92, 0.95)   // zipper / shirt
        case .minimalist:        RGBAColor(0.24, 0.24, 0.28)   // subtle collar
        }
    }
}

/// Cosmetic / power-up wearables (subset of GDD §2).
enum Accessory: String, CaseIterable, Codable, Identifiable {
    case blueLightGlasses, aviators, headphones, lanyard
    var id: String { rawValue }

    var label: String {
        switch self {
        case .blueLightGlasses: "Blue Light Glasses"
        case .aviators:         "Mirrored Aviators"
        case .headphones:       "Noise-Cancelling"
        case .lanyard:          "5-Year Lanyard"
        }
    }

    var symbol: String {
        switch self {
        case .blueLightGlasses: "eyeglasses"
        case .aviators:         "sunglasses.fill"
        case .headphones:       "headphones"
        case .lanyard:          "lanyardcard.fill"
        }
    }

    var blurb: String {
        switch self {
        case .blueLightGlasses: "−15% Bandwidth drain in Q-Bot 3000."
        case .aviators:         "Pure hotshot clout."
        case .headphones:       "Immune to Office Gossip debuffs."
        case .lanyard:          "Flex your tenure. It glares."
        }
    }
}

/// Preset skin tones offered in the creator.
enum SkinTone {
    static let presets: [RGBAColor] = [
        RGBAColor(0.99, 0.87, 0.77),
        RGBAColor(0.96, 0.80, 0.66),
        RGBAColor(0.89, 0.71, 0.55),
        RGBAColor(0.78, 0.58, 0.42),
        RGBAColor(0.60, 0.43, 0.30),
        RGBAColor(0.43, 0.30, 0.21),
        RGBAColor(0.29, 0.20, 0.15),
    ]
}

/// Hilariously mundane corporate titles (GDD §1).
enum CorporateTitles {
    static let prefixes = ["Junior", "Associate", "Senior", "Lead", "Regional", "Global", "Acting"]
    static let middles  = ["Synergy", "Spreadsheet", "Cloud", "Pipeline", "Quota", "Paradigm", "Bandwidth", "Vertical"]
    static let suffixes = ["Facilitator", "Wizard", "Evangelist", "Ninja", "Guru", "Architect", "Champion", "Specialist"]

    static func random() -> String {
        let p = prefixes.randomElement() ?? "Junior"
        let m = middles.randomElement() ?? "Synergy"
        let s = suffixes.randomElement() ?? "Facilitator"
        return "\(p) \(m) \(s)"
    }
}

// MARK: - Live editing model

/// Observable model driving the live character-creator preview.
final class PlayerAvatar: ObservableObject {
    @Published var name: String = ""
    @Published var title: String = CorporateTitles.random()
    @Published var hairStyle: HairStyle = .sideSwept
    @Published var skinTone: Color = SkinTone.presets[1].color
    @Published var eyeBagsLevel: CGFloat = 0.25
    @Published var starterOutfit: StarterOutfit = .overdressedRookie
    @Published var equippedAccessories: [Accessory] = []

    init() {}

    /// Re-init from a persisted snapshot (e.g. re-opening the creator).
    init(snapshot s: AvatarSnapshot) {
        name = s.name
        title = s.title
        hairStyle = s.hairStyle
        skinTone = s.skinTone.color
        eyeBagsLevel = CGFloat(s.eyeBagsLevel)
        starterOutfit = s.starterOutfit
        equippedAccessories = s.equippedAccessories
    }

    func isEquipped(_ a: Accessory) -> Bool { equippedAccessories.contains(a) }

    func toggle(_ a: Accessory) {
        if let i = equippedAccessories.firstIndex(of: a) {
            equippedAccessories.remove(at: i)
        } else {
            // One accessory per slot — matches the wardrobe's slot-exclusive
            // equip model so the preview can't stack two pairs of glasses.
            let slot = WearableCatalog.item(for: a).slot
            equippedAccessories.removeAll { WearableCatalog.item(for: $0).slot == slot }
            equippedAccessories.append(a)
        }
    }

    func rerollTitle() { title = CorporateTitles.random() }

    /// Build the persistable snapshot (name falls back to "New Hire" if blank).
    var snapshot: AvatarSnapshot {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return AvatarSnapshot(
            name: trimmed.isEmpty ? "New Hire" : trimmed,
            title: title,
            hairStyle: hairStyle,
            skinTone: RGBAColor(skinTone),
            eyeBagsLevel: Double(eyeBagsLevel),
            starterOutfit: starterOutfit,
            equippedAccessories: equippedAccessories
        )
    }
}

// MARK: - Persistence

/// Codable, persisted form of the avatar.
struct AvatarSnapshot: Codable, Equatable {
    var name: String
    var title: String
    var hairStyle: HairStyle
    var skinTone: RGBAColor
    var eyeBagsLevel: Double
    var starterOutfit: StarterOutfit
    var equippedAccessories: [Accessory]

    static let placeholder = AvatarSnapshot(
        name: "New Hire",
        title: "Junior Synergy Facilitator",
        hairStyle: .sideSwept,
        skinTone: SkinTone.presets[1],
        eyeBagsLevel: 0.25,
        starterOutfit: .overdressedRookie,
        equippedAccessories: []
    )
}

/// Tiny UserDefaults-backed store for the saved avatar.
enum AvatarStore {
    private static let key = "player.avatar.v1"

    static func save(_ snapshot: AvatarSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> AvatarSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(AvatarSnapshot.self, from: data)
    }
}

// MARK: - SpriteKit-facing appearance

/// Resolved base look (skin/outfit/hair) the overworld `PlayerNode` reads to
/// mirror the avatar. Equipped wearables are layered on separately so they can
/// update live without rebuilding the base figure.
struct AvatarAppearance {
    var skin: SKColor
    var outfit: SKColor
    var outfitAccent: SKColor
    var hair: SKColor
    var hairStyle: HairStyle
    var eyeBags: CGFloat

    static let hairColor = RGBAColor(0.24, 0.17, 0.13)

    init(_ s: AvatarSnapshot) {
        skin = s.skinTone.sk
        outfit = s.starterOutfit.torso.sk
        outfitAccent = s.starterOutfit.accent.sk
        hair = Self.hairColor.sk
        hairStyle = s.hairStyle
        eyeBags = CGFloat(s.eyeBagsLevel)
    }

    static var fallback: AvatarAppearance { AvatarAppearance(.placeholder) }
}
