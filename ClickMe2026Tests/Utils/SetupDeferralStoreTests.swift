//
//  SetupDeferralStoreTests.swift
//  ClickMe2026Tests
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import Testing
@testable import ClickMe2026

/// SIGN-06 / D-01: the persisted "Not now" on the setup hub. `UserManager`
/// cannot be built in tests (private init), so the flag is tested here and
/// the glue through region-scoped grep gates in plan 05-16.
@MainActor
@Suite("Setup deferral store")
struct SetupDeferralStoreTests {

    /// A fresh, empty `UserDefaults` domain per test, removed by `cleanup`.
    private func makeSuite() -> (defaults: UserDefaults, name: String) {
        let name = "SetupDeferralStoreTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: name) else {
            fatalError("Could not create UserDefaults suite \(name)")
        }
        return (defaults, name)
    }

    private func cleanup(_ name: String) {
        UserDefaults().removePersistentDomain(forName: name)
    }

    @Test("A fresh store is not deferred")
    func freshStoreIsNotDeferred() {
        let (defaults, name) = makeSuite()
        defer { cleanup(name) }

        #expect(SetupDeferralStore(defaults: defaults).isDeferred == false)
    }

    @Test("set() defers, and a second store on the same suite reads it (survives a relaunch)")
    func setPersistsAcrossStores() {
        let (defaults, name) = makeSuite()
        defer { cleanup(name) }

        SetupDeferralStore(defaults: defaults).set()

        #expect(SetupDeferralStore(defaults: defaults).isDeferred == true)
    }

    @Test("clear() ends the deferral for every store on the suite")
    func clearEndsDeferral() {
        let (defaults, name) = makeSuite()
        defer { cleanup(name) }
        let first = SetupDeferralStore(defaults: defaults)
        let second = SetupDeferralStore(defaults: defaults)
        first.set()

        first.clear()

        #expect(first.isDeferred == false)
        #expect(second.isDeferred == false)
    }

    @Test("clear() on a fresh store is harmless")
    func clearWhenNotDeferredIsHarmless() {
        let (defaults, name) = makeSuite()
        defer { cleanup(name) }
        let store = SetupDeferralStore(defaults: defaults)

        store.clear()

        #expect(store.isDeferred == false)
    }

    @Test("The persisted key is setupDeferred")
    func keyIsSetupDeferred() {
        #expect(SetupDeferralStore.key == "setupDeferred")
    }

    @Test("set() writes under the documented key")
    func setWritesUnderKey() {
        let (defaults, name) = makeSuite()
        defer { cleanup(name) }

        SetupDeferralStore(defaults: defaults).set()

        #expect(defaults.bool(forKey: "setupDeferred") == true)
    }
}
