//
//  ExpertBookingSummaryViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ExpertBookingSummaryViewModel: ObservableObject {

    // MARK: Data

    let bookingId: UUID

    @Published var detail: ExpertBookingDetail?
    @Published var loadState: LoadState = .idle

    /// True while accept/decline is in-flight. Blocks double-taps and
    /// drives the button spinner. Cleared as soon as the follow-up
    /// detail refetch settles.
    @Published var isSubmittingReschedule: Bool = false
    /// Alert copy for reschedule accept/decline failures (403, 422, etc).
    @Published var rescheduleError: String?

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Init

    init(bookingId: UUID, api: ClickMeAPI = .shared) {
        self.bookingId = bookingId
        self.api = api
    }

    // MARK: - Load

    func load() async {
        if case .loaded = loadState { return }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        loadState = .loading
        do {
            let response = try await api.getExpertBookingDetails(id: bookingId)
            detail = response.data
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }
    }

    // MARK: - Display helpers

    /// `"Oct 24, 2026"`
    var dateLabel: String {
        guard let detail else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: detail.session.schedule.startTime)
    }

    /// `"10:30 AM – 11:30 AM"`
    var timeRangeLabel: String {
        guard let detail else { return "" }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        let start = f.string(from: detail.session.schedule.startTime)
        let end = f.string(from: detail.session.schedule.endTime)
        return "\(start) – \(end)"
    }

    /// `"60 min"`
    var durationLabel: String {
        guard let detail else { return "" }
        let minutes = Int(detail.session.schedule.endTime.timeIntervalSince(detail.session.schedule.startTime) / 60)
        return "\(minutes) min"
    }

    /// Human meeting-type label — `"In-App Voice"` / `"Skype/Zoom"`.
    var meetingTypeLabel: String {
        guard let detail else { return "" }
        switch detail.session.meetingType {
        case .inAppVoice: return "In-App Voice"
        case .skypeZoom:  return "Skype/Zoom"
        }
    }

    /// SF Symbol matching the meeting type.
    var meetingTypeIcon: String {
        guard let detail else { return "phone" }
        switch detail.session.meetingType {
        case .inAppVoice: return "phone"
        case .skypeZoom:  return "video"
        }
    }

    // MARK: - Reschedule actions

    /// Accept a client-initiated reschedule. Rolls the booking forward
    /// to the proposed slot server-side, then reloads detail so the
    /// UI reflects the new times + cleared reschedule block.
    func acceptReschedule() async {
        guard !isSubmittingReschedule else { return }
        isSubmittingReschedule = true
        defer { isSubmittingReschedule = false }
        do {
            _ = try await api.acceptExpertReschedule(id: bookingId)
            await forceLoad()
        } catch {
            rescheduleError = error.userMessage
        }
    }

    /// Decline a client-initiated reschedule. Reverts the booking to
    /// its previous status (typically `confirmed`) and discards the
    /// proposed slot. `reason` is optional metadata.
    func declineReschedule(reason: String?) async {
        guard !isSubmittingReschedule else { return }
        isSubmittingReschedule = true
        defer { isSubmittingReschedule = false }
        let trimmed = reason?.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            _ = try await api.declineExpertReschedule(
                id: bookingId,
                reason: (trimmed?.isEmpty ?? true) ? nil : trimmed
            )
            await forceLoad()
        } catch {
            rescheduleError = error.userMessage
        }
    }

    /// Human-readable "Aug 4 · 2:00 PM" for the proposed slot, rendered
    /// in the caller's local timezone (the server also sends
    /// `proposed_timezone` if we ever want to display it in the
    /// proposer's zone; today we render in the recipient's zone).
    func formattedProposedSlot(_ proposal: RescheduleProposal) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, MMM d · h:mm a"
        return f.string(from: proposal.proposedStart)
    }

    /// Server-provided pre-formatted fee label (e.g. `"$50 USD"`).
    /// Falls back to `"<amount> <currency>"` when the server label is empty.
    var feeLabel: String {
        guard let fee = detail?.session.consultationFee else { return "" }
        if !fee.label.isEmpty { return fee.label }
        return "\(fee.amount) \(fee.currency)"
    }
}
