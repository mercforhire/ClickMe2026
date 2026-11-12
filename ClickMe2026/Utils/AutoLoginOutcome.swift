//
//  AutoLoginOutcome.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Whether a cold launch ends signed in or signed out (D-13).
///
/// `UserManager.tryAutoLogin()` classifies the result of its `/me` refresh
/// into a `RefreshResult` and asks `resolve` what to do. A 403
/// `ACCOUNT_SUSPENDED` used to fall into the transient-failure branch after
/// the suspension handler had already logged the user out, so the splash
/// routed a session-less user to a home shell and the suspension message
/// never appeared. A suspension now resolves to `signedOut`, like any other
/// rejected credential, and the splash routes to Login.
nonisolated enum AutoLoginOutcome: Equatable {
    case signedIn
    case signedOut

    /// How the `/me` refresh on a cold launch ended.
    enum RefreshResult: Equatable {
        /// `/me` answered; the session is valid.
        case succeeded
        /// 401, or a 403 that is not a suspension: the stored token is dead.
        case authRejected
        /// 403 `ACCOUNT_SUSPENDED`: the account may not use the app.
        case suspended
        /// Network error, 5xx or timeout: the session may still be valid, so
        /// the stored token is kept (offline tolerance).
        case transientFailure
    }

    /// The launch outcome for a stored-token state and a refresh result.
    /// - Parameters:
    ///   - hadStoredToken: Whether the keychain held a token at launch.
    ///   - refresh: How the `/me` refresh ended. Ignored without a token.
    static func resolve(hadStoredToken: Bool, refresh: RefreshResult) -> AutoLoginOutcome {
        guard hadStoredToken else { return .signedOut }
        switch refresh {
        case .succeeded, .transientFailure:
            return .signedIn
        case .authRejected, .suspended:
            return .signedOut
        }
    }
}
