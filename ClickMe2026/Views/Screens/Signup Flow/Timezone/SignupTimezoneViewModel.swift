//
//  SignupTimezoneViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class SignupTimezoneViewModel: ObservableObject {

    // MARK: State

    /// IANA identifier (e.g. `"America/Los_Angeles"`). Seeded from the
    /// accumulator on init (which itself defaults to
    /// `TimeZone.current.identifier` — the auto-detected zone).
    @Published var timezoneId: String
    /// Human-readable label matching one of `Timezones.all`.
    @Published var timezoneLabel: String

    // MARK: Dependencies

    private let accumulator: SignupAccumulator?

    // MARK: Init

    /// Preview / test init.
    init(
        timezoneId: String = TimeZone.current.identifier,
        timezoneLabel: String = Timezones.detected().label
    ) {
        self.accumulator = nil
        self.timezoneId = timezoneId
        self.timezoneLabel = timezoneLabel
    }

    /// Runtime init — hydrates from the accumulator and writes changes back.
    init(accumulator: SignupAccumulator) {
        self.accumulator = accumulator
        self.timezoneId = accumulator.timezone
        // Match the seed id to a display label from our curated list.
        // Falls back to the accumulator's raw id if the zone isn't listed
        // (rare; preserves round-trip).
        if let entry = Timezones.all.first(where: { $0.id == accumulator.timezone }) {
            self.timezoneLabel = entry.label
        } else {
            self.timezoneLabel = accumulator.timezone
        }
    }

    // MARK: Mutations

    func select(_ entry: Timezones.Entry) {
        timezoneId = entry.id
        timezoneLabel = entry.label
        accumulator?.timezone = entry.id
    }

    /// Re-detect from the device (useful after travel or if the user
    /// tapped through with a mismatched auto-seed).
    func autoDetect() {
        let entry = Timezones.detected()
        withAnimation(.easeInOut(duration: 0.2)) {
            timezoneId = entry.id
            timezoneLabel = entry.label
        }
        accumulator?.timezone = entry.id
    }
}
