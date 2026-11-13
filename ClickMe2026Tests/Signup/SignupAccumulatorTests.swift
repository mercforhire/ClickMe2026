//
//  SignupAccumulatorTests.swift
//  ClickMe2026Tests
//
//  SIGN-01: a profile photo is required to publish, and Publish names what
//  is missing instead of sending a request the server will refuse.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Signup accumulator", .serialized)
struct SignupAccumulatorTests {

    // MARK: - Fixtures

    private static let photoUrl = "https://cdn.test.clickme.local/avatars/me.jpg"

    /// An accumulator with every publish field filled in except the photo.
    private static func filledAccumulator(
        province: String = "ON",
        countryCode: String = "CAN",
        avatarUrl: String? = nil
    ) -> SignupAccumulator {
        let accumulator = SignupAccumulator()
        accumulator.firstName = "Sam"
        accumulator.city = "Toronto"
        accumulator.provinceState = province
        accumulator.countryCode = countryCode
        accumulator.timezone = "America/Toronto"
        accumulator.expertiseTags = [ExpertiseTagItem(id: UUID(), label: "SEO", categoryId: "")]
        accumulator.avatarUrl = avatarUrl
        return accumulator
    }

    // MARK: - SIGN-01: photo

    @Test("No photo: not ready, and the photo is the one thing missing")
    func noPhotoIsNotReady() {
        let accumulator = Self.filledAccumulator()

        #expect(!accumulator.isReadyToPublish)
        #expect(accumulator.missingForPublish == [.profilePicture])
        #expect(accumulator.buildPublishRequest() == nil)
    }

    @Test("With a photo: ready, nothing missing")
    func photoMakesItReady() {
        let accumulator = Self.filledAccumulator(avatarUrl: Self.photoUrl)

        #expect(accumulator.isReadyToPublish)
        #expect(accumulator.missingForPublish.isEmpty)
        #expect(accumulator.buildPublishRequest() != nil)
    }

    @Test("An empty photo URL counts as no photo")
    func emptyPhotoUrlIsMissing() {
        let accumulator = Self.filledAccumulator(avatarUrl: "")

        #expect(accumulator.missingForPublish == [.profilePicture])
    }

    @Test("An unverified email never blocks publish")
    func unverifiedEmailIsNotMissing() {
        let accumulator = Self.filledAccumulator(avatarUrl: Self.photoUrl)
        accumulator.emailVerified = false

        #expect(!accumulator.missingForPublish.contains(.verifyEmail))
        #expect(accumulator.isReadyToPublish)
    }

    @Test("Missing items come back in checklist order")
    func missingItemsAreInChecklistOrder() {
        let accumulator = SignupAccumulator()
        accumulator.timezone = ""

        #expect(accumulator.missingForPublish == [.basicInfo, .timezone, .profilePicture, .expertise])
    }

    @Test("Publish with no photo shows the missing step and sends nothing")
    func publishWithoutPhotoSendsNothing() async {
        let accumulator = Self.filledAccumulator()
        let api = APITestFactory.make { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data("{}".utf8))
        }
        let viewModel = SignupReviewViewModel(accumulator: accumulator, api: api)

        let published = await viewModel.publish()

        #expect(!published)
        #expect(viewModel.publishError == "Finish these first: Add profile picture.")
        #expect(!viewModel.didPublish)
        #expect(MockURLProtocol.recordedRequests.isEmpty)
    }
}
