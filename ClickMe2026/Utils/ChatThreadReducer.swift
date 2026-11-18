//
//  ChatThreadReducer.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Pure rules for the rows of one chat thread (CHAT-01, D-01), ported from
/// Android `ThreadReducer.kt` (07-RESEARCH Pattern 1). No view model, no
/// network: every rule is a plain function over `[ChatItem]`, so it is a unit
/// test.
///
/// Rules:
/// - A bubble keeps its `ChatMessage.id` through ack, fail, retry and every
///   merge, so SwiftUI never removes and re-inserts the row (Pitfall 2). Each
///   function mutates a message by taking it out of `.message`, changing it and
///   writing it back at the same index.
/// - Server rows are ordered by server time with a stable sort, then local
///   unsent bubbles follow in their current order (Pitfall 9).
/// - Every `client_msg_id` comparison ignores letter case, because the backend
///   compares UUIDs case-insensitively.
///
/// `markRead` is deliberately not ported: `ChattingViewModel.handleMessageRead`
/// keeps that job unchanged (D-17).
enum ChatThreadReducer {

    // MARK: - Send failure classification

    /// What the thread does with a send that did not succeed.
    enum SendFailure: Equatable {
        /// Keep the bubble on screen as Failed; a retry can still succeed.
        case keepAsFailed
        /// The server refused the message. Remove the bubble and give the text
        /// back; the code, when the body carried one, is for callers that
        /// branch on it.
        case refused(ErrorCode?)
    }

    /// Splits a failed send the way Android does (`SERVER_ERROR_FROM = 500`):
    /// an HTTP 4xx is a refusal, and everything else (5xx, a transport error,
    /// an undecodable or invalid response) keeps the bubble as Failed.
    static func sendFailure(for error: Error) -> SendFailure {
        guard case let NetworkError.httpError(statusCode, _) = error,
              (400...499).contains(statusCode)
        else { return .keepAsFailed }
        return .refused(BookingErrorMapper.code(for: error))
    }

    // MARK: - Local bubble lifecycle

    /// Adds a local bubble. The caller passes a `.sending` message with no
    /// server id.
    static func appendLocal(_ items: [ChatItem], _ message: ChatMessage) -> [ChatItem] {
        order(items + [.message(message)])
    }

    /// The send of `clientMsgId` succeeded. The bubble takes the server id and
    /// time and becomes `.sent`; Read stays Read. When a reload already added the
    /// server row, the two collapse into that row.
    static func ack(
        _ items: [ChatItem],
        clientMsgId: String,
        serverId: UUID,
        timestamp: Date,
        status: MessageStatus
    ) -> [ChatItem] {
        guard let bubbleIndex = indexOfMine(items, clientMsgId: clientMsgId),
              case let .message(bubble) = items[bubbleIndex]
        else { return items }

        var result = items
        let existingIndex = result.indices.first { $0 != bubbleIndex && result[$0].serverId == serverId }
        if let existingIndex {
            // The reload won the race: keep its row, hand it the bubble's key.
            if case var .message(existing) = result[existingIndex], existing.clientMsgId == nil {
                existing.clientMsgId = bubble.clientMsgId
                result[existingIndex] = .message(existing)
            }
            result.remove(at: bubbleIndex)
        } else {
            var updated = bubble
            updated.serverId = serverId
            updated.timestamp = timestamp
            updated.sendState = .sent
            if updated.status != .read { updated.status = status }
            result[bubbleIndex] = .message(updated)
        }
        return order(result)
    }

    /// The send of `clientMsgId` failed: the `.sending` bubble becomes `.failed`.
    static func fail(_ items: [ChatItem], clientMsgId: String) -> [ChatItem] {
        updateLocal(items, clientMsgId: clientMsgId, from: .sending, to: .failed)
    }

    /// Retry: the `.failed` bubble goes back to `.sending` with the same
    /// `client_msg_id` (D-01).
    static func retry(_ items: [ChatItem], clientMsgId: String) -> [ChatItem] {
        updateLocal(items, clientMsgId: clientMsgId, from: .failed, to: .sending)
    }

    /// Deletes a local unsent bubble. A row that already has a server id is
    /// never removed.
    static func remove(_ items: [ChatItem], clientMsgId: String) -> [ChatItem] {
        items.filter { item in
            guard case let .message(message) = item,
                  message.sender == .me,
                  message.serverId == nil,
                  sameId(message.clientMsgId, clientMsgId)
            else { return true }
            return false
        }
    }

    /// The own message with `clientMsgId`, or nil.
    static func findMine(_ items: [ChatItem], clientMsgId: String) -> ChatMessage? {
        guard let index = indexOfMine(items, clientMsgId: clientMsgId),
              case let .message(message) = items[index]
        else { return nil }
        return message
    }

    // MARK: - Server rows

