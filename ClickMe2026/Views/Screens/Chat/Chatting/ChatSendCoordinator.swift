//
//  ChatSendCoordinator.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Owns every chat send in flight, so `ChattingViewModel` holds no send
/// bookkeeping (07-CONTEXT code_context: "put the send/retry state into a helper
/// type", CLAUDE.md Function Design). A sibling of the view model in the manner
/// of `RescheduleResponder`.
///
/// One task per `client_msg_id` (D-01). `send` makes the POST, classifies the
/// result and hands the outcome back to the view model, which applies it to its
/// own `items` and `messageText`. The coordinator never reads or writes those,
/// keeps no message text once a send has finished, and never logs or stores
/// anything (D-02): a failed bubble exists only in the view model's memory.
///
/// Mirrors Android `ChatThreadViewModel.kt` `deliver`.
///
/// Not observable: it holds no view state.
final class ChatSendCoordinator {

    // MARK: Outcome

    /// How one POST ended, after classification.
    enum Outcome: Equatable {
        /// 201: the server has the message under `messageId`.
        case acked(messageId: UUID, timestamp: Date, status: MessageStatus)
        /// A network or server failure; the bubble stays on screen as Failed (D-01).
        case keptAsFailed
        /// The server refused the message (HTTP 4xx). The bubble goes away and the
        /// text returns to the composer (D-03).
        case refused(code: ErrorCode?, message: String)
    }

    // MARK: State

    private let api: ClickMeAPI
    private var inFlight: [String: Task<Void, Never>] = [:]

    init(api: ClickMeAPI) {
        self.api = api
    }

    /// True while a send for `clientMsgId` has not finished.
    func isInFlight(_ clientMsgId: String) -> Bool {
        inFlight[clientMsgId] != nil
    }

    // MARK: Send

    /// Starts the POST for one bubble. A second call for a `client_msg_id`
    /// already in flight makes no request. Several different ids can be in
    /// flight at once, and their outcomes can arrive in any order.
    ///
    /// - Parameters:
    ///   - text: The trimmed message text, exactly as it goes in the POST body.
    ///   - onOutcome: Runs on the main actor once the POST has ended and before
    ///     this send stops counting as in flight.
    func send(
        threadId: UUID,
        clientMsgId: String,
        text: String,
        onOutcome: @escaping @MainActor (Outcome) async -> Void
    ) {
        guard inFlight[clientMsgId] == nil else { return }
        let api = api
        inFlight[clientMsgId] = Task { [weak self] in
            let outcome = await Self.perform(api: api, threadId: threadId, clientMsgId: clientMsgId, text: text)
            await onOutcome(outcome)
            self?.inFlight[clientMsgId] = nil
        }
    }

    /// Test seam: waits until no send is in flight.
    func awaitAll() async {
        while let task = inFlight.values.first {
            await task.value
        }
    }

    private static func perform(
        api: ClickMeAPI,
        threadId: UUID,
        clientMsgId: String,
        text: String
    ) async -> Outcome {
        do {
            let ack = try await api.sendChatMessage(
                id: threadId,
                type: .text,
                content: text,
                clientMsgId: clientMsgId
            )
            return .acked(
                messageId: ack.data.messageId,
                timestamp: ack.data.timestamp,
                status: ack.data.status
            )
        } catch {
            switch ChatThreadReducer.sendFailure(for: error) {
            case .keepAsFailed:
                return .keptAsFailed
            case let .refused(code):
                return .refused(code: code, message: error.userMessage)
            }
        }
    }

    // MARK: Restore

    /// The composer text after a refused send (D-03): the refused text alone
    /// when the composer is blank, otherwise the refused text, a newline, then
    /// what was typed since. Mirrors Android `restoreToComposer`. Plan 07-02
    /// passes the result through the composer cap (D-04).
    nonisolated static func restoredText(refused: String, draft: String) -> String {
        if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return refused }
        return refused + "\n" + draft
    }
}
