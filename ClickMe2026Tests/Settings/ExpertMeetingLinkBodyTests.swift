//
//  ExpertMeetingLinkBodyTests.swift
//  ClickMe2026Tests
//
//  CR-01 / BACK-04: the meeting-link body rule for `PATCH /expert/profile`.
//  An expert with no link never sends the key, a set or changed link goes out
//  trimmed, and a link the server holds that the user cleared goes out as "".
//  A non-nil body always carries `meeting_url`, because
//  `{"professional_details":{}}` is a server no-op that still answers 200.
//
//  Every baseline is a literal, so no row builds the view model or reads
//  `UserManager.shared`; none depends on what the shared manager holds in the
//  test host.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Expert meeting link body")
struct ExpertMeetingLinkBodyTests {

    // MARK: - Fixtures

    private static let zoom = "https://zoom.us/j/123"
    private static let meet = "https://meet.google.com/abc-defg-hij"

    private static func body(_ current: String, _ baseline: String) -> UpdateExpertProfileRequest? {
        ExpertProfileSettingsViewModel.meetingLinkBody(current: current, baseline: baseline)
    }

    /// Every (current, baseline) pair the rule is tabled over.
    private static let pairs: [(current: String, baseline: String)] = [
        ("", ""),
        (" \n", ""),
        (" https://zoom.us/j/123 \n", "https://zoom.us/j/123"),
        ("  https://zoom.us/j/123 ", ""),
        ("https://meet.google.com/abc-defg-hij", "https://zoom.us/j/123"),
        ("", "https://zoom.us/j/123"),
        ("  \n ", "https://zoom.us/j/123")
    ]

    // MARK: - Rows

    @Test("no link on the server and the field left empty sends nothing")
    func unchangedEmptySendsNothing() {
        #expect(Self.body("", "") == nil)
        #expect(Self.body(" \n", "") == nil)
    }

    @Test("spaces around an unchanged link send nothing")
    func whitespaceAroundUnchangedLinkSendsNothing() {
        #expect(Self.body(" https://zoom.us/j/123 \n", Self.zoom) == nil)
    }

    @Test("a link set from empty is sent trimmed")
    func setFromEmptyIsTrimmed() throws {
        let body = try #require(Self.body("  https://zoom.us/j/123 ", ""))

        #expect(body.professionalDetails?.meetingUrl == Self.zoom)
    }

    @Test("a changed link sends the new one")
    func changedLinkSendsNewOne() throws {
        let body = try #require(Self.body(Self.meet, Self.zoom))

        #expect(body.professionalDetails?.meetingUrl == Self.meet)
    }

    @Test("clearing a set link sends an empty string (BACK-04)")
    func clearingSendsEmptyString() throws {
        let cleared = try #require(Self.body("", Self.zoom))
        let blank = try #require(Self.body("  \n ", Self.zoom))

        #expect(cleared.professionalDetails?.meetingUrl == "")
        #expect(blank.professionalDetails?.meetingUrl == "")
    }

    @Test("a meeting-link body is never an empty professional_details")
    func neverAnEmptyProfessionalDetails() {
        for pair in Self.pairs {
            guard let body = Self.body(pair.current, pair.baseline) else { continue }
            #expect(body.professionalDetails?.meetingUrl != nil)
        }
    }

    @Test("the body carries only the meeting link")
    func bodyCarriesOnlyTheMeetingLink() throws {
        let body = try #require(Self.body("", Self.zoom))

        #expect(body.personalInfo == nil)
        #expect(body.locationDetails == nil)
        #expect(body.languages == nil)
        #expect(body.expertiseTags == nil)
        #expect(body.professionalDetails?.jobTitle == nil)
        #expect(body.professionalDetails?.company == nil)
        #expect(body.professionalDetails?.education == nil)
    }

    @Test("a cleared link encodes as professional_details.meeting_url empty")
    func clearedLinkEncodesAsEmptyMeetingUrl() throws {
        let body = try #require(Self.body("", Self.zoom))

        // Same key strategy as NetworkService.
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let json = try #require(try JSONSerialization.jsonObject(with: encoder.encode(body)) as? [String: Any])

        #expect(Set(json.keys) == ["professional_details"])
        let details = try #require(json["professional_details"] as? [String: Any])
        #expect(Set(details.keys) == ["meeting_url"])
        #expect(details["meeting_url"] as? String == "")
    }
}
