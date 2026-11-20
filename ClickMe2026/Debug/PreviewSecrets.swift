//
//  PreviewSecrets.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Bearer tokens consumed only by SwiftUI Previews (the `LiveFetch*Bootstrap`
/// structs scattered across the preview files).
///
/// This file is tracked so a clean checkout compiles (D-25): `#Preview` bodies
/// are compiled in Release, so the type has to exist everywhere. It holds no
/// token. In DEBUG each value is read from an environment variable, then from
/// the gitignored repo-root `PreviewSecrets.local.json` (keys
/// `clientBearerToken` and `expertBearerToken`). That file sits outside the
/// synchronized `ClickMe2026/` folder, so it is never bundled. In Release both
/// values are `nil` and no file or environment read is compiled.
enum PreviewSecrets {

    /// Client-role JWT used by `#Preview("Live Fetch")` blocks that hit
    /// `/client/*` endpoints (Explore, Search, Favorites, Expert Profile,
    /// Expert Reviews, Make-a-Booking). Environment variable
    /// `CLICKME_PREVIEW_CLIENT_TOKEN`, or `clientBearerToken` in the local file.
    static let clientBearerToken: String? = {
        #if DEBUG
        token(env: "CLICKME_PREVIEW_CLIENT_TOKEN", key: "clientBearerToken")
        #else
        nil
        #endif
    }()

    /// Expert-role JWT used by expert-side previews (availability editor,
    /// bookings inbox, etc.). Environment variable
    /// `CLICKME_PREVIEW_EXPERT_TOKEN`, or `expertBearerToken` in the local file.
    static let expertBearerToken: String? = {
        #if DEBUG
        token(env: "CLICKME_PREVIEW_EXPERT_TOKEN", key: "expertBearerToken")
        #else
        nil
        #endif
    }()

    #if DEBUG
    /// Environment variable first, then the local JSON file. Best effort: a
    /// missing or unreadable file is the normal state on a clean checkout, so
    /// every failure yields `nil` and the live-fetch previews just stay empty.
    private static func token(env: String, key: String) -> String? {
        if let value = clean(ProcessInfo.processInfo.environment[env]) {
            return value
        }
        // <repo>/ClickMe2026/Debug/PreviewSecrets.swift -> <repo>/
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = repoRoot.appendingPathComponent("PreviewSecrets.local.json")
        guard
            let data = try? Data(contentsOf: fileURL),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return clean(object[key] as? String)
    }

    private static func clean(_ raw: String?) -> String? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
    #endif
}
