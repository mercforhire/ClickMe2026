//
//  ChatBlockStateTests.swift
//  ClickMe2026Tests
//
//  CHAT-03 (D-03, D-07, D-08): the pure block bookkeeping of a chat thread, a port of
//  Android `BlockStateTest` without its unblock latch. After a NOT_BLOCKER answer
//  `blockedByMe` is false, which already hides Unblock. Also covers the banner copy,
//  the error copy and the per-thread Session the view model holds.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("ChatBlockState")
@MainActor
struct ChatBlockStateTests {

    private typealias State = ChatBlockState
    private typealias Scanned = ChatBlockState.ScannedBlock

    private func httpError(status: Int = 403, code: String?, message: String = "m") -> NetworkError {
        let codePart = code.map { #""code":"\#($0)","# } ?? ""
        let body = #"{"status":"error",\#(codePart)"message":"\#(message)"}"#
        return .httpError(statusCode: status, data: Data(body.utf8))
    }

    private func blocked(byMe: Bool) -> State {
        State(isBlocked: true, blockedByMe: byMe)
    }

    // MARK: Transitions

    @Test("a block that succeeded means blocked by me")
    func blockSucceededMeansBlockedByMe() {
        #expect(State().onBlockSucceeded() == blocked(byMe: true))
    }

    @Test("an unblock that succeeded clears the block")
    func unblockSucceededClearsTheBlock() {
        #expect(blocked(byMe: true).onUnblockSucceeded() == State())
    }

    @Test("NOT_BLOCKER leaves the thread blocked, not by me, and hides Unblock")
    func notBlockerHidesUnblock() {
        let state = blocked(byMe: true).onNotBlocker()
        #expect(state == blocked(byMe: false))
        #expect(!state.showsUnblock)
    }

    @Test("THREAD_BLOCKED blocks the thread and keeps who blocked as known")
    func threadBlockedKeepsBlockedByMe() {
        #expect(State().onThreadBlocked() == blocked(byMe: false))
        #expect(State(isBlocked: false, blockedByMe: true).onThreadBlocked() == blocked(byMe: true))
    }

    // MARK: Scan

    @Test("a scan that does not list the thread leaves the state alone")
    func scanMissLeavesTheState() {
        #expect(State().applyScan(found: nil, sessionBlockedByMe: false) == State())
        #expect(blocked(byMe: false).applyScan(found: nil, sessionBlockedByMe: false) == blocked(byMe: false))
    }

    @Test("a scan miss after this session blocked the thread reads as blocked by me")
    func scanMissAfterSessionBlock() {
        #expect(State().applyScan(found: nil, sessionBlockedByMe: true) == blocked(byMe: true))
    }

    @Test("a scan that lists the thread takes both flags")
    func scanTakesBothFlags() {
        let state = State().applyScan(found: Scanned(isBlocked: true, blockedByMe: true), sessionBlockedByMe: false)
        #expect(state == blocked(byMe: true))
        #expect(state.showsUnblock)
    }

    @Test("a scan that lists the thread unblocked clears an earlier block")
    func scanUnblockedClears() {
        let state = blocked(byMe: false)
            .applyScan(found: Scanned(isBlocked: false, blockedByMe: false), sessionBlockedByMe: false)
        #expect(state == State())
    }

    @Test("a scan that lists a block by someone else wins over a session block")
    func scanFoundWinsOverSessionBlock() {
        let state = blocked(byMe: true)
            .applyScan(found: Scanned(isBlocked: true, blockedByMe: false), sessionBlockedByMe: true)
        #expect(state == blocked(byMe: false))
        #expect(!state.showsUnblock)
    }

    @Test("a thread row with no blocked_by_me key scans as not blocked by me")
    func scannedBlockFromThreadWithMissingKey() throws {
        let row = ChatFixtures.thread(id: UUID(), partnerId: UUID(), isBlocked: true, blockedByMe: nil)
        let data = ChatFixtures.threadsPage([row])
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let page = try decoder.decode(SuccessDataResponse<ChatsPayload>.self, from: data)
        let thread = try #require(page.data.threads.first)

        #expect(Scanned(thread: thread) == Scanned(isBlocked: true, blockedByMe: false))
    }

    // MARK: Menu and composer

    @Test("not blocked offers Block or Report and the normal composer")
    func notBlockedMenuAndComposer() {
        let state = State()
        #expect(state.menuEntry == .blockOrReport)
        #expect(!state.showsUnblock)
        #expect(State.composerMode(block: state, recipientUnavailable: false) == .normal)
    }

    @Test("blocked by me offers Unblock or Report")
    func blockedByMeMenuAndComposer() {
        let state = State().onBlockSucceeded()
        #expect(state.menuEntry == .unblockOrReport)
        #expect(State.composerMode(block: state, recipientUnavailable: false) == .blockedByMe)
    }

    @Test("a legacy block reads as blocked by the peer and offers Report only")
    func legacyBlockMenuAndComposer() {
        let state = State().applyScan(found: Scanned(isBlocked: true, blockedByMe: false), sessionBlockedByMe: false)
        #expect(state.menuEntry == .reportOnly)
        #expect(!state.showsUnblock)
        #expect(State.composerMode(block: state, recipientUnavailable: false) == .blockedByPeer)
    }

    @Test("a thread blocked by me and then refused with NOT_BLOCKER offers Report only")
    func notBlockerMenuIsReportOnly() {
        #expect(State().onBlockSucceeded().onNotBlocker().menuEntry == .reportOnly)
    }

    @Test("unavailable beats normal but a block beats unavailable")
    func blockedBeatsUnavailable() {
        #expect(State.composerMode(block: State(), recipientUnavailable: true) == .unavailable)
        #expect(State.composerMode(block: State().onBlockSucceeded(), recipientUnavailable: true) == .blockedByMe)
        #expect(State.composerMode(block: blocked(byMe: false), recipientUnavailable: true) == .blockedByPeer)
    }

    // MARK: Copy

    @Test("banner titles and symbols for all four modes")
    func bannerCopy() {
        #expect(State.bannerTitle(for: .normal) == nil)
        #expect(State.bannerTitle(for: .blockedByMe) == "You blocked this conversation")
        #expect(State.bannerTitle(for: .blockedByPeer) == "You can't reply to this conversation")
        #expect(State.bannerTitle(for: .unavailable) == "This user is unavailable.")
        #expect(State.bannerSymbol(for: .normal) == nil)
        #expect(State.bannerSymbol(for: .blockedByMe) == "hand.raised.fill")
        #expect(State.bannerSymbol(for: .blockedByPeer) == "hand.raised.fill")
        #expect(State.bannerSymbol(for: .unavailable) == "person.slash")
    }

    @Test("a transport error reads as a connection problem")
    func transportErrorCopy() {
        #expect(State.actionErrorMessage(for: URLError(.notConnectedToInternet)) == "Check your connection and try again.")
    }

    @Test("NOT_BLOCKER has its own copy")
    func notBlockerCopy() {
        let message = State.actionErrorMessage(for: httpError(code: "NOT_BLOCKER", message: "Nope"))
        #expect(message == "Only the person who blocked this conversation can unblock it.")
    }

    @Test("any other server error shows the server's message")
    func serverErrorCopy() {
        #expect(State.actionErrorMessage(for: httpError(status: 500, code: "INTERNAL_ERROR", message: "Server broke")) == "Server broke")
    }

    // MARK: Session

    @Test("THREAD_BLOCKED on a send marks the thread blocked with the blocker unknown")
    func sessionThreadBlockedRefusal() {
        var session = State.Session()

        let handled = session.applySendRefusal(.threadBlocked)

        #expect(handled)
        #expect(session.composerMode == .blockedByPeer)
    }

    @Test("RECIPIENT_UNAVAILABLE on a send marks the person unavailable")
    func sessionRecipientUnavailableRefusal() {
        var session = State.Session()

        let handled = session.applySendRefusal(.recipientUnavailable)

        #expect(handled)
        #expect(session.composerMode == .unavailable)
    }

    @Test("another code or none changes nothing and is not handled")
    func sessionOtherRefusal() {
        var session = State.Session()
        let before = session

        let handledNone = session.applySendRefusal(nil)
        let handledValidation = session.applySendRefusal(.validationError)

        #expect(!handledNone)
        #expect(!handledValidation)
        #expect(session == before)
        #expect(session.composerMode == .normal)
    }

    @Test("a block adopted from the Block & Report screen survives a scan that does not list the thread")
    func sessionAdoptThenScanMiss() {
        var session = State.Session()
        session.adopt(State().onBlockSucceeded())

        session.applyScan(found: nil)

        #expect(session.composerMode == .blockedByMe)
    }

    @Test("a NOT_BLOCKER answer to Unblock moves to blocked by the peer and returns the not-blocker copy")
    func sessionUnblockNotBlocker() {
        var session = State.Session()
        session.adopt(blocked(byMe: true))

        let message = session.applyUnblockFailure(httpError(code: "NOT_BLOCKER"))

        #expect(session.composerMode == .blockedByPeer)
        #expect(message == "Only the person who blocked this conversation can unblock it.")
        session.applyScan(found: nil)
        #expect(session.composerMode == .blockedByPeer)
    }

    @Test("a transport failure on Unblock keeps the state and returns the connection copy")
    func sessionUnblockTransportFailure() {
        var session = State.Session()
        session.adopt(blocked(byMe: true))

        let message = session.applyUnblockFailure(URLError(.notConnectedToInternet))

        #expect(session.composerMode == .blockedByMe)
        #expect(message == "Check your connection and try again.")
    }

    @Test("an unblock that succeeded gives the normal composer and forgets the session block")
    func sessionUnblockSucceeded() {
        var session = State.Session()
        session.adopt(blocked(byMe: true))

        session.applyUnblockSucceeded()
        session.applyScan(found: nil)

        #expect(session.composerMode == .normal)
    }
}
