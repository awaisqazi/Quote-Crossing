//
//  GachaEngine.swift
//  Quote Crossing
//
//  Core math for the Swag Vending Machine: base drop rates, pity, 50/50 banner
//  resolution, and duplicate refund calculations.
//

import Foundation

enum GachaRarity: Int, CaseIterable, Codable, Comparable, Identifiable {
    case oneStar = 1
    case twoStar = 2
    case threeStar = 3
    case fourStar = 4
    case fiveStar = 5

    var id: Int { rawValue }

    static func < (lhs: GachaRarity, rhs: GachaRarity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String { "\(rawValue)-Star" }

    var baseProbability: Double {
        switch self {
        case .oneStar: 0.600
        case .twoStar: 0.280
        case .threeStar: 0.090
        case .fourStar: 0.025
        case .fiveStar: 0.005
        }
    }

    var duplicateRefund: GachaRefund {
        switch self {
        case .oneStar:
            GachaRefund(currency: .scrapBasePay, amount: 5)
        case .twoStar:
            GachaRefund(currency: .scrapBasePay, amount: 15)
        case .threeStar:
            GachaRefund(currency: .commishCash, amount: 50)
        case .fourStar:
            GachaRefund(currency: .commishCash, amount: 250)
        case .fiveStar:
            GachaRefund(currency: .spiffCoins, amount: 500)
        }
    }
}

enum GachaRefundCurrency: String, Codable, Equatable {
    case scrapBasePay
    case commishCash
    case spiffCoins

    var label: String {
        switch self {
        case .scrapBasePay: "Scrap"
        case .commishCash: "Commish-Cash"
        case .spiffCoins: "SPIFF Coins"
        }
    }
}

struct GachaRefund: Codable, Equatable {
    let currency: GachaRefundCurrency
    let amount: Int

    var displayText: String {
        switch currency {
        case .scrapBasePay where amount == 5:
            "\(amount) Scrap Base Pay"
        default:
            "\(amount) \(currency.label)"
        }
    }
}

struct GachaItem: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let rarity: GachaRarity
    let wearable: WearableItem
    let isFeaturedBannerItem: Bool
}

enum GachaEngine {
    static let singlePullCost = 100
    static let softPityStart = 70
    static let hardPityPull = 90
    static let softPityStep = 0.025

    struct PityState: Codable, Equatable {
        var pullsSinceFiveStar: Int
        var featuredGuaranteed: Bool
    }

    struct DropRate: Identifiable, Equatable {
        let rarity: GachaRarity
        let probability: Double

        var id: GachaRarity { rarity }
    }

    struct PullResult: Identifiable, Equatable {
        let id = UUID()
        let item: GachaItem
        let rarity: GachaRarity
        let isDuplicate: Bool
        let duplicateRefund: GachaRefund?
        let newPityState: PityState
        let pullNumberSinceFiveStar: Int
        let effectiveFiveStarRate: Double
        let triggeredHardPity: Bool
        let wonFeaturedFlip: Bool?

        var isFiveStar: Bool { rarity == .fiveStar }
    }

    static let featuredBannerItem = GachaItem(
        id: "banner.pearPlatinumHoodie",
        name: "Pear Platinum Hoodie",
        rarity: .fiveStar,
        wearable: WearableItem(
            id: "pearPlatinumHoodie",
            name: "Pear Platinum Hoodie",
            slot: .torso,
            statBoostType: .rep,
            statBoostValue: 18,
            imageIcon: "tshirt.fill",
            tint: RGBAColor(0.96, 0.78, 0.25)
        ),
        isFeaturedBannerItem: true
    )

