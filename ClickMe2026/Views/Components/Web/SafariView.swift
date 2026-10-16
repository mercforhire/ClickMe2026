//
//  SafariView.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SafariServices
import SwiftUI

/// Thin SwiftUI wrapper around `SFSafariViewController` for showing
/// hosted web pages (privacy policy, terms, etc.) inside the app.
/// Keeping users in-process is the Apple-preferred pattern for policy
/// links — reviewers flag external `openURL` jumps on required
/// disclosures.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
