//
//  ToastCenterTests.swift
//  ClickMe2026Tests
//
//  BOOK-06 / UI-SPEC section 10: one toast at a time, a replacing message
//  restarts the timer, a tap dismisses early.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Toast center")
struct ToastCenterTests {

    @Test("show sets the message and a second show replaces it")
    func showReplaces() {
        let center = ToastCenter(displayDuration: .milliseconds(300))

        center.show("A")
        #expect(center.current?.message == "A")

        center.show("B")
        #expect(center.current?.message == "B")
        center.dismiss()
    }

    @Test("a replacing show restarts the 300 ms timer and the toast then clears")
    func replacementRestartsTimer() async throws {
        let center = ToastCenter(displayDuration: .milliseconds(300))

        center.show("A")
        try await Task.sleep(for: .milliseconds(180))
        center.show("B")
        try await Task.sleep(for: .milliseconds(180))
        // 360 ms after "A" but only 180 ms after "B": A's timer must not have cut B short.
        #expect(center.current?.message == "B")

        try await Task.sleep(for: .milliseconds(250))
        #expect(center.current == nil)
    }

    @Test("dismiss clears the toast immediately")
    func dismissClears() {
        let center = ToastCenter(displayDuration: .milliseconds(300))

        center.show("A", systemImage: "checkmark.circle.fill")
        #expect(center.current?.systemImage == "checkmark.circle.fill")

        center.dismiss()
        #expect(center.current == nil)
    }

    @Test("a toast shown after a dismiss still gets its full duration")
    func showAfterDismiss() async throws {
        let center = ToastCenter(displayDuration: .milliseconds(300))

        center.show("A")
        center.dismiss()
        try await Task.sleep(for: .milliseconds(100))
        center.show("B")
        try await Task.sleep(for: .milliseconds(200))

        #expect(center.current?.message == "B")
        center.dismiss()
    }
}
