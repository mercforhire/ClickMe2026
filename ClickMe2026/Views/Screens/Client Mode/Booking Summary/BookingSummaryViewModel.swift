//
//  BookingSummaryViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-27.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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

    /// Session outcome collapsed to the 3-case UI enum
    /// (completed / cancelled / missed). Drives the status badge on the
    /// expert card. Nil until the fetch resolves or the server returns
    /// a status the past-bucket mapping doesn't recognize — in that
    /// case the badge is hidden rather than lying with a stale label.
    @Published var status: PastBookingStatus?

    /// True when the caller has already left a review for this booking.
    /// Drives whether the "Your Feedback" section shows the star + comment
    /// summary or a "Leave a review" CTA.
    @Published var hasSubmittedReview: Bool

    /// Whether the Leave a Review button shows (BOOK-17): only for a
    /// completed session that has no review yet. A cancelled, declined,
    /// missed or expired booking never invites a review, because the server
    /// refuses one for a session that did not happen. `status` is nil until
    /// the detail loads, so nothing shows while the status is unknown.
    var showsLeaveReview: Bool { status == .completed && !hasSubmittedReview }

    /// The short booking ID line, for example `"ID: #A1B2C3D4"` (BOOK-20).
    /// Built by `BookingShortID`, the same helper Upcoming Booking details
    /// uses, so support sees one format across screens and platforms.
    @Published var bookingIDLabel: String?

    /// The expert's reason for declining, or nil when the booking was not
    /// declined or carries neither a code nor a note (BACK-02). The card shows
    /// only when this is set.
    @Published var declineNote: DeclineNote?

    /// Full text of the client's private note on this booking, surfaced
    /// from `ClientBookingDetail.privateNote`. `nil` while loading or
    /// when no note has been written — the "My Note" card renders an
    /// empty-state ghost in that case.
    @Published var privateNote: String?

    /// Pending reschedule proposal on this booking, or `nil` when the
    /// booking isn't in the `pending_reschedule` state. Drives the
    /// reschedule banner + accept/decline actions on the summary.
    @Published var reschedule: RescheduleProposal?

    /// End of the Stripe authorization window on this booking, or
    /// `nil` for free / long-lead / captured / terminal bookings.
    /// Non-gating (Phase 27.1) — used only to decide whether accepting
    /// the reschedule needs the payment-conversion disclosure copy.
    @Published var authorizationExpiresAt: Date?

    // MARK: Reschedule response

    /// Answers an expert-proposed time (BOOK-06, D-01). The same responder the
    /// Upcoming Booking details screen uses, so the accept disclosure and the
    /// PAYMENT_METHOD_REQUIRED recovery exist once. Its `refetch` is this
    /// model's silent `refresh()`, so a successful accept or decline updates
    /// the screen in place with no loading spinner (D-03). `onResolved` clears
    /// `reschedule` first, so the card goes even when that refresh fails (WR-01).
    let responder: RescheduleResponder

    // MARK: Load state
    @Published var loadState: LoadState

    /// Newest-refetch gate for `forceLoad(bookingId:)`. A `booking.update`
    /// during a pull-to-refresh, or a reschedule action's reload racing a
    /// socket refetch, starts overlapping fetches; only the most recently
    /// started one may write the screen (BOOK-18).
    private var reloads = ReloadGeneration()

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
        self.status = nil
        self.hasSubmittedReview = false
        self.privateNote = nil
        self.reschedule = nil
        self.bookingIDLabel = BookingShortID.label(bookingId)
        self.loadState = .idle
        self.api = api
        self.responder = RescheduleResponder(bookingId: bookingId, api: api)

        // Terminal state changes (e.g. completed) still land here — if
        // the booking is under this screen when it flips, refresh so
        // review eligibility / final price stay accurate. The refetch is
        // silent (`refresh()`): a realtime event never flips a loaded screen
        // back to a spinner, and a failed refetch keeps the content (D-03).
        // `reload()` stays for pull-to-refresh and the error state's retry.
        let targetId = bookingId
        self.bookingUpdateSubscription = RealtimeService.shared.onBookingUpdate { [weak self] event in
            guard event.bookingId == targetId else { return }
            Task { @MainActor in await self?.refresh() }
        }
        responder.refetch = { [weak self] in await self?.refresh() }
        responder.onResolved = { [weak self] in self?.reschedule = nil }
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
        status: PastBookingStatus? = .completed,
        privateNote: String? = nil,
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
        self.status = status
        self.hasSubmittedReview = hasSubmittedReview
        self.privateNote = privateNote
        self.reschedule = nil
        self.bookingIDLabel = "ID: #A1B2C3D4"
        self.currentStartTime = nil
        self.loadState = loadState
        self.api = .shared
        // No booking id, so the responder never sends a request.
        self.responder = RescheduleResponder(bookingId: nil)
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

    /// Re-fetches without leaving `.loaded`, so the content stays on screen
    /// while it updates (D-03). A failed detail fetch while loaded keeps the
    /// last good content; a failed review-context fetch keeps the previous
    /// review state. The detail and the review context are written together,
    /// and only while this call is still the newest. When not yet loaded this
    /// runs the full load instead, so the newest call settles `loadState`.
    func refresh() async {
        guard let bookingId else { return }
        guard case .loaded = loadState else {
            await forceLoad(bookingId: bookingId)
            return
        }
        let token = reloads.begin()
        let detail: ClientBookingDetail
        do {
            detail = try await api.getClientBookingDetail(id: bookingId).data
        } catch {
            // Intentionally swallowed: keep the last known good screen.
            return
        }
        guard reloads.isCurrent(token) else { return }

        // Review context is a soft dependency, as in the full load.
        let reviewContext = try? await api.getReviewContext(bookingId: bookingId).data
        guard reloads.isCurrent(token) else { return }

        apply(detail: detail)
        if let reviewContext {
            apply(reviewContext: reviewContext)
        }
    }

    /// Fetches the booking detail, then the review context, and hydrates the
    /// display fields. Overlapping calls keep only the newest response: the
    /// token is checked after each await, so a call superseded by a later one
    /// writes neither data nor load state and returns at its first failed
    /// check, while the newest call always settles `loadState`.
    private func forceLoad(bookingId: UUID) async {
        let token = reloads.begin()
        loadState = .loading
        do {
            let detailResponse = try await api.getClientBookingDetail(id: bookingId)
            guard reloads.isCurrent(token) else { return }
            apply(detail: detailResponse.data)
        } catch {
            guard reloads.isCurrent(token) else { return }
            loadState = .failed(error.userMessage)
            return
        }

        // Review context is a soft dependency — if it fails we can still
        // render the expert card, we just hide the feedback section.
        do {
            let reviewResponse = try await api.getReviewContext(bookingId: bookingId)
            guard reloads.isCurrent(token) else { return }
            apply(reviewContext: reviewResponse.data)
        } catch {
            guard reloads.isCurrent(token) else { return }
            hasSubmittedReview = false
        }

        guard reloads.isCurrent(token) else { return }
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
        status = Self.mapStatus(detail.status)
        declineNote = DeclineNote.make(
            status: detail.status,
            code: detail.declineReasonCode,
            text: detail.declineReasonText
        )
        privateNote = detail.privateNote
        reschedule = detail.reschedule
        currentStartTime = detail.startTime
        authorizationExpiresAt = detail.authorizationExpiresAt
    }

    /// The booking's *current* scheduled start — used by the reschedule
    /// banner to render the "From" side of the moving-from → moving-to
    /// row. Nil in preview seeds; the banner only shows when
    /// `reschedule` is set, and that only happens after `apply(detail:)`
    /// has run.
    @Published var currentStartTime: Date?

    /// Body of the "Accept the proposed reschedule?" dialog. Comes from the
    /// shared responder, so the payment-conversion disclosure and the
    /// near-term caveat read the same as on Upcoming Booking details.
    var acceptDialogMessage: String {
        RescheduleResponder.acceptDialogMessage(
            proposal: reschedule,
            authorizationExpiresAt: authorizationExpiresAt,
            now: Date()
        )
    }

    /// Collapse the raw wire status to the 3-case badge enum. Same rule
    /// used by `MyBookingsViewModel.mapPastIfApplicable`. Returns nil
    /// for statuses that don't belong on the summary badge (e.g.
    /// `pending_approval / confirmed / in_progress / rescheduled /
    /// unknown` — the summary screen is only ever pushed for terminal
    /// bookings, but we silently hide rather than lie if the caller opens
    /// it early or the status is one this build doesn't know).
    private static func mapStatus(_ raw: String) -> PastBookingStatus? {
        guard let status = BookingStatus(rawValue: raw) else { return nil }
        switch status {
        case .completed:                      return .completed
        case .cancelled, .declined:           return .cancelled
        case .missed, .expired:               return .missed
        case .pendingApproval, .confirmed,
             .pendingReschedule, .inProgress,
             .rescheduled, .unknown:          return nil
        }
    }

    /// Returns `nil` for free topics or when the server didn't send both an
    /// amount and a currency — the UI hides the row in that case. Amounts
    /// are in minor units; `Money` formats them with integer math so cents
    /// are never dropped for prices like $45.50.
    private static func formatPrice(topic: ClientBookingDetail.Topic) -> String? {
        if topic.isFree { return nil }
        guard let amount = topic.price?.amount,
              let currency = topic.price?.currency
        else { return nil }

        return Money.format(minorUnits: amount, currency: currency)
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
