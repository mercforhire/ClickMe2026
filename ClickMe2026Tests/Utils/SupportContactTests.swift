//
//  SupportContactTests.swift
//  ClickMe2026Tests
//
//  SET-02: one support address, shared by Help > Email Us and the suspension
//  notice. These pin its value so a change has to be made on purpose.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Support contact")
struct SupportContactTests {

    @Test("The support address is the ClickMe inbox")
    func addressIsPinned() {
        #expect(SupportContact.email == "clickmeapp@uptrendinvestments.net")
    }

    @Test("The mailto URL addresses that inbox")
    func mailtoURLIsPinned() {
        #expect(SupportContact.mailtoURL?.absoluteString == "mailto:clickmeapp@uptrendinvestments.net")
        #expect(SupportContact.mailtoURL?.scheme == "mailto")
    }

    @Test("The suspension notice uses the same address")
    func suspensionNoticeUsesIt() {
        #expect(SuspensionNotice.message.contains(SupportContact.email))
    }
}
