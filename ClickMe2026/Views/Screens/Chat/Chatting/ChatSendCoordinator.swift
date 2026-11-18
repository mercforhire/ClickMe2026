//
//  ChatSendCoordinator.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// RED-phase compile seam: the real implementation lands in the GREEN commit.
final class ChatSendCoordinator {

    enum Outcome: Equatable {
        case acked(messageId: UUID, timestamp: Date, status: MessageStatus)
        case keptAsFailed
        case refused(code: ErrorCode?, message: String)
    }

    init(api: ClickMeAPI) {}

    func isInFlight(_ clientMsgId: String) -> Bool { false }

    func send(
        threadId: UUID,
        clientMsgId: String,
        text: String,
        onOutcome: @escaping @MainActor (Outcome) async -> Void
    ) {}

    func awaitAll() async {}
}
