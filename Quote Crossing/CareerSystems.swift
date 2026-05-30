//
//  CareerSystems.swift
//  Quote Crossing
//
//  Offline-first progression state for the full Quota Crossing ecosystem.
//

import Foundation
import SwiftUI

enum CareerStep: String, Codable, CaseIterable, Identifiable {
    case badging
    case prospecting
    case pipeDex
    case qBot
    case salesEncounter
    case cubicleBase
    case bidDesk
    case qbrSocial
    case endgame

    var id: String { rawValue }

    var title: String {
        switch self {
        case .badging: "Badge Printed"
        case .prospecting: "Prospecting"
        case .pipeDex: "Pipe-Dex"
        case .qBot: "Q-Bot 3000"
        case .salesEncounter: "Sales Encounter"
        case .cubicleBase: "Cubicle Base"
        case .bidDesk: "Bid Desk"
        case .qbrSocial: "QBR Flex"
        case .endgame: "Platinum Trip"
        }
    }

    var chapter: String {
        switch self {
        case .badging: "Chapter 0"
        case .prospecting: "Chapter 1"
        case .pipeDex: "Chapter 2"
        case .qBot: "Chapter 3"
        case .salesEncounter: "Chapter 4"
        case .cubicleBase: "Chapter 5"
        case .bidDesk: "Chapter 6"
        case .qbrSocial: "Chapter 7"
        case .endgame: "Final Chapter"
        }
    }

    var storyBeat: String {
        switch self {
        case .badging:
            "Print your OmniTech badge and enter the quota floor."
        case .prospecting:
            "Work the Networking Lounge to uncover leads before gatekeepers drain your bandwidth."
        case .pipeDex:
            "Sort fresh prospects into the Pipe-Dex so the pipeline starts producing real opportunities."
        case .qBot:
            "Feed SKUs into Q-Bot 3000 and compile a quote weapon worth taking into battle."
        case .salesEncounter:
            "Use Jargon cards and quote math to wear down an opponent's Skepticism."
        case .cubicleBase:
            "Build a cubicle base that generates resources while protecting the office from incidents."
        case .bidDesk:
            "Slip through Finance patrols to recover margin and turn shaky quotes into bigger payouts."
        case .qbrSocial:
            "Package your wins into a QBR flex card and recruit friend NPCs for the next run."
        case .endgame:
            "Hit the $10M quota gate, defeat the Grumpy Megacorp CFO, and unlock Isla de Sinergia."
        }
    }

    var objective: String {
        switch self {
        case .badging: "Badge complete"
        case .prospecting: "Find your first qualified lead"
        case .pipeDex: "Grow the pipeline board"
        case .qBot: "Compile a battle-ready quote"
        case .salesEncounter: "Win a sales encounter"
        case .cubicleBase: "Place your first base rooms"
        case .bidDesk: "Recover quote margin"
        case .qbrSocial: "Export a QBR flex"
        case .endgame: "Close the $10M finale"
        }
    }

    var route: GameRoute {
        switch self {
        case .badging: .careerHub
        case .prospecting: .prospecting
        case .pipeDex: .pipeDex
        case .qBot: .qBot
        case .salesEncounter: .careerHub
        case .cubicleBase: .cubicleBuilder
        case .bidDesk: .bidDesk
        case .qbrSocial: .qbr
        case .endgame: .endgame
        }
    }
}

struct CareerState: Codable, Equatable {
    var completedStepIDs: Set<String> = [CareerStep.badging.rawValue]
    var lastOpenedRoute: GameRoute = .careerHub

    func isComplete(_ step: CareerStep) -> Bool {
        completedStepIDs.contains(step.rawValue)
    }

    var completionFraction: Double {
        Double(completedStepIDs.count) / Double(CareerStep.allCases.count)
    }

    var nextStep: CareerStep {
        CareerStep.allCases.first { !isComplete($0) } ?? .endgame
    }

