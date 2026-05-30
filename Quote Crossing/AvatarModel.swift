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
    case buzz, croppedFade, sideSwept, curtainSweep, shag
    case centerPart, longWaves, looseWaves, wavyLob, bluntBob, pixie, highPonytail, softBraid
    case topKnot, curly, texturedCurls, beanie, bald
    var id: String { rawValue }

    var label: String {
        switch self {
        case .buzz: "Buzz"
        case .croppedFade: "Cropped Fade"
        case .sideSwept: "Side-Swept"
        case .curtainSweep: "Curtain Sweep"
        case .shag: "Soft Shag"
        case .centerPart: "Center Part"
        case .longWaves: "Long Waves"
        case .looseWaves: "Loose Waves"
        case .wavyLob: "Wavy Lob"
        case .bluntBob: "Blunt Bob"
        case .pixie: "Pixie"
        case .highPonytail: "High Pony"
        case .softBraid: "Soft Braid"
        case .topKnot:   "Top Knot"
        case .curly:     "Curly"
        case .texturedCurls: "Textured Curls"
        case .beanie:    "Beanie"
        case .bald:      "Chrome Dome"
        }
    }

    static func options(for presentation: AvatarPresentation) -> [HairStyle] {
        switch presentation {
        case .masculine:
            [.buzz, .croppedFade, .sideSwept, .curtainSweep, .shag, .curly, .texturedCurls, .topKnot, .beanie, .bald]
        case .feminine:
            [.centerPart, .longWaves, .looseWaves, .wavyLob, .bluntBob, .pixie, .highPonytail, .softBraid, .curly, .texturedCurls, .beanie]
        case .androgynous:
            [.croppedFade, .curtainSweep, .shag, .centerPart, .wavyLob, .pixie, .topKnot, .curly, .texturedCurls, .beanie, .bald]
        }
    }

    static func defaultStyle(for presentation: AvatarPresentation) -> HairStyle {
        switch presentation {
        case .masculine: .sideSwept
        case .feminine: .longWaves
        case .androgynous: .curtainSweep
        }
    }

    func isAvailable(for presentation: AvatarPresentation) -> Bool {
        Self.options(for: presentation).contains(self)
    }
}

enum AvatarPresentation: String, CaseIterable, Codable, Identifiable {
    case masculine, feminine, androgynous
    var id: String { rawValue }

    var label: String {
        switch self {
        case .masculine: "Male"
        case .feminine: "Female"
        case .androgynous: "Androgynous"
        }
    }

    var shoulderScale: CGFloat {
        switch self {
        case .masculine: 1.08
        case .feminine: 0.94
        case .androgynous: 1.0
        }
    }
}

enum BodyBuild: String, CaseIterable, Codable, Identifiable {
    case slim, standard, athletic, sturdy
    var id: String { rawValue }

    var label: String {
        switch self {
        case .slim: "Slim"
        case .standard: "Standard"
        case .athletic: "Athletic"
        case .sturdy: "Sturdy"
        }
    }

    var widthScale: CGFloat {
        switch self {
        case .slim: 0.90
        case .standard: 1.0
        case .athletic: 1.08
        case .sturdy: 1.18
        }
    }

    var heightScale: CGFloat {
        switch self {
        case .slim: 1.04
        case .standard: 1.0
        case .athletic: 1.02
        case .sturdy: 0.96
        }
    }
}

