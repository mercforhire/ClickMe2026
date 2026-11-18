//
//  ChattingViewModelReadEmitTests.swift
//  ClickMe2026Tests
//
//  CHAT-07 (client half, D-16): a read receipt goes out for the unread peer
//  messages of every page loaded and for each live peer message, never for my
//  own messages, Read messages or ids already sent in this thread session. An
//  id counts as sent only when the socket was connected; receipts for ids
//  loaded while it was not go out once it connects, because the socket library
//  drops an emit made while disconnected.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Chat read receipts", .serialized)
@MainActor
struct ChattingViewModelReadEmitTests {

    private typealias Fixtures = ClientBookingFixtures

    nonisolated private static let threadId = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!
    nonisolated private static let myId = UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!
    nonisolated private static let peerId = UUID(uuidString: "dddddddd-dddd-4ddd-8ddd-dddddddddddd")!
    nonisolated private static let base = Date(timeIntervalSince1970: 1_800_000_000)

    nonisolated private static let unreadA = UUID(uuidString: "00000000-0000-4000-8000-00000000000a")!
    nonisolated private static let unreadB = UUID(uuidString: "00000000-0000-4000-8000-00000000000b")!
    nonisolated private static let mine = UUID(uuidString: "00000000-0000-4000-8000-00000000000c")!
    nonisolated private static let alreadyRead = UUID(uuidString: "00000000-0000-4000-8000-00000000000d")!
    nonisolated private static let olderUnread = UUID(uuidString: "00000000-0000-4000-8000-00000000000e")!

    typealias Responder = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    // MARK: Recorder

    /// Stands in for the socket: a connected flag the view model reads and the receipts it emits.
    private final class Socket {
        var connected: Bool
        private(set) var emits: [(threadId: UUID, ids: [UUID])] = []
        init(connected: Bool) { self.connected = connected }
        func record(_ threadId: UUID, _ ids: [UUID]) { emits.append((threadId, ids)) }
    }

    // MARK: Stub helpers

    nonisolated private static func isMessagesGet(_ request: URLRequest) -> Bool {
        request.httpMethod == "GET" && request.url?.path.hasSuffix("/messages") == true
    }

    nonisolated private static func page(of request: URLRequest) -> Int {
        guard let url = request.url,
              let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                  .queryItems?.first(where: { $0.name == "page" })?.value
        else { return 1 }
        return Int(value) ?? 1
    }

    nonisolated private static func row(
        _ id: UUID,
        from senderId: UUID = peerId,
        status: String = "sent",
        at offset: TimeInterval
    ) -> String {
        ChatFixtures.message(
            id: id, senderId: senderId, content: "hi", status: status,
            createdAt: base.addingTimeInterval(offset)
        )
    }

    /// Page 1 holds two unread peer messages, one of mine and one the peer already has Read.
    nonisolated private static let firstPageRows: [String] = [
        row(unreadA, at: 100),
        row(mine, from: myId, at: 101),
        row(alreadyRead, status: "read", at: 102),
        row(unreadB, at: 103)
    ]

    /// Answers each messages page from `pages` (1-based); anything else is a 404.
    nonisolated private static func messagesResponder(pages: [[String]]) -> Responder {
        { request in
            guard isMessagesGet(request) else {
                return Fixtures.response(
                    for: request,
                    status: 404,
                    body: Fixtures.errorBody(code: "NOT_FOUND", message: "Not found")
                )
            }
            let number = page(of: request)
            let rows = number <= pages.count ? pages[number - 1] : []
            return Fixtures.response(
                for: request,
                body: ChatFixtures.messagesPage(rows, page: number, totalPages: pages.count)
            )
        }
    }

    private func makeViewModel(pages: [[String]], socket: Socket) -> ChattingViewModel {
        ChattingViewModel(
            threadId: Self.threadId,
            peerName: "Peer",
            peerAvatarURL: "",
            api: APITestFactory.make(respond: Self.messagesResponder(pages: pages)),
            myUserId: Self.myId,
            myName: "Me",
            myAvatarURL: "https://example.invalid/me.png",
            isRealtimeConnected: { socket.connected },
            emitMessageRead: { socket.record($0, $1) }
        )
    }

    private func liveEvent(
        id: UUID = UUID(),
        threadId: UUID = ChattingViewModelReadEmitTests.threadId,
        senderId: UUID = ChattingViewModelReadEmitTests.peerId
    ) -> RealtimeMessageNewEvent {
        RealtimeMessageNewEvent(
            messageId: id, threadId: threadId, senderId: senderId,
            type: .text, content: "live", timestamp: Self.base.addingTimeInterval(500), status: .sent
        )
    }

