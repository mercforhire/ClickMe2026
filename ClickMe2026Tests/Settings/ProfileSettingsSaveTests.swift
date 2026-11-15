//
//  ProfileSettingsSaveTests.swift
//  ClickMe2026Tests
//
//  G-05-6 (SET-01 reopened): a Profile Settings save sends only the groups that
//  changed and never an empty first or last name. The mock mimics the backend's
//  `min(1)` rule on `basic.first_name` / `basic.last_name` and answers the
//  production 422 body, so a save that still carries `""` fails here the way it
//  fails on a device. Runs through the real view models with every request
//  answered by a mocked URLSession.
//

import Foundation
import Testing
@testable import ClickMe2026

/// Keeps the bytes of every PATCH body the mock handler read. The handler runs
/// on a URL loading thread and `httpBodyStream` can be read once, so the
/// recorder (behind a lock) is the single place the tests read bodies from.
private final class PatchRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var bodies: [Data] = []

    func record(_ data: Data) {
        lock.lock(); defer { lock.unlock() }
        bodies.append(data)
    }

    var count: Int {
        lock.lock(); defer { lock.unlock() }
        return bodies.count
    }

    /// Each captured body decoded as a JSON object, in request order.
    var json: [[String: Any]] {
        lock.lock(); defer { lock.unlock() }
        return bodies.compactMap { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] }
    }

    var first: [String: Any]? { json.first }
}

@MainActor
@Suite("Profile settings save", .serialized)
struct ProfileSettingsSaveTests {

    // MARK: - Fixtures

    private static let debounce: UInt64 = 20_000_000
    private static let settleNanoseconds: UInt64 = 200_000_000
    private static let nameRequired = "Please enter your first name."

    /// A `GET`/`PATCH /user/profile` body.
    private static func profileBody(
        firstName: String, lastName: String, bio: String = "Hello",
        city: String = "Toronto", state: String = "ON"
    ) -> String {
        """
        {"status":"success","data":{\
        "personal_details":{"first_name":"\(firstName)","last_name":"\(lastName)","email":"ada@example.com",\
        "avatar_url":null,"bio":"\(bio)"},\
        "professional_details":{"job_title":"Engineer","company":"Analytical"},\
        "location":{"city":"\(city)","state_province":"\(state)","country":"CAN","timezone":"America/Toronto"},\
        "languages":[{"id":"en","label":"English"}]}}
        """
    }

    /// The production 422 for `basic.first_name` / `basic.last_name` sent as `""`
    /// (userProfile.schema.js min(1)); only the empty name keys are listed.
    nonisolated private static func validationError(fields: [String]) -> Data {
        let errors = fields
            .map { #"{"field":"\#($0)","message":"Too small: expected string to have >=1 characters"}"# }
            .joined(separator: ",")
        return Data(
            """
            {"status":"error","message":"Please check the information you entered and try again.",\
            "errors":[\(errors)],"code":"VALIDATION_ERROR"}
            """.utf8
        )
    }

    /// GET answers 200 with the fixture. A PATCH is recorded, then answered 422
    /// when `basic.first_name` or `basic.last_name` is the empty string, else 200.
    private static func makeAPI(
        firstName: String, lastName: String, bio: String = "Hello",
        city: String = "Toronto", state: String = "ON"
    ) -> (ClickMeAPI, PatchRecorder) {
        let recorder = PatchRecorder()
        let ok = Data(profileBody(firstName: firstName, lastName: lastName, bio: bio, city: city, state: state).utf8)
        let api = APITestFactory.make { request in
            func reply(_ status: Int, _ data: Data) -> (HTTPURLResponse, Data) {
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: status, httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, data)
            }
            guard request.httpMethod == "PATCH" else { return reply(200, ok) }

            let data = request.bodyDataForTest() ?? Data()
            recorder.record(data)
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let basic = json?["basic"] as? [String: Any]
            let empty = ["first_name", "last_name"].filter { (basic?[$0] as? String) == "" }
            guard empty.isEmpty else {
                return reply(422, validationError(fields: empty.map { "basic.\($0)" }))
            }
            return reply(200, ok)
        }
        return (api, recorder)
    }

