//
//  ClientCancellationViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-27.
//  Copyright © 2026 Q42. All rights reserved.
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

    let reasons: [String]

    // MARK: Dependencies

    private let api: ClickMeAPI

    /// Runtime init — fetches display fields from `GET /client/bookings/:id`
    /// then lets the user pick a reason before calling
    /// `POST /client/bookings/:id/cancel`.
    init(
        bookingId: UUID,
        api: ClickMeAPI = .shared
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
            refundAmount: refundAmount(from: detail)
        )
    }

    /// Client-side preview of the refund amount until a server-side refund
    /// endpoint lands. Shows the paid amount when the money is still with
    /// us (`held` / `captured`) — hides for free sessions, refunded
    /// bookings, or when no payment was made. Actual refund amount is
    /// resolved on the server when the cancel call fires.
    private static func refundAmount(from detail: ClientBookingDetail) -> String? {
        if detail.topic.isFree { return nil }
        switch detail.paymentStatus {
        case "held", "captured":
            break
        default:
            return nil
        }
        guard let amount = detail.topic.price?.amount,
              let currency = detail.topic.price?.currency
        else { return nil }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        let value = Double(amount) / 100.0
        return formatter.string(from: NSNumber(value: value))
            ?? "\(currency) \(String(format: "%.2f", value))"
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
    func confirmCancellation(onConfirm: @escaping (String, String) -> Void) async {
        guard !isConfirming else { return }
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
        refundAmount: nil
    )

    static let sampleBooking = CancellationBooking(
        expertName: "Dr. Anya Sharma",
        expertTitle: "Career Coaching",
        dateString: "Wed, Jul 10 • 10:00 AM",
        imageURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuDOLbdN4ist5Yp2MU-iazD2ggqG2F42GhJKUDhi5omBTMQfsZ3aOtpJMI9x9l_BIc9uFxsR8Lm6fNjwJHuR85wD7jybmImSDCQBOeUITRzo8CARgZN-NnDwUZ5qrRhyWZQyQsu0uapd_3Xun_JTJNPp5yEWCYxukV7kO2-I-WVPLdAIRR18ZAhKbJ-EY4V6bi-sSR4ZWdwvqphktPI2BYaOKzT_05jLA25ati_Shxxg7npPn2mY05T4M16WVkyPp8szqHyPI3yoLBo",
        refundAmount: "$45.00"
    )
}
