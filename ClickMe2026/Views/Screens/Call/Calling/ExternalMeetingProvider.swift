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

    /// Match on the URL's scheme and host. Case-insensitive; tolerates
    /// missing scheme by trying the raw string as a fallback.
    static func detect(from url: URL?) -> ExternalMeetingProvider {
        guard let url else { return .unknown }
        let scheme = url.scheme?.lowercased() ?? ""
        let host = url.host?.lowercased() ?? ""
        let raw = url.absoluteString.lowercased()

        // Native app schemes are the strongest signal.
        switch scheme {
        case "skype":                 return .skype
        case "zoommtg", "zoomus":     return .zoom
        case "msteams":               return .microsoftTeams
        default: break
        }

        // https:// URLs — inspect host.
        if host.contains("skype.com")             { return .skype }
        if host.contains("zoom.us") || host.contains("zoom.com") { return .zoom }
        if host.contains("meet.google.com")       { return .googleMeet }
        if host.contains("teams.microsoft.com") ||
           host.contains("teams.live.com")        { return .microsoftTeams }

        // Last-ditch — no host but the substring is buried somewhere.
        if raw.contains("skype")     { return .skype }
        if raw.contains("zoom")      { return .zoom }
        if raw.contains("meet.google") { return .googleMeet }
        if raw.contains("teams.")    { return .microsoftTeams }

        return .unknown
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
