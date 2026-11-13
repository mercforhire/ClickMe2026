//
//  ProfileLanguagesSaveTests.swift
//  ClickMe2026Tests
//
//  SET-01: a language edit on the client and expert profile settings screens
//  reaches `PATCH /user/profile` as `languages.language_ids` (catalog ids in
//  the picked order) plus `languages.custom_languages` (the id-less entries).
//  The server fully replaces `user_languages` when the group is present, so
//  customs must always travel with the ids and a text-only edit must not send
//  the group at all. D-07 (settings half): clearing State/Province sends "",
//  never null. UI-SPEC EM4 / A9: a Done that would leave zero languages sends
//  nothing and keeps the previous list.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Profile languages save", .serialized)
struct ProfileLanguagesSaveTests {

    // MARK: - Fixtures

    private static let debounce: UInt64 = 20_000_000
    private static let settleNanoseconds: UInt64 = 200_000_000

    private static let english = LanguageItem(id: "en", label: "English")
    private static let spanish = LanguageItem(id: "es", label: "Spanish")
    private static let french = LanguageItem(id: "fr", label: "French")

    /// A `GET`/`PATCH /user/profile` body. `languagesJSON` is the raw array text.
    private static func profileBody(languagesJSON: String, state: String = "ON") -> String {
        """
        {"status":"success","data":{\
        "personal_details":{"first_name":"Ada","last_name":"Lovelace","email":"ada@example.com",\
        "avatar_url":null,"bio":"Hello"},\
        "professional_details":{"job_title":"Engineer","company":"Analytical"},\
        "location":{"city":"Toronto","state_province":"\(state)","country":"CAN","timezone":"America/Toronto"},\
        "languages":\(languagesJSON)}}
        """
    }

    private static let englishAndKlingon =
        #"[{"id":"en","label":"English"},{"id":null,"label":"Klingon"}]"#

