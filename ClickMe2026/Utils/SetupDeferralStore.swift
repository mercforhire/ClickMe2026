//
//  SetupDeferralStore.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The persisted "Not now" on the expert setup hub (SIGN-06, D-01).
///
/// Set when the user leaves the hub without publishing. Cleared on every
/// sign-out (so it never reaches the next account on the device), on Publish,
/// and when the user asks for Expert again.
final class SetupDeferralStore {

    /// UserDefaults key holding the flag.
    static let key = "setupDeferred"

    private let defaults: UserDefaults

    /// - Parameter defaults: Injectable so tests use an isolated suite.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Whether the user chose Not now and has not since ended the deferral.
    var isDeferred: Bool {
        defaults.bool(forKey: Self.key)
    }

    /// Stores the deferral.
    func set() {
        defaults.set(true, forKey: Self.key)
    }

    /// Ends the deferral.
    func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}
