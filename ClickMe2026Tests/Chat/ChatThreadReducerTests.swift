//
//  ChatThreadReducerTests.swift
//  ClickMe2026Tests
//
//  CHAT-01 (D-01) and CHAT-06 groundwork: the pure thread rules ported case for
//  case from Android `ThreadReducerTest.kt`, plus the iOS-only rows (bubble id
//  stability, booking-event rows, case-insensitive client_msg_id). Android's
//  markRead cases are not ported: `handleMessageRead` keeps that job, unchanged
//  (D-17).
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("ChatThreadReducer")
@MainActor
struct ChatThreadReducerTests {

    // MARK: Builders

    private func uuid(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", n))!
    }

    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    /// One of my own bubbles. Defaults to a pending local bubble.
    private func mine(
        clientMsgId: String? = nil,
        serverId: UUID? = nil,
        state: ChatSendState = .sending,
        status: MessageStatus = .sent,
        at seconds: TimeInterval = 100,
        text: String = "hi"
    ) -> ChatMessage {
        ChatMessage(
            serverId: serverId, sender: .me, senderName: "Me", body: text, avatarURL: "",
            timestamp: date(seconds), status: status, clientMsgId: clientMsgId, sendState: state
        )
    }

    private func peer(
        _ n: Int,
        at seconds: TimeInterval,
        status: MessageStatus = .sent,
        clientMsgId: String? = nil
    ) -> ChatMessage {
        ChatMessage(
            serverId: uuid(n), sender: .them, senderName: "Peer", body: "yo", avatarURL: "",
            timestamp: date(seconds), status: status, clientMsgId: clientMsgId
        )
    }

    private func bookingEvent(_ n: Int, at seconds: TimeInterval) -> BookingEvent {
        BookingEvent(
            icon: "checkmark.square", title: "Booking Confirmed", subtitle: nil, isAccepted: true,
            avatarURL: nil, bookingId: nil, isTerminal: false, topicTitle: nil, startTime: nil,
            durationMins: nil, serverId: uuid(n), createdAt: date(seconds)
        )
    }

    private func rows(_ messages: ChatMessage...) -> [ChatItem] {
        messages.map { .message($0) }
    }

    private func message(_ items: [ChatItem], at index: Int) throws -> ChatMessage {
        guard case let .message(message) = items[index] else {
            throw TestFailure(reason: "row \(index) is not a message")
        }
        return message
    }

    private struct TestFailure: Error { let reason: String }

    // MARK: Ported from ThreadReducerTest.kt

    @Test("own message: sending, then ack, then reload stays one row")
    func ownMessageSendingThenAckThenReloadStaysOneRow() throws {
        var items = ChatThreadReducer.appendLocal([], mine(clientMsgId: "c1"))
        let idBefore = items[0].id

        items = ChatThreadReducer.ack(items, clientMsgId: "c1", serverId: uuid(9), timestamp: date(200), status: .sent)
        let acked = try message(items, at: 0)
        #expect(acked.serverId == uuid(9))
        #expect(acked.sendState == .sent)
        #expect(acked.timestamp == date(200))

        let server = mine(clientMsgId: "c1", serverId: uuid(9), state: .sent, at: 200)
        items = ChatThreadReducer.mergePage(items, page: [.message(server)])
        #expect(items.count == 1)
        #expect(items[0].id == idBefore)
    }

    @Test("a page merges into an empty list in server-time order")
    func incomingPageMergesIntoEmptyList() {
        let page = rows(peer(2, at: 20), peer(1, at: 10), peer(3, at: 30))
        let merged = ChatThreadReducer.mergePage([], page: page)
        #expect(merged.map(\.serverId) == [uuid(1), uuid(2), uuid(3)])
    }

    @Test("an ack after a reload already added the row keeps one row")
    func ackAfterReloadAlreadyAddedTheRowKeepsOne() {
        var items = ChatThreadReducer.appendLocal([], mine(clientMsgId: "c1"))
        let server = mine(clientMsgId: "c1", serverId: uuid(9), state: .sent, at: 200)
        items = ChatThreadReducer.mergePage(items, page: [.message(server)])
        #expect(items.count == 1)

        items = ChatThreadReducer.ack(items, clientMsgId: "c1", serverId: uuid(9), timestamp: date(200), status: .sent)
        #expect(items.count == 1)
        #expect(items[0].serverId == uuid(9))
    }

