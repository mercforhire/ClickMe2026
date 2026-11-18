//
//  ChatConversationsUnreadTests.swift
//  ClickMe2026Tests
//
//  CHAT-07 (D-13): a live message from the other person adds 1 to the row's
//  unread count while that thread is not on screen, and moves the row to the
//  top. A message for the open thread, or one the signed-in user sent, never
//  adds. The next GET /chats replaces the local count with the server's.
//  CHAT-07 (D-12): a thread that opens zeroes its own row locally, without a
//  request; the server count wins again on the next quiet reload.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Chat list unread", .serialized)
@MainActor
struct ChatConversationsUnreadTests {

    nonisolated private static let threadA = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!
    nonisolated private static let threadB = UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!
    nonisolated private static let threadC = UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!
    nonisolated private static let myId = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
    nonisolated private static let peerA = UUID(uuidString: "22222222-2222-4222-8222-222222222222")!
    nonisolated private static let peerB = UUID(uuidString: "33333333-3333-4333-8333-333333333333")!

    /// The mutable thread-on-screen value the view model reads through its seam.
    private final class VisibleThread {
        var id: UUID?
    }

    /// Serves one fixed `GET /chats` page. `body` is read on every request, so a test can swap it.
    private final class ChatsServer: @unchecked Sendable {
        private let lock = NSLock()
        private var data: Data
        init(_ data: Data) { self.data = data }
        var body: Data {
            get { lock.lock(); defer { lock.unlock() }; return data }
            set { lock.lock(); data = newValue; lock.unlock() }
        }
    }

    /// Holds a stubbed response until `open()` is called, so a test can change the
    /// list while a request is in flight. Blocks only while armed, and for at most
    /// five seconds so a broken test cannot hang.
    private final class Gate: @unchecked Sendable {
        private let semaphore = DispatchSemaphore(value: 0)
        private let lock = NSLock()
        private var armed = false
        func arm() { lock.lock(); armed = true; lock.unlock() }
        func waitIfArmed() {
            lock.lock(); let isArmed = armed; lock.unlock()
            guard isArmed else { return }
            _ = semaphore.wait(timeout: .now() + 5)
        }
        /// Releases the waiting request and lets later ones through.
        func open() {
            lock.lock(); armed = false; lock.unlock()
            semaphore.signal()
        }
    }

    nonisolated private static func page(aUnread: Int = 0, bUnread: Int = 2) -> Data {
        ChatFixtures.threadsPage([
            ChatFixtures.thread(id: threadA, partnerId: peerA, partnerName: "Alice", unreadCount: aUnread),
            ChatFixtures.thread(id: threadB, partnerId: peerB, partnerName: "Bob", unreadCount: bUnread)
        ])
    }

