//
//  SignupBasicInfoProvinceTests.swift
//  ClickMe2026Tests
//
//  D-07 (signup half): Basic Info sends `province_state` as an empty string
//  only when the user emptied a province that had a value when the screen
//  opened (Android `SignupSetupRepository` clearProvince). Otherwise an empty
//  field sends no province key at all.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Signup basic info province", .serialized)
struct SignupBasicInfoProvinceTests {

    // MARK: - Fixtures

    private static func makeAPI() -> ClickMeAPI {
        APITestFactory.make { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            let body = """
            {"status":"success","data":{"profile_id":"\(UUID().uuidString)","completion_percentage":50,\
            "missing_fields":[],"setup_completed":false}}
            """
            return (response, Data(body.utf8))
        }
    }

    /// An accumulator holding a saved Basic Info slice with the given province.
    private static func accumulator(province: String) -> SignupAccumulator {
        let accumulator = SignupAccumulator()
        accumulator.firstName = "Sam"
        accumulator.city = "Toronto"
        accumulator.provinceState = province
        accumulator.countryCode = "CAN"
        return accumulator
    }

    /// The `location` object of the one PATCH the save sent.
    private static func sentLocation() throws -> [String: Any] {
        let request = try #require(MockURLProtocol.recordedRequests.first)
        let json = try #require(request.jsonBodyForTest())
        return try #require(json["location"] as? [String: Any])
    }

    // MARK: - Tests

    @Test("A province emptied after opening with a value is sent as an empty string")
    func clearedProvinceSendsEmptyString() async throws {
        let viewModel = SignupBasicInfoViewModel(accumulator: Self.accumulator(province: "ON"), api: Self.makeAPI())
        viewModel.province = ""

        let saved = await viewModel.save()

        #expect(saved)
        let location = try Self.sentLocation()
        #expect(location["province_state"] as? String == "")
    }

    @Test("A province that was empty when opened and left empty sends no province key")
    func untouchedEmptyProvinceSendsNothing() async throws {
        let viewModel = SignupBasicInfoViewModel(accumulator: Self.accumulator(province: ""), api: Self.makeAPI())

        let saved = await viewModel.save()

        #expect(saved)
        let location = try Self.sentLocation()
        #expect(location["province_state"] == nil)
        #expect(location["city"] as? String == "Toronto")
    }

    @Test("A whitespace-only province counts as empty")
    func whitespaceProvinceIsEmpty() async throws {
        let viewModel = SignupBasicInfoViewModel(accumulator: Self.accumulator(province: ""), api: Self.makeAPI())
        viewModel.province = "   "

        _ = await viewModel.save()

        let location = try Self.sentLocation()
        #expect(location["province_state"] == nil)
    }

    @Test("A typed province is sent trimmed")
    func typedProvinceIsSent() async throws {
        let viewModel = SignupBasicInfoViewModel(accumulator: Self.accumulator(province: ""), api: Self.makeAPI())
        viewModel.province = " BC "

        _ = await viewModel.save()

        let location = try Self.sentLocation()
        #expect(location["province_state"] as? String == "BC")
    }
}