    @Test("fail, retry and remove; a row with a server id is never removed")
    func failRetryRemove() throws {
        var items = ChatThreadReducer.appendLocal([], mine(clientMsgId: "c1"))

        items = ChatThreadReducer.fail(items, clientMsgId: "c1")
        #expect(try message(items, at: 0).sendState == .failed)

        items = ChatThreadReducer.retry(items, clientMsgId: "c1")
        let retried = try message(items, at: 0)
        #expect(retried.sendState == .sending)
        #expect(retried.clientMsgId == "c1")

        items = ChatThreadReducer.remove(items, clientMsgId: "c1")
        #expect(items.isEmpty)

        let sent = rows(mine(clientMsgId: "c2", serverId: uuid(2), state: .sent))
        #expect(ChatThreadReducer.remove(sent, clientMsgId: "c2").count == 1)
    }

    @Test("a lost response, then a reload, converges to one sent row")
    func lostResponseThenReloadConvergesToOneSentRow() throws {
        var items = ChatThreadReducer.appendLocal([], mine(clientMsgId: "c1"))
        items = ChatThreadReducer.fail(items, clientMsgId: "c1")
        let server = mine(clientMsgId: "c1", serverId: uuid(9), state: .sent, at: 150)

        items = ChatThreadReducer.mergePage(items, page: [.message(server)])

        #expect(items.count == 1)
        let row = try message(items, at: 0)
        #expect(row.serverId == uuid(9))
        #expect(row.sendState == .sent)
    }

    @Test("concurrent sends coexist after the server rows, in append order")
    func concurrentSendsCoexist() throws {
        var items = ChatThreadReducer.mergePage([], page: rows(peer(1, at: 10), peer(2, at: 20)))
        items = ChatThreadReducer.appendLocal(items, mine(clientMsgId: "c1"))
        items = ChatThreadReducer.appendLocal(items, mine(clientMsgId: "c2"))
        items = ChatThreadReducer.appendLocal(items, mine(clientMsgId: "c3"))

        #expect(items.map(\.serverId) == [uuid(1), uuid(2), nil, nil, nil])
        let localKeys = try (2..<items.count).map { try message(items, at: $0).clientMsgId }
        #expect(localKeys == ["c1", "c2", "c3"])
    }

    @Test("an incoming event from me, or with a known server id, adds nothing")
    func incomingIgnoresOwnAndDuplicates() {
        let myId = uuid(900)
        let base = ChatThreadReducer.mergePage([], page: rows(peer(1, at: 10)))

        let own = peer(2, at: 20)
        let afterOwn = ChatThreadReducer.onIncoming(base, own, senderId: myId, myId: myId)
        #expect(afterOwn.map(\.serverId) == [uuid(1)])

        let duplicate = peer(1, at: 10)
        let afterDuplicate = ChatThreadReducer.onIncoming(base, duplicate, senderId: uuid(901), myId: myId)
        #expect(afterDuplicate.map(\.serverId) == [uuid(1)])

        let added = ChatThreadReducer.onIncoming(base, peer(3, at: 5), senderId: uuid(901), myId: myId)
        #expect(added.map(\.serverId) == [uuid(3), uuid(1)])
    }

    @Test("an own Read message never goes back to Sent on a later merge or ack")
    func readNeverRegresses() throws {
        let read = mine(clientMsgId: "c1", serverId: uuid(1), state: .sent, status: .read, at: 10)
        var items = ChatThreadReducer.mergePage([], page: rows(read))

        let stale = mine(clientMsgId: "c1", serverId: uuid(1), state: .sent, status: .sent, at: 10)
        items = ChatThreadReducer.mergePage(items, page: [.message(stale)])
        #expect(try message(items, at: 0).status == .read)

        items = ChatThreadReducer.ack(items, clientMsgId: "c1", serverId: uuid(1), timestamp: date(10), status: .sent)
        #expect(ChatThreadReducer.findMine(items, clientMsgId: "c1")?.status == .read)
    }

