//
//  ExpertMeetingLinkReloadTests.swift
//  ClickMe2026Tests
//
//  CR-01, reload half (user decision 2026-11-15): after a load or a pull to
//  refresh, the meeting-link field shows the link the server holds, and a
//  server nil reads as "". Keeping the field's old text would show, and
//  baseline, a link that was cleared on another device or server-side.
//
//  Every input is a literal, so no row builds the view model, calls the API or
//  reads `UserManager.shared`; none depends on what the shared manager holds in
//  the test host.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Expert meeting link reload")
struct ExpertMeetingLinkReloadTests {

    // MARK: - Fixtures

    private static let zoom = "https://zoom.us/j/123"
    private static let meet = "https://meet.google.com/abc-defg-hij"

    private static func details(meetingUrl: String?) -> ExpertProfileData.ProfessionalDetails {
        ExpertProfileData.ProfessionalDetails(jobTitle: nil, company: nil, education: nil, meetingUrl: meetingUrl)
    }

    // MARK: - Rows

    @Test("a reload where the server holds no link empties the field")
    func serverNilEmptiesField() {
        let link = ExpertProfileSettingsViewModel.loadedMeetingLink(
            from: Self.details(meetingUrl: nil), current: Self.zoom
        )

        #expect(link == "")
    }

    @Test("a reload where the server holds an empty link empties the field")
    func serverEmptyEmptiesField() {
        let link = ExpertProfileSettingsViewModel.loadedMeetingLink(
            from: Self.details(meetingUrl: ""), current: Self.zoom
        )

        #expect(link == "")
    }

    @Test("a reload takes the server link over the field")
    func serverLinkWins() {
        let link = ExpertProfileSettingsViewModel.loadedMeetingLink(
            from: Self.details(meetingUrl: Self.meet), current: Self.zoom
        )

        #expect(link == Self.meet)
    }

    @Test("with no expert profile held the field keeps its text")
    func noProfileKeepsField() {
        #expect(ExpertProfileSettingsViewModel.loadedMeetingLink(from: nil, current: Self.zoom) == Self.zoom)
        #expect(ExpertProfileSettingsViewModel.loadedMeetingLink(from: nil, current: "") == "")
    }

    @Test("after a reload the baseline is the server link and no save is queued")
    func reloadedBaselineQueuesNoSave() {
        let served: [String?] = [nil, "", Self.meet]

        for server in served {
            let result = ExpertProfileSettingsViewModel.loadedMeetingLink(
                from: Self.details(meetingUrl: server), current: Self.zoom
            )
            // What forceLoad() puts in baselineMeetingUrl on the very next line.
            let baseline = result.trimmingCharacters(in: .whitespacesAndNewlines)

            #expect(baseline == (server ?? ""))
            #expect(ExpertProfileSettingsViewModel.meetingLinkBody(current: result, baseline: baseline) == nil)
        }
    }
}
