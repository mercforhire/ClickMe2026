//
//  ChatDisplayModels.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Which side of a chat bubble a message belongs on.
enum MessageSender { case me, them }

/// A single row rendered in the chat scroll view. Wraps the three kinds
/// of things the message list can contain — user messages, day / time
/// separators, and system-injected booking lifecycle events.
enum ChatItem: Identifiable {
    case message(ChatMessage)
    case timestamp(String)
    case systemEvent(BookingEvent)

    var id: String {
        switch self {
        case let .message(m): return m.id.uuidString
        case let .timestamp(t): return "ts_\(t)"
        case let .systemEvent(e): return e.id.uuidString
        }
    }
}

/// Display model for a single chat bubble. Populated from
/// `ChatMessageItem` on the wire.
struct ChatMessage: Identifiable {
    let id = UUID()
    let sender: MessageSender
    let senderName: String
    let body: String
    let avatarURL: String
}

/// Display model for a system-injected booking lifecycle event row
/// (e.g. "Booking Confirmed", "Request Expired"). Derived from
/// `ChatMessageItem` where `type == .event`.
struct BookingEvent: Identifiable {
    let id = UUID()
    let icon: String // SF Symbol
    let title: String
    let subtitle: String?
    let isAccepted: Bool
    let avatarURL: String? // nil = no avatar on left
}
