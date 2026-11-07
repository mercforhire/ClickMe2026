//
//  ReportChatViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-01.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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

    // MARK: Block state (synced from `GET /chats` on `loadBlockState`)
    /// `true` when the backing thread is blocked by either party. Drives
    /// the composer-disabled + banner states in `ReportChatBlockCard`.
    @Published var isBlocked: Bool
    /// `true` only when the caller is the recorded blocker, per
    /// `docs/ios/CHAT-UNBLOCK.md` §5.
    @Published var blockedByMe: Bool
    /// Set to `true` after a `403 NOT_BLOCKER` response — prevents the
    /// user from re-tapping Unblock and re-triggering the same denial.
    /// Legacy-block (§7) escape hatch: we still show Unblock when
    /// `blockedByMe` is false, but one rejection latches the button off
    /// for the remainder of this screen session.
    @Published var unblockDenied: Bool = false

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
        isBlocked: Bool = false,
        blockedByMe: Bool = false,
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
        self.isBlocked = isBlocked
        self.blockedByMe = blockedByMe
        self.reasons = reasons
        self.api = api
    }

    // MARK: - Block-state sync

    /// Fetches `GET /chats` once on view appear and extracts THIS
    /// thread's `isBlocked` + `blockedByMe` flags. There's no
    /// single-thread read endpoint, so we scan the list. Silent on
    /// failure — the card falls back to the "unknown ⇒ show Block"
    /// default, which is the safest wrong answer (an extra Block tap
    /// on an already-blocked thread is a documented 200 no-op).
    func loadBlockState() async {
        guard let threadId else { return }
        do {
            let response = try await api.getChats(page: 1, limit: 50)
            if let thread = response.data.threads.first(where: { $0.threadId == threadId }) {
                isBlocked = thread.isBlocked
                blockedByMe = thread.blockedByMe ?? false
            }
        } catch {
            // Silent — see docstring.
        }
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
                self.apiError = error.userMessage
            }
        }
    }

    // MARK: - Block

    /// POSTs `chat_action = "block"`. Fires the caller's `onBlock` closure
    /// on success so the chat view can dismiss. Locally reconciles state
    /// per `docs/ios/CHAT-UNBLOCK.md` §6 — if the peer actually blocked
    /// first, the next `GET /chats` will correct us.
    func blockUser(onBlock: @escaping (String) -> Void) {
        guard !isBlocking else { return }

        // Preview / design path — immediate callback, no network.
        guard let threadId else {
            isBlocked = true
            blockedByMe = true
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
                self.isBlocked = true
                self.blockedByMe = true
                onBlock(self.userName)
            } catch {
                self.apiError = error.userMessage
            }
        }
    }

    // MARK: - Unblock

    /// POSTs `chat_action = "unblock"`. Only valid for the recorded
    /// blocker; the server returns `403 NOT_BLOCKER` otherwise, which
    /// we reconcile per `docs/ios/CHAT-UNBLOCK.md` §6
    /// (`is_blocked = true, blocked_by_me = false`) so the UI drops the
    /// Unblock affordance and shows the "You can't reply" banner.
    func unblockUser(onUnblock: @escaping (String) -> Void) {
        guard !isBlocking else { return }

        // Preview / design path — immediate callback, no network.
        guard let threadId else {
            isBlocked = false
            blockedByMe = false
            onUnblock(userName)
            return
        }

        apiError = nil
        isBlocking = true

        Task { [weak self] in
            guard let self else { return }
            defer { self.isBlocking = false }
            do {
                _ = try await self.api.chatAction(id: threadId, action: "unblock")
                self.isBlocked = false
                self.blockedByMe = false
                onUnblock(self.userName)
            } catch {
                // 403 NOT_BLOCKER → stay blocked but by the other party.
                // We'd never show the Unblock button in that state, so
                // this is defense-in-depth against race conditions
                // (e.g. the peer blocked between our last load and now).
                if case let NetworkError.httpError(status, data) = error,
                   status == 403,
                   let envelope = try? JSONDecoder().decode(StandardErrorResponse.self, from: data),
                   envelope.code == .notBlocker
                {
                    self.isBlocked = true
                    self.blockedByMe = false
                    self.unblockDenied = true
                }
                self.apiError = error.userMessage
            }
        }
    }

    // MARK: - Error mapping


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
