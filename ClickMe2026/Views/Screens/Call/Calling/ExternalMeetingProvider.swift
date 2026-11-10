//
//  ExternalMeetingProvider.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Which external meeting service a `skype_zoom` URL is for. The
/// backend collapses every non-Agora meeting under one enum bucket,
/// so the client has to sniff the URL to pick the right verb + icon.
///
/// Anything we don't recognize falls through to `.unknown` — the UI
/// then uses generic "Open Meeting" copy so we never mis-label a link.
enum ExternalMeetingProvider {
    case skype
    case zoom
    case googleMeet
    case microsoftTeams
    case unknown

    /// Match on the URL's scheme and host. Matching is case-insensitive.
    ///
    /// A host counts as a provider only when it equals the provider's domain
    /// or is a dotted subdomain of it, so `evilzoom.us` and `zoom.us.evil.com`
    /// stay `.unknown`. A URL without a host (for example the bare string
    /// `zoom.us/j/1`) is `.unknown` too, so the UI falls back to the generic
    /// "Open Meeting" copy.
    static func detect(from url: URL?) -> ExternalMeetingProvider {
        guard let url else { return .unknown }
        let scheme = url.scheme?.lowercased() ?? ""
        let host = url.host?.lowercased() ?? ""

        // Native app schemes are the strongest signal.
        switch scheme {
        case "skype":                 return .skype
        case "zoommtg", "zoomus":     return .zoom
        case "msteams":               return .microsoftTeams
        default: break
        }

        // https:// URLs — inspect host.
        if Self.host(host, isOrEndsWith: "skype.com")             { return .skype }
        if Self.host(host, isOrEndsWith: "zoom.us") ||
           Self.host(host, isOrEndsWith: "zoom.com")              { return .zoom }
        if Self.host(host, isOrEndsWith: "meet.google.com")       { return .googleMeet }
        if Self.host(host, isOrEndsWith: "teams.microsoft.com") ||
           Self.host(host, isOrEndsWith: "teams.live.com")        { return .microsoftTeams }

        return .unknown
    }

    /// True when `host` is `domain` or a subdomain of it. One trailing dot
    /// (the fully qualified form, `zoom.us.`) is ignored.
    private static func host(_ host: String, isOrEndsWith domain: String) -> Bool {
        var normalized = host.lowercased()
        if normalized.hasSuffix(".") { normalized.removeLast() }
        return normalized == domain || normalized.hasSuffix("." + domain)
    }

    /// Display name used in button labels and status text.
    var displayName: String {
        switch self {
        case .skype:          return "Skype"
        case .zoom:           return "Zoom"
        case .googleMeet:     return "Google Meet"
        case .microsoftTeams: return "Microsoft Teams"
        case .unknown:        return "Meeting"
        }
    }

    /// SF Symbol shown next to the "Open in …" button. `.unknown`
    /// falls back to the generic arrow-out icon so we never render a
    /// misleading brand-adjacent glyph.
    var iconSystemName: String {
        switch self {
        case .skype, .zoom, .googleMeet, .microsoftTeams:
            return "video.fill"
        case .unknown:
            return "arrow.up.right.square.fill"
        }
    }
}