    mutating func complete(_ step: CareerStep) {
        completedStepIDs.insert(step.rawValue)
    }
}

struct ProspectingState: Codable, Equatable {
    var scansCompleted: Int = 0
    var leadsFound: Int = 0
    var gatekeeperHits: Int = 0
    var scannerCharges: Int = 3
    var lastLeadName: String = "No lead scanned yet"

    var scannerLabel: String {
        "\(scannerCharges)/3 WiFi scans"
    }
}

struct BidDeskState: Codable, Equatable {
    var runsCompleted: Int = 0
    var marginRecovered: Int = 0
    var timesSpotted: Int = 0
    var lastOutcome: String = "No Bid Desk run filed."
    var bestStealthRating: Int = 0
}

struct ExpenseRunState: Codable, Equatable {
    var boardPosition: Int = 0
    var diceRolls: Int = 0
    var regionalListings: Int = 0
    var revengeList: [String] = []
    var friendNPCs: [FriendNPC] = []
    var lastBoardEvent: String = "Expense Run board is ready."
}

struct TreasuryState: Codable, Equatable {
    var basePayReserve: Int = 2_500
    var cloudIndexUnits: Int = 0
    var hardwareIndexUnits: Int = 0
    var servicesIndexUnits: Int = 0
    var marketDay: Int = 1
    var lastMarketEvent: String = "Markets open flat."

    var portfolioValue: Int {
        basePayReserve + cloudIndexUnits * 120 + hardwareIndexUnits * 95 + servicesIndexUnits * 105
    }
}

struct EndgameState: Codable, Equatable {
    var quotaTarget: Int = 10_000_000
    var cfoDefeated: Bool = false
    var islaUnlocked: Bool = false
    var newGamePlus: Bool = false
    var lastFinaleLog: String = "The Grumpy Megacorp CFO is watching your quota."
}

struct FriendNPC: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var title: String
    var lifetimeCash: Int
    var badgeTier: CardTier
    var outfitSummary: String

    var flexLine: String {
        "\(name) • \(lifetimeCash.formatted(.number.grouping(.automatic)))"
    }
}

struct QBRSharePayload: Codable, Equatable {
    var version: Int = 1
    var name: String
    var title: String
    var lifetimeCash: Int
    var wins: Int
    var losses: Int
    var badgeTier: CardTier
    var outfitIDs: [String]

    var encodedString: String {
        guard let data = try? JSONEncoder().encode(self) else { return "OTS-INVALID" }
        return "OTS-\(data.base64EncodedString())"
    }

    static func decode(_ raw: String) -> QBRSharePayload? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload = trimmed.hasPrefix("OTS-") ? String(trimmed.dropFirst(4)) : trimmed
        guard let data = Data(base64Encoded: payload) else { return nil }
        return try? JSONDecoder().decode(QBRSharePayload.self, from: data)
    }

    func friendNPC() -> FriendNPC {
        FriendNPC(
            id: encodedString,
            name: name,
            title: title,
            lifetimeCash: lifetimeCash,
            badgeTier: badgeTier,
            outfitSummary: outfitIDs.isEmpty ? "Starter loadout" : "\(outfitIDs.count) flex pieces"
        )
    }
}

enum GameRoute: String, Codable, CaseIterable, Identifiable, Equatable, Hashable {
    case careerHub
    case prospecting
    case pipeDex
    case qBot
    case bidDesk
    case cubicleBuilder
    case expenseRun
    case treasury
    case outfitter
    case swagVending
    case wardrobe
    case socialLinks
    case qbr
    case endgame
    case pause

    var id: String { rawValue }

    var title: String {
        switch self {
        case .careerHub: "Career Path"
        case .prospecting: "Prospecting"
        case .pipeDex: "Pipe-Dex"
        case .qBot: "Q-Bot 3000"
        case .bidDesk: "Bid Desk"
        case .cubicleBuilder: "Cubicle Base"
        case .expenseRun: "Expense Run"
        case .treasury: "Treasury"
        case .outfitter: "Outfitter"
        case .swagVending: "Swag Vending"
        case .wardrobe: "Wardrobe"
        case .socialLinks: "Rolodex"
        case .qbr: "QBR Card"
        case .endgame: "Platinum Trip"
        case .pause: "Pause"
        }
    }

