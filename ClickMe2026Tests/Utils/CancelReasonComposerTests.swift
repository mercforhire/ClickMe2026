//
//  CancelReasonComposerTests.swift
//  ClickMe2026Tests
//
//  BOOK-07: the cancellation comment is sent as "label: comment", capped by
//  UTF-16 length at character boundaries so the server's max(500) never rejects it.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Cancel reason composer")
struct CancelReasonComposerTests {

    @Test("a blank comment sends the label alone")
    func blankCommentSendsLabel() {
        #expect(CancelReasonComposer.reason(label: "Change of plans", comment: "") == "Change of plans")
        #expect(CancelReasonComposer.reason(label: "Change of plans", comment: "   \n ") == "Change of plans")
    }

    @Test("a comment is trimmed and joined to the label")
    func commentIsTrimmedAndJoined() {
        #expect(
            CancelReasonComposer.reason(label: "Other", comment: "  running late  ")
                == "Other: running late"
        )
    }

    @Test("capComment stops ASCII at 450 units")
    func capsAscii() {
        let capped = CancelReasonComposer.capComment(String(repeating: "a", count: 600))
        #expect(capped.utf16.count == 450)
    }

    @Test("capComment on family emoji keeps whole characters and at most 450 units")
    func capsEmojiWithoutSplitting() {
        let family = "👨‍👩‍👧‍👦"
        let capped = CancelReasonComposer.capComment(String(repeating: family, count: 300))
        #expect(capped.utf16.count <= CancelReasonComposer.commentLimit)
        #expect(capped.utf16.count > 0)
        #expect(capped.count == capped.utf16.count / family.utf16.count)
        #expect(capped == String(repeating: family, count: capped.count))
    }

    @Test("capComment leaves a short comment alone")
    func shortCommentUnchanged() {
        #expect(CancelReasonComposer.capComment("see you later") == "see you later")
    }

    @Test("the longest label with a 450-unit comment is 472 units")
    func longestReasonIs472() {
        let comment = String(repeating: "b", count: 450)
        let reason = CancelReasonComposer.reason(label: "Found another expert", comment: comment)
        #expect(reason.utf16.count == 472)
    }

    @Test("a composed reason over 500 units is capped at 500")
    func composedReasonCapped() {
        let reason = CancelReasonComposer.reason(label: "Other", comment: String(repeating: "c", count: 900))
        #expect(reason.utf16.count == CancelReasonComposer.reasonLimit)
    }

    @Test("the 500 cap never splits an emoji")
    func composedReasonCapKeepsEmojiWhole() {
        let reason = CancelReasonComposer.reason(label: "Other", comment: String(repeating: "😀", count: 400))
        #expect(reason.utf16.count <= CancelReasonComposer.reasonLimit)
        #expect(reason.hasPrefix("Other: "))
        let body = reason.dropFirst("Other: ".count)
        #expect(body == String(repeating: "😀", count: body.count)[...])
    }
}
