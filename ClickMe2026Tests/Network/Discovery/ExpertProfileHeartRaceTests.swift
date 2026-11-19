//
//  ExpertProfileHeartRaceTests.swift
//  ClickMe2026Tests
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//
//  IN-19: the details response carries `is_favorite` as the server read it. When
//  the user toggled the heart while that request was in flight, the response must
//  not flip the heart back, whether the toggle is still running or already done.
//
//  The details response is held by `HeldURLProtocol` so the test can land it
//  after the toggle.
//

import Foundation
import Testing
@testable import ClickMe2026

private enum HeartFixture {
    static let expertId = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!

    nonisolated static func details(isFavorite: Bool) -> Data {
        Data(
            """
            {"status":"success","data":{"profile":{"name":"Ada Lovelace","title":"Mathematician",\
            "bio":"Wrote the first program.","stats":{"experience_years":5,"total_bookings":3}},\
            "topics_of_discussion":[],"recent_reviews":[],"is_bookable":true,"is_favorite":\(isFavorite)}}
            """.utf8
        )
    }

    nonisolated static let reviews = Data(
        """
        {"status":"success","data":{"summary":{"expert_id":"11111111-1111-4111-8111-111111111111",\
        "overall_rating":4.5,"total_reviews":0,"rating_distribution":{"5_star":0,"4_star":0,\
        "3_star":0,"2_star":0,"1_star":0}},"reviews":[]}}
        """.utf8
    )

    nonisolated static func toggled(isFavorite: Bool) -> Data {
        Data(
            #"{"status":"success","data":{"expert_id":"\#(expertId.uuidString.lowercased())","is_favorite":\#(isFavorite)}}"#.utf8
        )
    }

    nonisolated static func isDetails(_ request: URLRequest) -> Bool {
        request.url?.path.hasSuffix("/details") == true
    }

    nonisolated static func isToggle(_ request: URLRequest) -> Bool {
        (request.httpMethod == "PUT" || request.httpMethod == "DELETE")
            && request.url?.path.contains("/client/favorites/") == true
    }

    static func seed() -> PublicExpertProfile {
        PublicExpertProfile(
            expertId: expertId, name: "Seed Name", title: "", rating: 0, reviewCount: 0, yearsExp: "",
            bookings: "", isOnline: false, bio: "", expertiseTags: [], topics: [], reviews: [], imageURL: ""
        )
    }
}

extension HeldResponseTests {

    @Suite("Expert profile · heart against a late details response (IN-19)", .serialized)
    @MainActor
    struct ExpertProfileHeartRaceTests {

        /// Holds the details request. The favorite toggle answers at once with `toggleAnswer`.
        private func makeViewModel(toggleAnswer: Bool, holdingToggle: Bool = false) -> ExpertProfileViewModel {
            HeldURLProtocol.configure(
                hold: { HeartFixture.isDetails($0) || (holdingToggle && HeartFixture.isToggle($0)) },
                otherwise: { request in
                    if HeartFixture.isToggle(request) { return (200, HeartFixture.toggled(isFavorite: toggleAnswer)) }
                    if request.url?.path.hasSuffix("/reviews") == true { return (200, HeartFixture.reviews) }
                    return (404, Data(#"{"status":"error","message":"nope"}"#.utf8))
                }
            )
            return ExpertProfileViewModel(expert: HeartFixture.seed(), api: HeldURLProtocol.makeAPI())
        }

        @Test("a toggle that finished while the details were in flight is not undone by them")
        func finishedToggleSurvivesLateDetails() async throws {
            let viewModel = makeViewModel(toggleAnswer: true)
            let load = Task { await viewModel.loadProfileDetails() }
            try #require(await waitUntil("the details request to be held") { HeldURLProtocol.heldCount == 1 })

            await viewModel.toggleFavorite()
            #expect(viewModel.isFavorited)
            #expect(!viewModel.isFavoriteInFlight)

            // The server read the heart as empty, before the toggle.
            HeldURLProtocol.release(where: HeartFixture.isDetails, body: HeartFixture.details(isFavorite: false))
            await load.value

            #expect(viewModel.isFavorited)
            #expect(viewModel.loadState == .loaded)
        }

        @Test("a toggle still running when the details start keeps its value after both finish")
        func runningToggleSurvivesLateDetails() async throws {
            let viewModel = makeViewModel(toggleAnswer: true, holdingToggle: true)
            let toggle = Task { await viewModel.toggleFavorite() }
            try #require(await waitUntil("the toggle to be held") { HeldURLProtocol.heldCount == 1 })
            let load = Task { await viewModel.loadProfileDetails() }
            try #require(await waitUntil("the details request to be held") { HeldURLProtocol.heldCount == 2 })

            HeldURLProtocol.release(where: HeartFixture.isToggle, body: HeartFixture.toggled(isFavorite: true))
            await toggle.value
            HeldURLProtocol.release(where: HeartFixture.isDetails, body: HeartFixture.details(isFavorite: false))
            await load.value

            #expect(viewModel.isFavorited)
        }

        @Test("a details load that starts after the toggle finished applies the server value again")
        func laterLoadAppliesServerValue() async throws {
            let viewModel = makeViewModel(toggleAnswer: true)
            await viewModel.toggleFavorite()
            #expect(viewModel.isFavorited)

            // Another device unfavorited meanwhile; a load that starts now reads that.
            let load = Task { await viewModel.loadProfileDetails() }
            try #require(await waitUntil("the details request to be held") { HeldURLProtocol.heldCount == 1 })
            HeldURLProtocol.release(where: HeartFixture.isDetails, body: HeartFixture.details(isFavorite: false))
            await load.value

            #expect(!viewModel.isFavorited)
        }

        @Test("a details load with no toggle applies the server value")
        func detailsWithoutToggleApplyServerValue() async throws {
            let viewModel = makeViewModel(toggleAnswer: true)
            let load = Task { await viewModel.loadProfileDetails() }
            try #require(await waitUntil("the details request to be held") { HeldURLProtocol.heldCount == 1 })
            HeldURLProtocol.release(where: HeartFixture.isDetails, body: HeartFixture.details(isFavorite: true))
            await load.value

            #expect(viewModel.isFavorited)
        }
    }
}
