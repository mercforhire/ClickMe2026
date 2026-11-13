//
//  ModeSwitchGate.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The one entry point for Mode Switch screens (SIGN-06, D-03).
///
/// Like `PushRoutePlanner` plus its account source, the decision stays in the
/// pure `ExpertModeGate` and in `UserManager.requestModeSwitch` (which itself
/// refuses any switch during a call). This type only adds the in-call alert
/// for a tap. Push handlers do not use it (plan 05-10: no in-call alert on a
/// push replay).
enum ModeSwitchGate {

    /// Asks to switch to `mode` on behalf of a user tap.
    /// - Parameters:
    ///   - mode: The mode the user picked.
    ///   - userManager: The session owner; injectable for previews.
    ///   - callCenter: The call state; injectable for previews.
    /// - Returns: nil when a call was already active (the alert was shown and
    ///   nothing changed), otherwise the request's result.
    @MainActor
    @discardableResult
    static func request(
        _ mode: AppMode,
        userManager: UserManager = .shared,
        callCenter: CallCenter = .shared
    ) async -> UserManager.ModeSwitchResult? {
        guard callCenter.attempt("switch modes") else { return nil }
        let result = await userManager.requestModeSwitch(mode, source: .user)
        if result == .blockedByCall {
            // A call started while the lookup ran: say why nothing changed.
            callCenter.attempt("switch modes")
        }
        return result
    }
}
