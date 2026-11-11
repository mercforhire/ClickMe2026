//
//  SkypeStatusTextTests.swift
//  ClickMe2026Tests
//
//  Pins the Skype/Zoom session copy (CALL-06, D-09): the status line never
//  promises an automatic end, and tells the user to tap End Session.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Skype status text")
struct SkypeStatusTextTests {

    // MARK: - Status line

    @Test("before the link is opened, the user is told to open it")
    func beforeOpen() {
        let vm = MeetingCallViewModel(
            scheduledStart: Date().addingTimeInterval(-60),
            scheduledEnd: Date().addingTimeInterval(30 * 60)
        )
        vm.hasOpenedExternalLink = false
        #expect(vm.skypeStatusText == "Open the meeting link to start the session.")
    }

    @Test("opened with a known end shows the finish time and asks the user to end it")
    func openedWithEnd() throws {
        let vm = MeetingCallViewModel(
            scheduledStart: Date().addingTimeInterval(-60),
            scheduledEnd: Date().addingTimeInterval(30 * 60)
        )
        vm.hasOpenedExternalLink = true
        let endLabel = try #require(vm.scheduledEndLabel)
        #expect(
            vm.skypeStatusText
                == "Meeting in progress. Scheduled to finish at \(endLabel). Tap End Session when you're done."
        )
    }

    @Test("opened with an unknown end omits the finish time")
    func openedWithoutEnd() {
        let vm = MeetingCallViewModel(scheduledStart: nil, scheduledEnd: nil)
        vm.hasOpenedExternalLink = true
        #expect(vm.skypeStatusText == "Meeting in progress. Tap End Session when you're done.")
    }

    @Test("no state says or implies the meeting ends automatically")
    func neverPromisesAutoEnd() {
        for opened in [false, true] {
            for end in [Date().addingTimeInterval(600), nil] {
                let vm = MeetingCallViewModel(scheduledStart: nil, scheduledEnd: end)
                vm.hasOpenedExternalLink = opened
                let text = vm.skypeStatusText.lowercased()
                #expect(!text.contains("automatic"))
                #expect(!text.contains("auto-end"))
                #expect(!text.contains("end by itself"))
            }
        }
    }

    // MARK: - Ending banner (D-15)

    @Test("overtime warning at end + 55 reads 'This call will end in 5 minutes'")
    func bannerOvertimeWarning() {
        let vm = MeetingCallViewModel(
            scheduledStart: Date().addingTimeInterval(-85 * 60),
            scheduledEnd: Date().addingTimeInterval(-55 * 60)
        )
        vm.isOvertimeWarning = true
        #expect(vm.endingBannerText == "This call will end in 5 minutes")
    }

    @Test("past the scheduled end without the warning reads 'Scheduled time complete'")
    func bannerPastEnd() {
        let vm = MeetingCallViewModel(
            scheduledStart: Date().addingTimeInterval(-30 * 60),
            scheduledEnd: Date().addingTimeInterval(-60)
        )
        vm.isOvertimeWarning = false
        #expect(vm.endingBannerText == "Scheduled time complete — you can wrap up when ready.")
    }

    @Test("final stretch reads 'Session ending soon'")
    func bannerFinalStretch() {
        let vm = MeetingCallViewModel(
            scheduledStart: Date().addingTimeInterval(-28 * 60),
            scheduledEnd: Date().addingTimeInterval(120)
        )
        vm.isOvertimeWarning = false
        #expect(vm.endingBannerText == "Session ending soon — please start wrapping up.")
    }
}
