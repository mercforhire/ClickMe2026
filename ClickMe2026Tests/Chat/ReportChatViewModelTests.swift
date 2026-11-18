//
//  ReportChatViewModelTests.swift
//  ClickMe2026Tests
//
//  CHAT-03 (D-07, D-08): the Block & Report screen follows the blocker matrix. Block 200
//  is blocked by me, unblock 200 is not blocked, unblock 403 NOT_BLOCKER is blocked by
//  the peer, and every outcome is handed to the thread through onBlockStateChange.
//  CHAT-04 (D-05): the screen only ever describes what blocking does to this chat.
//  CHAT-02 (D-09, D-19): chat reports send the UserReportReason raw value, details are
//  capped at 1,000 UTF-16 units and a failed report is never retried.
//  The block lookup uses ChatThreadLookup (limit 100), not a single page of 50.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Report and block", .serialized)
@MainActor
struct ReportChatViewModelTests {

    private typealias Fixtures = ClientBookingFixtures

    nonisolated private static let threadId = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!
    nonisolated private static let partnerId = UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!

    typealias Responder = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    /// What the screen handed back, in order.
    @MainActor
    private final class Log {
        private(set) var states: [ChatBlockState] = []
        private(set) var blocked: [String] = []
        private(set) var reports: [(reason: String, details: String)] = []

        func record(_ state: ChatBlockState) { states.append(state) }
        func recordBlock(_ name: String) { blocked.append(name) }
        func recordReport(_ reason: String, _ details: String) { reports.append((reason, details)) }
    }

    // MARK: Stub helpers

    nonisolated private static func isChatsList(_ request: URLRequest) -> Bool {
        request.httpMethod == "GET" && request.url?.path.hasSuffix("/chats") == true
    }

    nonisolated private static func isActionsPost(_ request: URLRequest) -> Bool {
        request.httpMethod == "POST" && request.url?.path.hasSuffix("/actions") == true
    }

