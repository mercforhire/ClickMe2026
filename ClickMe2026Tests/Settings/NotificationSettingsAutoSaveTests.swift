//
//  NotificationSettingsAutoSaveTests.swift
//  ClickMe2026Tests
//
//  SET-04: opening Notification preferences saves nothing. Applying the
//  loaded rows changes the toggles, which trips the view's change observer
//  (`scheduleAutoSave()`); the view model must recognise that the toggles
//  equal what it just applied and send no PATCH. One real flip sends one.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Notification settings auto-save", .serialized)
struct NotificationSettingsAutoSaveTests {

    // MARK: - Fixtures

    /// Short debounce so the suite runs fast; the waits below are 10x this.
    private static let debounce: UInt64 = 20_000_000
    private static let settleNanoseconds: UInt64 = 200_000_000

    /// A client that answers GET with the grid where `booking/requests` is
    /// OFF (every other row on), and PATCH with a success body. The first
    /// row must be off, or the load path never trips the observer and the
    /// tests pass vacuously.
    private static func makeAPI() -> ClickMeAPI {
        let rows = NotificationSettingsViewModel.defaultSections.flatMap { section in
            section.settings.map { setting -> String in
                let isOn = !(section.categoryKey == "booking" && setting.subCategoryKey == "requests")
                return """
                {"category":"\(section.categoryKey)","sub_category":"\(setting.subCategoryKey)",\
                "push_enabled":\(isOn),"email_enabled":\(isOn),"in_app_enabled":\(isOn)}
                """
            }
        }
        let preferencesBody = Data(
            "{\"status\":\"success\",\"data\":{\"preferences\":[\(rows.joined(separator: ","))]}}".utf8
        )
        let successBody = Data("{\"status\":\"success\",\"message\":\"ok\"}".utf8)

        return APITestFactory.make { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, request.httpMethod == "PATCH" ? successBody : preferencesBody)
        }
    }

    private static func makeViewModel() -> NotificationSettingsViewModel {
        NotificationSettingsViewModel(api: makeAPI(), autoSaveDebounce: debounce)
    }

    private static func patchCount() -> Int {
        MockURLProtocol.recordedRequests.filter { $0.httpMethod == "PATCH" }.count
    }

    private static func settle() async {
        try? await Task.sleep(nanoseconds: settleNanoseconds)
    }

    // MARK: - Tests

    @Test("Opening the screen with a server row off sends no PATCH")
    func loadSendsNothing() async {
        let viewModel = Self.makeViewModel()

        await viewModel.load()
        // What the view's .onChange(of: autoSaveSnapshot) does after the rows change.
        viewModel.scheduleAutoSave()
        await Self.settle()

        // The seed really did turn a row off (otherwise this test proves nothing).
        #expect(viewModel.sections[0].settings[0].isOn == false)
        #expect(Self.patchCount() == 0)
    }

    @Test("Flipping one toggle sends exactly one PATCH, and an unchanged re-schedule sends no second")
    func oneFlipSendsOnePatch() async {
        let viewModel = Self.makeViewModel()
        await viewModel.load()

        viewModel.sections[0].settings[1].isOn.toggle()
        viewModel.scheduleAutoSave()
        await Self.settle()
        #expect(Self.patchCount() == 1)

        viewModel.scheduleAutoSave()
        await Self.settle()
        #expect(Self.patchCount() == 1)
    }

    @Test("Flipping a toggle and flipping it back inside the debounce window sends no PATCH")
    func flipAndFlipBackSendsNothing() async {
        let viewModel = Self.makeViewModel()
        await viewModel.load()

        viewModel.sections[0].settings[1].isOn.toggle()
        viewModel.scheduleAutoSave()
        viewModel.sections[0].settings[1].isOn.toggle()
        viewModel.scheduleAutoSave()
        await Self.settle()

        #expect(Self.patchCount() == 0)
    }

    @Test("A reload after the first load sends no PATCH")
    func reloadSendsNothing() async {
        let viewModel = Self.makeViewModel()
        await viewModel.load()
        await viewModel.reload()
        viewModel.scheduleAutoSave()
        await Self.settle()

        #expect(Self.patchCount() == 0)
    }
}