    /// Every request, GET or PATCH, answers 200 with the same profile body.
    private static func makeAPI(languagesJSON: String) -> ClickMeAPI {
        let body = Data(profileBody(languagesJSON: languagesJSON).utf8)
        return APITestFactory.make { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, body)
        }
    }

    /// Decodes the stubbed profile through the app's own decoder.
    private static func profile(from api: ClickMeAPI) async throws -> UserProfileData {
        try await api.getUserProfile().data
    }

    private static func makeClient(
        languagesJSON: String = englishAndKlingon
    ) async throws -> (ClientProfileSettingsViewModel, ClickMeAPI) {
        let api = makeAPI(languagesJSON: languagesJSON)
        let vm = ClientProfileSettingsViewModel(api: api, autoSaveDebounce: debounce)
        vm.hydrate(from: try await profile(from: api))
        // The hydration GET is not what the tests count.
        MockURLProtocol.recordedRequests = []
        return (vm, api)
    }

    private static func patches() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter { $0.httpMethod == "PATCH" }
    }

    private static func settle() async {
        try? await Task.sleep(nanoseconds: settleNanoseconds)
    }

    private static func languagesGroup(of request: URLRequest) -> [String: Any]? {
        request.jsonBodyForTest()?["languages"] as? [String: Any]
    }

    // MARK: - Client

    @Test("Client: a language edit sends ids in picked order and the custom languages")
    func clientLanguageEditSendsIdsAndCustoms() async throws {
        let (vm, _) = try await Self.makeClient()

        vm.languageItems = [Self.spanish, Self.english]
        await vm.performAutoSave()

        let sent = Self.patches()
        #expect(sent.count == 1)
        let group = try #require(sent.first.flatMap(Self.languagesGroup(of:)))
        #expect(group["language_ids"] as? [String] == ["es", "en"])
        #expect(group["custom_languages"] as? [String] == ["Klingon"])
        #expect(vm.didAutoSave)
        #expect(vm.autoSaveError == nil)
    }

    @Test("Client: a text-only edit sends no languages group")
    func clientTextEditOmitsLanguages() async throws {
        let (vm, _) = try await Self.makeClient()

        vm.bio = "A different bio"
        await vm.performAutoSave()

        let sent = Self.patches()
        #expect(sent.count == 1)
        let body = try #require(sent.first?.jsonBodyForTest())
        #expect(body["languages"] == nil)
        #expect((body["basic"] as? [String: Any])?["bio"] as? String == "A different bio")
    }

    @Test("Client: clearing State/Province sends an empty string, never null")
    func clientClearedStateSendsEmptyString() async throws {
        let (vm, _) = try await Self.makeClient()

        vm.state = ""
        await vm.performAutoSave()

        let request = try #require(Self.patches().first)
        let location = try #require(request.jsonBodyForTest()?["location"] as? [String: Any])
        #expect(location["state_province"] as? String == "")
        let text = String(decoding: try #require(request.bodyDataForTest()), as: UTF8.self)
        #expect(!text.contains("null"))
    }

    @Test("Client: after a successful language save, an unchanged re-schedule sends no second PATCH")
    func clientSavedLanguagesAreIdempotent() async throws {
        let (vm, _) = try await Self.makeClient()

        vm.languageItems = [Self.spanish, Self.english]
        await vm.performAutoSave()
        #expect(Self.patches().count == 1)

        vm.scheduleAutoSave()
        await Self.settle()

        #expect(Self.patches().count == 1)
    }

    @Test("Client: two language edits inside one debounce window send one PATCH with the final selection")
    func clientTwoEditsOnePatch() async throws {
        let (vm, _) = try await Self.makeClient()

        vm.languageItems = [Self.spanish, Self.english]
        vm.scheduleAutoSave()
        vm.languageItems = [Self.french, Self.english]
        vm.scheduleAutoSave()
        await Self.settle()

        let sent = Self.patches()
        #expect(sent.count == 1)
        let group = try #require(sent.first.flatMap(Self.languagesGroup(of:)))
        #expect(group["language_ids"] as? [String] == ["fr", "en"])
    }

    // MARK: - Client: zero languages (UI-SPEC EM4, A9)

    @Test("Client: Done with nothing selected keeps the previous list, sends nothing and explains why")
    func clientZeroDoneKeepsPreviousList() async throws {
        let (vm, _) = try await Self.makeClient(languagesJSON: #"[{"id":"en","label":"English"}]"#)

        vm.applyLanguageSelection([])
        vm.scheduleAutoSave()
        await Self.settle()

        #expect(vm.languageItems == [Self.english])
        #expect(vm.autoSaveError == "Keep at least one language.")
        #expect(Self.patches().isEmpty)
    }

    @Test("Client: Done with nothing selected on a profile that has none is a silent no-op")
    func clientZeroDoneOnEmptyProfileIsSilent() async throws {
        let (vm, _) = try await Self.makeClient(languagesJSON: "[]")

        vm.applyLanguageSelection([])
        vm.scheduleAutoSave()
        await Self.settle()

        #expect(vm.languages.isEmpty)
        #expect(vm.autoSaveError == nil)
        #expect(Self.patches().isEmpty)
    }

    @Test("Client: deselecting every catalog language keeps the custom ones and still saves")
    func clientCustomOnlyIsNotZero() async throws {
        let (vm, _) = try await Self.makeClient()

        vm.applyLanguageSelection([])
        await vm.performAutoSave()

        #expect(vm.autoSaveError == nil)
        let group = try #require(Self.patches().first.flatMap(Self.languagesGroup(of:)))
        #expect(group["language_ids"] as? [String] == [])
        #expect(group["custom_languages"] as? [String] == ["Klingon"])
    }

    @Test("Client: Done with a selection applies it in picked order")
    func clientDoneAppliesSelection() async throws {
        let (vm, _) = try await Self.makeClient()

        vm.applyLanguageSelection([Self.french, Self.spanish])

        #expect(vm.languageItems == [Self.french, Self.spanish])
        #expect(vm.languages == ["French", "Spanish", "Klingon"])
        #expect(vm.autoSaveError == nil)
    }
}