    var compactTitle: String {
        switch self {
        case .careerHub: "Career"
        case .prospecting: "Scan"
        case .pipeDex: "Pipe-Dex"
        case .qBot: "Q-Bot"
        case .bidDesk: "Bid Desk"
        case .cubicleBuilder: "Base"
        case .expenseRun: "Expense"
        case .treasury: "Treasury"
        case .outfitter: "Outfit"
        case .swagVending: "Swag"
        case .wardrobe: "Closet"
        case .socialLinks: "Rolodex"
        case .qbr: "QBR"
        case .endgame: "Finale"
        case .pause: "Pause"
        }
    }

    var systemImage: String {
        switch self {
        case .careerHub: "target"
        case .prospecting: "dot.viewfinder"
        case .pipeDex: "funnel.fill"
        case .qBot: "cpu.fill"
        case .bidDesk: "figure.walk.motion"
        case .cubicleBuilder: "building.2.crop.circle.fill"
        case .expenseRun: "dice.fill"
        case .treasury: "chart.line.uptrend.xyaxis"
        case .outfitter: "bag.fill"
        case .swagVending: "gift.fill"
        case .wardrobe: "hanger"
        case .socialLinks: "person.2.wave.2.fill"
        case .qbr: "person.text.rectangle.fill"
        case .endgame: "airplane.departure"
        case .pause: "pause.fill"
        }
    }

    var tint: Color {
        switch self {
        case .careerHub: QuotaOS.Colors.gold
        case .prospecting: QuotaOS.Colors.blue
        case .pipeDex: QuotaOS.Colors.green
        case .qBot: QuotaOS.Colors.orange
        case .bidDesk: QuotaOS.Colors.red
        case .cubicleBuilder: QuotaOS.Colors.teal
        case .expenseRun: QuotaOS.Colors.purple
        case .treasury: QuotaOS.Colors.mint
        case .outfitter: QuotaOS.Colors.pink
        case .swagVending: QuotaOS.Colors.gold
        case .wardrobe: QuotaOS.Colors.teal
        case .socialLinks: QuotaOS.Colors.blue
        case .qbr: QuotaOS.Colors.purple
        case .endgame: QuotaOS.Colors.gold
        case .pause: QuotaOS.Colors.slate
        }
    }
}

extension CubicleRoomType {
    var unlockRoute: GameRoute? {
        switch self {
        case .premiumCoffeeBar: .prospecting
        case .saasTestingLab: .qBot
        case .itHelpDesk: .bidDesk
        case .executiveLounge: .qbr
        case .supplyArchive: .treasury
        }
    }

    var officeRole: String {
        switch self {
        case .premiumCoffeeBar:
            "Keeps field networking fast and funds the early office buildout."
        case .saasTestingLab:
            "Turns SKU experiments into Q-Bot quote weapons."
        case .itHelpDesk:
            "Opens a defensive desk for Bid Desk runs and incident control."
        case .executiveLounge:
            "Hosts QBR flexes, social links, and vendor visits from strong Feng Shui."
        case .supplyArchive:
            "Adds Treasury access, but hurts nearby Feng Shui if placed poorly."
        }
    }

    var unlockSummary: String {
        guard let unlockRoute else { return "Office boost" }
        return "Opens \(unlockRoute.title)"
    }
}

struct CubiclePlacedRoom: Equatable, Identifiable {
    var id: UUID
    var type: CubicleRoomType
    var origin: CubicleGridPoint
    var durability: Int
}

struct CubicleLayoutSummary: Equatable {
    var rooms: [CubiclePlacedRoom]