    nonisolated private static func actionsPosts() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter(isActionsPost)
    }

    nonisolated private static func chatsGets() -> [URLRequest] {
        MockURLProtocol.recordedRequests.filter(isChatsList)
    }

    nonisolated private static let actionsOK: Responder = { request in
        Fixtures.response(for: request, body: Data(#"{"status":"success"}"#.utf8))
    }

    nonisolated private static func actionsFail(_ status: Int, code: String, message: String) -> Responder {
        { request in
            Fixtures.response(for: request, status: status, body: Fixtures.errorBody(code: code, message: message))
        }
    }

    /// Routes GET /chats to `onChats` and POST /chats/{id}/actions to `onActions`; 404 otherwise.
    private static func makeAPI(onChats: Responder? = nil, onActions: Responder? = nil) -> ClickMeAPI {
        APITestFactory.make { request in
            if isChatsList(request), let onChats { return try onChats(request) }
            if isActionsPost(request), let onActions { return try onActions(request) }
            return Fixtures.response(
                for: request,
                status: 404,
                body: Fixtures.errorBody(code: "NOT_FOUND", message: "Not found")
            )
        }
    }

    nonisolated private static func chatsJSON(_ rows: [String]) -> Responder {
        { request in Fixtures.response(for: request, body: ChatFixtures.threadsPage(rows)) }
    }

    private func makeViewModel(
        isBlocked: Bool = false,
        blockedByMe: Bool = false,
        api: ClickMeAPI,
        log: Log
    ) -> ReportChatViewModel {
        ReportChatViewModel(
            threadId: Self.threadId,
            userName: "Peer",
            isBlocked: isBlocked,
            blockedByMe: blockedByMe,
            api: api,
            onBlockStateChange: { log.record($0) }
        )
    }

    private static let notBlocked = ChatBlockState(isBlocked: false, blockedByMe: false)
    private static let blockedByMe = ChatBlockState(isBlocked: true, blockedByMe: true)
    private static let blockedByPeer = ChatBlockState(isBlocked: true, blockedByMe: false)

    // MARK: Block

    @Test("block 200 gives blocked by me, tells the thread once and posts action block")
    func blockSucceeds() async {
        let log = Log()
        let viewModel = makeViewModel(api: Self.makeAPI(onActions: Self.actionsOK), log: log)

        viewModel.blockUser { log.recordBlock($0) }
        await viewModel.awaitPendingAction()

        #expect(viewModel.blockState == Self.blockedByMe)
        #expect(log.states == [Self.blockedByMe])
        #expect(log.blocked == ["Peer"])
        let posts = Self.actionsPosts()
        #expect(posts.count == 1)
        #expect(posts.first?.jsonBodyForTest()?["action"] as? String == "block")
        #expect(viewModel.apiError == nil)
    }

    @Test("a 500 on block shows its title and the server message, and changes nothing")
    func blockServerError() async {
        let log = Log()
        let api = Self.makeAPI(onActions: Self.actionsFail(500, code: "INTERNAL_ERROR", message: "Server broke"))
        let viewModel = makeViewModel(api: api, log: log)

        viewModel.blockUser { log.recordBlock($0) }
        await viewModel.awaitPendingAction()

        #expect(viewModel.apiErrorTitle == "Couldn't block user")
        #expect(viewModel.apiError == "Server broke")
        #expect(viewModel.blockState == Self.notBlocked)
        #expect(log.states.isEmpty)
        #expect(log.blocked.isEmpty)
    }

    @Test("a transport error on block reads as a connection problem")
    func blockTransportFailure() async {
        let log = Log()
        let api = Self.makeAPI(onActions: { _ in throw URLError(.notConnectedToInternet) })
        let viewModel = makeViewModel(api: api, log: log)

        viewModel.blockUser { _ in }
        await viewModel.awaitPendingAction()

        #expect(viewModel.apiError == "Check your connection and try again.")
        #expect(viewModel.blockState == Self.notBlocked)
    }

    @Test("a second Block tap while the first runs sends no second request")
    func blockIgnoresARepeatTap() async {
        let log = Log()
        let viewModel = makeViewModel(api: Self.makeAPI(onActions: Self.actionsOK), log: log)

        viewModel.blockUser { _ in }
        viewModel.blockUser { _ in }
        await viewModel.awaitPendingAction()

        #expect(Self.actionsPosts().count == 1)
        #expect(log.states == [Self.blockedByMe])
    }

    // MARK: Unblock

    @Test("unblock 200 from blocked by me gives not blocked and tells the thread")
    func unblockSucceeds() async {
        let log = Log()
        let viewModel = makeViewModel(
            isBlocked: true,
            blockedByMe: true,
            api: Self.makeAPI(onActions: Self.actionsOK),
            log: log
        )

        viewModel.unblockUser { log.recordBlock($0) }
        await viewModel.awaitPendingAction()

        #expect(viewModel.blockState == Self.notBlocked)
        #expect(log.states == [Self.notBlocked])
        #expect(Self.actionsPosts().first?.jsonBodyForTest()?["action"] as? String == "unblock")
    }

    @Test("unblock 403 NOT_BLOCKER moves to blocked by the peer with its own title and message")
    func unblockNotBlocker() async {
        let log = Log()
        let api = Self.makeAPI(onActions: Self.actionsFail(403, code: "NOT_BLOCKER", message: "Not the blocker"))
        let viewModel = makeViewModel(isBlocked: true, blockedByMe: true, api: api, log: log)

        viewModel.unblockUser { log.recordBlock($0) }
        await viewModel.awaitPendingAction()

        #expect(viewModel.blockState == Self.blockedByPeer)
        #expect(viewModel.blockState.showsUnblock == false)
        #expect(viewModel.apiErrorTitle == "Couldn't unblock user")
        #expect(viewModel.apiError == "Only the person who blocked this conversation can unblock it.")
        #expect(log.states == [Self.blockedByPeer])
        #expect(log.blocked.isEmpty)
    }

    @Test("a 500 on unblock keeps blocked by me and shows the server message")
    func unblockServerError() async {
        let log = Log()
        let api = Self.makeAPI(onActions: Self.actionsFail(500, code: "INTERNAL_ERROR", message: "Server broke"))
        let viewModel = makeViewModel(isBlocked: true, blockedByMe: true, api: api, log: log)

        viewModel.unblockUser { _ in }
        await viewModel.awaitPendingAction()

        #expect(viewModel.apiErrorTitle == "Couldn't unblock user")
        #expect(viewModel.apiError == "Server broke")
        #expect(viewModel.blockState == Self.blockedByMe)
        #expect(log.states.isEmpty)
    }

    // MARK: Lookup

    @Test("the lookup reads a legacy block as blocked by the peer, with pages of 100")
    func loadBlockStateListed() async {
        let log = Log()
        let row = ChatFixtures.thread(id: Self.threadId, partnerId: Self.partnerId, isBlocked: true, blockedByMe: false)
        let viewModel = makeViewModel(api: Self.makeAPI(onChats: Self.chatsJSON([row])), log: log)

        await viewModel.loadBlockState()

        #expect(viewModel.blockState == Self.blockedByPeer)
        #expect(log.states == [Self.blockedByPeer])
        let gets = Self.chatsGets()
        #expect(gets.count == 1)
        let limit = gets.first?.url
            .flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems }?
            .first { $0.name == "limit" }?.value
        #expect(limit == "100")
    }

    @Test("a thread the lookup does not list leaves the state alone and tells nobody")
    func loadBlockStateNotListed() async {
        let log = Log()
        let other = ChatFixtures.thread(id: UUID(), partnerId: UUID())
        let viewModel = makeViewModel(
            isBlocked: true,
            blockedByMe: true,
            api: Self.makeAPI(onChats: Self.chatsJSON([other])),
            log: log
        )

        await viewModel.loadBlockState()

        #expect(viewModel.blockState == Self.blockedByMe)
        #expect(log.states.isEmpty)
    }

    @Test("a lookup that fails leaves the state alone and tells nobody")
    func loadBlockStateFails() async {
        let log = Log()
        let api = Self.makeAPI(onChats: { _ in throw URLError(.timedOut) })
        let viewModel = makeViewModel(isBlocked: true, blockedByMe: true, api: api, log: log)

        await viewModel.loadBlockState()

        #expect(viewModel.blockState == Self.blockedByMe)
        #expect(log.states.isEmpty)
        #expect(viewModel.apiError == nil)
    }
}
