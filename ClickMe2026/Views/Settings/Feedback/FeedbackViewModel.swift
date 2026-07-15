//
//  FeedbackViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-29.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class FeedbackViewModel: ObservableObject {

    // MARK: View state
    @Published var feedbackType: String
    @Published var details: String
    @Published var email: String
    @Published var showTypePicker: Bool
    @Published var isSubmitting: Bool
    @Published var didSubmit: Bool
    @Published var showDetailsError: Bool

    let feedbackTypes: [String]

    init(
        feedbackType: String = "Bug Report",
        details: String = "",
        email: String = "",
        showTypePicker: Bool = false,
        isSubmitting: Bool = false,
        didSubmit: Bool = false,
        showDetailsError: Bool = false,
        feedbackTypes: [String] = FeedbackViewModel.defaultTypes
    ) {
        self.feedbackType = feedbackType
        self.details = details
        self.email = email
        self.showTypePicker = showTypePicker
        self.isSubmitting = isSubmitting
        self.didSubmit = didSubmit
        self.showDetailsError = showDetailsError
        self.feedbackTypes = feedbackTypes
    }

    // MARK: Actions

    func selectType(_ type: String) {
        withAnimation(.easeInOut(duration: 0.2)) { feedbackType = type }
    }

    /// Clear the details validation error if the user has started typing.
    func detailsDidChange() {
        if showDetailsError, !details.isEmpty {
            withAnimation { showDetailsError = false }
        }
    }

    /// Validate and run the submitting → submitted animation choreography.
    /// Networking is intentionally disabled while testing the app flow.
    func submit() {
        guard !isSubmitting, !didSubmit else { return }
        guard !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            withAnimation { showDetailsError = true }
            return
        }
        withAnimation(.easeInOut(duration: 0.2)) { isSubmitting = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self.isSubmitting = false
                self.didSubmit = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                withAnimation { self?.didSubmit = false }
            }
        }
    }

    // MARK: Defaults

    static let defaultTypes: [String] = [
        "Bug Report",
        "Feature Request",
        "General Feedback",
        "Performance Issue",
        "Other",
    ]
}
