//
//  BookingSummaryViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-27.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class BookingSummaryViewModel: ObservableObject {


    // MARK: Fetch identity

    /// Server booking UUID. `nil` in the preview-seed path where fields are
    /// injected directly and no fetch is performed.
    let bookingId: UUID?

    // MARK: Session data (server-fed at runtime, seeded in previews)

    /// Server UUID for the session's expert. Needed to push
    /// `MakeABookingView` when the user taps "Book Again". `nil` before the
    /// fetch settles or in the preview-seed path (previews don't need it).
    @Published var expertId: UUID?
    @Published var expertName: String
    @Published var expertTitle: String
    @Published var expertImageURL: String
    @Published var topic: String
    @Published var dateTime: String
    /// Formatted price the client paid for the session, e.g. `"$45.00"`.
    /// `nil` when the session was free or the server didn't send amount /
    /// currency for this booking.
    @Published var pricePaid: String?
    @Published var feedbackStars: Int
    @Published var feedbackText: String?

    /// True when the caller has already left a review for this booking.
    /// Drives whether the "Your Feedback" section shows the star + comment
    /// summary or a "Leave a review" CTA.
    @Published var hasSubmittedReview: Bool

    // MARK: Load state
    @Published var loadState: LoadState

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Realtime

    /// Auto-cancels on VM deallocation.
    private var bookingUpdateSubscription: RealtimeSubscription?

    /// Runtime init — fetches booking + review context from the backend.
    init(
        bookingId: UUID,
        api: ClickMeAPI = .shared
    ) {
        self.bookingId = bookingId
        self.expertId = nil
        self.expertName = ""
        self.expertTitle = ""
        self.expertImageURL = ""
        self.topic = ""
        self.dateTime = ""
        self.pricePaid = nil
        self.feedbackStars = 0
        self.feedbackText = nil
        self.hasSubmittedReview = false
        self.loadState = .idle
        self.api = api

        // Terminal state changes (e.g. completed) still land here — if
        // the booking is under this screen when it flips, refresh so
        // review eligibility / final price stay accurate.
        let targetId = bookingId
        self.bookingUpdateSubscription = RealtimeService.shared.onBookingUpdate { [weak self] event in
            guard event.bookingId == targetId else { return }
            Task { @MainActor in await self?.reload() }
        }
    }

    /// Preview seam — pre-populates all display fields as if the fetch had
    /// already succeeded, so `#Preview` renders faithfully without hitting
    /// the network.
    init(
        expertName: String = "David Miller",
        expertTitle: String = "Machine Learning Lead",
        expertImageURL: String = "https://lh3.googleusercontent.com/aida-public/AB6AXuBnTZGMesjV2RDjvDlTqiAhGQcKvp9VwRAGKeFBQjZ2Ne3kX7qgo1NEGGhlYpLGEM-O7oYGv4ngC22GSYW5O_7nNSrkzsKF21q6DvxVUAClnY1puOrcVVRfxo7a2Q8VsPQTLluTXbfFumBJAsA8IdqCPigzs8DbXKLxdIp29xbIBxU61gPcbgR5RkgqIyJ0vmmgN_pFjG77f1XqxGlAMxxuvd1iOf-mQ1Wzc-mmg94vsBrnZYSiSZuYJ-83ZQi8i5encZyL6jSAENg",
        topic: String = "Machine Learning Consultation",
        dateTime: String = "Oct 8, 2024 • 2:00 PM - 3:00 PM",
        pricePaid: String? = "$45.00",
        feedbackStars: Int = 5,
        feedbackText: String? = "David is truly an expert in his field. The way he broke down complex GAN concepts was incredible. Already seeing performance improvements in our dev environment. Highly recommended!",
        hasSubmittedReview: Bool = true,
        loadState: LoadState = .loaded
    ) {
        self.bookingId = nil
        self.expertId = nil
        self.expertName = expertName
        self.expertTitle = expertTitle
        self.expertImageURL = expertImageURL
        self.topic = topic
        self.dateTime = dateTime
        self.pricePaid = pricePaid
        self.feedbackStars = feedbackStars
        self.feedbackText = feedbackText
        self.hasSubmittedReview = hasSubmittedReview
        self.loadState = loadState
        self.api = .shared
    }

    // MARK: - Load

    /// Fetches `GET /client/bookings/:id` and `GET /bookings/:id/reviews/context`
    /// sequentially, then hydrates the display fields. Idempotent — skips
    /// when there's no `bookingId` (preview seed) or when already loaded.
    func load() async {
        guard let bookingId else { return }
        if case .loaded = loadState { return }
        await forceLoad(bookingId: bookingId)
    }

    func reload() async {
        guard let bookingId else { return }
        await forceLoad(bookingId: bookingId)
    }

    private func forceLoad(bookingId: UUID) async {
        loadState = .loading
        do {
            let detailResponse = try await api.getClientBookingDetail(id: bookingId)
            apply(detail: detailResponse.data)
        } catch {
            loadState = .failed(error.userMessage)
            return
        }

        // Review context is a soft dependency — if it fails we can still
        // render the expert card, we just hide the feedback section.
        do {
            let reviewResponse = try await api.getReviewContext(bookingId: bookingId)
            apply(reviewContext: reviewResponse.data)
        } catch {
            hasSubmittedReview = false
        }

        loadState = .loaded
    }

    private func apply(detail: ClientBookingDetail) {
        expertId = detail.expert.id
        expertName = detail.expert.fullName ?? ""
        expertTitle = detail.expert.title ?? ""
        expertImageURL = detail.expert.avatarUrl ?? ""
        topic = detail.topic.title
        dateTime = Self.formatDateTime(start: detail.startTime, end: detail.endTime)
        pricePaid = Self.formatPrice(topic: detail.topic)
    }

    /// Returns `nil` for free topics or when the server didn't send both an
    /// amount and a currency — the UI hides the row in that case. Amounts
    /// are in minor units (cents); we divide by 100 to a Double so cents
    /// aren't dropped for prices like $45.50.
    private static func formatPrice(topic: ClientBookingDetail.Topic) -> String? {
        if topic.isFree { return nil }
        guard let amount = topic.price?.amount,
              let currency = topic.price?.currency
        else { return nil }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        let value = Double(amount) / 100.0
        return formatter.string(from: NSNumber(value: value))
            // Fallback if `currencyCode` is unrecognized by ICU.
            ?? "\(currency) \(String(format: "%.2f", value))"
    }

    private func apply(reviewContext: ReviewContextData) {
        hasSubmittedReview = reviewContext.hasSubmitted
        feedbackStars = reviewContext.prefill?.rating ?? 0
        feedbackText = reviewContext.prefill?.comment
    }

    // MARK: - Formatting

    /// "Oct 8, 2024 • 2:00 PM - 3:00 PM" — matches the pre-integration copy
    /// so the layout is identical whether seeded or fetched.
    private static func formatDateTime(start: Date, end: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        let dateString = dateFormatter.string(from: start)
        let startTime = timeFormatter.string(from: start)
        let endTime = timeFormatter.string(from: end)
        return "\(dateString) • \(startTime) - \(endTime)"
    }

    // MARK: - Error mapping

}
