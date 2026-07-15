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

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

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
            loadState = .failed(Self.errorMessage(for: error))
        }
    }

    private static func map(detail: ClientBookingDetail) -> CancellationBooking {
        CancellationBooking(
            expertName: detail.expert.fullName ?? "",
            expertTitle: detail.expert.title ?? detail.topic.title,
            dateString: formatDateTime(start: detail.startTime, end: detail.endTime),
            imageURL: detail.expert.avatarUrl ?? "",
            // Refund preview endpoint is a follow-up backend task — hide
            // the copy until the server tells us the refund policy for
            // this booking.
            refundType: nil
        )
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
            cancelError = Self.errorMessage(for: error)
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

    private static func errorMessage(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

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
        refundType: nil
    )

    static let sampleBooking = CancellationBooking(
        expertName: "Dr. Anya Sharma",
        expertTitle: "Career Coaching",
        dateString: "Wed, Jul 10 • 10:00 AM",
        imageURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuDOLbdN4ist5Yp2MU-iazD2ggqG2F42GhJKUDhi5omBTMQfsZ3aOtpJMI9x9l_BIc9uFxsR8Lm6fNjwJHuR85wD7jybmImSDCQBOeUITRzo8CARgZN-NnDwUZ5qrRhyWZQyQsu0uapd_3Xun_JTJNPp5yEWCYxukV7kO2-I-WVPLdAIRR18ZAhKbJ-EY4V6bi-sSR4ZWdwvqphktPI2BYaOKzT_05jLA25ati_Shxxg7npPn2mY05T4M16WVkyPp8szqHyPI3yoLBo",
        refundType: nil
    )
}
