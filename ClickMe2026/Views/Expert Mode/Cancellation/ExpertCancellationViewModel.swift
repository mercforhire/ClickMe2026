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

    init(
        clientName: String = "Marcus Chen",
        clientImageURL: String = ExpertCancellationViewModel.sampleImageURL,
        sessionTopic: String = "Advanced UX Mentorship",
        dateTime: String = "Wed, Oct 25 • 2:00 PM - 3:00 PM",
        refundType: String = "full refund",
        selectedReason: CancellationReason = .none,
        showReasonPicker: Bool = false,
        isCancelling: Bool = false
    ) {
        self.clientName = clientName
        self.clientImageURL = clientImageURL
        self.sessionTopic = sessionTopic
        self.dateTime = dateTime
        self.refundType = refundType
        self.selectedReason = selectedReason
        self.showReasonPicker = showReasonPicker
        self.isCancelling = isCancelling
    }

    // MARK: Actions

    func selectReason(_ reason: CancellationReason) {
        selectedReason = reason
        showReasonPicker = false
    }

    /// Start the cancellation choreography (0.6s delay so the spinner is visible)
    /// then fire the caller's confirmation callback.
    func confirmCancellation(onConfirm: @escaping (CancellationReason) -> Void) {
        guard !isCancelling else { return }
        isCancelling = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self else { return }
            onConfirm(self.selectedReason)
        }
    }

    // MARK: Defaults

    static let sampleImageURL = "https://lh3.googleusercontent.com/aida-public/AB6AXuDCOCKO8Jh3Fbog5yeJjSZME2HdEtpgiy2Pt8UZYEmtxT8vPftYq60O6IWPdP2pG56WHlsXU-oHGMY6kiXZzCPIMZ2FYgqaAfpCcc1lEMy0TsrGqKelaCsqYtfh5Xase1bE71McPLDjmgRyUi7cKDB_1Db7-4-iMm6lfIRssnx9zaaZ4E_qTXFrEUXzspZ9aAhy_wCN7HpjK2CY06mfthhK004CI1TQJfD5T9lPU-uSzvE_vIBz3TT8lcqSS4VzPzKL3UqUwTPdlfg"
}
