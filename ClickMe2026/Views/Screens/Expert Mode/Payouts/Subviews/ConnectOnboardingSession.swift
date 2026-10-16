//
//  ConnectOnboardingSession.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import AuthenticationServices
import SwiftUI
import UIKit

/// Presents the Stripe Connect Account Link URL in an in-app Safari
/// session (`ASWebAuthenticationSession`) and closes automatically when
/// Safari navigates to a `clickme://…` URL.
///
/// Why this two-step scheme dance is necessary:
///
///  * Stripe's Account Link API only accepts publicly reachable `https`
///    URLs for `return_url` / `refresh_url` — it rejects `clickme://`
///    with 400 `url_invalid`.
///  * `ASWebAuthenticationSession`'s `.customScheme("clickme")` callback
///    only intercepts navigation to `clickme://…`, not to https URLs.
///
/// The gap is bridged by the backend serving a minimal HTTP 302 at
/// `/connect/return` and `/connect/refresh` that redirects to the
/// corresponding `clickme://` URL. Safari attempts the custom-scheme
/// navigation, `ASWebAuthenticationSession` intercepts, closes, and
/// delivers the URL back to the completion handler — all without the
/// user ever leaving the app.
@MainActor
final class ConnectOnboardingSession: NSObject, ASWebAuthenticationPresentationContextProviding {

    /// Callback URL scheme registered under `CFBundleURLTypes` in
    /// Info.plist. The backend's /connect/return and /connect/refresh
    /// routes issue 302 redirects to `\(scheme)://connect/return` and
    /// `\(scheme)://connect/refresh` respectively.
    private static let scheme = "clickme"

    /// Held for the lifetime of the presentation — releasing the
    /// session mid-flight cancels the sheet.
    private var current: ASWebAuthenticationSession?

    /// Starts the session. `onFinish` fires exactly once with:
    ///  * `.completed(url)` — Safari hit the callback scheme; caller
    ///    should refresh connect status. If the URL path was
    ///    `/refresh` (link expired mid-flow), caller can immediately
    ///    mint a new link and re-start.
    ///  * `.cancelled` — user dismissed the sheet or ASWeb errored.
    func start(url: URL, onFinish: @escaping (Outcome) -> Void) {
        let session = ASWebAuthenticationSession(
            url: url,
            callback: .customScheme(Self.scheme)
        ) { [weak self] callbackURL, error in
            self?.current = nil
            if let callbackURL {
                onFinish(.completed(callbackURL))
            } else {
                onFinish(.cancelled(error))
            }
        }
        session.presentationContextProvider = self
        // Fresh cookies each time — the previous onboarding session's
        // Stripe state should not carry over.
        session.prefersEphemeralWebBrowserSession = true
        current = session
        session.start()
    }

    enum Outcome {
        case completed(URL)
        case cancelled(Error?)
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding

    nonisolated func presentationAnchor(
        for session: ASWebAuthenticationSession
    ) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })
                ?? ASPresentationAnchor()
        }
    }
}

// MARK: - Path helper

extension URL {
    /// True when this URL is the Stripe Connect refresh callback (as
    /// opposed to the completion callback). Backends 302 the refresh
    /// path to `clickme://connect/refresh`.
    var isConnectRefresh: Bool {
        host == "connect" && path == "/refresh"
    }
}
