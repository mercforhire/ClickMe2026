//
//  LoadCancellationTests.swift
//  ClickMe2026Tests
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//
//  IN-15: a load cancelled because its screen went away (`URLError.cancelled`) is
//  not a failure. The section goes back to what it showed before, so no failure
//  card flashes and the next appearance loads again.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("A cancelled load is not a failure (IN-15)", .serialized)
@MainActor
struct LoadCancellationTests {

    private func cancelledAPI() -> ClickMeAPI {
        APITestFactory.make { _ in throw URLError(.cancelled) }
    }

    // MARK: Helpers

    @Test("isCancellation is true for CancellationError and URLError.cancelled only")
    func isCancellation() {
        #expect(CancellationError().isCancellation)
        #expect(URLError(.cancelled).isCancellation)
        #expect(!URLError(.timedOut).isCancellation)
        #expect(!URLError(.notConnectedToInternet).isCancellation)
        #expect(!NetworkError.invalidResponse.isCancellation)
    }

    @Test("afterCancelledLoad returns to the earlier state and leaves a settled section alone")
    func afterCancelledLoad() {
        #expect(LoadState.loading.afterCancelledLoad(previous: .idle) == .idle)
        #expect(LoadState.loading.afterCancelledLoad(previous: .failed("Offline")) == .failed("Offline"))
        #expect(LoadState.loading.afterCancelledLoad(previous: .loaded) == .loaded)
        #expect(LoadState.loading.afterCancelledLoad(previous: .loading) == .idle)
        #expect(LoadState.loaded.afterCancelledLoad(previous: .idle) == .loaded)
        #expect(LoadState.failed("Later").afterCancelledLoad(previous: .idle) == .failed("Later"))
    }

    // MARK: The four loaders

    @Test("Make a Booking topics: a cancelled first load goes back to idle")
    func topicsCancelledFirstLoad() async {
        let viewModel = MakeABookingViewModel(
            expertId: UUID(), expertName: "Ada", expertTitle: "Engineer", expertImageURL: "", api: cancelledAPI()
        )

        await viewModel.loadTopics()

        #expect(viewModel.topicsState == .idle)
    }

    @Test("Make a Booking topics: a cancelled retry keeps the earlier failure")
    func topicsCancelledRetry() async {
        let viewModel = MakeABookingViewModel(
            expertId: UUID(), expertName: "Ada", expertTitle: "Engineer", expertImageURL: "", api: cancelledAPI()
        )
        viewModel.topicsState = .failed("Offline")

        await viewModel.loadTopics()

        #expect(viewModel.topicsState == .failed("Offline"))
    }

    @Test("Make a Booking topics: a real failure still shows")
    func topicsRealFailure() async {
        let api = APITestFactory.make { _ in throw URLError(.notConnectedToInternet) }
        let viewModel = MakeABookingViewModel(
            expertId: UUID(), expertName: "Ada", expertTitle: "Engineer", expertImageURL: "", api: api
        )

        await viewModel.loadTopics()

        guard case .failed = viewModel.topicsState else {
            Issue.record("a lost connection must still be a failure, got \(viewModel.topicsState)")
            return
        }
    }

    @Test("Favorites: a cancelled first load goes back to idle, a cancelled retry keeps the failure")
    func favoritesCancelled() async {
        let viewModel = FavoritesViewModel(api: cancelledAPI())

        await viewModel.load()
        #expect(viewModel.state == .idle)

        viewModel.state = .failed("Offline")
        await viewModel.reload()
        #expect(viewModel.state == .failed("Offline"))
    }

    @Test("Reviews: a cancelled first load goes back to idle, a cancelled retry keeps the failure")
    func reviewsCancelled() async {
        let viewModel = ExpertReviewsViewModel(expertId: UUID(), api: cancelledAPI())

        await viewModel.load()
        #expect(viewModel.state == .idle)

        viewModel.state = .failed("Offline")
        await viewModel.reload()
        #expect(viewModel.state == .failed("Offline"))
    }

    @Test("Request Sent: a cancelled first load goes back to idle, a cancelled retry keeps the failure")
    func requestSentCancelled() async {
        let viewModel = BookingRequestSentViewModel(bookingId: UUID(), api: cancelledAPI())

        await viewModel.load()
        #expect(viewModel.state == .idle)

        viewModel.state = .failed("Offline")
        await viewModel.reload()
        #expect(viewModel.state == .failed("Offline"))
    }
}
