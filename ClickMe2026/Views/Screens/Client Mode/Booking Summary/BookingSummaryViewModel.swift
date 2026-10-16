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

    /// In-flight flag for accept/decline reschedule.
    @Published var isSubmittingReschedule: Bool = false
    @Published var rescheduleError: String?

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
        self.status = nil
        self.hasSubmittedReview = false
        self.privateNote = nil
        self.reschedule = nil
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
        self.currentStartTime = nil
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
        status = Self.mapStatus(detail.status)
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

    // MARK: - Payment-conversion disclosure (Phase 27.1)

    /// True when accepting the pending reschedule would push the
    /// session past this booking's authorization window — in which
    /// case the server voids the current hold and re-schedules the
    /// charge to ~24h before the new session. Drives the accept-
    /// reschedule confirmation dialog's copy.
    var requiresAcceptRescheduleDisclosure: Bool {
        guard let expiresAt = authorizationExpiresAt,
              let proposal = reschedule
        else { return false }
        return proposal.proposedEnd > expiresAt
    }

    /// True when the T-24h charge would fire within the next ~24 hours
    /// (proposed session start under 48h from now). Used to append the
    /// near-term caveat to the disclosure copy. Sub-24h proposals are
    /// refused server-side, so this only fires in the 24–48h band.
    var acceptRescheduleChargesSoon: Bool {
        guard let proposal = reschedule else { return false }
        return proposal.proposedStart.timeIntervalSinceNow < 48 * 3600
    }

    // MARK: - Reschedule actions

    /// Accept an expert-initiated reschedule. Rolls the booking
    /// forward server-side, then reloads detail so the banner clears
    /// and the times update. No-op when there's no booking id
    /// (preview seed) or a submission is already in flight.
    ///
    /// **PAYMENT_METHOD_REQUIRED recovery (Phase 27.1):** the check on
    /// this endpoint is DB-only — a 422 does not mean "user has no
    /// cards." Fetch the vault and retry with a `stripe_payment_method_id`
    /// when possible. See `RESCHEDULE-PAYMENT-CONVERSION.md` §3.1.
    func acceptReschedule() async {
        guard !isSubmittingReschedule, let bookingId else { return }
        isSubmittingReschedule = true
        defer { isSubmittingReschedule = false }

        do {
            _ = try await api.acceptClientReschedule(id: bookingId)
            await forceLoad(bookingId: bookingId)
            return
        } catch {
            guard Self.errorCode(for: error) == .paymentMethodRequired else {
                rescheduleError = error.userMessage
                return
            }
            // Fall through to pm-recovery below.
        }

        let vault: [PaymentMethodItem]
        do {
            vault = try await api.getPaymentMethods().data.paymentMethods
        } catch {
            rescheduleError = "Couldn't check your saved payment methods. Please try again."
            return
        }

        let preferredId = vault.first(where: { $0.isDefault })?.id ?? vault.first?.id
        guard let pmId = preferredId else {
            rescheduleError = "Please add a payment method in Settings > Payment before accepting this reschedule."
            return
        }

        do {
            _ = try await api.acceptClientReschedule(id: bookingId, stripePaymentMethodId: pmId)
            await forceLoad(bookingId: bookingId)
        } catch {
            // Second failure is terminal — including a repeat
            // PAYMENT_METHOD_REQUIRED (the chosen card can't be
            // prepared for future billing either).
            if Self.errorCode(for: error) == .paymentMethodRequired {
                rescheduleError = "The card on file can't be used for this reschedule. Please add a new payment method in Settings > Payment and try again."
            } else {
                rescheduleError = error.userMessage
            }
        }
    }

    private static func errorCode(for error: Error) -> ErrorCode? {
        guard case let NetworkError.httpError(_, data) = error,
              let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        else { return nil }
        return response.code
    }

    /// Decline an expert-initiated reschedule with an optional reason.
    func declineReschedule(reason: String?) async {
        guard !isSubmittingReschedule, let bookingId else { return }
        isSubmittingReschedule = true
        defer { isSubmittingReschedule = false }
        let trimmed = reason?.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            _ = try await api.declineClientReschedule(
                id: bookingId,
                reason: (trimmed?.isEmpty ?? true) ? nil : trimmed
            )
            await forceLoad(bookingId: bookingId)
        } catch {
            rescheduleError = error.userMessage
        }
    }

    /// "Wed, Jul 10 · 10:00 AM" — used by the from/to row on the
    /// reschedule banner.
    func formatSlot(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, MMM d · h:mm a"
        return f.string(from: date)
    }

    /// Collapse the raw wire status to the 3-case badge enum. Same rule
    /// used by `MyBookingsViewModel.mapPastIfApplicable`. Returns nil
    /// for statuses that don't belong on the summary badge (e.g.
    /// `pending_approval / confirmed / in_progress` — the summary
    /// screen is only ever pushed for terminal bookings, but we
    /// silently hide rather than lie if the caller opens it early).
    private static func mapStatus(_ raw: String) -> PastBookingStatus? {
        guard let status = BookingStatus(rawValue: raw) else { return nil }
        switch status {
        case .completed:                      return .completed
        case .cancelled, .declined:           return .cancelled
        case .missed, .expired:               return .missed
        case .pendingApproval, .confirmed,
             .pendingReschedule, .inProgress: return nil
        }
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
