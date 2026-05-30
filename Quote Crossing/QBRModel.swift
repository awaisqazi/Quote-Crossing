//
//  QBRModel.swift
//  Quote Crossing
//
//  Data for the "Quarterly Brag Report" (QBR) Digital Business Card (GDD §3).
//  Card rarity upgrades automatically as Lifetime Commish-Cash grows.
//

import SwiftUI

/// Card finish tiers — upgrade automatically at lifetime-earnings milestones.
enum CardTier: Int, CaseIterable, Comparable, Codable {
    case matte, glossy, holographic, diamond

    static func < (a: CardTier, b: CardTier) -> Bool { a.rawValue < b.rawValue }

    static func tier(forLifetime cash: Int) -> CardTier {
        switch cash {
        case ..<3_000:  .matte
        case ..<8_000:  .glossy
        case ..<20_000: .holographic
        default:        .diamond
        }
    }

    var displayName: String {
        switch self {
        case .matte:       "Matte Cardstock"
        case .glossy:      "Glossy Finish"
        case .holographic: "Holographic Foil"
        case .diamond:     "Diamond Tier"
        }
    }

    var isFoil: Bool { self >= .holographic }

    /// Accent colour for borders / labels.
    var accent: Color {
        switch self {
        case .matte:       Color(red: 0.62, green: 0.66, blue: 0.74)
        case .glossy:      Color(red: 0.40, green: 0.66, blue: 0.98)
        case .holographic: Color(red: 0.75, green: 0.55, blue: 0.98)
        case .diamond:     Color(red: 0.70, green: 0.92, blue: 1.0)
        }
    }
}

/// Snapshot of the player data shown on the card.
struct QBRStats {
    var name: String
    var title: String
    var lifetimeCash: Int
    var wins: Int
    var losses: Int
    var tier: CardTier
    var fiscalLabel: String
    var deskPlantStatus: String

    var battles: Int { wins + losses }
    var winRate: Double { battles == 0 ? 0 : Double(wins) / Double(battles) }
    var winRateText: String { battles == 0 ? "—" : "\(Int((winRate * 100).rounded()))%" }
    var record: String { "\(wins)W · \(losses)L" }
    var friendString: String { StableFriendCode.make(name: name, title: title) }
}

/// Persists the lifetime/career stats shown on the QBR across launches.
enum StatsStore {
    private static let key = "player.stats.v1"

    struct Snapshot: Codable {
        var commishCash: Int
        var lifetimeCommishCash: Int
        var wins: Int
        var losses: Int
        var fiscalYearStartedAt: Date?
        var spiffCoins: Int?
        var scrapBasePay: Int?
        var gachaPullsSinceFiveStar: Int?
        var gachaFeaturedGuaranteed: Bool?
        var career: CareerState?
        var prospecting: ProspectingState?
        var bidDesk: BidDeskState?
        var expenseRun: ExpenseRunState?
        var treasury: TreasuryState?
        var endgame: EndgameState?
    }

    static func save(_ snapshot: Snapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }
}

private enum StableFriendCode {
    private static let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    static func make(name: String, title: String) -> String {
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in "\(name)|\(title)".utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }

        var value = hash
        var code: [Character] = []
        for _ in 0..<6 {
            let index = Int(value % UInt64(alphabet.count))
            code.append(alphabet[index])
            value /= UInt64(alphabet.count)
        }
        return "OTS-\(String(code))"
    }
}
