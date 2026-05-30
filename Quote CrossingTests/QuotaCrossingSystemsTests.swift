//
//  QuotaCrossingSystemsTests.swift
//  Quote CrossingTests
//
//  Focused coverage for math-heavy systems from the GDD.
//

import XCTest
import CoreGraphics
@testable import Quote_Crossing

final class QuotaCrossingSystemsTests: XCTestCase {
    func testGachaBaseDropTableAndRefundsMatchDesign() {
        XCTAssertEqual(GachaRarity.oneStar.baseProbability, 0.600, accuracy: 0.0001)
        XCTAssertEqual(GachaRarity.twoStar.baseProbability, 0.280, accuracy: 0.0001)
        XCTAssertEqual(GachaRarity.threeStar.baseProbability, 0.090, accuracy: 0.0001)
        XCTAssertEqual(GachaRarity.fourStar.baseProbability, 0.025, accuracy: 0.0001)
        XCTAssertEqual(GachaRarity.fiveStar.baseProbability, 0.005, accuracy: 0.0001)

        let total = GachaRarity.allCases.reduce(0.0) { $0 + $1.baseProbability }
        XCTAssertEqual(total, 1.0, accuracy: 0.0001)

        XCTAssertEqual(GachaRarity.oneStar.duplicateRefund, GachaRefund(currency: .scrapBasePay, amount: 5))
        XCTAssertEqual(GachaRarity.twoStar.duplicateRefund, GachaRefund(currency: .scrapBasePay, amount: 15))
        XCTAssertEqual(GachaRarity.threeStar.duplicateRefund, GachaRefund(currency: .commishCash, amount: 50))
        XCTAssertEqual(GachaRarity.fourStar.duplicateRefund, GachaRefund(currency: .commishCash, amount: 250))
        XCTAssertEqual(GachaRarity.fiveStar.duplicateRefund, GachaRefund(currency: .spiffCoins, amount: 500))
    }

    func testGachaPityRatesStartAtSeventyAndHardPityAtNinety() {
        XCTAssertEqual(fiveStarRate(afterMisses: 68), 0.005, accuracy: 0.0001)
        XCTAssertEqual(fiveStarRate(afterMisses: 69), 0.030, accuracy: 0.0001)
        XCTAssertEqual(fiveStarRate(afterMisses: 70), 0.055, accuracy: 0.0001)
        XCTAssertEqual(fiveStarRate(afterMisses: 89), 1.000, accuracy: 0.0001)
    }

    func testGuaranteedFeaturedBannerConsumesGuaranteeOnFiveStar() {
        var generator = FixedGenerator()
        let result = GachaEngine.pull(
            pityState: .init(pullsSinceFiveStar: 89, featuredGuaranteed: true),
            ownedItemIDs: [],
            using: &generator
        )

        XCTAssertTrue(result.triggeredHardPity)
        XCTAssertTrue(result.item.isFeaturedBannerItem)
        XCTAssertEqual(result.item.id, GachaEngine.featuredBannerItem.id)
        XCTAssertEqual(result.newPityState.pullsSinceFiveStar, 0)
        XCTAssertFalse(result.newPityState.featuredGuaranteed)
    }

    func testElementalTriangleAndCoreJargonCardsMatchDesign() {
        XCTAssertTrue(JargonElement.cloud.hasAdvantage(over: .hardware))
        XCTAssertTrue(JargonElement.hardware.hasAdvantage(over: .onPrem))
        XCTAssertTrue(JargonElement.onPrem.hasAdvantage(over: .cloud))
        XCTAssertFalse(JargonElement.saas.hasAdvantage(over: .cloud))

        let cards = Dictionary(uniqueKeysWithValues: JargonCard.coreDeck.map { ($0.name, $0) })
        XCTAssertEqual(cards["Move the Needle"]?.cost, 10)
        XCTAssertEqual(cards["Move the Needle"]?.damage, 40)
        XCTAssertEqual(cards["Move the Needle"]?.element, .cloud)
        XCTAssertEqual(cards["Boil the Ocean"]?.cost, 25)
        XCTAssertEqual(cards["Boil the Ocean"]?.damage, 95)
        XCTAssertEqual(cards["Boil the Ocean"]?.element, .saas)
        XCTAssertEqual(cards["Circle Back"]?.cost, 12)
        XCTAssertEqual(cards["Circle Back"]?.healing, 60)
        XCTAssertEqual(cards["Circle Back"]?.element, .hardware)
    }