    @Test("prepending an older page that overlaps leaves no duplicates")
    func prependOlderOverlapHasNoDuplicates() {
        var items = ChatThreadReducer.mergePage([], page: rows(peer(3, at: 30), peer(4, at: 40)))

        items = ChatThreadReducer.mergePage(
            items,
            page: rows(peer(1, at: 10), peer(2, at: 20), peer(3, at: 30), peer(4, at: 40))
        )

        #expect(items.map(\.serverId) == [uuid(1), uuid(2), uuid(3), uuid(4)])
    }

    @Test("equal timestamps keep their original order")
    func equalTimestampsKeepStableOrder() {
        let page = rows(peer(2, at: 10), peer(1, at: 10), peer(3, at: 10))
        let items = ChatThreadReducer.mergePage([], page: page)
        #expect(items.map(\.serverId) == [uuid(2), uuid(1), uuid(3)])
    }

    @Test("unreadPeerIds skips my messages, Read ones and ids already emitted")
    func unreadPeerIdsSkipsMineReadAndEmitted() {
        let items = ChatThreadReducer.mergePage(
            [],
            page: rows(
                peer(1, at: 10),
                peer(2, at: 20, status: .read),
                peer(3, at: 30),
                peer(4, at: 40),
                mine(clientMsgId: "c1", serverId: uuid(5), state: .sent, at: 50)
            )
        )

        let unread = ChatThreadReducer.unreadPeerIds(items, alreadyEmitted: [uuid(3)])

        #expect(unread == [uuid(1), uuid(4)])
    }

    @Test("an ack drops the bubble when the server row is already there without a client_msg_id")
    func ackDropsBubbleWhenServerRowAlreadyPresentWithoutClientMsgId() throws {
        var items = ChatThreadReducer.appendLocal([], mine(clientMsgId: "c1"))
        let serverRow = mine(serverId: uuid(9), state: .sent, status: .read, at: 200)
        items = ChatThreadReducer.mergePage(items, page: [.message(serverRow)])
        // The page row has no client_msg_id, so the bubble was not matched by it.
        #expect(items.count == 2)

        items = ChatThreadReducer.ack(items, clientMsgId: "c1", serverId: uuid(9), timestamp: date(200), status: .sent)

        #expect(items.count == 1)
        let row = try message(items, at: 0)
        #expect(row.serverId == uuid(9))
        #expect(row.clientMsgId == "c1")
        #expect(row.status == .read)
    }

    @Test("an ack for an unknown client_msg_id changes nothing")
    func ackOnUnknownClientMsgIdChangesNothing() {
        let items = ChatThreadReducer.appendLocal([], mine(clientMsgId: "c1"))
        let after = ChatThreadReducer.ack(items, clientMsgId: "zzz", serverId: uuid(9), timestamp: date(1), status: .sent)
        #expect(after.map(\.id) == items.map(\.id))
        #expect(after.map(\.serverId) == [nil])
    }

    @Test("a peer row sharing my client_msg_id is a separate row")
    func peerRowSharingMyClientMsgIdStaysDistinct() {
        let own = mine(clientMsgId: "dup", serverId: uuid(1), state: .sent, at: 100)
        var items = ChatThreadReducer.mergePage([], page: rows(own))
        let peerRow = peer(2, at: 200, clientMsgId: "DUP")
        items = ChatThreadReducer.mergePage(items, page: [.message(own), .message(peerRow)])
        #expect(items.count == 2)
        #expect(items.map(\.serverId) == [uuid(1), uuid(2)])
    }

    @Test("a peer row keeps its row when a reload adds a client_msg_id")
    func peerRowKeepsItsIdWhenAReloadAddsClientMsgId() {
        var items = ChatThreadReducer.mergePage([], page: rows(peer(5, at: 50)))
        let idBefore = items[0].id
        items = ChatThreadReducer.mergePage(items, page: rows(peer(5, at: 50, clientMsgId: "x9")))
        #expect(items.count == 1)
        #expect(items[0].id == idBefore)
    }

    // MARK: iOS-only rows

