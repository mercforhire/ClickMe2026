//
//  ReportChatViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-01.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ReportChatViewModel: ObservableObject {

    // MARK: Content
    @Published var userName: String

    // MARK: Report form state
    @Published var selectedReason: String
    @Published var description: String
    @Published var showBlockConfirm: Bool
    @Published var isSubmitting: Bool
    @Published var didSubmit: Bool
    @Published var showReasonError: Bool

    let reasons: [String]

    init(
        userName: String = "Dr. Olivia Bennett",
        selectedReason: String = "",
        description: String = "",
        showBlockConfirm: Bool = false,
        isSubmitting: Bool = false,
        didSubmit: Bool = false,
        showReasonError: Bool = false,
        reasons: [String] = ReportChatViewModel.defaultReasons
    ) {
        self.userName = userName
        self.selectedReason = selectedReason
        self.description = description
        self.showBlockConfirm = showBlockConfirm
        self.isSubmitting = isSubmitting
        self.didSubmit = didSubmit
        self.showReasonError = showReasonError
        self.reasons = reasons
    }

    // MARK: Actions

    func selectReason(_ reason: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedReason = reason
            showReasonError = false
        }
    }

    /// Validate and run the submitting → submitted animation choreography.
    /// Networking is intentionally disabled while testing the app flow.
    func submitReport(onReport: @escaping (String, String) -> Void) {
        guard !isSubmitting, !didSubmit else { return }
        guard !selectedReason.isEmpty else {
            withAnimation { showReasonError = true }
            return
        }
        withAnimation { isSubmitting = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self.isSubmitting = false
                self.didSubmit = true
            }
            onReport(self.selectedReason, self.description)
        }
    }

    // MARK: Defaults

    static let defaultReasons: [String] = [
        "Spam or scam",
        "Harassment or bullying",
        "Inappropriate content",
        "Fake profile",
        "Hate speech",
        "Other",
    ]
}
