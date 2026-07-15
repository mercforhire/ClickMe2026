//
//  SmokeConfig.swift
//  ClickMe2026Tests
//
//  Shared configuration for integration/smoke tests that hit a real backend.
//  Credentials are read from process environment variables so nothing sensitive
//  ends up in source. When these variables are absent, `isEnabled` is `false`
//  and gated tests are skipped instead of failing.
//
//  To run smoke tests locally, set these in your scheme's "Run" → "Arguments" →
//  "Environment Variables":
//
//    CLICKME_TEST_EMAIL    = test-account@example.com
//    CLICKME_TEST_PASSWORD = correct-horse-battery-staple
//

import Foundation
import Testing

enum SmokeConfig {

    static var email: String? {
        ProcessInfo.processInfo.environment["CLICKME_TEST_EMAIL"]
    }

    static var password: String? {
        ProcessInfo.processInfo.environment["CLICKME_TEST_PASSWORD"]
    }

    /// True when at least an email is provided. Used by `.enabled(if:)` to
    /// gate the entire smoke suite.
    static var isEnabled: Bool {
        (email?.isEmpty == false)
    }

    /// True when both credentials are present — required for the happy-path
    /// login test.
    static var hasCredentials: Bool {
        isEnabled && (password?.isEmpty == false)
    }
}

extension Tag {
    /// Tag applied to tests that hit a real backend. Use to filter them in/out.
    @Tag static var integration: Tag
}
