//
//  ChattingViewModelSendTests.swift
//  ClickMe2026Tests
//
//  CHAT-01 (D-01, D-03): a sent message appears at once as a pending bubble,
//  the 201 ack updates that same bubble in place, a network or server failure
//  leaves a Failed bubble, and a refused send returns its text to the composer.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Chat thread send", .serialized)
@MainActor
struct ChattingViewModelSendTests {

    private typealias Fixtures = ClientBookingFixtures

    nonisolated private static let threadId = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!
    nonisolated private static let myId = UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!
    /// Exactly representable and one millisecond-safe, so the ISO round trip is lossless.
    nonisolated private static let ackTime = Date(timeIntervalSince1970: 1_800_000_000.5)

    typealias Responder = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    // MARK: Stub helpers

    nonisolated private static func isSend(_ request: URLRequest) -> Bool {
        request.httpMethod == "POST" && request.url?.path.hasSuffix("/send") == true
    }

    nonisolated private static func sendPosts() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter(isSend)
    }

    /// A 201 ack whose message id is the request's own `client_msg_id`, so every send gets its own id.
    nonisolated private static let ackResponder: Responder = { request in
        let clientMsgId = request.jsonBodyForTest()?["client_msg_id"] as? String ?? ""
        let messageId = UUID(uuidString: clientMsgId) ?? UUID()
        let body = Data(
            #"{"status":"success","data":{"message_id":"\#(messageId.uuidString)","status":"sent","timestamp":"\#(Fixtures.iso(ackTime))"}}"#.utf8
        )
        return Fixtures.response(for: request, status: 201, body: body)
    }

    nonisolated private static func errorResponder(status: Int, code: String, message: String) -> Responder {
        { request in
            Fixtures.response(for: request, status: status, body: Fixtures.errorBody(code: code, message: message))
        }
    }

    nonisolated private static let offlineResponder: Responder = { _ in
        throw URLError(.notConnectedToInternet)
    }

    private static func makeAPI(onSend: @escaping Responder) -> ClickMeAPI {
        APITestFactory.make { request in
            if isSend(request) { return try onSend(request) }
            return Fixtures.response(
                for: request,
                status: 404,
                body: Fixtures.errorBody(code: "NOT_FOUND", message: "Not found")
            )
        }
    }

    /// A view model with a non-empty identity, so no `/me` or `/user/profile` request is made.
    private func makeViewModel(onSend: @escaping Responder) -> ChattingViewModel {
        ChattingViewModel(
            threadId: Self.threadId,
            peerName: "Peer",
            peerAvatarURL: "",
            api: Self.makeAPI(onSend: onSend),
            myUserId: Self.myId,
            myName: "Me",
            myAvatarURL: "https://example.invalid/me.png"
        )
    }

    private func messages(_ viewModel: ChattingViewModel) -> [ChatMessage] {
        viewModel.items.compactMap {
            if case let .message(message) = $0 { return message }
            return nil
        }
    }

    // MARK: Optimistic append and ack

    @Test("send appends a pending bubble at once, then the ack updates that same bubble")
    func pendingBubbleThenAckKeepsTheSameBubble() async throws {
        let viewModel = makeViewModel(onSend: Self.ackResponder)
        viewModel.messageText = "hello"
        let tokenBefore = viewModel.scrollToBottomToken

        await viewModel.sendMessage()

        let pending = try #require(messages(viewModel).last)
        #expect(pending.sender == .me)
        #expect(pending.body == "hello")
        #expect(pending.sendState == .sending)
        #expect(pending.clientMsgId != nil)
        #expect(pending.serverId == nil)
        #expect(viewModel.messageText == "")
        #expect(viewModel.scrollToBottomToken == tokenBefore + 1)

        await viewModel.awaitInFlightSends()

        let acked = try #require(messages(viewModel).last)
        #expect(messages(viewModel).count == 1)
        #expect(acked.id == pending.id)
        #expect(acked.serverId == UUID(uuidString: try #require(pending.clientMsgId)))
        #expect(acked.timestamp == Self.ackTime)
        #expect(acked.sendState == .sent)

        let posts = Self.sendPosts()
        #expect(posts.count == 1)
        let body = try #require(posts.first?.jsonBodyForTest())
        #expect(body["client_msg_id"] as? String == pending.clientMsgId)
        #expect(body["content"] as? String == "hello")
    }

    @Test("two sends before any ack keep append order and both end up sent")
    func twoSendsInFlightAtOnce() async throws {
        let viewModel = makeViewModel(onSend: Self.ackResponder)

        viewModel.messageText = "a"
        await viewModel.sendMessage()
        viewModel.messageText = "b"
        await viewModel.sendMessage()

        #expect(messages(viewModel).map(\.body) == ["a", "b"])
        #expect(messages(viewModel).allSatisfy { $0.sendState == .sending })

        await viewModel.awaitInFlightSends()

        #expect(messages(viewModel).map(\.body) == ["a", "b"])
        #expect(messages(viewModel).allSatisfy { $0.sendState == .sent })
        let posts = Self.sendPosts()
        #expect(posts.count == 2)
        let ids = Set(posts.compactMap { $0.jsonBodyForTest()?["client_msg_id"] as? String })
        #expect(ids.count == 2)
    }

    // MARK: Failures that keep the bubble

    @Test("a 500 keeps the bubble in place as failed, with no alert")
    func serverErrorKeepsTheBubbleAsFailed() async throws {
        let viewModel = makeViewModel(onSend: Self.errorResponder(status: 500, code: "INTERNAL_ERROR", message: "Boom"))
        viewModel.messageText = "hello"
        await viewModel.sendMessage()
        let id = try #require(messages(viewModel).last).id

        await viewModel.awaitInFlightSends()

        let failed = try #require(messages(viewModel).last)
        #expect(messages(viewModel).count == 1)
        #expect(failed.id == id)
        #expect(failed.sendState == .failed)
        #expect(viewModel.sendError == nil)
    }

    @Test("a transport failure keeps the bubble in place as failed, with no alert")
    func transportFailureKeepsTheBubbleAsFailed() async throws {
        let viewModel = makeViewModel(onSend: Self.offlineResponder)
        viewModel.messageText = "hello"
        await viewModel.sendMessage()

        await viewModel.awaitInFlightSends()

        let failed = try #require(messages(viewModel).last)
        #expect(failed.sendState == .failed)
        #expect(viewModel.sendError == nil)
    }

    // MARK: Refusals that return the text

    @Test("a 422 removes the bubble, restores the text and shows the server's reason")
    func validationRefusalRestoresTheText() async throws {
        let viewModel = makeViewModel(
            onSend: Self.errorResponder(status: 422, code: "VALIDATION_ERROR", message: "Bad text")
        )
        viewModel.messageText = "hello"
        await viewModel.sendMessage()

        await viewModel.awaitInFlightSends()

        #expect(messages(viewModel).isEmpty)
        #expect(viewModel.messageText == "hello")
        #expect(viewModel.sendError == "Bad text")
    }

    @Test("a refused send puts its text ahead of what was typed since, on its own line")
    func refusalRestoresAheadOfTheDraft() async throws {
        let viewModel = makeViewModel(
            onSend: Self.errorResponder(status: 422, code: "VALIDATION_ERROR", message: "Bad text")
        )
        viewModel.messageText = "first"
        await viewModel.sendMessage()
        viewModel.messageText = "draft"

        await viewModel.awaitInFlightSends()

        #expect(viewModel.messageText == "first\ndraft")
    }

    @Test("a 403 THREAD_BLOCKED takes the refused path until plan 07-04")
    func blockedThreadIsRefusedForNow() async throws {
        let viewModel = makeViewModel(
            onSend: Self.errorResponder(status: 403, code: "THREAD_BLOCKED", message: "You can't message this person")
        )
        viewModel.messageText = "hello"
        await viewModel.sendMessage()

        await viewModel.awaitInFlightSends()

        #expect(messages(viewModel).isEmpty)
        #expect(viewModel.messageText == "hello")
        #expect(viewModel.sendError != nil)
    }

    // MARK: Empty input

    @Test("whitespace-only text appends nothing and makes no request")
    func whitespaceOnlySendsNothing() async throws {
        let viewModel = makeViewModel(onSend: Self.ackResponder)
        viewModel.messageText = "   \n"

        await viewModel.sendMessage()
        await viewModel.awaitInFlightSends()

        #expect(viewModel.items.isEmpty)
        #expect(MockURLProtocol.recordedRequests.isEmpty)
    }

    // MARK: Coordinator

    @Test("a second send for a client_msg_id already in flight makes no request")
    func coordinatorIgnoresADuplicateInFlight() async throws {
        let api = Self.makeAPI(onSend: Self.ackResponder)
        let coordinator = ChatSendCoordinator(api: api)
        let clientMsgId = UUID().uuidString

        coordinator.send(threadId: Self.threadId, clientMsgId: clientMsgId, text: "x") { _ in }
        coordinator.send(threadId: Self.threadId, clientMsgId: clientMsgId, text: "x") { _ in }
        #expect(coordinator.isInFlight(clientMsgId))

        await coordinator.awaitAll()

        #expect(!coordinator.isInFlight(clientMsgId))
        #expect(Self.sendPosts().count == 1)
    }
}
