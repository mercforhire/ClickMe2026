//
//  ChatStarter.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-22.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import Observation

/// Single-flight `POST /chats/initiate` for a Message button.
///
/// One in-flight initiate per screen, and a failure is shown, never swallowed
/// (WR-10). The expert Booking Summary, Upcoming Bookings list and Request
/// Decision screens each hold one and bind `apiError` to a "Couldn't start chat"
/// alert. The client Booking Summary and Upcoming Booking details keep their own
/// equivalent in their view models.
///
/// Observable rather than `ObservableObject`, like `RescheduleResponder`: the
/// owning screens are SwiftUI views that read `isStarting` and `apiError` in their body.
@MainActor
@Observable
final class ChatStarter {

    /// True while `POST /chats/initiate` runs. The button can show a spinner and
    /// disable itself, and `start(peerId:)` ignores repeat calls while it is set.
    private(set) var isStarting = false

    /// Text for the "Couldn't start chat" alert; nil when there is no error.
    var apiError: String?

    @ObservationIgnored private let api: ClickMeAPI

    /// - Parameter api: The API client; tests inject a stubbed one.
    init(api: ClickMeAPI = .shared) {
        self.api = api
    }

    /// Gets or creates the chat thread with `peerId`.
    ///
    /// - Parameter peerId: The other user's id.
    /// - Returns: The thread id, or nil when there is nothing to open: a chat is
    ///   already being started (this call does nothing), the call failed (`apiError`
    ///   then holds the text for the alert), or the task was cancelled (the screen
    ///   went away, which is not an error).
    func start(peerId: UUID) async -> UUID? {
        guard !isStarting else { return nil }
        isStarting = true
        defer { isStarting = false }
        apiError = nil
        do {
            return try await api.initiateChat(peerId: peerId).data.threadId
        } catch {
            guard !error.isCancellation else { return nil }
            // The backend answers 404 for a new thread with a suspended or removed user.
            if case NetworkError.httpError(let statusCode, _) = error, statusCode == 404 {
                apiError = ExpertProfileBlockViewModel.unavailableMessage
            } else if BookingErrorMapper.code(for: error) == .notFound {
                apiError = ExpertProfileBlockViewModel.unavailableMessage
            } else {
                apiError = error.userMessage
            }
            return nil
        }
    }
}