enum BodyType: String, CaseIterable, Codable, Identifiable {
    case mascLean, mascClassic, mascBroad, mascHeavyset
    case femmePetite, femmeClassic, femmeCurvy, femmeAthletic
    case androLean, androBalanced, androStrong

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mascLean: "Lean"
        case .mascClassic: "Classic"
        case .mascBroad: "Broad"
        case .mascHeavyset: "Heavyset"
        case .femmePetite: "Petite"
        case .femmeClassic: "Classic"
        case .femmeCurvy: "Curvy"
        case .femmeAthletic: "Athletic"
        case .androLean: "Lean"
        case .androBalanced: "Balanced"
        case .androStrong: "Strong"
        }
    }

    static func options(for presentation: AvatarPresentation) -> [BodyType] {
        switch presentation {
        case .masculine:
            [.mascLean, .mascClassic, .mascBroad, .mascHeavyset]
        case .feminine:
            [.femmePetite, .femmeClassic, .femmeCurvy, .femmeAthletic]
        case .androgynous:
            [.androLean, .androBalanced, .androStrong]
        }
    }

    static func defaultType(for presentation: AvatarPresentation) -> BodyType {
        switch presentation {
        case .masculine: .mascClassic
        case .feminine: .femmeClassic
        case .androgynous: .androBalanced
        }
    }

    static func migrated(from build: BodyBuild, presentation: AvatarPresentation) -> BodyType {
        switch presentation {
        case .masculine:
            switch build {
            case .slim: .mascLean
            case .standard: .mascClassic
            case .athletic: .mascBroad
            case .sturdy: .mascHeavyset
            }
        case .feminine:
            switch build {
            case .slim: .femmePetite
            case .standard: .femmeClassic
            case .athletic: .femmeAthletic
            case .sturdy: .femmeCurvy
            }
        case .androgynous:
            switch build {
            case .slim: .androLean
            case .standard: .androBalanced
            case .athletic, .sturdy: .androStrong
            }
        }
    }

    var shoulderScale: CGFloat {
        switch self {
        case .mascLean: 0.98
        case .mascClassic: 1.08
        case .mascBroad: 1.24
        case .mascHeavyset: 1.18
        case .femmePetite: 0.82
        case .femmeClassic: 0.92
        case .femmeCurvy: 0.96
        case .femmeAthletic: 1.04
        case .androLean: 0.92
        case .androBalanced: 1.0
        case .androStrong: 1.12
        }
    }

    var waistScale: CGFloat {
        switch self {
        case .mascLean: 0.82
        case .mascClassic: 0.94
        case .mascBroad: 0.98
        case .mascHeavyset: 1.16
        case .femmePetite: 0.68
        case .femmeClassic: 0.74
        case .femmeCurvy: 0.76
        case .femmeAthletic: 0.82
        case .androLean: 0.76
        case .androBalanced: 0.86
        case .androStrong: 0.96
        }
    }

    var hipScale: CGFloat {
        switch self {
        case .mascLean: 0.86
        case .mascClassic: 0.96
        case .mascBroad: 1.02
        case .mascHeavyset: 1.18
        case .femmePetite: 0.88
        case .femmeClassic: 1.02
        case .femmeCurvy: 1.20
        case .femmeAthletic: 1.04
        case .androLean: 0.84
        case .androBalanced: 0.96
        case .androStrong: 1.08
        }
    }

    var heightScale: CGFloat {
        switch self {
        case .mascLean: 1.05
        case .mascClassic: 1.0
        case .mascBroad: 1.02
        case .mascHeavyset: 0.96
        case .femmePetite: 0.92
        case .femmeClassic: 0.98
        case .femmeCurvy: 0.96
        case .femmeAthletic: 1.03
        case .androLean: 1.04
        case .androBalanced: 1.0
        case .androStrong: 1.02
        }
    }

    var headScale: CGFloat {
        switch self {
        case .femmePetite: 0.96
        case .mascBroad, .mascHeavyset, .androStrong: 1.04
        default: 1.0
        }
    }
}

enum FaceShape: String, CaseIterable, Codable, Identifiable {
    case round, oval, heart, angular, square
    var id: String { rawValue }

    var label: String {
        switch self {
        case .round: "Round"
        case .oval: "Oval"
        case .heart: "Heart"
        case .angular: "Angular"
        case .square: "Square"
        }
    }

    var widthScale: CGFloat {
        switch self {
        case .round: 1.02
        case .oval: 0.95
        case .heart: 0.98
        case .angular: 1.0
        case .square: 1.06
        }
    }

