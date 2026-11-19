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

import Combine
import Foundation
import Testing
@testable import ClickMe2026

/// `MockURLProtocol.handler` is global state, so these suites depend on the test
/// plan's `parallelizable: false` (`ClickMe2026/AllTests.xctestplan`). `.serialized`
/// only orders tests inside one suite.
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

    /// A flag a test flips while a stubbed handler reads it on another thread.
    private final class FailureSwitch: @unchecked Sendable {
        private let lock = NSLock()
        private var value = false
        var isOn: Bool {
            get { lock.withLock { value } }
            set { lock.withLock { value = newValue } }
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

    private static func makeViewModel(server: ChatsServer, gate: RequestGate) -> ChatConversationsViewModel {
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

    /// - Parameters:
    ///   - content: Pass `nil` for a live event that carries no text.
    private static func event(thread: UUID, sender: UUID, content: String? = "hello") -> RealtimeMessageNewEvent {
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
        await waitUntil("the new thread at the top") { viewModel.chats.first?.threadId == Self.threadC }

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
        let gate = RequestGate()
        let viewModel = Self.makeViewModel(server: server, gate: gate)
        await viewModel.load()

        gate.arm()
        let reload = Task { await viewModel.silentReload() }
        await waitUntil("the second GET /chats") { Self.chatsGets().count >= 2 }
        viewModel.markOpened(threadId: Self.threadB)
        gate.open()
        await reload.value

        #expect(count(viewModel, Self.threadB) == 0)
    }

    @Test("a reload that finishes after a live peer message keeps the local count")
    func lateReloadKeepsLiveIncrement() async {
        let server = ChatsServer(Self.page(aUnread: 0, bUnread: 2))
        let gate = RequestGate()
        let viewModel = Self.makeViewModel(server: server, gate: gate)
        await viewModel.load()

        gate.arm()
        let reload = Task { await viewModel.silentReload() }
        await waitUntil("the second GET /chats") { Self.chatsGets().count >= 2 }
        viewModel.handleMessageNew(Self.event(thread: Self.threadB, sender: Self.peerB))
        gate.open()
        await reload.value

        #expect(count(viewModel, Self.threadB) == 3)
    }

    @Test("the next reload after the first one ended takes the server's count again")
    func overridesEndWithTheReload() async {
        let server = ChatsServer(Self.page(aUnread: 0, bUnread: 3))
        let gate = RequestGate()
        let viewModel = Self.makeViewModel(server: server, gate: gate)
        await viewModel.load()
        gate.arm()
        let reload = Task { await viewModel.silentReload() }
        await waitUntil("the second GET /chats") { Self.chatsGets().count >= 2 }
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
        let gate = RequestGate()
        let viewModel = Self.makeViewModel(server: server, gate: gate)
        await viewModel.load()
        #expect(viewModel.chats.map(\.threadId) == [Self.threadA, Self.threadB])

        gate.arm()
        let reload = Task { await viewModel.silentReload() }
        await waitUntil("the second GET /chats") { Self.chatsGets().count >= 2 }
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
        let gate = RequestGate()
        let viewModel = Self.makeViewModel(server: server, gate: gate)
        await viewModel.load()

        gate.arm()
        let reload = Task { await viewModel.silentReload() }
        await waitUntil("the second GET /chats") { Self.chatsGets().count >= 2 }
        viewModel.handleMessageNew(Self.event(thread: Self.threadB, sender: Self.peerB, content: "first"))
        viewModel.handleMessageNew(Self.event(thread: Self.threadA, sender: Self.peerA, content: "second"))
        gate.open()
        await reload.value

        #expect(viewModel.chats.map(\.threadId) == [Self.threadA, Self.threadB])
        #expect(viewModel.chats.map(\.lastMessage) == ["second", "first"])
    }

    @Test("a live message without text during a reload leaves the server's newer preview in place (WR-07)")
    func lateReloadKeepsServerPreviewForTextlessEvent() async {
        let server = ChatsServer(Self.page())
        let gate = RequestGate()
        let viewModel = Self.makeViewModel(server: server, gate: gate)
        await viewModel.load()

        // The server already holds a newer preview than the one the list shows.
        server.body = ChatFixtures.threadsPage([
            ChatFixtures.thread(id: Self.threadA, partnerId: Self.peerA, partnerName: "Alice"),
            ChatFixtures.thread(
                id: Self.threadB,
                partnerId: Self.peerB,
                partnerName: "Bob",
                unreadCount: 2,
                lastMessage: "newer on the server"
            )
        ])
        gate.arm()
        let reload = Task { await viewModel.silentReload() }
        await waitUntil("the second GET /chats") { Self.chatsGets().count >= 2 }
        viewModel.handleMessageNew(Self.event(thread: Self.threadB, sender: Self.peerB, content: nil))
        gate.open()
        await reload.value

        // The event carried no text, so it says nothing about the preview. The row
        // still moves to the top and counts as unread.
        #expect(viewModel.chats.map(\.threadId) == [Self.threadB, Self.threadA])
        #expect(viewModel.chats.first?.lastMessage == "newer on the server")
        #expect(viewModel.chats.first?.timeLabel.isEmpty == false)
        #expect(count(viewModel, Self.threadB) == 3)
    }

    // MARK: Overlapping reloads (IN-10)

    /// After the first load, `silentReload` runs twice: request 2 (reload A) is held on `gate`.
    /// The mock runs one request at a time, so request 3 (reload B) reaches the handler only
    /// after A's answer. Reload B has still started by then as far as the view model can tell:
    /// its bookkeeping begins before its request is sent. Each answer is the page the server
    /// held when its request arrived, as a real server would answer.
    private static func makeOverlapViewModel(server: ChatsServer, gate: RequestGate) -> ChatConversationsViewModel {
        let api = APITestFactory.make { request in
            let snapshot = server.body
            if chatsGets().count == 2 { gate.waitIfArmed() }
            return ClientBookingFixtures.response(for: request, body: snapshot)
        }
        return ChatConversationsViewModel(api: api, currentUserId: { myId }, visibleThreadId: { nil })
    }

    /// Every value `chats` takes from now on, in order. Reload B's request goes out right after
    /// reload A's answer, so a test cannot stop between the two answers; it reads them here.
    private func recordChats(of viewModel: ChatConversationsViewModel) -> ChatsRecorder {
        let recorder = ChatsRecorder()
        recorder.cancellable = viewModel.$chats.dropFirst().sink { recorder.values.append($0) }
        return recorder
    }

    private final class ChatsRecorder {
        var values: [[ChatPreview]] = []
        var cancellable: AnyCancellable?
    }

    /// Lets a task that was just created run up to its first suspension (the request it sends).
    private func letReloadStart() async {
        for _ in 0..<5 { await Task.yield() }
        try? await Task.sleep(for: .milliseconds(50))
    }

    @Test("a change recorded before a second reload started is not laid over that reload's newer response (IN-10)")
    func changeBeforeSecondReloadDoesNotReachIt() async {
        let server = ChatsServer(Self.page(aUnread: 0, bUnread: 2))
        let gate = RequestGate()
        let viewModel = Self.makeOverlapViewModel(server: server, gate: gate)
        await viewModel.load()

        gate.arm()
        let reloadA = Task { await viewModel.silentReload() }
        await waitUntil("the second GET /chats") { Self.chatsGets().count >= 2 }
        viewModel.markOpened(threadId: Self.threadB)
        // More peer messages reached the server before reload B's request was sent.
        server.body = Self.page(aUnread: 0, bUnread: 5)
        let reloadB = Task { await viewModel.silentReload() }
        await letReloadStart()

        let recorder = recordChats(of: viewModel)
        gate.open()
        await reloadA.value
        await reloadB.value

        // Reload A started before the change, so its answer takes the change. Reload B
        // started after it, so its answer is the server's.
        #expect(recorder.values.count == 2)
        #expect(recorder.values.first?.first { $0.threadId == Self.threadB }?.unreadCount == 0)
        #expect(count(viewModel, Self.threadB) == 5)
    }

    @Test("each overlapping reload takes only the changes recorded after its own request started (IN-10)")
    func eachReloadTakesItsOwnChanges() async {
        let server = ChatsServer(Self.page(aUnread: 0, bUnread: 2))
        let gate = RequestGate()
        let viewModel = Self.makeOverlapViewModel(server: server, gate: gate)
        await viewModel.load()

        gate.arm()
        let reloadA = Task { await viewModel.silentReload() }
        await waitUntil("the second GET /chats") { Self.chatsGets().count >= 2 }
        viewModel.markOpened(threadId: Self.threadB)
        server.body = Self.page(aUnread: 0, bUnread: 5)
        let reloadB = Task { await viewModel.silentReload() }
        await letReloadStart()
        // A live message for A arrives while both requests are out.
        viewModel.handleMessageNew(Self.event(thread: Self.threadA, sender: Self.peerA, content: "fresh"))

        let recorder = recordChats(of: viewModel)
        gate.open()
        await reloadA.value
        await reloadB.value

        // Reload A started before both changes and takes both.
        #expect(recorder.values.count == 2)
        let answerA = recorder.values.first ?? []
        #expect(answerA.map(\.threadId) == [Self.threadA, Self.threadB])
        #expect(answerA.first?.lastMessage == "fresh")
        #expect(answerA.first?.unreadCount == 1)
        #expect(answerA.last?.unreadCount == 0)

        // Reload B started after markOpened, so it takes only the live message.
        #expect(viewModel.chats.map(\.threadId) == [Self.threadA, Self.threadB])
        #expect(viewModel.chats.first?.lastMessage == "fresh")
        #expect(count(viewModel, Self.threadA) == 1)
        #expect(count(viewModel, Self.threadB) == 5)
    }

    @Test("once every reload has ended, no recorded change is left for the next one (IN-10)")
    func changesEndWithTheLastOverlappingReload() async {
        let server = ChatsServer(Self.page(aUnread: 0, bUnread: 2))
        let gate = RequestGate()
        let viewModel = Self.makeOverlapViewModel(server: server, gate: gate)
        await viewModel.load()

        gate.arm()
        let reloadA = Task { await viewModel.silentReload() }
        await waitUntil("the second GET /chats") { Self.chatsGets().count >= 2 }
        let reloadB = Task { await viewModel.silentReload() }
        await letReloadStart()
        viewModel.markOpened(threadId: Self.threadB)
        gate.open()
        await reloadA.value
        await reloadB.value
        #expect(count(viewModel, Self.threadB) == 0)

        server.body = Self.page(aUnread: 0, bUnread: 1)
        await viewModel.silentReload()
        #expect(count(viewModel, Self.threadB) == 1)
    }

    @Test("markOpened while the first load runs keeps the row at 0 even though the row is not listed yet")
    func openedDuringFirstLoadStaysZero() async {
        let server = ChatsServer(Self.page(aUnread: 4, bUnread: 3))
        let gate = RequestGate()
        let viewModel = Self.makeViewModel(server: server, gate: gate)

        gate.arm()
        let load = Task { await viewModel.load() }
        await waitUntil("the first GET /chats") { Self.chatsGets().count >= 1 }
        #expect(viewModel.chats.isEmpty)
        viewModel.markOpened(threadId: Self.threadB)
        gate.open()
        await load.value

        #expect(count(viewModel, Self.threadB) == 0)
        #expect(count(viewModel, Self.threadA) == 4)
    }

    // MARK: Unknown thread while a load is in flight (WR-06)

    @Test("an unknown thread's message during the first load triggers one follow-up fetch that lists it")
    func unknownThreadDuringFirstLoadRefetches() async {
        let server = ChatsServer(Self.page())
        let gate = RequestGate()
        let viewModel = Self.makeViewModel(server: server, gate: gate)

        gate.arm()
        let load = Task { await viewModel.load() }
        await waitUntil("the first GET /chats") { Self.chatsGets().count >= 1 }
        // The held response was taken before the message; the next one lists the thread.
        server.body = ChatFixtures.threadsPage([
            ChatFixtures.thread(id: Self.threadC, partnerId: UUID(), partnerName: "Cara", unreadCount: 1),
            ChatFixtures.thread(id: Self.threadA, partnerId: Self.peerA, partnerName: "Alice", unreadCount: 0)
        ])
        viewModel.handleMessageNew(Self.event(thread: Self.threadC, sender: UUID()))
        gate.open()
        await load.value
        await waitUntil("the new thread at the top") { viewModel.chats.first?.threadId == Self.threadC }

        #expect(Self.chatsGets().count == 2)
        #expect(viewModel.chats.map(\.threadId) == [Self.threadC, Self.threadA])
        #expect(viewModel.loadState == .loaded)
    }

    @Test("an unknown thread's message during a pull-to-refresh triggers one follow-up fetch")
    func unknownThreadDuringPullToRefreshRefetches() async {
        let server = ChatsServer(Self.page())
        let gate = RequestGate()
        let viewModel = Self.makeViewModel(server: server, gate: gate)
        await viewModel.load()

        gate.arm()
        let refresh = Task { await viewModel.reload() }
        await waitUntil("the second GET /chats") { Self.chatsGets().count >= 2 }
        server.body = ChatFixtures.threadsPage([
            ChatFixtures.thread(id: Self.threadC, partnerId: UUID(), partnerName: "Cara", unreadCount: 1),
            ChatFixtures.thread(id: Self.threadA, partnerId: Self.peerA, partnerName: "Alice", unreadCount: 0)
        ])
        viewModel.handleMessageNew(Self.event(thread: Self.threadC, sender: UUID()))
        gate.open()
        await refresh.value
        await waitUntil("the new thread at the top") { viewModel.chats.first?.threadId == Self.threadC }

        #expect(Self.chatsGets().count == 3)
        #expect(viewModel.chats.map(\.threadId) == [Self.threadC, Self.threadA])
    }

    @Test("a load with no unknown-thread message makes no follow-up fetch")
    func plainLoadMakesNoFollowUp() async {
        let server = ChatsServer(Self.page())
        let viewModel = Self.makeViewModel(server: server)

        await viewModel.load()
        await viewModel.reload()

        #expect(Self.chatsGets().count == 2)
    }

    @Test("a load that fails drops the pending follow-up")
    func failedLoadDropsFollowUp() async {
        let server = ChatsServer(Self.page())
        let gate = RequestGate()
        let failing = FailureSwitch()
        let api = APITestFactory.make { request in
            gate.waitIfArmed()
            if failing.isOn {
                return ClientBookingFixtures.response(
                    for: request,
                    status: 500,
                    body: ClientBookingFixtures.errorBody(code: "INTERNAL_ERROR", message: "Boom")
                )
            }
            return ClientBookingFixtures.response(for: request, body: server.body)
        }
        let viewModel = ChatConversationsViewModel(api: api, currentUserId: { Self.myId }, visibleThreadId: { nil })

        failing.isOn = true
        gate.arm()
        let load = Task { await viewModel.load() }
        await waitUntil("the first GET /chats") { Self.chatsGets().count >= 1 }
        viewModel.handleMessageNew(Self.event(thread: Self.threadC, sender: UUID()))
        gate.open()
        await load.value

        failing.isOn = false
        await viewModel.load()

        #expect(Self.chatsGets().count == 2)
        #expect(viewModel.loadState == .loaded)
    }

    /// A server whose first request is held on `gate` and lists A and B. Later requests list
    /// thread C, except those whose number (1-based, in request order) is in `failing`, which
    /// answer 500.
    private static func makeFollowUpViewModel(gate: RequestGate, failing: ClosedRange<Int>) -> ChatConversationsViewModel {
        let withC = ChatFixtures.threadsPage([
            ChatFixtures.thread(id: threadC, partnerId: UUID(), partnerName: "Cara", unreadCount: 1),
            ChatFixtures.thread(id: threadA, partnerId: peerA, partnerName: "Alice", unreadCount: 0)
        ])
        let api = APITestFactory.make { request in
            // Requests run one at a time here, so the log's size is this request's number.
            let number = chatsGets().count
            gate.waitIfArmed()
            if number == 1 { return ClientBookingFixtures.response(for: request, body: page()) }
            if failing.contains(number) {
                return ClientBookingFixtures.response(
                    for: request,
                    status: 500,
                    body: ClientBookingFixtures.errorBody(code: "INTERNAL_ERROR", message: "Boom")
                )
            }
            return ClientBookingFixtures.response(for: request, body: withC)
        }
        return ChatConversationsViewModel(api: api, currentUserId: { myId }, visibleThreadId: { nil })
    }

    @Test("a follow-up fetch that fails is retried by the next load() and then stops (IN-08)")
    func failedFollowUpIsRetriedByNextLoad() async {
        let gate = RequestGate()
        let viewModel = Self.makeFollowUpViewModel(gate: gate, failing: 2...2)

        gate.arm()
        let load = Task { await viewModel.load() }
        await waitUntil("the first GET /chats") { Self.chatsGets().count >= 1 }
        viewModel.handleMessageNew(Self.event(thread: Self.threadC, sender: UUID()))
        gate.open()
        await load.value

        // The follow-up ran and failed: the list is still the first response.
        #expect(Self.chatsGets().count == 2)
        #expect(viewModel.chats.map(\.threadId) == [Self.threadA, Self.threadB])
        #expect(viewModel.loadState == .loaded)

        await viewModel.load()
        #expect(Self.chatsGets().count == 3)
        #expect(viewModel.chats.map(\.threadId) == [Self.threadC, Self.threadA])

        // The retry succeeded, so the flag is gone and a further load() is a no-op.
        await viewModel.load()
        #expect(Self.chatsGets().count == 3)
    }

    @Test("a retried follow-up that fails again waits for the next load() instead of looping (IN-08)")
    func failedRetryDoesNotLoop() async {
        let gate = RequestGate()
        let viewModel = Self.makeFollowUpViewModel(gate: gate, failing: 2...3)

        gate.arm()
        let load = Task { await viewModel.load() }
        await waitUntil("the first GET /chats") { Self.chatsGets().count >= 1 }
        viewModel.handleMessageNew(Self.event(thread: Self.threadC, sender: UUID()))
        gate.open()
        await load.value
        #expect(Self.chatsGets().count == 2)

        await viewModel.load()
        #expect(Self.chatsGets().count == 3)
        #expect(viewModel.chats.map(\.threadId) == [Self.threadA, Self.threadB])

        // Still owed, one more attempt per load(), never a loop inside one call.
        await viewModel.load()
        #expect(Self.chatsGets().count == 4)
        #expect(viewModel.chats.map(\.threadId) == [Self.threadC, Self.threadA])
    }

    @Test("a pull-to-refresh after a failed follow-up covers it without an extra fetch (IN-08)")
    func refreshCoversFailedFollowUp() async {
        let gate = RequestGate()
        let viewModel = Self.makeFollowUpViewModel(gate: gate, failing: 2...2)

        gate.arm()
        let load = Task { await viewModel.load() }
        await waitUntil("the first GET /chats") { Self.chatsGets().count >= 1 }
        viewModel.handleMessageNew(Self.event(thread: Self.threadC, sender: UUID()))
        gate.open()
        await load.value

        await viewModel.reload()
        #expect(Self.chatsGets().count == 3)
        #expect(viewModel.chats.map(\.threadId) == [Self.threadC, Self.threadA])

        await viewModel.load()
        #expect(Self.chatsGets().count == 3)
    }

    @Test("a live message for an unknown thread before the first load started adds no request")
    func unknownThreadBeforeFirstLoadIsIgnored() async {
        let server = ChatsServer(Self.page())
        let viewModel = Self.makeViewModel(server: server)

        viewModel.handleMessageNew(Self.event(thread: Self.threadC, sender: UUID()))
        // A reload started by the message would run while `load()` awaits its request,
        // so it would add a second GET /chats before the check below.
        await viewModel.load()

        #expect(viewModel.loadState == .loaded)
        #expect(Self.chatsGets().count == 1)
    }
}
