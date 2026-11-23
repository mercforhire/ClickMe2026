//
//  ChatStarterTests.swift
//  ClickMe2026Tests
//
//  WR-10: the expert Message buttons start a chat through one single-flight
//  helper that shows failures instead of swallowing them (quick 261122-tcf).
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Chat starter", .serialized)
@MainActor
struct ChatStarterTests {

    private typealias Fixtures = ClientBookingFixtures

    nonisolated private static let threadId = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"

    nonisolated private static var initiateSuccess: Data {
        Data(#"{"status":"success","data":{"thread_id":"\#(threadId)","created_at":null}}"#.utf8)
    }

    private var peerId: UUID { UUID(uuidString: Fixtures.expertId)! }

    private func initiatePosts() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter {
            $0.httpMethod == "POST" && $0.url?.path.hasSuffix("/chats/initiate") == true
        }
    }

    private func makeStarter(
        onInitiate: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
    ) -> ChatStarter {
        ChatStarter(api: APITestFactory.make(respond: onInitiate))
    }

    @Test("start sends one POST /chats/initiate with the peer_id and returns the thread")
    func startReturnsThread() async throws {
        let starter = makeStarter { request in
            Fixtures.response(for: request, status: 201, body: Self.initiateSuccess)
        }

        let thread = await starter.start(peerId: peerId)

        #expect(thread == UUID(uuidString: Self.threadId))
        #expect(starter.apiError == nil)
        #expect(!starter.isStarting)
        let posts = initiatePosts()
        #expect(posts.count == 1)
        let body = try #require(posts.first?.jsonBodyForTest())
        #expect((body["peer_id"] as? String)?.lowercased() == Fixtures.expertId)
    }

    @Test("a 404 NOT_FOUND reads as an unavailable user")
    func startUnavailable() async {
        let starter = makeStarter { request in
            Fixtures.response(
                for: request,
                status: 404,
                body: Fixtures.errorBody(code: "NOT_FOUND", message: "User not found.")
            )
        }

        let thread = await starter.start(peerId: peerId)

        #expect(thread == nil)
        #expect(starter.apiError == ExpertProfileBlockViewModel.unavailableMessage)
        #expect(!starter.isStarting)
    }

    @Test("a 500 shows the server's message")
    func startServerError() async {
        let starter = makeStarter { request in
            Fixtures.response(
                for: request,
                status: 500,
                body: Fixtures.errorBody(code: "INTERNAL_ERROR", message: "Server exploded")
            )
        }

        let thread = await starter.start(peerId: peerId)

        #expect(thread == nil)
        #expect(starter.apiError == "Server exploded")
        #expect(!starter.isStarting)
    }

    @Test("a second start while the first request runs sends no second POST")
    func secondStartIsIgnored() async {
        let gate = RequestGate()
        let starter = makeStarter { request in
            gate.waitIfArmed()
            return Fixtures.response(for: request, status: 201, body: Self.initiateSuccess)
        }

        gate.arm()
        let first = Task { await starter.start(peerId: peerId) }
        await waitUntil("the POST /chats/initiate") { initiatePosts().count == 1 }
        #expect(starter.isStarting)
        let second = await starter.start(peerId: peerId)
        #expect(second == nil)
        gate.open()

        let thread = await first.value
        #expect(thread == UUID(uuidString: Self.threadId))
        #expect(initiatePosts().count == 1)
        #expect(!starter.isStarting)
    }

    @Test("a cancelled request returns nil with no alert")
    func cancellationShowsNoAlert() async {
        let starter = makeStarter { _ in throw URLError(.cancelled) }

        let thread = await starter.start(peerId: peerId)

        #expect(thread == nil)
        #expect(starter.apiError == nil)
        #expect(!starter.isStarting)
    }

    @Test("a new start clears the previous error before it sends")
    func newStartClearsPreviousError() async {
        let starter = makeStarter { request in
            if MockURLProtocol.recordedRequests.count == 1 {
                return Fixtures.response(
                    for: request,
                    status: 500,
                    body: Fixtures.errorBody(code: "INTERNAL_ERROR", message: "Server exploded")
                )
            }
            return Fixtures.response(for: request, status: 201, body: Self.initiateSuccess)
        }

        _ = await starter.start(peerId: peerId)
        #expect(starter.apiError == "Server exploded")

        let thread = await starter.start(peerId: peerId)

        #expect(thread == UUID(uuidString: Self.threadId))
        #expect(starter.apiError == nil)
        #expect(initiatePosts().count == 2)
    }
}