    var heightScale: CGFloat {
        switch self {
        case .round: 0.98
        case .oval: 1.08
        case .heart: 1.04
        case .angular: 1.04
        case .square: 0.96
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .round, .oval: 0.50
        case .heart: 0.44
        case .angular: 0.34
        case .square: 0.28
        }
    }
}

enum AvatarAesthetic: String, CaseIterable, Codable, Identifiable {
    case logoLead, pastelCampus, startupFleece, polishedCloser, streetwearFounder, badgeBoss
    var id: String { rawValue }

    var label: String {
        switch self {
        case .logoLead: "Logo Lead"
        case .pastelCampus: "Pastel Campus"
        case .startupFleece: "Startup Fleece"
        case .polishedCloser: "Polished Closer"
        case .streetwearFounder: "Streetwear Founder"
        case .badgeBoss: "Badge Boss"
        }
    }

    var blurb: String {
        switch self {
        case .logoLead: "Friendly mascot energy."
        case .pastelCampus: "Soft colors, clean lines."
        case .startupFleece: "Low-friction demo day."
        case .polishedCloser: "Buttoned-up boardroom."
        case .streetwearFounder: "Offsite confidence."
        case .badgeBoss: "Tenure as a lifestyle."
        }
    }

    var tint: RGBAColor {
        switch self {
        case .logoLead: RGBAColor(0.50, 0.72, 0.96)
        case .pastelCampus: RGBAColor(0.96, 0.58, 0.78)
        case .startupFleece: RGBAColor(0.32, 0.50, 0.44)
        case .polishedCloser: RGBAColor(0.20, 0.25, 0.42)
        case .streetwearFounder: RGBAColor(0.20, 0.20, 0.27)
        case .badgeBoss: RGBAColor(0.66, 0.88, 0.96)
        }
    }

    func outfit(for presentation: AvatarPresentation) -> StarterOutfit {
        switch self {
        case .logoLead:
            presentation == .feminine ? .campusCasual : .pastelJacket
        case .pastelCampus:
            .campusCasual
        case .startupFleece:
            .techBro
        case .polishedCloser:
            .overdressedRookie
        case .streetwearFounder:
            .quotaHoodie
        case .badgeBoss:
            .executiveBadge
        }
    }

    func hairStyle(for presentation: AvatarPresentation) -> HairStyle {
        switch self {
        case .logoLead:
            presentation == .feminine ? .longWaves : .sideSwept
        case .pastelCampus:
            presentation == .masculine ? .curtainSweep : .looseWaves
        case .startupFleece:
            presentation == .feminine ? .wavyLob : .croppedFade
        case .polishedCloser:
            presentation == .feminine ? .bluntBob : .sideSwept
        case .streetwearFounder:
            presentation == .feminine ? .highPonytail : .beanie
        case .badgeBoss:
            presentation == .feminine ? .softBraid : .beanie
        }
    }

    var hairColor: RGBAColor {
        switch self {
        case .logoLead, .pastelCampus: HairColorPreset.logoBrown.color
        case .startupFleece: HairColorPreset.espresso.color
        case .polishedCloser: HairColorPreset.graphite.color
        case .streetwearFounder: HairColorPreset.plum.color
        case .badgeBoss: HairColorPreset.espresso.color
        }
    }
}

enum HairColorPreset: String, CaseIterable, Identifiable {
    case logoBrown, espresso, plum, copper, blush, graphite, platinum
    var id: String { rawValue }

    var label: String {
        switch self {
        case .logoBrown: "Logo Brown"
        case .espresso: "Espresso"
        case .plum: "Plum"
        case .copper: "Copper"
        case .blush: "Blush"
        case .graphite: "Graphite"
        case .platinum: "Platinum"
        }
    }

    var color: RGBAColor {
        switch self {
        case .logoBrown: RGBAColor(0.33, 0.20, 0.25)
        case .espresso: RGBAColor(0.15, 0.10, 0.10)
        case .plum: RGBAColor(0.25, 0.15, 0.31)
        case .copper: RGBAColor(0.74, 0.34, 0.25)
        case .blush: RGBAColor(0.82, 0.46, 0.55)
        case .graphite: RGBAColor(0.13, 0.14, 0.18)
        case .platinum: RGBAColor(0.82, 0.78, 0.68)
        }
    }
}

