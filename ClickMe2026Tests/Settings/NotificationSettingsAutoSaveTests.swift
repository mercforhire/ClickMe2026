//
//  NotificationSettingsAutoSaveTests.swift
//  ClickMe2026Tests
//
//  SET-04: opening Notification preferences saves nothing. Applying the
//  loaded rows changes the toggles, which trips the view's change observer
//  (`scheduleAutoSave()`); the view model must recognise that the toggles
//  equal what it just applied and send no PATCH. One real flip sends one.
//
//  This suite does not use `MockURLProtocol`: its handler and request log are
//  process-global, and other suites reset them while this one runs. The
//  private protocol below owns its state, so only this suite's traffic lands
//  in its log.
//

import Foundation
import Testing
@testable import ClickMe2026

/// Answers `GET`/`PATCH /notifications/preferences` from state installed by the
/// suite, and records every request it sees. Only this suite registers it.
private final class PreferencesStubProtocol: URLProtocol {

    private struct State {
        var preferencesBody = Data()
        var successBody = Data()
        var requests: [URLRequest] = []
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var state = State()

    /// Replaces the stub bodies and clears the request log.
    static func install(preferencesBody: Data, successBody: Data) {
        lock.withLock {
            state = State(preferencesBody: preferencesBody, successBody: successBody, requests: [])
        }
    }

    /// PATCHes sent to the notification preferences path since `install`.
    static var preferencePatches: [URLRequest] {
        lock.withLock {
            state.requests.filter {
                $0.httpMethod == "PATCH" && $0.url?.path.hasSuffix("/notifications/preferences") == true
            }
        }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let request = self.request
        let body: Data = Self.lock.withLock {
            Self.state.requests.append(request)
            return request.httpMethod == "PATCH" ? Self.state.successBody : Self.state.preferencesBody
        }
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@MainActor
@Suite("Notification settings auto-save", .serialized)
struct NotificationSettingsAutoSaveTests {

    // MARK: - Fixtures

    /// Short debounce so the suite runs fast; the waits below are 10x this.
    private static let debounce: UInt64 = 20_000_000
    private static let settleNanoseconds: UInt64 = 200_000_000
    /// Upper bound for a PATCH to appear before the settle window starts.
    private static let patchWaitSeconds: Int64 = 2

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
        PreferencesStubProtocol.install(preferencesBody: preferencesBody, successBody: successBody)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [PreferencesStubProtocol.self]
        let service = NetworkService(session: URLSession(configuration: config))
        return ClickMeAPI(baseURL: APITestFactory.baseURL, service: service)
    }

    private static func makeViewModel() -> NotificationSettingsViewModel {
        NotificationSettingsViewModel(api: makeAPI(), autoSaveDebounce: debounce)
    }

    private static func patchCount() -> Int {
        PreferencesStubProtocol.preferencePatches.count
    }

    /// Polls (up to `patchWaitSeconds`) until at least `expected` PATCHes have arrived.
    private static func awaitPatchCount(atLeast expected: Int) async {
        let deadline = ContinuousClock.now + .seconds(patchWaitSeconds)
        while patchCount() < expected, ContinuousClock.now < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    /// Waits for the expected PATCHes, then a fixed settle window so any extra PATCH would also land.
    private static func settle(expectingPatches expected: Int = 0) async {
        await awaitPatchCount(atLeast: expected)
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
        await Self.settle(expectingPatches: 1)
        #expect(Self.patchCount() == 1)

        viewModel.scheduleAutoSave()
        await Self.settle(expectingPatches: 1)
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
