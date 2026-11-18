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
    /// The chosen reason; nothing is preselected (UI-SPEC A13).
    @Published var selectedReason: UserReportReason?
    /// Report details, capped at `maxDetailsLength` UTF-16 units on typing and paste.
    @Published var description: String {
        didSet {
            if description.utf16.count > Self.maxDetailsLength {
                description = UTF16Prefix.prefix(description, limit: Self.maxDetailsLength)
            }
        }
    }
    @Published var showBlockConfirm: Bool
    @Published var isSubmitting: Bool
    @Published var didSubmit: Bool
    @Published var isBlocking: Bool
    @Published var showReasonError: Bool

    // MARK: Block state (synced from `GET /chats` on `loadBlockState`)
    /// Who blocked this conversation, per `docs/ios/CHAT-UNBLOCK.md` §5. Every
    /// change is also handed to `onBlockStateChange`, so the thread behind this
    /// screen shows the new banner or composer without a reload (UI N1).
    @Published private(set) var blockState: ChatBlockState

    /// Title of the alert shown for `apiError`: one per action.
    @Published private(set) var apiErrorTitle = "Couldn't block user"
    /// Alert copy shown on a block, unblock or report failure.
    @Published var apiError: String?

    /// The Task of the latest block, unblock or report, kept so tests can await it.
    private(set) var actionTask: Task<Void, Never>?

    /// The moderation reasons the picker offers, in enum order.
    let reasons: [UserReportReason]

    /// Longest report details the screen allows. Android and `ReportUserSheet` cap
    /// at 1,000; the backend accepts 2,000 (`details: z.string().max(2000)`).
    static let maxDetailsLength = 1000

    /// Server thread id — required for the real API path. Nil in
    /// design/preview mode; block + report short-circuit to a canned
    /// animation without a network call.
    let threadId: UUID?

    // MARK: Dependencies

    private let api: ClickMeAPI
    private let onBlockStateChange: (ChatBlockState) -> Void
    /// Bumped on every state change, so a lookup that started earlier cannot
    /// overwrite a block or unblock that finished while it was running.
    private var stateRevision = 0

    // MARK: Init

    init(
        threadId: UUID? = nil,
        userName: String = "Dr. Olivia Bennett",
        selectedReason: UserReportReason? = nil,
        description: String = "",
        showBlockConfirm: Bool = false,
        isSubmitting: Bool = false,
        didSubmit: Bool = false,
        isBlocking: Bool = false,
        showReasonError: Bool = false,
        isBlocked: Bool = false,
        blockedByMe: Bool = false,
        reasons: [UserReportReason] = UserReportReason.allCases,
        api: ClickMeAPI = .shared,
        onBlockStateChange: @escaping (ChatBlockState) -> Void = { _ in }
    ) {
        self.threadId = threadId
        self.userName = userName
        self.selectedReason = selectedReason
        self.description = UTF16Prefix.prefix(description, limit: Self.maxDetailsLength)
        self.showBlockConfirm = showBlockConfirm
        self.isSubmitting = isSubmitting
        self.didSubmit = didSubmit
        self.isBlocking = isBlocking
        self.showReasonError = showReasonError
        self.blockState = ChatBlockState(isBlocked: isBlocked, blockedByMe: blockedByMe)
        self.reasons = reasons
        self.api = api
        self.onBlockStateChange = onBlockStateChange
    }

    // MARK: - Block-state sync

    /// Reads this thread's block flags from `GET /chats` (limit 100, up to 3 pages)
    /// on appear. A thread the lookup does not list, or a lookup that fails, leaves
    /// the state alone: a miss never reads as "not blocked" (CHAT-UNBLOCK §6), and
    /// an extra Block tap on a blocked thread is a documented 200 no-op.
    func loadBlockState() async {
        guard let threadId else { return }
        let revision = stateRevision
        do {
            guard let found = try await ChatThreadLookup.find(threadId: threadId, api: api) else { return }
            guard revision == stateRevision else { return }
            apply(blockState.applyScan(found: ChatBlockState.ScannedBlock(thread: found), sessionBlockedByMe: false))
        } catch {
            // Silent — see docstring.
        }
    }

    /// Waits for the latest block, unblock or report request (test seam).
    func awaitPendingAction() async { await actionTask?.value }

    /// Takes a new state and tells the thread behind this screen.
    private func apply(_ state: ChatBlockState) {
        stateRevision += 1
        blockState = state
        onBlockStateChange(state)
    }

    // MARK: - Reason selection

    func selectReason(_ reason: UserReportReason) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedReason = reason
            showReasonError = false
        }
    }

    // MARK: - Report

    /// Validates the form, then POSTs `chat_action = "report"` with the selected
    /// reason's raw value (D-09) and the trimmed details. Fires the caller's
    /// `onReport` closure on success and flips into the "submitted" animation state.
    /// A failure is shown and never retried: reports share a 10-per-hour limit.
    func submitReport(onReport: @escaping (String, String) -> Void) {
        guard !isSubmitting, !didSubmit else { return }
        guard let selected = selectedReason else {
            withAnimation { showReasonError = true }
            return
        }
        let reason = selected.rawValue
        let details = description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Preview / design path — canned success animation, no network.
        guard let threadId else {
            withAnimation { isSubmitting = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                guard let self else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.isSubmitting = false
                    self.didSubmit = true
                }
                onReport(reason, details)
            }
            return
        }

        apiError = nil
        withAnimation { isSubmitting = true }

        actionTask = Task { [weak self] in
            guard let self else { return }
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
                self.apiErrorTitle = "Couldn't send report"
                self.apiError = ChatBlockState.actionErrorMessage(
                    for: error,
                    connectionFallback: "Your report wasn't sent. Check your connection and try again."
                )
            }
        }
    }

    // MARK: - Block

    /// POSTs `chat_action = "block"`. A 200 is blocked by me (CHAT-UNBLOCK §6); the
    /// thread is told, then the caller's `onBlock` closure runs so the chat view can
    /// dismiss. If the peer blocked first, the next `GET /chats` corrects the state.
    func blockUser(onBlock: @escaping (String) -> Void) {
        guard !isBlocking else { return }

        // Preview / design path — immediate callback, no network.
        guard let threadId else {
            apply(blockState.onBlockSucceeded())
            onBlock(userName)
            return
        }

        apiError = nil
        isBlocking = true

        actionTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isBlocking = false }
            do {
                _ = try await self.api.chatAction(id: threadId, action: "block")
                self.apply(self.blockState.onBlockSucceeded())
                onBlock(self.userName)
            } catch {
                self.apiErrorTitle = "Couldn't block user"
                self.apiError = ChatBlockState.actionErrorMessage(for: error)
            }
        }
    }

    // MARK: - Unblock

    /// POSTs `chat_action = "unblock"`. Only the recorded blocker can; the server
    /// answers `403 NOT_BLOCKER` otherwise, which moves the state to blocked by the
    /// peer (CHAT-UNBLOCK §6) so the card drops its Unblock button.
    func unblockUser(onUnblock: @escaping (String) -> Void) {
        guard !isBlocking else { return }

        // Preview / design path — immediate callback, no network.
        guard let threadId else {
            apply(blockState.onUnblockSucceeded())
            onUnblock(userName)
            return
        }

        apiError = nil
        isBlocking = true

        actionTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isBlocking = false }
            do {
                _ = try await self.api.chatAction(id: threadId, action: "unblock")
                self.apply(self.blockState.onUnblockSucceeded())
                onUnblock(self.userName)
            } catch {
                if BookingErrorMapper.code(for: error) == .notBlocker {
                    self.apply(self.blockState.onNotBlocker())
                }
                self.apiErrorTitle = "Couldn't unblock user"
                self.apiError = ChatBlockState.actionErrorMessage(for: error)
            }
        }
    }
}
