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

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: Types fetch

    @Published var feedbackTypes: [FeedbackTypeItem]
    @Published var loadState: LoadState

    // MARK: Form state

    @Published var selectedType: FeedbackTypeItem?
    @Published var details: String
    @Published var email: String
    @Published var showTypePicker: Bool

    // MARK: Submission state

    @Published var isSubmitting: Bool
    @Published var didSubmit: Bool
    @Published var showDetailsError: Bool
    /// Non-field submission failures — network / 5xx / 429. Surfaced as an alert.
    @Published var apiError: String?

    // MARK: Dependencies

    private let api: ClickMeAPI

    init(
        feedbackTypes: [FeedbackTypeItem] = [],
        loadState: LoadState = .idle,
        selectedType: FeedbackTypeItem? = nil,
        details: String = "",
        email: String = "",
        showTypePicker: Bool = false,
        isSubmitting: Bool = false,
        didSubmit: Bool = false,
        showDetailsError: Bool = false,
        apiError: String? = nil,
        api: ClickMeAPI = .shared
    ) {
        self.feedbackTypes = feedbackTypes
        self.loadState = loadState
        self.selectedType = selectedType
        self.details = details
        self.email = email
        self.showTypePicker = showTypePicker
        self.isSubmitting = isSubmitting
        self.didSubmit = didSubmit
        self.showDetailsError = showDetailsError
        self.apiError = apiError
        self.api = api
    }

    /// Preview seam — installs canned types + a preselected first entry
    /// as if the fetch had already succeeded.
    static func previewSeed(
        types: [FeedbackTypeItem] = FeedbackViewModel.sampleTypes,
        selectedIndex: Int = 0,
        details: String = "",
        email: String = "",
        showDetailsError: Bool = false
    ) -> FeedbackViewModel {
        FeedbackViewModel(
            feedbackTypes: types,
            loadState: .loaded,
            selectedType: types.indices.contains(selectedIndex) ? types[selectedIndex] : types.first,
            details: details,
            email: email,
            showDetailsError: showDetailsError
        )
    }

    // MARK: - Load

    /// Fetches `GET /feedback/types` and defaults the picker to the first
    /// entry. Idempotent — skips when already loaded so it doesn't clobber
    /// preview seeds.
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
            let response = try await api.getFeedbackTypes()
            feedbackTypes = response.data.types
            if selectedType == nil, let first = feedbackTypes.first {
                selectedType = first
            }
            loadState = .loaded
        } catch {
            loadState = .failed(Self.errorMessage(for: error))
        }
    }

    // MARK: - Actions

    func selectType(_ type: FeedbackTypeItem) {
        withAnimation(.easeInOut(duration: 0.2)) { selectedType = type }
    }

    /// Clear the details validation error if the user has started typing.
    func detailsDidChange() {
        if showDetailsError, !details.isEmpty {
            withAnimation { showDetailsError = false }
        }
    }

    // MARK: - Submit

    /// Validates locally, POSTs `/feedback/submit`, then either flashes the
    /// "Feedback Sent!" confirmation and auto-clears the form, or maps the
    /// failure back to inline / alert error state.
    func submit() async {
        guard !isSubmitting, !didSubmit else { return }

        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedDetails.isEmpty else {
            withAnimation { showDetailsError = true }
            return
        }
        guard let typeId = selectedType?.id else {
            apiError = "Please choose a feedback category before submitting."
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) { isSubmitting = true }
        defer { isSubmitting = false }

        do {
            _ = try await api.submitFeedback(
                typeId: typeId,
                details: trimmedDetails,
                email: trimmedEmail.isEmpty ? nil : trimmedEmail,
                metadata: nil
            )
        } catch {
            handle(submitError: error)
            return
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            didSubmit = true
        }
        // Auto-clear the form once submission is confirmed so the next visit
        // starts fresh instead of reusing stale copy.
        details = ""
        email = ""
        showDetailsError = false
        if let first = feedbackTypes.first { selectedType = first }

        // Flash the "Sent!" confirmation for 2s, then drop back to the idle
        // Submit label so the button is ready for another entry.
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        withAnimation { didSubmit = false }
    }

    // MARK: - Error mapping

    private func handle(submitError error: Error) {
        guard case let NetworkError.httpError(statusCode, data) = error else {
            apiError = Self.errorMessage(for: error)
            return
        }

        switch statusCode {
        case 422:
            // Map field errors onto their fields. In practice these come
            // through as `details` (empty/too short) or `email` (bad format).
            if let response = try? JSONDecoder().decode(FieldValidationErrorResponse.self, from: data) {
                var handled = false
                for fieldError in response.errors {
                    switch fieldError.field {
                    case "details":
                        withAnimation { showDetailsError = true }
                        handled = true
                    case "email", "type_id":
                        apiError = fieldError.message
                        handled = true
                    default:
                        apiError = fieldError.message
                        handled = true
                    }
                }
                if !handled {
                    apiError = "Please check your entries and try again."
                }
            } else {
                apiError = Self.decodeStandardMessage(from: data)
                    ?? "Please check your entries and try again."
            }

        case 429:
            apiError = "Too many attempts. Please try again in a moment."

        default:
            apiError = Self.decodeStandardMessage(from: data)
                ?? "Couldn't send your feedback. Please try again."
        }
    }

    private static func decodeStandardMessage(from data: Data) -> String? {
        (try? JSONDecoder().decode(StandardErrorResponse.self, from: data))?.message
    }

    private static func errorMessage(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    // MARK: Previews

    /// Sample data for `#Preview` — shape matches the real server response
    /// so preview cards look faithful without a network call.
    static let sampleTypes: [FeedbackTypeItem] = [
        FeedbackTypeItem(id: "bug_report",       label: "Bug Report",        description: "Something isn't working right."),
        FeedbackTypeItem(id: "feature_request",  label: "Feature Request",   description: "An idea for improvement."),
        FeedbackTypeItem(id: "general_feedback", label: "General Feedback",  description: "Anything else you'd like to share."),
        FeedbackTypeItem(id: "performance",      label: "Performance Issue", description: "The app feels slow or unresponsive."),
        FeedbackTypeItem(id: "other",            label: "Other",             description: "Doesn't fit any category above."),
    ]
}