    nonisolated private static func chatsGets() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter {
            $0.httpMethod == "GET" && $0.url?.path.hasSuffix("/chats") == true
        }
    }

    private static func makeViewModel(
        server: ChatsServer,
        visible: VisibleThread = VisibleThread()
    ) -> ChatConversationsViewModel {
        let api = APITestFactory.make { request in
            ClientBookingFixtures.response(for: request, body: server.body)
        }
        return ChatConversationsViewModel(
            api: api,
            currentUserId: { myId },
            visibleThreadId: { visible.id }
        )
    }

    private static func makeViewModel(server: ChatsServer, gate: Gate) -> ChatConversationsViewModel {
        let api = APITestFactory.make { request in
            // The snapshot is taken before the wait, as a server would take it, so a
            // body swapped while the request is held does not reach this response.
            let snapshot = server.body
            gate.waitIfArmed()
            return ClientBookingFixtures.response(for: request, body: snapshot)
        }
        return ChatConversationsViewModel(
            api: api,
            currentUserId: { myId },
            visibleThreadId: { nil }
        )
    }

    private static func event(thread: UUID, sender: UUID, content: String = "hello") -> RealtimeMessageNewEvent {
        RealtimeMessageNewEvent(
            messageId: UUID(),
            threadId: thread,
            senderId: sender,
            type: .text,
            content: content,
            timestamp: Date(),
            status: .sent
        )
    }

    private func count(_ viewModel: ChatConversationsViewModel, _ thread: UUID) -> Int? {
        viewModel.chats.first { $0.threadId == thread }?.unreadCount
    }

    /// Waits up to two seconds for `condition`, yielding between checks.
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    // MARK: D-13 +1 for a peer message on a closed thread

    @Test("peer message for a closed thread adds 1 and moves the row to the top")
    func peerMessageAddsOne() async {
        let server = ChatsServer(Self.page())
        let viewModel = Self.makeViewModel(server: server)
        await viewModel.load()
        #expect(viewModel.chats.map(\.threadId) == [Self.threadA, Self.threadB])

        viewModel.handleMessageNew(Self.event(thread: Self.threadB, sender: Self.peerB))

        #expect(count(viewModel, Self.threadB) == 3)
        #expect(viewModel.chats.first?.threadId == Self.threadB)
        #expect(count(viewModel, Self.threadA) == 0)
    }

    @Test("peer message for the thread on screen leaves the count at 0 and moves the row to the top")
    func visibleThreadDoesNotCount() async {
        let server = ChatsServer(Self.page())
        let visible = VisibleThread()
        let viewModel = Self.makeViewModel(server: server, visible: visible)
        await viewModel.load()
        visible.id = Self.threadA

        viewModel.handleMessageNew(Self.event(thread: Self.threadA, sender: Self.peerA))

        #expect(count(viewModel, Self.threadA) == 0)
        #expect(viewModel.chats.first?.threadId == Self.threadA)
    }

    @Test("a message the signed-in user sent never adds to the count")
    func ownMessageDoesNotCount() async {
        let server = ChatsServer(Self.page())
        let viewModel = Self.makeViewModel(server: server)
        await viewModel.load()

        viewModel.handleMessageNew(Self.event(thread: Self.threadB, sender: Self.myId))

        #expect(count(viewModel, Self.threadB) == 2)
    }

    @Test("99 plus one peer message reads 100")
    func ninetyNinePlusOne() async {
        let server = ChatsServer(Self.page(bUnread: 99))
        let viewModel = Self.makeViewModel(server: server)
        await viewModel.load()

        viewModel.handleMessageNew(Self.event(thread: Self.threadB, sender: Self.peerB))

        #expect(count(viewModel, Self.threadB) == 100)
    }

    @Test("a message for a thread not in the list triggers one GET /chats and the server page replaces the list")
    func unknownThreadReloads() async {
        let server = ChatsServer(Self.page())
        let viewModel = Self.makeViewModel(server: server)
        await viewModel.load()
        #expect(Self.chatsGets().count == 1)

        server.body = ChatFixtures.threadsPage([
            ChatFixtures.thread(id: Self.threadC, partnerId: UUID(), partnerName: "Cara", unreadCount: 1),
            ChatFixtures.thread(id: Self.threadA, partnerId: Self.peerA, partnerName: "Alice", unreadCount: 0)
        ])
        viewModel.handleMessageNew(Self.event(thread: Self.threadC, sender: UUID()))
        await waitUntil { viewModel.chats.first?.threadId == Self.threadC }

        #expect(Self.chatsGets().count == 2)
        #expect(viewModel.chats.map(\.threadId) == [Self.threadC, Self.threadA])
        #expect(count(viewModel, Self.threadC) == 1)
    }

    @Test("the next GET /chats replaces a drifted local count with the server's")
    func reloadResyncs() async {
        let server = ChatsServer(Self.page())
        let viewModel = Self.makeViewModel(server: server)
        await viewModel.load()
        viewModel.handleMessageNew(Self.event(thread: Self.threadB, sender: Self.peerB))
        #expect(count(viewModel, Self.threadB) == 3)

        await viewModel.silentReload()

        #expect(count(viewModel, Self.threadB) == 2)
    }

    // MARK: D-12 opening a thread zeroes its row

    @Test("markOpened zeroes the opened row, leaves the others, and sends no request")
    func markOpenedZeroesRow() async {
        let server = ChatsServer(Self.page(aUnread: 4, bUnread: 3))
        let viewModel = Self.makeViewModel(server: server)
        await viewModel.load()
        let requestsBefore = MockURLProtocol.recordedRequests.count

        viewModel.markOpened(threadId: Self.threadB)

        #expect(count(viewModel, Self.threadB) == 0)
        #expect(count(viewModel, Self.threadA) == 4)
        #expect(MockURLProtocol.recordedRequests.count == requestsBefore)
    }

    @Test("markOpened for a thread that is not in the list changes nothing")
    func markOpenedUnknownThread() async {
        let server = ChatsServer(Self.page(aUnread: 4, bUnread: 3))
        let viewModel = Self.makeViewModel(server: server)
        await viewModel.load()
        let before = viewModel.chats

        viewModel.markOpened(threadId: Self.threadC)

        #expect(viewModel.chats == before)
    }

    @Test("after markOpened, a quiet reload puts the server's count back")
    func markOpenedThenReloadServerWins() async {
        let server = ChatsServer(Self.page(aUnread: 0, bUnread: 3))
        let viewModel = Self.makeViewModel(server: server)
        await viewModel.load()
        viewModel.markOpened(threadId: Self.threadB)
        #expect(count(viewModel, Self.threadB) == 0)

        server.body = Self.page(aUnread: 0, bUnread: 1)
        await viewModel.silentReload()

        #expect(count(viewModel, Self.threadB) == 1)
    }

    // MARK: Reloads that overlap local changes (WR-04)

    @Test("a reload that finishes after markOpened keeps the row at 0 instead of the server's older count")
    func lateReloadKeepsOpenedRowAtZero() async {
        let server = ChatsServer(Self.page(aUnread: 0, bUnread: 3))
        let gate = Gate()
        let viewModel = Self.makeViewModel(server: server, gate: gate)
        await viewModel.load()

        gate.arm()
        let reload = Task { await viewModel.silentReload() }
        await waitUntil { Self.chatsGets().count >= 2 }
        viewModel.markOpened(threadId: Self.threadB)
        gate.open()
        await reload.value

        #expect(count(viewModel, Self.threadB) == 0)
    }

    @Test("a reload that finishes after a live peer message keeps the local count")
    func lateReloadKeepsLiveIncrement() async {
        let server = ChatsServer(Self.page(aUnread: 0, bUnread: 2))
        let gate = Gate()
        let viewModel = Self.makeViewModel(server: server, gate: gate)
        await viewModel.load()

        gate.arm()
        let reload = Task { await viewModel.silentReload() }
        await waitUntil { Self.chatsGets().count >= 2 }
        viewModel.handleMessageNew(Self.event(thread: Self.threadB, sender: Self.peerB))
        gate.open()
        await reload.value

        #expect(count(viewModel, Self.threadB) == 3)
    }

    @Test("the next reload after the first one ended takes the server's count again")
    func overridesEndWithTheReload() async {
        let server = ChatsServer(Self.page(aUnread: 0, bUnread: 3))
        let gate = Gate()
        let viewModel = Self.makeViewModel(server: server, gate: gate)
        await viewModel.load()
        gate.arm()
        let reload = Task { await viewModel.silentReload() }
        await waitUntil { Self.chatsGets().count >= 2 }
        viewModel.markOpened(threadId: Self.threadB)
        gate.open()
        await reload.value

        server.body = Self.page(aUnread: 0, bUnread: 1)
        await viewModel.silentReload()

        #expect(count(viewModel, Self.threadB) == 1)
    }

    @Test("a reload that finishes after a live message keeps the row's preview and its place at the top")
    func lateReloadKeepsLivePreviewAndOrder() async {
        let server = ChatsServer(Self.page(aUnread: 0, bUnread: 2))
        let gate = Gate()
        let viewModel = Self.makeViewModel(server: server, gate: gate)
        await viewModel.load()
        #expect(viewModel.chats.map(\.threadId) == [Self.threadA, Self.threadB])

        gate.arm()
        let reload = Task { await viewModel.silentReload() }
        await waitUntil { Self.chatsGets().count >= 2 }
        viewModel.handleMessageNew(Self.event(thread: Self.threadB, sender: Self.peerB, content: "fresh"))
        gate.open()
        await reload.value

        #expect(viewModel.chats.map(\.threadId) == [Self.threadB, Self.threadA])
        #expect(viewModel.chats.first?.lastMessage == "fresh")
        #expect(viewModel.chats.first?.timeLabel.isEmpty == false)
        #expect(count(viewModel, Self.threadB) == 3)
    }

    @Test("two live messages during a reload keep the newest conversation on top")
    func lateReloadKeepsNewestFirst() async {
        let server = ChatsServer(Self.page(aUnread: 0, bUnread: 0))
        let gate = Gate()
        let viewModel = Self.makeViewModel(server: server, gate: gate)
        await viewModel.load()

        gate.arm()
        let reload = Task { await viewModel.silentReload() }
        await waitUntil { Self.chatsGets().count >= 2 }
        viewModel.handleMessageNew(Self.event(thread: Self.threadB, sender: Self.peerB, content: "first"))
        viewModel.handleMessageNew(Self.event(thread: Self.threadA, sender: Self.peerA, content: "second"))
        gate.open()
        await reload.value

        #expect(viewModel.chats.map(\.threadId) == [Self.threadA, Self.threadB])
        #expect(viewModel.chats.map(\.lastMessage) == ["second", "first"])
    }

    @Test("markOpened while the first load runs keeps the row at 0 even though the row is not listed yet")
    func openedDuringFirstLoadStaysZero() async {
        let server = ChatsServer(Self.page(aUnread: 4, bUnread: 3))
        let gate = Gate()
        let viewModel = Self.makeViewModel(server: server, gate: gate)

        gate.arm()
        let load = Task { await viewModel.load() }
        await waitUntil { Self.chatsGets().count >= 1 }
        #expect(viewModel.chats.isEmpty)
        viewModel.markOpened(threadId: Self.threadB)
        gate.open()
        await load.value

        #expect(count(viewModel, Self.threadB) == 0)
        #expect(count(viewModel, Self.threadA) == 4)
    }

    @Test("a live message for an unknown thread before the first load finished starts no request")
    func unknownThreadBeforeFirstLoadIsIgnored() async {
        let server = ChatsServer(Self.page())
        let viewModel = Self.makeViewModel(server: server)

        viewModel.handleMessageNew(Self.event(thread: Self.threadC, sender: UUID()))
        try? await Task.sleep(for: .milliseconds(50))

        #expect(viewModel.loadState == .idle)
        #expect(Self.chatsGets().isEmpty)
    }
}
