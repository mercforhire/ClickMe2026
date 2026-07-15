//
//  RequestDecisionViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class RequestDecisionViewModel: ObservableObject {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: Data

    /// Server request UUID — nil in the preview-seed path where fields are
    /// injected directly and no fetch is performed.
    let requestId: UUID?

    @Published var request: IncomingRequest
    @Published var clientMessage: String
    @Published var potentialEarnings: Double
    @Published var currency: String
    /// Inherited from the list — when true the footer hides Accept/Decline
    /// and the view renders an "This request has expired" banner instead.
    @Published var isExpired: Bool

    @Published var loadState: LoadState

    // MARK: Sheet state
    @Published var showAcceptSheet = false
    @Published var showDeclineSheet = false

    // MARK: Submission state
    @Published var isSubmitting: Bool
    @Published var isAccepted: Bool
    @Published var isDeclined: Bool
    @Published var submitError: String?

    // MARK: Dependencies
    private let api: ClickMeAPI

    // MARK: Init

    /// Runtime init — hydrates from `GET /expert/booking-requests/:id`.
    init(
        requestId: UUID,
        isExpired: Bool = false,
        api: ClickMeAPI = .shared
    ) {
        self.requestId = requestId
        self.request = IncomingRequest.placeholder
        self.clientMessage = ""
        self.potentialEarnings = 0
        self.currency = "USD"
        self.isExpired = isExpired
        self.loadState = .idle
        self.isSubmitting = false
        self.isAccepted = false
        self.isDeclined = false
        self.submitError = nil
        self.api = api
    }

    /// Preview seam — pre-populates all display fields as if the fetch had
    /// already succeeded, so `#Preview` renders faithfully without hitting
    /// the network.
    init(
        request: IncomingRequest = IncomingRequest.samples[0],
        clientMessage: String = "Hi, I'm really looking forward to our session. I'd love to discuss my career path and get your advice on breaking into the design industry. Thanks!",
        potentialEarnings: Double = 75.0,
        currency: String = "USD",
        isExpired: Bool = false,
        loadState: LoadState = .loaded
    ) {
        self.requestId = nil
        self.request = request
        self.clientMessage = clientMessage
        self.potentialEarnings = potentialEarnings
        self.currency = currency
        self.isExpired = isExpired
        self.loadState = loadState
        self.isSubmitting = false
        self.isAccepted = false
        self.isDeclined = false
        self.submitError = nil
        self.api = .shared
    }

    // MARK: - Load

    /// Fetches `GET /expert/booking-requests/:id`. Idempotent — skips when
    /// there's no `requestId` (preview seed) or when already loaded.
    func load() async {
        guard let requestId else { return }
        if case .loaded = loadState { return }
        await forceLoad(requestId: requestId)
    }

    func reload() async {
        guard let requestId else { return }
        await forceLoad(requestId: requestId)
    }

    private func forceLoad(requestId: UUID) async {
        loadState = .loading
        do {
            let response = try await api.getBookingRequest(id: requestId)
            let detail = response.data
            request = Self.map(detail: detail, isExpired: isExpired)
            clientMessage = detail.session.clientMessage ?? ""
            potentialEarnings = detail.economics.potentialEarnings ?? 0
            currency = detail.economics.currency ?? "USD"
            loadState = .loaded
        } catch {
            loadState = .failed(Self.errorMessage(for: error))
        }
    }

    // MARK: - Sheet intents

    func openAcceptSheet() {
        guard !isExpired, !isAccepted, !isDeclined else { return }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            showAcceptSheet = true
        }
    }

    func openDeclineSheet() {
        guard !isExpired, !isAccepted, !isDeclined else { return }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            showDeclineSheet = true
        }
    }

    func dismissSheets() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            showAcceptSheet = false
            showDeclineSheet = false
        }
    }

    // MARK: - Accept / Decline API calls

    /// Fires `POST /expert/booking-requests/:id/accept`. `message` is
    /// optional — trimmed and nil'd when empty. On success closes the
    /// sheet and flips `isAccepted` for the footer's "Accepted!" state.
    func confirmAccept(message: String) async {
        guard let requestId else { return }
        guard !isSubmitting else { return }

        submitError = nil
        isSubmitting = true
        defer { isSubmitting = false }

        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            _ = try await api.acceptBookingRequest(
                id: requestId,
                message: trimmed.isEmpty ? nil : trimmed
            )
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                showAcceptSheet = false
            }
            withAnimation(.easeInOut(duration: 0.25).delay(0.15)) {
                isAccepted = true
            }
        } catch {
            submitError = Self.errorMessage(for: error)
        }
    }

    /// Fires `POST /expert/booking-requests/:id/decline`. `reasonCode` is
    /// required (server enum, e.g. `UNAVAILABLE`); `reasonText` is
    /// optional free-text shown to the client.
    func confirmDecline(reasonCode: String, reasonText: String) async {
        guard let requestId else { return }
        guard !isSubmitting else { return }

        submitError = nil
        isSubmitting = true
        defer { isSubmitting = false }

        let trimmed = reasonText.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            _ = try await api.declineBookingRequest(
                id: requestId,
                reasonCode: reasonCode,
                reasonText: trimmed.isEmpty ? nil : trimmed
            )
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                showDeclineSheet = false
            }
            withAnimation(.easeInOut(duration: 0.25).delay(0.15)) {
                isDeclined = true
            }
        } catch {
            submitError = Self.errorMessage(for: error)
        }
    }

    // MARK: - Other intents

    /// Fires from the "Message" button in the footer. TODO: wire to the
    /// chat thread with this client once the chat flow is available from
    /// the expert side.
    func messageTapped() {
        // no-op for now
    }

    /// Fires from the "View Profile" label under the client name. TODO:
    /// wire to a public client profile route once that screen exists.
    func viewProfileTapped() {
        // no-op for now
    }

    // MARK: - Mapping

    private static func map(detail: BookingRequestDetail, isExpired: Bool) -> IncomingRequest {
        IncomingRequest(
            id: detail.requestId,
            clientName: detail.client.name ?? "Client",
            topic: detail.session.topic ?? "Session",
            date: formatDate(detail.session.startTime),
            time: formatTime(detail.session.startTime),
            duration: formatDuration(start: detail.session.startTime, end: detail.session.endTime),
            earnings: detail.economics.potentialEarnings ?? 0,
            currency: detail.economics.currency ?? "USD",
            meetingType: detail.session.meetingType,
            imageURL: detail.client.avatarUrl ?? "",
            clientNote: detail.session.clientMessage,
            isExpired: isExpired
        )
    }

    private static func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    private static func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    private static func formatDuration(start: Date, end: Date) -> String {
        let minutes = Int(end.timeIntervalSince(start) / 60)
        return "\(minutes)m"
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
}

// MARK: - Decline reason enum

/// Machine-readable decline reasons sent to
/// `POST /expert/booking-requests/:id/decline` as `reason_code`.
/// Human labels are for the client-side picker. Backend spec:
/// "Machine-readable decline reason (e.g. UNAVAILABLE, OUTSIDE_EXPERTISE)".
enum DeclineReason: String, CaseIterable, Identifiable {
    case unavailable = "UNAVAILABLE"
    case outsideExpertise = "OUTSIDE_EXPERTISE"
    case scheduleConflict = "SCHEDULE_CONFLICT"
    case pricing = "PRICING"
    case other = "OTHER"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .unavailable:       return "Not available at that time"
        case .outsideExpertise:  return "Outside my expertise"
        case .scheduleConflict:  return "Schedule conflict"
        case .pricing:           return "Pricing mismatch"
        case .other:             return "Other reason"
        }
    }
}