    @Test("a bubble keeps its id through append, ack, fail, retry and a merge that holds its server row")
    func bubbleIdIsStableThroughEveryTransition() throws {
        var items = ChatThreadReducer.appendLocal([], mine(clientMsgId: "c1"))
        let id = items[0].id

        items = ChatThreadReducer.fail(items, clientMsgId: "c1")
        #expect(items[0].id == id)
        items = ChatThreadReducer.retry(items, clientMsgId: "c1")
        #expect(items[0].id == id)
        items = ChatThreadReducer.ack(items, clientMsgId: "c1", serverId: uuid(7), timestamp: date(300), status: .sent)
        #expect(items[0].id == id)
        let server = mine(clientMsgId: "c1", serverId: uuid(7), state: .sent, at: 300)
        items = ChatThreadReducer.mergePage(items, page: [.message(server)])
        #expect(items.count == 1)
        #expect(items[0].id == id)
    }

    @Test("an event row on an overlapping page keeps one row and the existing id")
    func eventRowOnAnOverlappingPageKeepsTheExistingId() {
        var items = ChatThreadReducer.mergePage([], page: [.systemEvent(bookingEvent(1, at: 10))])
        let idBefore = items[0].id

        items = ChatThreadReducer.mergePage(
            items,
            page: [.systemEvent(bookingEvent(1, at: 10)), .message(peer(2, at: 20))]
        )

        #expect(items.count == 2)
        #expect(items[0].id == idBefore)
        #expect(items.map(\.serverId) == [uuid(1), uuid(2)])
    }

    @Test("an event row sorts among the messages by its created time")
    func eventRowSortsByCreatedTime() {
        let items = ChatThreadReducer.mergePage(
            [],
            page: [.message(peer(2, at: 20)), .systemEvent(bookingEvent(1, at: 10)), .message(peer(3, at: 30))]
        )
        #expect(items.map(\.serverId) == [uuid(1), uuid(2), uuid(3)])
    }

    @Test("timestamp separators have no server id and pass through after the server rows")
    func timestampRowsPassThroughAfterServerRows() {
        let ordered = ChatThreadReducer.order([.timestamp("Today"), .message(peer(1, at: 10))])
        #expect(ordered.map(\.serverId) == [uuid(1), nil])
        #expect(ordered.last?.id == "ts_Today")
    }

    @Test("client_msg_id matching ignores letter case")
    func clientMsgIdMatchingIgnoresCase() {
        let items = ChatThreadReducer.appendLocal([], mine(clientMsgId: "abc-1"))
        #expect(ChatThreadReducer.findMine(items, clientMsgId: "ABC-1") != nil)
        let failed = ChatThreadReducer.fail(items, clientMsgId: "ABC-1")
        #expect(ChatThreadReducer.findMine(failed, clientMsgId: "abc-1")?.sendState == .failed)
    }

    // MARK: Send-failure classification

    @Test("an HTTP 4xx is a refusal that carries the error code; everything else keeps the bubble as failed")
    func sendFailureClassification() {
        let validation = NetworkError.httpError(
            statusCode: 422,
            data: ClientBookingFixtures.errorBody(code: "VALIDATION_ERROR", message: "Bad text")
        )
        #expect(ChatThreadReducer.sendFailure(for: validation) == .refused(.validationError))

        let blocked = NetworkError.httpError(
            statusCode: 403,
            data: ClientBookingFixtures.errorBody(code: "THREAD_BLOCKED", message: "Blocked")
        )
        #expect(ChatThreadReducer.sendFailure(for: blocked) == .refused(.threadBlocked))

        let noBody = NetworkError.httpError(statusCode: 400, data: Data())
        #expect(ChatThreadReducer.sendFailure(for: noBody) == .refused(nil))

        let server = NetworkError.httpError(
            statusCode: 500,
            data: ClientBookingFixtures.errorBody(code: "INTERNAL_ERROR", message: "Boom")
        )
        #expect(ChatThreadReducer.sendFailure(for: server) == .keepAsFailed)
        #expect(ChatThreadReducer.sendFailure(for: URLError(.notConnectedToInternet)) == .keepAsFailed)
        #expect(ChatThreadReducer.sendFailure(for: NetworkError.invalidResponse) == .keepAsFailed)
        #expect(ChatThreadReducer.sendFailure(for: NetworkError.decodingFailed(URLError(.cannotParseResponse))) == .keepAsFailed)
    }
}
