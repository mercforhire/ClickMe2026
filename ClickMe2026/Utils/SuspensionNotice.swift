//
//  SuspensionNotice.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The "account suspended" alert shown once on Login (D-13).
///
/// Copy is fixed by 04-UI-SPEC (Suspension on cold launch) and taken from
/// Android's `suspended_title` and `suspended_body`, with the support address
/// from SET-02. Android's `suspended_ok` button reads `OK`; iOS uses the
/// UI-SPEC label `Close Alert`, and the difference is logged, not aligned.
nonisolated enum SuspensionNotice {
    static let title = "Your account has been suspended"
    static let message = "You can't use ClickMe with this account right now. If you think this is a mistake, contact \(SupportContact.email)."
    static let dismissLabel = "Close Alert"

    /// Whether Login should raise the alert now. True only while the account
    /// is flagged as suspended and this appearance has not shown it yet.
    /// Dismissing the alert clears the flag, so a later fresh sign-in reads
    /// `wasSuspended == false` and never sees it again.
    static func shouldPresent(wasSuspended: Bool, alreadyPresented: Bool) -> Bool {
        wasSuspended && !alreadyPresented
    }
}