    var roomTypes: Set<CubicleRoomType> {
        Set(rooms.map(\.type))
    }

    var roomCount: Int {
        rooms.count
    }

    static let saveKey = "player.cubicle.layout.v1"

    static var empty: CubicleLayoutSummary {
        CubicleLayoutSummary(rooms: [])
    }

    static func load(defaults: UserDefaults = .standard) -> CubicleLayoutSummary {
        guard let data = defaults.data(forKey: saveKey),
              let rooms = try? JSONDecoder().decode([SavedCubiclePlacement].self, from: data) else {
            return .empty
        }
        let shouldMapLegacyLayout = !rooms.isEmpty
            && !defaults.bool(forKey: OfficeBoard.mapAlignedLayoutKey)
            && rooms.allSatisfy { room in
                guard let origin = room.origin else { return true }
                return OfficeBoard.isLegacyBuilderOrigin(origin)
        }
        let placedRooms = rooms.enumerated().map { index, room in
            let decodedOrigin = room.origin ?? CubicleGridPoint(column: index % 8, row: index / 8)
            return CubiclePlacedRoom(
                id: room.id ?? UUID(),
                type: room.type,
                origin: shouldMapLegacyLayout ? OfficeBoard.mapAlignedOrigin(fromLegacy: decodedOrigin) : decodedOrigin,
                durability: room.durability ?? 100
            )
        }
        return CubicleLayoutSummary(rooms: placedRooms)
    }

    func unlockRoom(for route: GameRoute) -> CubicleRoomType? {
        switch route {
        case .qBot: .saasTestingLab
        case .bidDesk: .itHelpDesk
        case .treasury: .supplyArchive
        case .qbr, .socialLinks, .expenseRun: .executiveLounge
        default: nil
        }
    }

    func isUnlocked(_ route: GameRoute) -> Bool {
        guard let room = unlockRoom(for: route) else { return true }
        return roomTypes.contains(room)
    }

    func requirementText(for route: GameRoute) -> String? {
        guard let room = unlockRoom(for: route), !roomTypes.contains(room) else { return nil }
        return "Build \(room.displayName)"
    }

    private struct SavedCubiclePlacement: Decodable {
        let id: UUID?
        let type: CubicleRoomType
        let origin: CubicleGridPoint?
        let durability: Int?
    }
}

struct OfficeEntrance: Equatable, Identifiable {
    var route: GameRoute
    var title: String
    var subtitle: String
    var requirement: String?
    var roomID: UUID? = nil
    var roomType: CubicleRoomType? = nil
    var gridOrigin: CubicleGridPoint? = nil

    var id: String { roomID?.uuidString ?? route.rawValue }
    var isLocked: Bool { requirement != nil }
    var isRoomFixture: Bool { roomID != nil }
    var destinationRoute: GameRoute { isLocked ? .cubicleBuilder : route }
    var ctaTitle: String { isLocked ? "Build Room" : "Enter \(title)" }
    var ctaSubtitle: String { requirement ?? subtitle }

    static func mapEntrances(layout: CubicleLayoutSummary) -> [OfficeEntrance] {
        var entrances = [
            OfficeEntrance(route: .prospecting,
                           title: "Networking",
                           subtitle: "Field leads in the grass",
                           requirement: nil),
            OfficeEntrance(route: .cubicleBuilder,
                           title: "Cubicle Base",
                           subtitle: "\(layout.roomCount) rooms built",
                           requirement: nil),
            OfficeEntrance(route: .pipeDex,
                           title: "Pipe-Dex",
                           subtitle: "Pipeline board",
                           requirement: nil)
        ]

        entrances += layout.rooms.compactMap { room in
            guard let route = room.type.unlockRoute else { return nil }
            return OfficeEntrance(
                route: route,
                title: room.type.shortName,
                subtitle: room.type.unlockSummary,
                requirement: nil,
                roomID: room.id,
                roomType: room.type,
                gridOrigin: room.origin
            )
        }

        return entrances
    }
}