    /// Merges a page of server rows into `items` without dropping or
    /// duplicating anything (Pitfall 1). A page row is matched to an existing
    /// row by server id first, then, for my own messages, by `client_msg_id`. A
    /// match is reconciled in place, keeping the existing row's `id`; no match
    /// appends. Existing rows nothing matches (older pages, pending and failed
    /// bubbles) are kept.
    static func mergePage(_ items: [ChatItem], page: [ChatItem]) -> [ChatItem] {
        var result = items
        for incoming in page {
            if let index = indexOfMatch(result, incoming: incoming) {
                result[index] = reconcile(existing: result[index], incoming: incoming)
            } else {
                result.append(incoming)
            }
        }
        return order(result)
    }

    /// A `message.new` socket event. Ignored when `myId` sent it (the sender is
    /// never echoed, but be safe) or when the server id is already shown;
    /// otherwise it is added in server-time order.
    static func onIncoming(
        _ items: [ChatItem],
        _ message: ChatMessage,
        senderId: UUID?,
        myId: UUID?
    ) -> [ChatItem] {
        if let senderId, senderId == myId { return items }
        if let serverId = message.serverId, items.contains(where: { $0.serverId == serverId }) { return items }
        return order(items + [.message(message)])
    }

    /// Server ids of peer messages that are not Read yet and not in
    /// `alreadyEmitted`, in list order. The caller emits a read receipt for them
    /// (plan 07-03).
    static func unreadPeerIds(_ items: [ChatItem], alreadyEmitted: Set<UUID>) -> [UUID] {
        items.compactMap { item in
            guard case let .message(message) = item,
                  message.sender == .them,
                  message.status != .read,
                  let serverId = message.serverId,
                  !alreadyEmitted.contains(serverId)
            else { return nil }
            return serverId
        }
    }

    // MARK: - Order

    /// Rows with a server id (messages and booking events) sorted by server
    /// time, then rows with no server id in their current order.
    ///
    /// Swift's `sorted` is not documented as stable, so the sort key is the
    /// time and then the original index: equal times keep their order.
    static func order(_ items: [ChatItem]) -> [ChatItem] {
        var server: [(index: Int, item: ChatItem)] = []
        var local: [ChatItem] = []
        for (index, item) in items.enumerated() {
            if item.serverId != nil {
                server.append((index, item))
            } else {
                local.append(item)
            }
        }
        server.sort { lhs, rhs in
            let left = lhs.item.orderDate ?? .distantPast
            let right = rhs.item.orderDate ?? .distantPast
            if left != right { return left < right }
            return lhs.index < rhs.index
        }
        return server.map(\.item) + local
    }

    // MARK: - Helpers

    private static func updateLocal(
        _ items: [ChatItem],
        clientMsgId: String,
        from: ChatSendState,
        to: ChatSendState
    ) -> [ChatItem] {
        var result = items
        for index in result.indices {
            guard case var .message(message) = result[index],
                  message.sender == .me,
                  message.serverId == nil,
                  message.sendState == from,
                  sameId(message.clientMsgId, clientMsgId)
            else { continue }
            message.sendState = to
            result[index] = .message(message)
        }
        return result
    }

    private static func indexOfMatch(_ existing: [ChatItem], incoming: ChatItem) -> Int? {
        if let serverId = incoming.serverId,
           let index = existing.firstIndex(where: { $0.serverId == serverId }) {
            return index
        }
        guard case let .message(message) = incoming,
              message.sender == .me,
              let clientMsgId = message.clientMsgId
        else { return nil }
        return indexOfMine(existing, clientMsgId: clientMsgId)
    }

    /// The matched row becomes the server's version of itself but keeps its
    /// `id`, so the list key does not change and the row is not recreated. A
    /// message keeps the `client_msg_id` it already had and never goes from Read
    /// back to Sent.
    private static func reconcile(existing: ChatItem, incoming: ChatItem) -> ChatItem {
        switch (existing, incoming) {
        case let (.message(old), .message(new)):
            var merged = new
            merged.id = old.id
            merged.clientMsgId = old.clientMsgId ?? new.clientMsgId
            if old.status == .read { merged.status = .read }
            merged.sendState = .sent
            return .message(merged)
        case let (.systemEvent(old), .systemEvent(new)):
            var merged = new
            merged.id = old.id
            return .systemEvent(merged)
        default:
            return incoming
        }
    }

    private static func indexOfMine(_ items: [ChatItem], clientMsgId: String) -> Int? {
        items.firstIndex { item in
            guard case let .message(message) = item, message.sender == .me else { return false }
            return sameId(message.clientMsgId, clientMsgId)
        }
    }

    /// Case-insensitive id comparison; false when either side is nil.
    private static func sameId(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs, let rhs else { return false }
        return lhs.caseInsensitiveCompare(rhs) == .orderedSame
    }
}