enum EyeColorPreset: String, CaseIterable, Identifiable {
    case midnight, brown, hazel, blue, green, violet
    var id: String { rawValue }

    var label: String {
        switch self {
        case .midnight: "Midnight"
        case .brown: "Brown"
        case .hazel: "Hazel"
        case .blue: "Blue"
        case .green: "Green"
        case .violet: "Violet"
        }
    }

    var color: RGBAColor {
        switch self {
        case .midnight: RGBAColor(0.10, 0.10, 0.16)
        case .brown: RGBAColor(0.28, 0.16, 0.11)
        case .hazel: RGBAColor(0.42, 0.31, 0.16)
        case .blue: RGBAColor(0.22, 0.45, 0.70)
        case .green: RGBAColor(0.18, 0.46, 0.34)
        case .violet: RGBAColor(0.43, 0.26, 0.58)
        }
    }
}

enum FacialHairStyle: String, CaseIterable, Codable, Identifiable {
    case none, stubble, mustache, fullBeard
    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: "None"
        case .stubble: "Stubble"
        case .mustache: "Mustache"
        case .fullBeard: "Full Beard"
        }
    }
}

/// Starter wardrobe origin styles (GDD §1).
enum StarterOutfit: String, CaseIterable, Codable, Identifiable {
    case overdressedRookie, techBro, minimalist, pastelJacket, campusCasual, quotaHoodie, executiveBadge
    var id: String { rawValue }

    var label: String {
        switch self {
        case .overdressedRookie: "Overdressed Rookie"
        case .techBro:           "The Tech Bro"
        case .minimalist:        "The Minimalist"
        case .pastelJacket:      "Pastel Jacket"
        case .campusCasual:      "Campus Casual"
        case .quotaHoodie:       "Quota Hoodie"
        case .executiveBadge:    "Badge Boss"
        }
    }

    var blurb: String {
        switch self {
        case .overdressedRookie: "A suit that's slightly too big."
        case .techBro:           "Plaid shirt, standard fleece."
        case .minimalist:        "Black turtleneck. That's it."
        case .pastelJacket:      "Logo-style soft jacket over a clean tee."
        case .campusCasual:      "Pastel top and mint slacks."
        case .quotaHoodie:       "Dark hoodie, huge tenure energy."
        case .executiveBadge:    "Diamond badge, impossible confidence."
        }
    }

    /// Main torso colour.
    var torso: RGBAColor {
        switch self {
        case .overdressedRookie: RGBAColor(0.20, 0.25, 0.42)   // navy suit
        case .techBro:           RGBAColor(0.32, 0.50, 0.44)   // fleece green
        case .minimalist:        RGBAColor(0.13, 0.13, 0.16)   // black turtleneck
        case .pastelJacket:      RGBAColor(0.83, 0.48, 0.57)   // logo rose jacket
        case .campusCasual:      RGBAColor(0.96, 0.58, 0.78)   // pastel top
        case .quotaHoodie:       RGBAColor(0.20, 0.20, 0.27)   // charcoal hoodie
        case .executiveBadge:    RGBAColor(0.31, 0.30, 0.39)   // soft charcoal suit
        }
    }

    /// Collar / tie / zipper accent colour.
    var accent: RGBAColor {
        switch self {
        case .overdressedRookie: RGBAColor(0.86, 0.27, 0.30)   // red tie
        case .techBro:           RGBAColor(0.90, 0.92, 0.95)   // zipper / shirt
        case .minimalist:        RGBAColor(0.24, 0.24, 0.28)   // subtle collar
        case .pastelJacket:      RGBAColor(0.98, 0.96, 0.90)
        case .campusCasual:      RGBAColor(0.68, 0.90, 0.80)
        case .quotaHoodie:       RGBAColor(0.62, 0.86, 0.96)
        case .executiveBadge:    RGBAColor(0.66, 0.88, 0.96)
        }
    }

