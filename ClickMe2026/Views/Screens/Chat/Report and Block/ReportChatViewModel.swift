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
    @Published var isBlocking: Bool
    @Published var showReasonError: Bool

    /// Alert copy shown on either block or report failure.
    @Published var apiError: String?

    let reasons: [String]

    /// Server thread id — required for the real API path. Nil in
    /// design/preview mode; block + report short-circuit to a canned
    /// animation without a network call.
    let threadId: UUID?

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Init

    init(
        threadId: UUID? = nil,
        userName: String = "Dr. Olivia Bennett",
        selectedReason: String = "",
        description: String = "",
        showBlockConfirm: Bool = false,
        isSubmitting: Bool = false,
        didSubmit: Bool = false,
        isBlocking: Bool = false,
        showReasonError: Bool = false,
        reasons: [String] = ReportChatViewModel.defaultReasons,
        api: ClickMeAPI = .shared
    ) {
        self.threadId = threadId
        self.userName = userName
        self.selectedReason = selectedReason
        self.description = description
        self.showBlockConfirm = showBlockConfirm
        self.isSubmitting = isSubmitting
        self.didSubmit = didSubmit
        self.isBlocking = isBlocking
        self.showReasonError = showReasonError
        self.reasons = reasons
        self.api = api
    }

    // MARK: - Reason selection

    func selectReason(_ reason: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedReason = reason
            showReasonError = false
        }
    }

    // MARK: - Report

    /// Validates the form, then POSTs `chat_action = "report"` with the
    /// selected reason + description. Fires the caller's `onReport`
    /// closure on success and flips into the "submitted" animation state.
    func submitReport(onReport: @escaping (String, String) -> Void) {
        guard !isSubmitting, !didSubmit else { return }
        guard !selectedReason.isEmpty else {
            withAnimation { showReasonError = true }
            return
        }

        // Preview / design path — canned success animation, no network.
        guard let threadId else {
            withAnimation { isSubmitting = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                guard let self else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.isSubmitting = false
                    self.didSubmit = true
                }
                onReport(self.selectedReason, self.description)
            }
            return
        }

        apiError = nil
        withAnimation { isSubmitting = true }

        Task { [weak self] in
            guard let self else { return }
            let reason = self.selectedReason
            let details = self.description.trimmingCharacters(in: .whitespacesAndNewlines)
            do {
                _ = try await self.api.chatAction(
                    id: threadId,
                    action: "report",
                    reason: reason,
                    details: details.isEmpty ? nil : details
                )
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.isSubmitting = false
                    self.didSubmit = true
                }
                onReport(reason, details)
            } catch {
                withAnimation { self.isSubmitting = false }
                self.apiError = Self.errorMessage(for: error)
            }
        }
    }

    // MARK: - Block

    /// POSTs `chat_action = "block"`. Fires the caller's `onBlock` closure
    /// on success so the chat view can dismiss.
    func blockUser(onBlock: @escaping (String) -> Void) {
        guard !isBlocking else { return }

        // Preview / design path — immediate callback, no network.
        guard let threadId else {
            onBlock(userName)
            return
        }

        apiError = nil
        isBlocking = true

        Task { [weak self] in
            guard let self else { return }
            defer { self.isBlocking = false }
            do {
                _ = try await self.api.chatAction(id: threadId, action: "block")
                onBlock(self.userName)
            } catch {
                self.apiError = Self.errorMessage(for: error)
            }
        }
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
