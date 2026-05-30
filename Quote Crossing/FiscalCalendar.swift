//
//  FiscalCalendar.swift
//  Quote Crossing
//
//  GDD §4 "The Fiscal Calendar": one real-world minute advances one in-game
//  hour. The year is split into four quarters; Q4 becomes the EOQ Blizzard,
//  raising stakes for encounters and payouts.
//

import Foundation

enum FiscalQuarter: Int, CaseIterable, Codable {
    case q1 = 1, q2, q3, q4

    var label: String { "Q\(rawValue)" }

    var title: String {
        switch self {
        case .q1: "Pipeline Kickoff"
        case .q2: "Forecast Season"
        case .q3: "Procurement Fog"
        case .q4: "EOQ Blizzard"
        }
    }
}

struct FiscalMoment: Equatable {
    let totalGameHours: Int

    var fiscalYear: Int {
        (totalGameHours / FiscalCalendar.hoursPerFiscalYear) + 1
    }

    var quarter: FiscalQuarter {
        let index = (totalGameHours / FiscalCalendar.hoursPerQuarter) % FiscalQuarter.allCases.count
        return FiscalQuarter(rawValue: index + 1) ?? .q1
    }

    var hoursIntoQuarter: Int {
        totalGameHours % FiscalCalendar.hoursPerQuarter
    }

    var dayOfQuarter: Int {
        (hoursIntoQuarter / 24) + 1
    }

    var weekOfQuarter: Int {
        ((dayOfQuarter - 1) / 7) + 1
    }

    var hourOfDay: Int {
        (FiscalCalendar.startHour + totalGameHours) % 24
    }

    var isEOQBlizzard: Bool {
        quarter == .q4
    }

    var commissionMultiplier: Double {
        isEOQBlizzard ? 1.5 : 1.0
    }

    var skepticismMultiplier: Double {
        isEOQBlizzard ? 2.0 : 1.0
    }

    var hudLabel: String {
        "\(quarter.label) W\(weekOfQuarter) D\(dayOfQuarter)"
    }

    var clockText: String {
        String(format: "%02d:00", hourOfDay)
    }

    var qbrLabel: String {
        "\(quarter.label) FY\(fiscalYear) - \(quarter.title)"
    }

    func adjustedReward(_ baseReward: Int) -> Int {
        Int((Double(baseReward) * commissionMultiplier).rounded())
    }

    func adjustedSkepticism(_ baseSkepticism: Int) -> Int {
        Int((Double(baseSkepticism) * skepticismMultiplier).rounded())
    }
}

enum FiscalCalendar {
    static let secondsPerGameHour: TimeInterval = 60
    static let startHour = 9
    static let weeksPerQuarter = 13
    static let hoursPerQuarter = weeksPerQuarter * 7 * 24
    static let hoursPerFiscalYear = hoursPerQuarter * FiscalQuarter.allCases.count

    static func moment(startedAt: Date, now: Date) -> FiscalMoment {
        let elapsed = max(0, now.timeIntervalSince(startedAt))
        return FiscalMoment(totalGameHours: Int(elapsed / secondsPerGameHour))
    }
}