    /// Lower-body colour used by the full-body avatar render.
    var pants: RGBAColor {
        switch self {
        case .overdressedRookie: RGBAColor(0.18, 0.22, 0.36)
        case .techBro:           RGBAColor(0.60, 0.72, 0.86)
        case .minimalist:        RGBAColor(0.15, 0.15, 0.20)
        case .pastelJacket:      RGBAColor(0.68, 0.82, 0.96)
        case .campusCasual:      RGBAColor(0.65, 0.88, 0.80)
        case .quotaHoodie:       RGBAColor(0.19, 0.19, 0.26)
        case .executiveBadge:    RGBAColor(0.24, 0.23, 0.32)
        }
    }

    var shoes: RGBAColor {
        switch self {
        case .minimalist, .quotaHoodie, .executiveBadge:
            RGBAColor(0.18, 0.12, 0.18)
        case .campusCasual:
            RGBAColor(0.35, 0.24, 0.34)
        default:
            RGBAColor(0.72, 0.38, 0.42)
        }
    }
}

enum CorporatePosture: String, CaseIterable, Codable, Identifiable {
    case eagerIntern, balancedOperator, tenuredSlouch
    var id: String { rawValue }

    var label: String {
        switch self {
        case .eagerIntern: "Eager Intern"
        case .balancedOperator: "Balanced"
        case .tenuredSlouch: "Tenured Slouch"
        }
    }
}

enum CorporateSmile: String, CaseIterable, Codable, Identifiable {
    case genuineJoy, serviceSmirk, deadInside
    var id: String { rawValue }

