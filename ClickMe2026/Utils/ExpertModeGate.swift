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

    // MARK: - Launch and login landing

    /// Whether launch or login should look up the expert's setup state
    /// (D-01, D-04; Android `isExpert && !setupDeferred`, plus the stored
    /// Expert case).
    ///
    /// The lookup is a `GET /expert/*` call, which the server answers by
    /// promoting a client-only account through `ensureExpert`. So a client-only
    /// account that is not in Expert mode must not trigger it. A stored Expert
    /// mode counts as consent: the user chose Expert earlier (build 6 let
    /// anyone), so an unfinished profile opens the hub, not an empty dashboard.
    /// - Parameters:
    ///   - isExpert: Whether the account's roles include expert.
    ///   - storedModeIsExpert: Whether a persisted mode exists and is Expert.
    ///   - deferred: Whether the user chose Not now on the hub (D-01).
    static func shouldCheckSetupAtLaunch(isExpert: Bool, storedModeIsExpert: Bool, deferred: Bool) -> Bool {
        !deferred && (isExpert || storedModeIsExpert)
    }

    /// Whether the landing decision needs the expert's topic count (D-04).
    ///
    /// `expertHasTopics()` is a `GET /expert/*` call, so it is made only on a
    /// first boot (no stored mode) and only for an expert; a client-only
    /// account is never sent to the expert endpoints.
    /// - Parameters:
    ///   - hasStoredPreference: Whether a mode was persisted for this login.
    ///   - isExpert: Whether the account's roles include expert.
    static func shouldLookUpTopics(hasStoredPreference: Bool, isExpert: Bool) -> Bool {
        !hasStoredPreference && isExpert
    }

    /// The home mode Splash and Login land on once setup is not in the way.
    ///
    /// A stored mode is restored as is (Mode Switch allows either mode
    /// whatever the role). With no stored mode, Expert only for an expert with
    /// at least one topic: an empty Expert dashboard is worse than client home.
    /// - Parameters:
    ///   - hasStoredPreference: Whether a mode was persisted for this login.
    ///   - storedMode: The persisted mode, read only when `hasStoredPreference`.
    ///   - isExpert: Whether the account's roles include expert.
    ///   - hasTopics: Whether the expert has a topic; false when not looked up.
    static func landingMode(
        hasStoredPreference: Bool,
        storedMode: AppMode,
        isExpert: Bool,
        hasTopics: Bool
    ) -> AppMode {
        if hasStoredPreference { return storedMode }
        return isExpert && hasTopics ? .expert : .client
    }

    // MARK: - Foreground re-check

    /// What the foreground re-check does with a pending setup check.
    enum RecheckDecision: Equatable {
        /// Nothing is pending.
        case none
        /// The roles are not known yet (the launch kept the token but `/me`
        /// was unreachable). Keep the flag and make no request.
        case wait
        /// The check no longer applies. Drop the flag and make no request.
        case clearPending
        /// Look up the setup state now.
        case check
    }

    /// Whether a pending setup check is retried when the app returns to the
    /// foreground (D-02; Android `recheckSetupIfPending`).
    ///
    /// The retry is a `GET /expert/*` call, which the server answers by
    /// promoting a client-only account through `ensureExpert`. Nothing in the
    /// background may do that, so a client-only account outside Expert mode
    /// clears the flag without a request (D-04, Android's role guard). A
    /// deferred setup (Not now) is never re-checked (D-01).
    /// - Parameters:
    ///   - pending: Whether a launch or login lookup failed, or the roles were unknown.
    ///   - deferred: Whether the user chose Not now on the hub.
    ///   - roles: The account's roles, or nil when `/me` has not loaded.
    ///   - mode: The current app mode.
    static func recheckDecision(pending: Bool, deferred: Bool, roles: [UserRole]?, mode: AppMode) -> RecheckDecision {
        guard pending else { return .none }
        guard !deferred else { return .clearPending }
        guard let roles else { return .wait }
        return roles.contains(.expert) || mode == .expert ? .check : .clearPending
    }
}