    static let catalog: [GachaItem] = [
        GachaItem(id: "swag.logoStickerHat", name: "Logo Sticker Hat", rarity: .oneStar,
                  wearable: WearableItem(id: "logoStickerHat", name: "Logo Sticker Hat", slot: .head,
                                         statBoostType: nil, statBoostValue: 0,
                                         imageIcon: "baseball.cap.fill", tint: RGBAColor(0.28, 0.42, 0.66)),
                  isFeaturedBannerItem: false),
        GachaItem(id: "swag.vendorSocks", name: "Vendor Booth Socks", rarity: .oneStar,
                  wearable: WearableItem(id: "vendorBoothSocks", name: "Vendor Booth Socks", slot: .lanyard,
                                         statBoostType: nil, statBoostValue: 0,
                                         imageIcon: "tag.fill", tint: RGBAColor(0.45, 0.50, 0.56)),
                  isFeaturedBannerItem: false),
        GachaItem(id: "swag.qrLanyard", name: "QR Demo Lanyard", rarity: .twoStar,
                  wearable: WearableItem(id: "qrDemoLanyard", name: "QR Demo Lanyard", slot: .lanyard,
                                         statBoostType: .maxBandwidth, statBoostValue: 4,
                                         imageIcon: "lanyardcard.fill", tint: RGBAColor(0.22, 0.58, 0.76)),
                  isFeaturedBannerItem: false),
        GachaItem(id: "swag.apiBeanie", name: "API Partner Beanie", rarity: .twoStar,
                  wearable: WearableItem(id: "apiPartnerBeanie", name: "API Partner Beanie", slot: .head,
                                         statBoostType: .jargon, statBoostValue: 3,
                                         imageIcon: "graduationcap.fill", tint: RGBAColor(0.38, 0.30, 0.62)),
                  isFeaturedBannerItem: false),
        GachaItem(id: "swag.cloudFleece", name: "Cloud Region Fleece", rarity: .threeStar,
                  wearable: WearableItem(id: "cloudRegionFleece", name: "Cloud Region Fleece", slot: .torso,
                                         statBoostType: .maxPatience, statBoostValue: 8,
                                         imageIcon: "tshirt.fill", tint: RGBAColor(0.20, 0.55, 0.80)),
                  isFeaturedBannerItem: false),
        GachaItem(id: "swag.partnerShades", name: "Partner Summit Shades", rarity: .threeStar,
                  wearable: WearableItem(id: "partnerSummitShades", name: "Partner Summit Shades", slot: .eyewear,
                                         statBoostType: .rep, statBoostValue: 5,
                                         imageIcon: "sunglasses.fill", tint: RGBAColor(0.20, 0.18, 0.24)),
                  isFeaturedBannerItem: false),
        GachaItem(id: "swag.presidentBlazer", name: "President's Club Blazer", rarity: .fourStar,
                  wearable: WearableItem(id: "presidentsClubBlazer", name: "President's Club Blazer", slot: .torso,
                                         statBoostType: .rep, statBoostValue: 10,
                                         imageIcon: "tshirt.fill", tint: RGBAColor(0.12, 0.28, 0.48)),
                  isFeaturedBannerItem: false),
        GachaItem(id: "swag.platinumBadge", name: "Platinum Sponsor Badge", rarity: .fourStar,
                  wearable: WearableItem(id: "platinumSponsorBadge", name: "Platinum Sponsor Badge", slot: .lanyard,
                                         statBoostType: .jargon, statBoostValue: 9,
                                         imageIcon: "lanyardcard.fill", tint: RGBAColor(0.78, 0.82, 0.88)),
                  isFeaturedBannerItem: false),
        featuredBannerItem,
        GachaItem(id: "swag.unicornCrown", name: "Unicorn Pipeline Crown", rarity: .fiveStar,
                  wearable: WearableItem(id: "unicornPipelineCrown", name: "Unicorn Pipeline Crown", slot: .head,
                                         statBoostType: .rep, statBoostValue: 16,
                                         imageIcon: "crown.fill", tint: RGBAColor(0.88, 0.42, 0.78)),
                  isFeaturedBannerItem: false)
    ]