    /// GET answers 200 with the fixture; every PATCH answers 422 VALIDATION_ERROR
    /// naming `field` with the raw validator text a name over 100 characters gets.
    private static func makeAlways422API(field: String, firstName: String, lastName: String) -> ClickMeAPI {
        let ok = Data(profileBody(firstName: firstName, lastName: lastName).utf8)
        let rejected = Data(
            """
            {"status":"error","message":"Please check the information you entered and try again.",\
            "errors":[{"field":"\(field)","message":"Too big: expected string to have <=100 characters"}],\
            "code":"VALIDATION_ERROR"}
            """.utf8
        )
        return APITestFactory.make { request in
            let status = request.httpMethod == "PATCH" ? 422 : 200
            let response = HTTPURLResponse(
                url: request.url!, statusCode: status, httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, status == 422 ? rejected : ok)
        }
    }

    private static func makeClient(
        firstName: String, lastName: String, bio: String = "Hello",
        city: String = "Toronto", state: String = "ON"
    ) async throws -> (ClientProfileSettingsViewModel, PatchRecorder) {
        let (api, recorder) = makeAPI(firstName: firstName, lastName: lastName, bio: bio, city: city, state: state)
        let vm = ClientProfileSettingsViewModel(api: api, autoSaveDebounce: debounce)
        vm.hydrate(from: try await api.getUserProfile().data)
        return (vm, recorder)
    }

    private static func settle() async {
        try? await Task.sleep(nanoseconds: settleNanoseconds)
    }

    // MARK: - Client

    @Test("G-05-6: on an empty-name profile, a province edit saves")
    func clientProvinceEditOnEmptyNameProfileSaves() async throws {
        let (vm, recorder) = try await Self.makeClient(firstName: "", lastName: "")

        vm.state = ""
        await vm.performAutoSave()

        #expect(recorder.count == 1)
        let body = try #require(recorder.first)
        #expect(body["basic"] == nil)
        let location = try #require(body["location"] as? [String: Any])
        #expect(location["state_province"] as? String == "")
        #expect(vm.didAutoSave)
        #expect(vm.autoSaveError == nil)
    }

    @Test("Client: a bio edit on an empty-name profile sends the bio and neither name key")
    func clientBioEditOnEmptyNameProfileSaves() async throws {
        let (vm, recorder) = try await Self.makeClient(firstName: "", lastName: "")

        vm.bio = "A different bio"
        await vm.performAutoSave()

        let basic = try #require(recorder.first?["basic"] as? [String: Any])
        #expect(basic["bio"] as? String == "A different bio")
        #expect(basic["first_name"] == nil)
        #expect(basic["last_name"] == nil)
        #expect(vm.didAutoSave)
        #expect(vm.autoSaveError == nil)
    }

    @Test("Client: a bio edit on a first-name-only profile sends first_name and no last_name")
    func clientBioEditOnFirstNameOnlyProfileSaves() async throws {
        let (vm, recorder) = try await Self.makeClient(firstName: "Ada", lastName: "")

        vm.bio = "A different bio"
        await vm.performAutoSave()

        let basic = try #require(recorder.first?["basic"] as? [String: Any])
        #expect(basic["first_name"] as? String == "Ada")
        #expect(basic["last_name"] == nil)
        #expect(basic["bio"] as? String == "A different bio")
        #expect(vm.autoSaveError == nil)
    }

    @Test("Client: after the province save, an unchanged re-schedule sends no second PATCH")
    func clientSavedProvinceIsIdempotent() async throws {
        let (vm, recorder) = try await Self.makeClient(firstName: "", lastName: "")

        vm.state = ""
        await vm.performAutoSave()
        #expect(recorder.count == 1)

        vm.scheduleAutoSave()
        await Self.settle()

        #expect(recorder.count == 1)
    }

    @Test("Client: a cleared first name is held, flagged, and does not block another edit")
    func clientClearedFirstNameIsHeld() async throws {
        let (vm, recorder) = try await Self.makeClient(firstName: "Ada", lastName: "Lovelace")

        vm.firstName = ""
        await vm.performAutoSave()

        #expect(recorder.count == 0)
        #expect(vm.firstNameError == Self.nameRequired)
        #expect(vm.lastNameError == nil)
        #expect(!vm.didAutoSave)

        vm.city = "Ottawa"
        await vm.performAutoSave()

        #expect(recorder.count == 1)
        let body = try #require(recorder.first)
        #expect(body["basic"] == nil)
        #expect((body["location"] as? [String: Any])?["city"] as? String == "Ottawa")
        #expect(vm.autoSaveError == nil)

        vm.firstName = "Ada"
        #expect(vm.firstNameError == nil)
    }

