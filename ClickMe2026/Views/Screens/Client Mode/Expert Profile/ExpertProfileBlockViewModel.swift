//
//  ExpertProfileBlockViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// Blocks an expert from their public profile (CHAT-04, D-06).
///
/// The thread endpoint is the only block API: `POST /chats/{id}/actions` with
/// action `block`. A profile has no thread id, so the block first runs the
/// idempotent `POST /chats/initiate` to get or create one. The profile stays on
/// screen and no chat is opened; success is a toast through `ToastCenter`, and
/// unblocking happens in the chat.
///
/// Copy only describes messaging (D-05). The view asks for confirmation before
/// calling `block`, so nothing is sent until the user confirms.
@MainActor
final class ExpertProfileBlockViewModel: ObservableObject {

    /// Shown when `POST /chats/initiate` answers 404: the backend refuses a new thread
    /// with a suspended or removed peer.
    static let unavailableMessage = "This user is unavailable."

    /// True while the initiate and block requests run. The view shows a scrim and
    /// disables the menu, and `block` ignores repeat calls (D-06).
    @Published private(set) var isBlocking = false

    /// Text for the "Couldn't block user" alert; nil when there is no error.
    @Published var apiError: String?

    /// The running block, kept so tests can await it.
    private(set) var blockTask: Task<Void, Never>?

    private let api: ClickMeAPI
    private let toasts: ToastCenter

    init(api: ClickMeAPI = .shared, toasts: ToastCenter = .shared) {
        self.api = api
        self.toasts = toasts
    }

    /// The name used in the alert title and toast: `this user` when the name is empty.
    static func displayName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "this user" : trimmed
    }

    /// The alert text for a failed `initiateChat`. The backend answers 404 for a new thread with a
    /// suspended or removed peer, so that status (or the `NOT_FOUND` code) reads as unavailable.
    /// Branches on status and `ErrorCode`, never on message text.
    private static func initiateErrorMessage(for error: Error) -> String {
        if case NetworkError.httpError(let statusCode, _) = error, statusCode == 404 {
            return unavailableMessage
        }
        if BookingErrorMapper.code(for: error) == .notFound { return unavailableMessage }
        return ChatBlockState.actionErrorMessage(for: error)
    }

    /// Test seam: waits for the running block, if any.
    func awaitBlock() async {
        await blockTask?.value
    }

    /// Gets or creates the thread with `peerId`, then blocks it.
    /// - Parameters:
    ///   - peerId: The expert's user id.
    ///   - peerName: Shown in the confirmation toast.
    func block(peerId: UUID, peerName: String) {
        guard !isBlocking else { return }
        isBlocking = true
        apiError = nil
        blockTask = Task { [weak self] in
            guard let self else { return }
            let threadId: UUID
            do {
                threadId = try await api.initiateChat(peerId: peerId).data.threadId
            } catch {
                apiError = Self.initiateErrorMessage(for: error)
                isBlocking = false
                return
            }
            do {
                _ = try await api.chatAction(id: threadId, action: "block")
                toasts.show("You blocked \(Self.displayName(peerName))", systemImage: "checkmark.circle.fill")
            } catch {
                apiError = ChatBlockState.actionErrorMessage(for: error)
            }
            isBlocking = false
        }
    }
}