    func testSharePayloadRoundTripsIntoFriendNPC() {
        let payload = QBRSharePayload(
            name: "Morgan",
            title: "Regional VP of Vibes",
            lifetimeCash: 1_250_000,
            wins: 8,
            losses: 2,
            badgeTier: .diamond,
            outfitIDs: ["pearPlatinumHoodie", "platinumSponsorBadge"]
        )

        let decoded = QBRSharePayload.decode(payload.encodedString)
        XCTAssertEqual(decoded, payload)

        let npc = payload.friendNPC()
        XCTAssertEqual(npc.name, payload.name)
        XCTAssertEqual(npc.badgeTier, .diamond)
        XCTAssertEqual(npc.outfitSummary, "2 flex pieces")
    }

    func testNewGameDoesNotGrantFreeCreatorAccessories() {
        let suiteName = "quota-crossing-inventory-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let inventory = InventoryManager(defaults: defaults)
        inventory.configureForNewGameIfNeeded(starters: [.aviators, .headphones, .lanyard])

        XCTAssertTrue(inventory.ownedItems.isEmpty)
        XCTAssertTrue(inventory.equippedItems.isEmpty)
        XCTAssertFalse(inventory.ownsItem(id: WearableCatalog.aviators.id))
    }

    func testCubicleBuilderUsesSameBoardCoordinatesAsOverworld() {
        let origin = CubicleGridPoint(column: 8, row: 18)
        let footprint = CubicleRoomType.premiumCoffeeBar.footprint
        let worldPosition = OfficeBoard.worldPosition(for: origin, footprint: footprint)

        XCTAssertEqual(worldPosition.x, (CGFloat(8) + 0.5) * GameMetrics.tileSize, accuracy: 0.001)
        XCTAssertEqual(worldPosition.y, (CGFloat(18) + 1.5) * GameMetrics.tileSize, accuracy: 0.001)
        XCTAssertTrue(OfficeBoard.isBuildable(origin))
        XCTAssertFalse(OfficeBoard.isBuildable(OfficeBoard.networkingAnchor))
        XCTAssertEqual(OfficeBoard.tile(at: OfficeBoard.elevator), .elevator)
    }

    func testPlacedCubicleRoomsBecomeWalkableMapEntrances() throws {
        let suiteName = "quota-crossing-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let roomID = UUID()
        let origin = CubicleGridPoint(column: 11, row: 14)
        let placement = TestCubiclePlacement(
            id: roomID,
            type: .saasTestingLab,
            origin: origin,
            durability: 87
        )
        defaults.set(try JSONEncoder().encode([placement]), forKey: CubicleLayoutSummary.saveKey)
        defaults.set(true, forKey: OfficeBoard.mapAlignedLayoutKey)

        let summary = CubicleLayoutSummary.load(defaults: defaults)
        XCTAssertEqual(summary.rooms.count, 1)
        XCTAssertEqual(summary.rooms.first?.id, roomID)
        XCTAssertEqual(summary.rooms.first?.origin, origin)

        let entrance = OfficeEntrance.mapEntrances(layout: summary).first { $0.roomID == roomID }
        XCTAssertEqual(entrance?.route, .qBot)
        XCTAssertEqual(entrance?.roomType, .saasTestingLab)
        XCTAssertEqual(entrance?.gridOrigin, origin)
        XCTAssertEqual(entrance?.destinationRoute, .qBot)
    }

    private func fiveStarRate(afterMisses misses: Int) -> Double {
        GachaEngine.effectiveDropTable(
            for: .init(pullsSinceFiveStar: misses, featuredGuaranteed: false)
        )
        .first { $0.rarity == .fiveStar }?
        .probability ?? 0
    }
}

private struct TestCubiclePlacement: Encodable {
    let id: UUID
    let type: CubicleRoomType
    let origin: CubicleGridPoint
    let durability: Int
}

private struct FixedGenerator: RandomNumberGenerator {
    mutating func next() -> UInt64 { 0 }
}
