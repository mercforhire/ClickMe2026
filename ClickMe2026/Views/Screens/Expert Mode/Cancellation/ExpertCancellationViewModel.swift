//
//  ExpertCancellationViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-02.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ExpertCancellationViewModel: ObservableObject {

    // MARK: Content
    @Published var clientName: String
    @Published var clientImageURL: String
    @Published var sessionTopic: String
    @Published var dateTime: String
    @Published var refundType: String

    // MARK: Form state
    @Published var selectedReason: CancellationReason
    @Published var showReasonPicker: Bool
    @Published var isCancelling: Bool

    /// Non-fatal error surfaced from the cancel API call.
    @Published var apiError: String?

    // MARK: Booking identity

    /// Server booking id. Nil in the design/preview path where the screen
    /// is instantiated with canned display copy; required for the API
    /// path so `confirmCancellation` has something to POST against.
    let bookingId: UUID?

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Init

    init(
        bookingId: UUID? = nil,
        clientName: String = "Marcus Chen",
        clientImageURL: String = ExpertCancellationViewModel.sampleImageURL,
        sessionTopic: String = "Advanced UX Mentorship",
        dateTime: String = "Wed, Oct 25 • 2:00 PM - 3:00 PM",
        refundType: String = "full refund",
        selectedReason: CancellationReason = .none,
        showReasonPicker: Bool = false,
        isCancelling: Bool = false,
        api: ClickMeAPI = .shared
    ) {
        self.bookingId = bookingId
        self.clientName = clientName
        self.clientImageURL = clientImageURL
        self.sessionTopic = sessionTopic
        self.dateTime = dateTime
        self.refundType = refundType
        self.selectedReason = selectedReason
        self.showReasonPicker = showReasonPicker
        self.isCancelling = isCancelling
        self.api = api
    }

    // MARK: Actions

    func selectReason(_ reason: CancellationReason) {
        selectedReason = reason
        showReasonPicker = false
    }

    /// POSTs `/expert/bookings/:id/cancel` with the selected reason, then
    /// fires the caller's `onConfirm` on success. On failure the alert
    /// surfaces via `apiError` and the view stays open.
    ///
    /// When `bookingId` is nil (preview / design path) skips the network
    /// hop and simulates success after 0.6s so the choreography still
    /// runs in the canvas.
    func confirmCancellation(onConfirm: @escaping (CancellationReason) -> Void) {
        guard !isCancelling, selectedReason != .none else { return }
        apiError = nil
        isCancelling = true

        // Preview / design path — no bookingId, no network call.
        guard let bookingId else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self else { return }
                let reason = self.selectedReason
                self.isCancelling = false
                onConfirm(reason)
            }
            return
        }

        // Runtime path — real cancel.
        Task { [weak self] in
            guard let self else { return }
            defer { self.isCancelling = false }
            do {
                _ = try await self.api.cancelExpertBooking(
                    id: bookingId,
                    reason: self.selectedReason.rawValue
                )
                onConfirm(self.selectedReason)
            } catch {
                self.apiError = error.userMessage
            }
        }
    }

    // MARK: - Error mapping


    // MARK: Defaults

    static let sampleImageURL = "https://lh3.googleusercontent.com/aida-public/AB6AXuDCOCKO8Jh3Fbog5yeJjSZME2HdEtpgiy2Pt8UZYEmtxT8vPftYq60O6IWPdP2pG56WHlsXU-oHGMY6kiXZzCPIMZ2FYgqaAfpCcc1lEMy0TsrGqKelaCsqYtfh5Xase1bE71McPLDjmgRyUi7cKDB_1Db7-4-iMm6lfIRssnx9zaaZ4E_qTXFrEUXzspZ9aAhy_wCN7HpjK2CY06mfthhK004CI1TQJfD5T9lPU-uSzvE_vIBz3TT8lcqSS4VzPzKL3UqUwTPdlfg"
}
