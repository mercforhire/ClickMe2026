//
//  ExpertModeGate.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The pure decisions behind the Expert-mode gate (SIGN-06, D-01 to D-03).
///
/// `UserManager.requestModeSwitch(_:source:)` owns the state and the network
/// lookup; every decision it makes lives here so it can be tested without a
/// `UserManager` (its init is private). Mirrors Android's `requestModeSwitch`.
enum ExpertModeGate {

    /// What a finished setup lookup means for an Expert switch.
    enum Outcome: Equatable {
        /// Show the Expert home.
        case enterExpert
        /// Show the setup hub so the expert can finish their profile.
        case openSetupHub
    }

    /// Only a lookup that answered "setup is not finished" opens the hub.
    ///
    /// - Parameter setupCompleted: The expert profile's `setup_completed`, or
    ///   nil when the lookup failed (offline, server error). A failed lookup
    ///   fails open and enters Expert, the same as Splash and Android (D-02):
    ///   a finished expert must not be locked out by a bad connection (D-01).
    static func decide(setupCompleted: Bool?) -> Outcome {
        setupCompleted == false ? .openSetupHub : .enterExpert
    }

    /// The only place a failed setup lookup becomes nil (D-02).
    ///
    /// Callers pass a closure that reads the profile only after the network
    /// call has returned, so a profile cached earlier in the session can never
    /// stand in for a failed lookup. That cache can wrongly say "unfinished":
    /// Publish does not refresh it.
    /// - Parameter lookup: Fetches the profile, then returns its `setup_completed`.
    static func setupCompleted(from lookup: () async throws -> Bool?) async -> Bool? {
        do {
            return try await lookup()
        } catch {
            return nil
        }
    }

    /// What an Expert switch resolves to once its lookup has returned.
    enum SwitchResolution: Equatable {
        /// A newer mode request started while this one waited on its lookup.
        /// This result writes nothing; the newer request owns the state.
        case superseded
        /// The user signed out during the lookup. Nothing is written.
        case sessionEnded
        /// A call is active, so no switch is applied (single-call invariant,
        /// 05-CONTEXT; Android `callGuard.attempt(RestrictedAction.SwitchModes)`).
        /// Holds for a user tap and for a push, and raises no alert here.
        case blockedByCall
        /// Persist Expert mode and show the Expert home.
        case enterExpert
        /// Setup is unfinished, so Expert is not entered. `opensHub` is true
        /// only when the user asked: a push never asks for the hub because the
        /// push planner already fails closed on incomplete setup (RESEARCH R5).
        case setupRequired(opensHub: Bool)
    }

    /// Applies the gate's checks in order: superseded, signed out, call
    /// active, then the setup decision.
    /// - Parameters:
    ///   - isLatestRequest: Whether no newer mode request began since this one.
    ///   - isLoggedIn: Whether a session still exists after the lookup.
    ///   - isCallActive: The call state read after the lookup, so a call that
    ///     started while it ran also blocks.
    ///   - setupCompleted: The lookup result; nil means it failed.
    ///   - fromPush: Whether a push, not a user tap, asked for the switch.
    static func resolveSwitch(
        isLatestRequest: Bool,
        isLoggedIn: Bool,
        isCallActive: Bool,
        setupCompleted: Bool?,
        fromPush: Bool
    ) -> SwitchResolution {
        guard isLatestRequest else { return .superseded }
        guard isLoggedIn else { return .sessionEnded }
        guard !isCallActive else { return .blockedByCall }
        switch decide(setupCompleted: setupCompleted) {
        case .enterExpert:
            return .enterExpert
        case .openSetupHub:
            return .setupRequired(opensHub: !fromPush)
        }
    }
}
