//
//  ExternalMeetingProviderTests.swift
//  ClickMe2026Tests
//
//  Pins host matching for external meeting links (CALL-09). A link is labelled
//  with a provider only when its host is that provider's domain or a dotted
//  subdomain of it; lookalike hosts and bare strings stay `.unknown`.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("ExternalMeetingProvider host matching")
struct ExternalMeetingProviderTests {

    // MARK: - Real provider hosts

    @Test("real provider hosts keep their name", arguments: [
        ("https://zoom.us/j/1", ExternalMeetingProvider.zoom),
        ("https://us02web.zoom.us/j/1", .zoom),
        ("https://ZOOM.US/j/1", .zoom),
        ("https://zoom.com/j/1", .zoom),
        ("https://zoom.us./j/1", .zoom),
        ("https://join.skype.com/abc", .skype),
        ("https://skype.com/abc", .skype),
        ("https://meet.google.com/abc-defg-hij", .googleMeet),
        ("https://teams.microsoft.com/l/x", .microsoftTeams),
        ("https://teams.live.com/x", .microsoftTeams)
    ])
    func realHosts(link: String, expected: ExternalMeetingProvider) {
        #expect(ExternalMeetingProvider.detect(from: URL(string: link)) == expected)
    }

    // MARK: - Lookalike hosts

    @Test("lookalike hosts are not trusted", arguments: [
        "https://evilzoom.us/j/1",
        "https://zoom.us.evil.com/j/1",
        "https://zoom.us@evil.com/j/1",
        "https://notskype.com/abc",
        "https://skype.com.evil.com/abc",
        "https://evilmeet.google.com.evil.com/abc",
        "https://teams.microsoft.com.evil.com/x",
        "https://evil.com/zoom/skype/teams.live.com"
    ])
    func lookalikeHosts(link: String) {
        #expect(ExternalMeetingProvider.detect(from: URL(string: link)) == .unknown)
    }

    // MARK: - Native schemes

    @Test("native app schemes map to their provider", arguments: [
        ("skype:live:abc", ExternalMeetingProvider.skype),
        ("zoommtg://zoom.us/join", .zoom),
        ("zoomus://x", .zoom),
        ("msteams://x", .microsoftTeams)
    ])
    func nativeSchemes(link: String, expected: ExternalMeetingProvider) {
        #expect(ExternalMeetingProvider.detect(from: URL(string: link)) == expected)
    }

    // MARK: - Missing host

    @Test("a URL with no host is unknown")
    func missingHost() {
        #expect(ExternalMeetingProvider.detect(from: URL(string: "zoom.us/j/1")) == .unknown)
    }

    @Test("nil is unknown")
    func nilURL() {
        #expect(ExternalMeetingProvider.detect(from: nil) == .unknown)
    }

    // MARK: - Open button title (CALL-08)

    @Test("the Open button names the provider", arguments: [
        ("https://join.skype.com/abc", "Open in Skype"),
        ("https://us02web.zoom.us/j/1", "Open in Zoom"),
        ("https://meet.google.com/abc-defg-hij", "Open in Google Meet"),
        ("https://teams.microsoft.com/l/x", "Open in Microsoft Teams")
    ])
    func openTitleNamesProvider(link: String, expected: String) {
        #expect(ExternalMeetingProvider.detect(from: URL(string: link)).openButtonTitle == expected)
    }

    @Test("an unrecognized or lookalike host reads Open Meeting, never Open in Meeting", arguments: [
        "https://example.com/room/1",
        "https://evilzoom.us/j/1",
        "https://zoom.us.evil.com/j/1",
        "zoom.us/j/1"
    ])
    func openTitleForUnknownHost(link: String) {
        let title = ExternalMeetingProvider.detect(from: URL(string: link)).openButtonTitle
        #expect(title == "Open Meeting")
    }

    @Test("nil and empty links read Open Meeting")
    func openTitleForMissingLink() {
        #expect(ExternalMeetingProvider.detect(from: nil).openButtonTitle == "Open Meeting")
        #expect(ExternalMeetingProvider.detect(from: URL(string: "")).openButtonTitle == "Open Meeting")
    }
}
