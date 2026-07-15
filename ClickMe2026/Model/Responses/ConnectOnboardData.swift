//
//  ConnectOnboardData.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Response payload for `POST /expert/connect/onboard`.
///
/// Fresh Stripe hosted Account Link URL for the expert to complete KYC +
/// bank onboarding in an in-app browser / webview. The URL is single-use
/// and expires in ~5 minutes — always call this endpoint immediately
/// before presenting; never cache the returned value.
struct ConnectOnboardData: Decodable {
    /// Hosted Stripe Account Link URL. Open in an in-app browser (e.g.
    /// `SFSafariViewController`) or webview.
    let url: String
}
