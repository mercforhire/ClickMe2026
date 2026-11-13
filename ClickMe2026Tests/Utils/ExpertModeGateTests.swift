//
//  ExpertModeGateTests.swift
//  ClickMe2026Tests
//
//  SIGN-06 (D-01, D-02, D-03): the Expert-mode gate. An unfinished setup opens
//  the setup hub, a finished one or a failed lookup enters Expert mode (fail
//  open), a stale or signed-out request writes nothing, and no switch is
//  applied while a call is active (single-call invariant).
//
//  `UserManager` cannot be built in tests (private init), so every decision
//  its `requestModeSwitch` makes is a pure `ExpertModeGate` function covered
//  here.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Expert mode gate")
struct ExpertModeGateTests {

    private static let everySetupState: [Bool?] = [nil, false, true]
    private static let everyBool: [Bool] = [false, true]

    // MARK: - decide

    @Test("an unfinished setup opens the hub")
    func incompleteOpensHub() {
        #expect(ExpertModeGate.decide(setupCompleted: false) == .openSetupHub)
    }

    @Test("a finished setup enters Expert")
    func completeEntersExpert() {
        #expect(ExpertModeGate.decide(setupCompleted: true) == .enterExpert)
    }

    @Test("a failed lookup (nil) fails open and enters Expert")
    func failedLookupEntersExpert() {
        #expect(ExpertModeGate.decide(setupCompleted: nil) == .enterExpert)
    }

    // MARK: - setupCompleted(from:)

    @Test("a lookup that throws offline is nil")
    func offlineLookupIsNil() async {
        let result = await ExpertModeGate.setupCompleted {
            throw URLError(.notConnectedToInternet)
        }
        #expect(result == nil)
    }

    @Test("a lookup that returns false is false")
    func lookupFalse() async {
        let result = await ExpertModeGate.setupCompleted { false }
        #expect(result == false)
    }

    @Test("a lookup that returns true is true")
    func lookupTrue() async {
        let result = await ExpertModeGate.setupCompleted { true }
        #expect(result == true)
    }

    @Test("a throwing lookup never yields a stale cached false: the gate enters Expert")
    func staleCacheDoesNotWin() async {
        // Publish does not refresh the cached profile, so the cache can still
        // say "unfinished" after setup was finished in this session.
        let staleCachedValue = false
        let result = await ExpertModeGate.setupCompleted {
            // The network call throws before the cached value could be read.
            try await Self.failBeforeReading()
            return staleCachedValue
        }
        #expect(result == nil)
        #expect(ExpertModeGate.decide(setupCompleted: result) == .enterExpert)
    }

    private static func failBeforeReading() async throws {
        throw URLError(.timedOut)
    }

    // MARK: - resolveSwitch

    @Test("a superseded request is superseded whatever else is true")
    func supersededWinsEverything() {
        for loggedIn in Self.everyBool {
            for call in Self.everyBool {
                for setup in Self.everySetupState {
                    for push in Self.everyBool {
                        let resolution = ExpertModeGate.resolveSwitch(
                            isLatestRequest: false,
                            isLoggedIn: loggedIn,
                            isCallActive: call,
                            setupCompleted: setup,
                            fromPush: push
                        )
                        #expect(resolution == .superseded)
                    }
                }
            }
        }
    }

    @Test("a sign-out during the lookup ends the session before any setup decision")
    func signedOutIsSessionEnded() {
        for call in Self.everyBool {
            for setup in Self.everySetupState {
                for push in Self.everyBool {
                    let resolution = ExpertModeGate.resolveSwitch(
                        isLatestRequest: true,
                        isLoggedIn: false,
                        isCallActive: call,
                        setupCompleted: setup,
                        fromPush: push
                    )
                    #expect(resolution == .sessionEnded)
                }
            }
        }
    }

    @Test("an active call blocks the switch for every setup state and both sources")
    func callActiveIsBlocked() {
        for setup in Self.everySetupState {
            for push in Self.everyBool {
                let resolution = ExpertModeGate.resolveSwitch(
                    isLatestRequest: true,
                    isLoggedIn: true,
                    isCallActive: true,
                    setupCompleted: setup,
                    fromPush: push
                )
                #expect(resolution == .blockedByCall)
            }
        }
    }

    @Test("a push during a call does not switch mode")
    func pushDuringCallIsBlocked() {
        let resolution = ExpertModeGate.resolveSwitch(
            isLatestRequest: true,
            isLoggedIn: true,
            isCallActive: true,
            setupCompleted: true,
            fromPush: true
        )
        #expect(resolution == .blockedByCall)
    }

    @Test("a failed lookup enters Expert")
    func resolveNilEntersExpert() {
        for push in Self.everyBool {
            let resolution = ExpertModeGate.resolveSwitch(
                isLatestRequest: true,
                isLoggedIn: true,
                isCallActive: false,
                setupCompleted: nil,
                fromPush: push
            )
            #expect(resolution == .enterExpert)
        }
    }

    @Test("a finished setup enters Expert")
    func resolveTrueEntersExpert() {
        for push in Self.everyBool {
            let resolution = ExpertModeGate.resolveSwitch(
                isLatestRequest: true,
                isLoggedIn: true,
                isCallActive: false,
                setupCompleted: true,
                fromPush: push
            )
            #expect(resolution == .enterExpert)
        }
    }

    @Test("an unfinished setup from a user tap opens the hub")
    func resolveFalseUserOpensHub() {
        let resolution = ExpertModeGate.resolveSwitch(
            isLatestRequest: true,
            isLoggedIn: true,
            isCallActive: false,
            setupCompleted: false,
            fromPush: false
        )
        #expect(resolution == .setupRequired(opensHub: true))
    }

    @Test("an unfinished setup from a push never opens the hub")
    func resolveFalsePushDoesNotOpenHub() {
        let resolution = ExpertModeGate.resolveSwitch(
            isLatestRequest: true,
            isLoggedIn: true,
            isCallActive: false,
            setupCompleted: false,
            fromPush: true
        )
        #expect(resolution == .setupRequired(opensHub: false))
    }
}
