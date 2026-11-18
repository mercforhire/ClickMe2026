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
            do {
                let response = try await api.initiateChat(peerId: peerId)
                _ = try await api.chatAction(id: response.data.threadId, action: "block")
                toasts.show("You blocked \(Self.displayName(peerName))", systemImage: "checkmark.circle.fill")
            } catch {
                apiError = error.userMessage
            }
            isBlocking = false
        }
    }
}