    var label: String {
        switch self {
        case .genuineJoy: "Genuine Joy"
        case .serviceSmirk: "Service Smirk"
        case .deadInside: "Dead Inside"
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
    @Published var presentation: AvatarPresentation = .masculine
    @Published var bodyBuild: BodyBuild = .standard
    @Published var bodyType: BodyType = .mascClassic
    @Published var faceShape: FaceShape = .round
    @Published var aesthetic: AvatarAesthetic = .logoLead
    @Published var hairStyle: HairStyle = .sideSwept
    @Published var hairColor: Color = HairColorPreset.logoBrown.color.color
    @Published var skinTone: Color = SkinTone.presets[1].color
    @Published var eyeColor: Color = EyeColorPreset.midnight.color.color
    @Published var facialHair: FacialHairStyle = .none
    @Published var eyeBagsLevel: CGFloat = 0.25
    @Published var posture: CorporatePosture = .balancedOperator
    @Published var corporateSmile: CorporateSmile = .serviceSmirk
    @Published var starterOutfit: StarterOutfit = .overdressedRookie
    @Published var equippedAccessories: [Accessory] = []

    init() {}

    /// Re-init from a persisted snapshot (e.g. re-opening the creator).
    init(snapshot s: AvatarSnapshot) {
        name = s.name
        title = s.title
        presentation = s.presentation ?? .masculine
        bodyBuild = s.bodyBuild ?? .standard
        bodyType = s.bodyType ?? BodyType.migrated(from: s.bodyBuild ?? .standard, presentation: presentation)
        faceShape = s.faceShape ?? .round
        aesthetic = s.aesthetic ?? .logoLead
        hairStyle = s.hairStyle
        hairColor = (s.hairColor ?? AvatarAppearance.hairColor).color
        skinTone = s.skinTone.color
        eyeColor = (s.eyeColor ?? EyeColorPreset.midnight.color).color
        facialHair = presentation == .feminine ? .none : (s.facialHair ?? .none)
        eyeBagsLevel = CGFloat(s.eyeBagsLevel)
        posture = s.posture ?? .balancedOperator
        corporateSmile = s.corporateSmile ?? .serviceSmirk
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

    func setPresentation(_ newPresentation: AvatarPresentation) {
        guard presentation != newPresentation else { return }
        presentation = newPresentation
        bodyType = BodyType.defaultType(for: newPresentation)
        if !hairStyle.isAvailable(for: newPresentation) {
            hairStyle = HairStyle.defaultStyle(for: newPresentation)
        }
        if newPresentation == .feminine {
            facialHair = .none
        }
        starterOutfit = aesthetic.outfit(for: newPresentation)
    }

    func applyAesthetic(_ newAesthetic: AvatarAesthetic) {
        aesthetic = newAesthetic
        starterOutfit = newAesthetic.outfit(for: presentation)
        let style = newAesthetic.hairStyle(for: presentation)
        hairStyle = style.isAvailable(for: presentation) ? style : HairStyle.defaultStyle(for: presentation)
        hairColor = newAesthetic.hairColor.color
    }

    /// Build the persistable snapshot (name falls back to "New Hire" if blank).
    var snapshot: AvatarSnapshot {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return AvatarSnapshot(
            name: trimmed.isEmpty ? "New Hire" : trimmed,
            title: title,
            presentation: presentation,
            bodyBuild: bodyBuild,
            bodyType: bodyType,
            faceShape: faceShape,
            aesthetic: aesthetic,
            hairStyle: hairStyle,
            hairColor: RGBAColor(hairColor),
            skinTone: RGBAColor(skinTone),
            eyeColor: RGBAColor(eyeColor),
            facialHair: presentation == .feminine ? .none : facialHair,
            eyeBagsLevel: Double(eyeBagsLevel),
            posture: posture,
            corporateSmile: corporateSmile,
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
    var presentation: AvatarPresentation?
    var bodyBuild: BodyBuild?
    var bodyType: BodyType?
    var faceShape: FaceShape?
    var aesthetic: AvatarAesthetic?
    var hairStyle: HairStyle
    var hairColor: RGBAColor?
    var skinTone: RGBAColor
    var eyeColor: RGBAColor?
    var facialHair: FacialHairStyle?
    var eyeBagsLevel: Double
    var posture: CorporatePosture?
    var corporateSmile: CorporateSmile?
    var starterOutfit: StarterOutfit
    var equippedAccessories: [Accessory]

    static let placeholder = AvatarSnapshot(
        name: "New Hire",
        title: "Junior Synergy Facilitator",
        presentation: .masculine,
        bodyBuild: .standard,
        bodyType: .mascClassic,
        faceShape: .round,
        aesthetic: .logoLead,
        hairStyle: .sideSwept,
        hairColor: HairColorPreset.logoBrown.color,
        skinTone: SkinTone.presets[1],
        eyeColor: EyeColorPreset.midnight.color,
        facialHair: FacialHairStyle.none,
        eyeBagsLevel: 0.25,
        posture: .balancedOperator,
        corporateSmile: .serviceSmirk,
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
    var eye: SKColor
    var hairStyle: HairStyle
    var presentation: AvatarPresentation
    var bodyBuild: BodyBuild
    var bodyType: BodyType
    var faceShape: FaceShape
    var aesthetic: AvatarAesthetic
    var facialHair: FacialHairStyle
    var eyeBags: CGFloat
    var smile: CorporateSmile

    static let hairColor = HairColorPreset.logoBrown.color

    init(_ s: AvatarSnapshot) {
        skin = s.skinTone.sk
        outfit = s.starterOutfit.torso.sk
        outfitAccent = s.starterOutfit.accent.sk
        hair = (s.hairColor ?? Self.hairColor).sk
        eye = (s.eyeColor ?? EyeColorPreset.midnight.color).sk
        hairStyle = s.hairStyle
        presentation = s.presentation ?? .masculine
        bodyBuild = s.bodyBuild ?? .standard
        bodyType = s.bodyType ?? BodyType.migrated(from: bodyBuild, presentation: presentation)
        faceShape = s.faceShape ?? .round
        aesthetic = s.aesthetic ?? .logoLead
        facialHair = presentation == .feminine ? .none : (s.facialHair ?? .none)
        eyeBags = CGFloat(s.eyeBagsLevel)
        smile = s.corporateSmile ?? .serviceSmirk
    }

    static var fallback: AvatarAppearance { AvatarAppearance(.placeholder) }
}