    @Test("Client: a 422 on save names the field, in iOS copy")
    func clientA422NamesTheField() async throws {
        let api = Self.makeAlways422API(field: "basic.first_name", firstName: "Ada", lastName: "Lovelace")
        let vm = ClientProfileSettingsViewModel(api: api, autoSaveDebounce: Self.debounce)
        vm.hydrate(from: try await api.getUserProfile().data)

        vm.firstName = String(repeating: "A", count: 101)
        await vm.performAutoSave()

        #expect(vm.autoSaveError == "Check First Name, then try again.")
        #expect(vm.autoSaveError?.contains("Too big") == false)
        #expect(!vm.didAutoSave)
    }

    // MARK: - Expert

    /// Never call `load()`, `reload()`, `scheduleAutoSave()` or the private save
    /// on the expert view model here: they refresh the expert profile through the
    /// shared manager's real API. The body builders plus the mock API are the seam.
    private static func makeExpert(
        firstName: String, lastName: String, bio: String = "Hello",
        city: String = "Toronto", state: String = "ON"
    ) async throws -> (ExpertProfileSettingsViewModel, ClickMeAPI, PatchRecorder) {
        let (api, recorder) = makeAPI(firstName: firstName, lastName: lastName, bio: bio, city: city, state: state)
        let vm = ExpertProfileSettingsViewModel(api: api)
        vm.hydrate(from: try await api.getUserProfile().data)
        return (vm, api, recorder)
    }

    @Test("Expert: on an empty-name profile, clearing the province builds a location-only body that saves")
    func expertProvinceEditOnEmptyNameProfileSaves() async throws {
        let (vm, api, recorder) = try await Self.makeExpert(firstName: "", lastName: "")

        vm.state = ""
        let body = try #require(vm.makeProfileUpdateBody())
        #expect(body.basic == nil)
        #expect(body.location != nil)
        _ = try await api.updateUserProfile(body)

        #expect(recorder.count == 1)
        let sent = try #require(recorder.first)
        #expect(sent["basic"] == nil)
        #expect((sent["location"] as? [String: Any])?["state_province"] as? String == "")
    }

    @Test("Expert: a bio edit on a first-name-only profile sends first_name and no last_name")
    func expertBioEditOnFirstNameOnlyProfileSaves() async throws {
        let (vm, api, recorder) = try await Self.makeExpert(firstName: "Ada", lastName: "")

        vm.bio = "A different bio"
        _ = try await api.updateUserProfile(try #require(vm.makeProfileUpdateBody()))

        let basic = try #require(recorder.first?["basic"] as? [String: Any])
        #expect(basic["first_name"] as? String == "Ada")
        #expect(basic["last_name"] == nil)
        #expect(basic["bio"] as? String == "A different bio")
    }

    @Test("Expert: a city-only edit sends no meeting-link body")
    func expertCityEditSendsNoMeetingLink() async throws {
        let (vm, _, _) = try await Self.makeExpert(firstName: "Ada", lastName: "Lovelace")

        vm.city = "Ottawa"

        #expect(vm.makeProfileUpdateBody() != nil)
        #expect(vm.makeExpertProfileUpdateBody() == nil)
    }

    @Test("Expert: a changed meeting link alone sends the trimmed link and no profile body")
    func expertMeetingLinkOnlyEdit() async throws {
        let (vm, _, _) = try await Self.makeExpert(firstName: "Ada", lastName: "Lovelace")
        let link = "https://zoom.us/j/\(UUID().uuidString)"

        vm.meetingUrl = "  \(link) "

        #expect(vm.makeProfileUpdateBody() == nil)
        let expertBody = try #require(vm.makeExpertProfileUpdateBody())
        #expect(expertBody.professionalDetails?.meetingUrl == link)
    }

    @Test("Expert: a cleared first name is held and flagged")
    func expertClearedFirstNameIsHeld() async throws {
        let (vm, _, _) = try await Self.makeExpert(firstName: "Ada", lastName: "Lovelace")

        vm.firstName = ""

        #expect(vm.firstNameError == Self.nameRequired)
        #expect(vm.lastNameError == nil)
        #expect(vm.makeProfileUpdateBody() == nil)
    }
}
