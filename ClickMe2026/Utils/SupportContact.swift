//
//  SupportContact.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The single ClickMe support inbox (SET-02, fixed on main by `cae4090`).
///
/// Help's "Email Us" row and the suspension notice both read it from here.
/// Change the address in this file only; `SupportContactTests` pins the value
/// and a grep gate in plan 05-05 keeps any other Swift file from spelling it.
/// `nonisolated` so the `nonisolated` `SuspensionNotice` can read it.
nonisolated enum SupportContact {
    static let email = "clickmeapp@uptrendinvestments.net"

    /// `mailto:` URL for the support inbox. iOS routes it to whichever mail
    /// client the user has picked as default.
    static var mailtoURL: URL? { URL(string: "mailto:" + email) }
}
