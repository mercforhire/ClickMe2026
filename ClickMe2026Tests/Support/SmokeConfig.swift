//
//  SmokeConfig.swift
//  ClickMe2026Tests
//
//  Shared configuration for integration/smoke tests that hit a real backend.
//  Nothing sensitive ever ends up in source. When credentials are absent the
//  smoke suite is skipped, so default test runs stay green.
//
//  How to provide credentials:
//
//  A. Scheme (recommended for local runs) —
//     Product → Scheme → Edit Scheme → Test → Arguments → Environment
//     Variables. Add:
//         CLICKME_TEST_EMAIL    = you@example.com
//         CLICKME_TEST_PASSWORD = ...
//     Make sure "Expand Variables Based On" points at the app target.
//
//  B. CI via a wrapper script — `scripts/run-smoke-tests.sh` uses
//     `xcrun simctl spawn` with `--env` to inject creds into the test process.
//
//  C. Command-line UserDefaults — the tool also reads from
//     `UserDefaults.standard`, so bundles launched with
//         -CLICKME_TEST_EMAIL you@example.com
//     as process arguments will pick them up. `xcodebuild test` does NOT
//     forward these directly, so this path is only useful when invoking the
//     test binary via `xctest`/`simctl` directly.
//

import Foundation
import Testing

enum SmokeConfig {

    static var email: String? {
        firstNonEmpty(env: "CLICKME_TEST_EMAIL", defaultsKey: "CLICKME_TEST_EMAIL")
    }

    static var password: String? {
        firstNonEmpty(env: "CLICKME_TEST_PASSWORD", defaultsKey: "CLICKME_TEST_PASSWORD")
    }

    /// True when at least an email is provided. Used by `.enabled(if:)` to
    /// gate the entire smoke suite.
    static var isEnabled: Bool { email != nil }

    /// True when both credentials are present — required for the happy-path
    /// login test.
    static var hasCredentials: Bool {
        isEnabled && password != nil
    }

    private static func firstNonEmpty(env: String, defaultsKey: String) -> String? {
        if let v = ProcessInfo.processInfo.environment[env], !v.isEmpty { return v }
        if let v = UserDefaults.standard.string(forKey: defaultsKey), !v.isEmpty { return v }
        return nil
    }
}

extension Tag {
    /// Tag applied to tests that hit a real backend. Use to filter them in/out.
    @Tag static var integration: Tag
}