    // MARK: Per page

    @Test("page 1 emits one receipt with exactly the unread peer ids, not mine or the Read one")
    func pageOneEmitsOnlyUnreadPeerMessages() async throws {
        let socket = Socket(connected: true)
        let viewModel = makeViewModel(pages: [Self.firstPageRows], socket: socket)

        await viewModel.load()

        #expect(socket.emits.count == 1)
        #expect(socket.emits.first?.threadId == Self.threadId)
        #expect(socket.emits.first?.ids == [Self.unreadA, Self.unreadB])
    }

    @Test("loadEarlier emits one more receipt with only the new unread id")
    func olderPageEmitsOnlyItsNewId() async throws {
        let socket = Socket(connected: true)
        let older = [Self.row(Self.olderUnread, at: 10), Self.row(Self.unreadA, at: 100)]
        let viewModel = makeViewModel(pages: [Self.firstPageRows, older], socket: socket)
        await viewModel.load()

        await viewModel.loadEarlier()

        #expect(socket.emits.count == 2)
        #expect(socket.emits.last?.ids == [Self.olderUnread])
    }

    @Test("a loadEarlier page that only repeats shown rows emits nothing")
    func repeatedPageEmitsNothing() async throws {
        let socket = Socket(connected: true)
        let viewModel = makeViewModel(pages: [Self.firstPageRows, Self.firstPageRows], socket: socket)
        await viewModel.load()

        await viewModel.loadEarlier()

        #expect(socket.emits.count == 1)
    }

    // MARK: Held until connected (Pitfall 4)

    @Test("while disconnected nothing is emitted or recorded, and one receipt goes out on connect")
    func receiptsAreHeldUntilTheSocketConnects() async throws {
        let socket = Socket(connected: false)
        let viewModel = makeViewModel(pages: [Self.firstPageRows], socket: socket)

        await viewModel.load()
        #expect(socket.emits.isEmpty)

        viewModel.realtimeDidConnect()
        #expect(socket.emits.isEmpty)

        socket.connected = true
        viewModel.realtimeDidConnect()
        #expect(socket.emits.count == 1)
        #expect(socket.emits.first?.ids == [Self.unreadA, Self.unreadB])

        viewModel.realtimeDidConnect()
        #expect(socket.emits.count == 1)
    }

    @Test("a reconnect sends receipts only for ids that were never sent")
    func reconnectDoesNotResendSentIds() async throws {
        let socket = Socket(connected: true)
        let viewModel = makeViewModel(pages: [Self.firstPageRows], socket: socket)
        await viewModel.load()

        socket.connected = false
        viewModel.handleMessageNew(liveEvent(id: Self.olderUnread))
        #expect(socket.emits.count == 1)

        socket.connected = true
        viewModel.realtimeDidConnect()
        #expect(socket.emits.count == 2)
        #expect(socket.emits.last?.ids == [Self.olderUnread])
    }

    // MARK: Live messages

    @Test("a live peer message of this thread emits one receipt for its id")
    func livePeerMessageEmitsItsId() async throws {
        let socket = Socket(connected: true)
        let viewModel = makeViewModel(pages: [[]], socket: socket)
        await viewModel.load()
        let id = UUID()

        viewModel.handleMessageNew(liveEvent(id: id))

        #expect(socket.emits.count == 1)
        #expect(socket.emits.first?.ids == [id])
    }

    @Test("my own message or another thread's message emits nothing")
    func ownAndForeignLiveMessagesEmitNothing() async throws {
        let socket = Socket(connected: true)
        let viewModel = makeViewModel(pages: [[]], socket: socket)
        await viewModel.load()

        viewModel.handleMessageNew(liveEvent(senderId: Self.myId))
        viewModel.handleMessageNew(liveEvent(threadId: UUID()))

        #expect(socket.emits.isEmpty)
    }

    @Test("a live message already shown is not emitted twice")
    func repeatedLiveMessageEmitsOnce() async throws {
        let socket = Socket(connected: true)
        let viewModel = makeViewModel(pages: [[]], socket: socket)
        await viewModel.load()
        let event = liveEvent()

        viewModel.handleMessageNew(event)
        viewModel.handleMessageNew(event)

        #expect(socket.emits.count == 1)
    }
}
