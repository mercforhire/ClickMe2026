//
//  ClientCancellationViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-27.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ClientCancellationViewModel: ObservableObject {


    // MARK: Identity
    let bookingId: UUID?

    // MARK: View state
    @Published var step: CancelStep
    @Published var selectedReason: String
    @Published var comment: String
    @Published var isConfirming: Bool

    // MARK: Data
    @Published var booking: CancellationBooking
    @Published var loadState: LoadState
    /// Alert text for cancel-request failures (network / 4xx / 5xx).
    @Published var cancelError: String?
    /// True after a Confirm Cancellation tap found the refund case had changed
    /// since it was shown. The tap submitted nothing; the next tap does (D-06).
    @Published var previewChangedNotice = false

    let reasons: [String]

    // MARK: Dependencies

    private let api: ClickMeAPI
    /// The clock the refund preview reads. Injected so tests can move time.
    private let now: @MainActor () -> Date

    /// Runtime init — fetches display fields from `GET /client/bookings/:id`
    /// then lets the user pick a reason before calling
    /// `POST /client/bookings/:id/cancel`.
    init(
        bookingId: UUID,
        api: ClickMeAPI = .shared,
        now: @escaping @MainActor () -> Date = { Date() }
    ) {
        self.bookingId = bookingId
        self.step = .reason
        self.selectedReason = ClientCancellationViewModel.defaultReasons.first ?? ""
        self.comment = ""
        self.isConfirming = false
        self.booking = ClientCancellationViewModel.placeholderBooking
        self.loadState = .idle
        self.reasons = ClientCancellationViewModel.defaultReasons
        self.api = api
        self.now = now
    }

    /// Preview seam — pre-populates the display booking as if the fetch had
    /// already succeeded, so `#Preview` renders without a network call.
    init(
        booking: CancellationBooking = ClientCancellationViewModel.sampleBooking,
        step: CancelStep = .reason,
        selectedReason: String = "Change of plans",
        comment: String = "",
        isConfirming: Bool = false,
        reasons: [String] = ClientCancellationViewModel.defaultReasons
    ) {
        self.bookingId = nil
        self.booking = booking
        self.step = step
        self.selectedReason = selectedReason
        self.comment = comment
        self.isConfirming = isConfirming
        self.loadState = .loaded
        self.reasons = reasons
        self.api = .shared
        self.now = { Date() }
        recomputeRefundCase()
    }

    // MARK: - Load

    /// Fetches the booking's display fields. Idempotent — skips when there's
    /// no `bookingId` (preview seed) or when already loaded.
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
            let response = try await api.getClientBookingDetail(id: bookingId)
            booking = Self.map(detail: response.data)
            recomputeRefundCase()
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }
    }

    private static func map(detail: ClientBookingDetail) -> CancellationBooking {
        CancellationBooking(
            expertName: detail.expert.fullName ?? "",
            expertTitle: detail.expert.title ?? detail.topic.title,
            dateString: formatDateTime(start: detail.startTime, end: detail.endTime),
            imageURL: detail.expert.avatarUrl ?? "",
            refundFacts: CancelRefundPreview.Facts(detail: detail),
            refundCase: nil
        )
    }

    // MARK: - Refund preview

    /// Re-evaluates the money case from the booking facts and the clock.
    /// Called after a load and every 60 seconds while the confirm step is on
    /// screen, so the line follows the 24-hour edge (D-06).
    func recomputeRefundCase() {
        guard let facts = booking.refundFacts else { return }
        booking.refundCase = CancelRefundPreview.refundCase(facts, now: now())
    }

    // MARK: - Actions

    func advanceToConfirmation() {
        withAnimation { step = .confirmation }
    }

    /// Fires `POST /client/bookings/:id/cancel` with the picked reason as
    /// a display string. On success, invokes the caller's `onConfirm`
    /// closure so the parent NavigationStack can pop back and refresh.
    /// Comment is intentionally dropped — the server only accepts a single
    /// `reason` field today.
    ///
    /// The refund case is recomputed first. If it differs from the one on
    /// screen (for example the session crossed the 24-hour line while the step
    /// was open), the new case is stored, `previewChangedNotice` is set and
    /// nothing is sent; the next tap submits (D-06).
    func confirmCancellation(onConfirm: @escaping (String, String) -> Void) async {
        guard !isConfirming else { return }

        if let facts = booking.refundFacts {
            let current = CancelRefundPreview.refundCase(facts, now: now())
            if current != booking.refundCase {
                booking.refundCase = current
                previewChangedNotice = true
                return
            }
        }
        previewChangedNotice = false

        guard let bookingId else {
            // Preview / seeded path — no real booking to cancel.
            onConfirm(selectedReason, comment)
            return
        }

        cancelError = nil
        withAnimation { isConfirming = true }
        defer { isConfirming = false }

        do {
            _ = try await api.cancelClientBooking(id: bookingId, reason: selectedReason)
        } catch {
            cancelError = error.userMessage
            return
        }

        onConfirm(selectedReason, comment)
    }

    // MARK: - Formatting

    /// Matches the pre-integration copy so the layout is identical whether
    /// seeded or fetched — e.g. `"Wed, Jul 10 • 10:00 AM"`.
    private static func formatDateTime(start: Date, end: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, MMM d"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        return "\(dateFormatter.string(from: start)) • \(timeFormatter.string(from: start))"
    }

    // MARK: - Error mapping


    // MARK: Sample data

    static let defaultReasons: [String] = [
        "Change of plans",
        "Found another expert",
        "Schedule conflict",
        "Personal emergency",
        "Other",
    ]

    /// Empty stub the runtime init points at while the real detail fetch
    /// is in flight. Content is never shown — the view routes the loading
    /// state to a spinner instead.
    private static let placeholderBooking = CancellationBooking(
        expertName: "",
        expertTitle: "",
        dateString: "",
        imageURL: "",
        refundFacts: nil,
        refundCase: nil
    )

    static let sampleBooking = CancellationBooking(
        expertName: "Dr. Anya Sharma",
        expertTitle: "Career Coaching",
        dateString: "Wed, Jul 10 • 10:00 AM",
        imageURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuDOLbdN4ist5Yp2MU-iazD2ggqG2F42GhJKUDhi5omBTMQfsZ3aOtpJMI9x9l_BIc9uFxsR8Lm6fNjwJHuR85wD7jybmImSDCQBOeUITRzo8CARgZN-NnDwUZ5qrRhyWZQyQsu0uapd_3Xun_JTJNPp5yEWCYxukV7kO2-I-WVPLdAIRR18ZAhKbJ-EY4V6bi-sSR4ZWdwvqphktPI2BYaOKzT_05jLA25ati_Shxxg7npPn2mY05T4M16WVkyPp8szqHyPI3yoLBo",
        // A paid, already-charged booking three days out, so previews show case C.
        refundFacts: CancelRefundPreview.Facts(
            isFree: false,
            priceAmountMinor: 4500,
            currency: "CAD",
            paymentStatus: "captured",
            authorizationExpiresAt: nil,
            paymentActionRequired: false,
            start: Date().addingTimeInterval(3 * 24 * 3600)
        ),
        refundCase: nil
    )
}