    static func effectiveDropTable(for pityState: PityState) -> [DropRate] {
        let upcomingPullNumber = pityState.pullsSinceFiveStar + 1

        if upcomingPullNumber >= hardPityPull {
            return GachaRarity.allCases.map {
                DropRate(rarity: $0, probability: $0 == .fiveStar ? 1.0 : 0.0)
            }
        }

        let softPityBonusSteps = max(0, upcomingPullNumber - softPityStart + 1)
        let fiveStarRate = min(1.0, GachaRarity.fiveStar.baseProbability + Double(softPityBonusSteps) * softPityStep)
        let nonFiveBaseTotal = GachaRarity.allCases
            .filter { $0 != .fiveStar }
            .reduce(0.0) { $0 + $1.baseProbability }
        let nonFiveScale = (1.0 - fiveStarRate) / nonFiveBaseTotal

        return GachaRarity.allCases.map { rarity in
            if rarity == .fiveStar {
                return DropRate(rarity: rarity, probability: fiveStarRate)
            }
            return DropRate(rarity: rarity, probability: rarity.baseProbability * nonFiveScale)
        }
    }

    static func pull(pityState: PityState, ownedItemIDs: Set<String>) -> PullResult {
        var generator = SystemRandomNumberGenerator()
        return pull(pityState: pityState, ownedItemIDs: ownedItemIDs, using: &generator)
    }

    static func pull<R: RandomNumberGenerator>(pityState: PityState,
                                               ownedItemIDs: Set<String>,
                                               using generator: inout R) -> PullResult {
        let pullNumber = pityState.pullsSinceFiveStar + 1
        let table = effectiveDropTable(for: pityState)
        let rarity = rollRarity(from: table, using: &generator)
        let isHardPity = pullNumber >= hardPityPull && rarity == .fiveStar

        let featuredOutcome = resolveFeaturedOutcome(
            rarity: rarity,
            wasFeaturedGuaranteed: pityState.featuredGuaranteed,
            using: &generator
        )
        let item = rollItem(rarity: rarity,
                            forceFeatured: featuredOutcome.isFeatured,
                            using: &generator)
        let isDuplicate = ownedItemIDs.contains(item.wearable.id)
        let refund = isDuplicate ? rarity.duplicateRefund : nil

        var newPity = pityState
        if rarity == .fiveStar {
            newPity.pullsSinceFiveStar = 0
            newPity.featuredGuaranteed = featuredOutcome.lostFlip
        } else {
            newPity.pullsSinceFiveStar = pullNumber
        }

        return PullResult(
            item: item,
            rarity: rarity,
            isDuplicate: isDuplicate,
            duplicateRefund: refund,
            newPityState: newPity,
            pullNumberSinceFiveStar: pullNumber,
            effectiveFiveStarRate: table.first(where: { $0.rarity == .fiveStar })?.probability ?? GachaRarity.fiveStar.baseProbability,
            triggeredHardPity: isHardPity,
            wonFeaturedFlip: featuredOutcome.flipResult
        )
    }

    private static func rollRarity<R: RandomNumberGenerator>(from table: [DropRate],
                                                             using generator: inout R) -> GachaRarity {
        let roll = Double.random(in: 0..<1, using: &generator)
        var cumulative = 0.0

        for entry in table.sorted(by: { $0.rarity < $1.rarity }) {
            cumulative += entry.probability
            if roll < cumulative {
                return entry.rarity
            }
        }

        return .fiveStar
    }

    private static func resolveFeaturedOutcome<R: RandomNumberGenerator>(rarity: GachaRarity,
                                                                         wasFeaturedGuaranteed: Bool,
                                                                         using generator: inout R) -> (isFeatured: Bool, lostFlip: Bool, flipResult: Bool?) {
        guard rarity == .fiveStar else { return (false, wasFeaturedGuaranteed, nil) }
        if wasFeaturedGuaranteed { return (true, false, true) }

        let wonFlip = Bool.random(using: &generator)
        return (wonFlip, !wonFlip, wonFlip)
    }

    private static func rollItem<R: RandomNumberGenerator>(rarity: GachaRarity,
                                                           forceFeatured: Bool,
                                                           using generator: inout R) -> GachaItem {
        if forceFeatured {
            return featuredBannerItem
        }

        let pool = catalog.filter { item in
            item.rarity == rarity && (rarity != .fiveStar || !item.isFeaturedBannerItem)
        }
        return pool.randomElement(using: &generator) ?? catalog.first { $0.rarity == rarity } ?? featuredBannerItem
    }
}
