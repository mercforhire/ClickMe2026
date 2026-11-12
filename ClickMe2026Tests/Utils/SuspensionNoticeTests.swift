//
//  SuspensionNoticeTests.swift
//  ClickMe2026Tests
//
//  D-13: Login shows the suspension alert once. The copy is fixed by
//  04-UI-SPEC (Suspension on cold launch); dismissing the alert clears
//  UserManager.wasSuspended, so a later fresh sign-in does not show it again.
//

import Testing
@testable import ClickMe2026

@MainActor
@Suite("Suspension notice")
struct SuspensionNoticeTests {

    @Test("presents when suspended and not yet shown")
    func presentsWhenSuspended() {
        #expect(SuspensionNotice.shouldPresent(wasSuspended: true, alreadyPresented: false))
    }

    @Test("does not present a second time on the same appearance")
    func doesNotRepeat() {
        #expect(!SuspensionNotice.shouldPresent(wasSuspended: true, alreadyPresented: true))
    }

    @Test("does not present on a fresh sign-in after dismissal")
    func doesNotPresentWhenFlagCleared() {
        #expect(!SuspensionNotice.shouldPresent(wasSuspended: false, alreadyPresented: false))
        #expect(!SuspensionNotice.shouldPresent(wasSuspended: false, alreadyPresented: true))
    }

    @Test("copy matches the UI-SPEC strings exactly")
    func copyMatchesSpec() {
        #expect(SuspensionNotice.title == "Your account has been suspended")
        #expect(
            SuspensionNotice.message
                == "You can't use ClickMe with this account right now. If you think this is a mistake, contact clickmeapp@uptrendinvestments.net."
        )
        #expect(SuspensionNotice.dismissLabel == "Close Alert")
        #expect(SuspensionNotice.message.contains("clickmeapp@uptrendinvestments.net"))
    }
}
