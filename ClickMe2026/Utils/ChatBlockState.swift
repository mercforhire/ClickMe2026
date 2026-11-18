//
//  ChatBlockState.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Block state of one chat thread. A port of Android `BlockState.kt`, following
/// `docs/ios/CHAT-UNBLOCK.md` §5 (UI matrix), §6 (local state after each outcome)
/// and §7 (legacy blocks), with decisions D-03, D-07 and D-08 of phase 07.
///
/// - Block 200: blocked by me. Unblock 200: not blocked.
/// - Unblock 403 `NOT_BLOCKER`: still blocked, but not by me. `blockedByMe` is then
///   false, which already hides Unblock, so unlike Android there is no separate latch.
/// - Send 403 `THREAD_BLOCKED`: blocked; who blocked stays as it was known.
/// - A legacy block (`isBlocked` with `blockedByMe` false) reads as blocked by the
///   peer, so no Unblock is offered (D-08).
/// - A `GET /chats` scan that does not list the thread must not mean "unblocked":
///   an empty thread is absent from that list, so the state is left alone unless
///   this session blocked the thread (CHAT-UNBLOCK §6).
struct ChatBlockState: Equatable {

    var isBlocked = false
    var blockedByMe = false

    // MARK: - Types

    /// The block flags a `GET /chats` scan found for one thread.
    struct ScannedBlock: Equatable {
        let isBlocked: Bool
        let blockedByMe: Bool

        init(isBlocked: Bool, blockedByMe: Bool) {
            self.isBlocked = isBlocked
            self.blockedByMe = blockedByMe
        }

        /// `ChatThreadItem` already decodes a missing `blocked_by_me` as false (D-08).
        init(thread: ChatThreadItem) {
            self.init(isBlocked: thread.isBlocked, blockedByMe: thread.blockedByMe)
        }
    }

    /// What the thread's composer slot shows.
    enum ComposerMode: Equatable {
        case normal
        case blockedByMe
        case blockedByPeer
        case unavailable
    }

    /// Which entry the thread menu offers next to Report.
    enum MenuEntry: Equatable {
        case blockOrReport
        case unblockOrReport
        case reportOnly
    }

    // MARK: - Transitions

    /// Applies a `GET /chats` scan. `found` is nil when the thread is not listed.
    /// A listed thread wins; an unlisted one is blocked by me only when this session
    /// blocked it, and otherwise keeps the state it had, so a miss never reads as
    /// unblocked.
    func applyScan(found: ScannedBlock?, sessionBlockedByMe: Bool) -> ChatBlockState {
        if let found {
            return ChatBlockState(isBlocked: found.isBlocked, blockedByMe: found.blockedByMe)
        }
        if sessionBlockedByMe {
            return ChatBlockState(isBlocked: true, blockedByMe: true)
        }
        return self
    }

    func onBlockSucceeded() -> ChatBlockState {
        ChatBlockState(isBlocked: true, blockedByMe: true)
    }

    func onUnblockSucceeded() -> ChatBlockState {
        ChatBlockState(isBlocked: false, blockedByMe: false)
    }

    /// Unblock was refused with 403 `NOT_BLOCKER`: blocked by the peer.
    func onNotBlocker() -> ChatBlockState {
        ChatBlockState(isBlocked: true, blockedByMe: false)
    }

    /// A send was refused with 403 `THREAD_BLOCKED`. Who blocked is not known from
    /// that answer, so `blockedByMe` is kept.
    func onThreadBlocked() -> ChatBlockState {
        ChatBlockState(isBlocked: true, blockedByMe: blockedByMe)
    }

    // MARK: - Derived

    /// Unblock is offered to the recorded blocker only (CHAT-03).
    var showsUnblock: Bool { isBlocked && blockedByMe }

    var menuEntry: MenuEntry {
        if !isBlocked { return .blockOrReport }
        return showsUnblock ? .unblockOrReport : .reportOnly
    }

    /// The composer mode the block flags imply on their own.
    var ownComposerMode: ComposerMode {
        if !isBlocked { return .normal }
        return blockedByMe ? .blockedByMe : .blockedByPeer
    }

    /// Blocked modes win (the server checks `THREAD_BLOCKED` before
    /// `RECIPIENT_UNAVAILABLE`), then an unavailable recipient, then normal.
    static func composerMode(block: ChatBlockState, recipientUnavailable: Bool) -> ComposerMode {
        if block.isBlocked { return block.ownComposerMode }
        return recipientUnavailable ? .unavailable : .normal
    }

    // MARK: - Copy

    static func bannerTitle(for mode: ComposerMode) -> String? {
        switch mode {
        case .normal: return nil
        case .blockedByMe: return "You blocked this conversation"
        case .blockedByPeer: return "You can't reply to this conversation"
        case .unavailable: return "This user is unavailable."
        }
    }

    static func bannerSymbol(for mode: ComposerMode) -> String? {
        switch mode {
        case .normal: return nil
        case .blockedByMe, .blockedByPeer: return "hand.raised.fill"
        case .unavailable: return "person.slash"
        }
    }

    static let notBlockerMessage = "Only the person who blocked this conversation can unblock it."
    static let connectionFallback = "Check your connection and try again."

    /// The text under "Couldn't unblock user". A transport error reads as a
    /// connection problem; `NOT_BLOCKER` has its own copy; anything else shows the
    /// server's message. Branches on `ErrorCode`, never on message text.
    static func actionErrorMessage(
        for error: Error,
        connectionFallback: String = ChatBlockState.connectionFallback
    ) -> String {
        if error is URLError { return connectionFallback }
        if BookingErrorMapper.code(for: error) == .notBlocker { return notBlockerMessage }
        return error.userMessage
    }

    // MARK: - Session

    /// The per-thread block bookkeeping the thread view model holds as one value, so
    /// the view model keeps no transition logic of its own (07-CONTEXT size rule).
    struct Session: Equatable {
        private(set) var block = ChatBlockState()
        private(set) var recipientUnavailable = false
        /// True once this screen session blocked the thread, so a scan that does not
        /// list the thread (an empty one) still reads as blocked by me.
        private(set) var sessionBlockedByMe = false
        /// True while an Unblock request runs, so one tap sequence sends one request.
        private(set) var isUnblocking = false
        /// Counts sends refused as blocked or unavailable; the view announces each one.
        private(set) var refusalCount = 0

        var composerMode: ComposerMode {
            ChatBlockState.composerMode(block: block, recipientUnavailable: recipientUnavailable)
        }

        mutating func applyScan(found: ScannedBlock?) {
            block = block.applyScan(found: found, sessionBlockedByMe: sessionBlockedByMe)
        }

        /// A send was refused with `code` (D-03). `THREAD_BLOCKED` marks the thread
        /// blocked; `RECIPIENT_UNAVAILABLE` marks the person unavailable for this
        /// session. Returns true for those two, so the caller shows the banner and
        /// rescans instead of showing an alert. The server checks `THREAD_BLOCKED`
        /// first, so blocked wins when both apply.
        mutating func applySendRefusal(_ code: ErrorCode?) -> Bool {
            switch code {
            case .threadBlocked:
                block = block.onThreadBlocked()
            case .recipientUnavailable:
                recipientUnavailable = true
            default:
                return false
            }
            refusalCount &+= 1
            return true
        }

        /// Takes the outcome of the Block & Report screen without a reload.
        mutating func adopt(_ state: ChatBlockState) {
            block = state
            sessionBlockedByMe = state.isBlocked && state.blockedByMe
        }

        /// Starts an Unblock request. False while one is already running (repeat taps).
        mutating func beginUnblock() -> Bool {
            guard !isUnblocking else { return false }
            isUnblocking = true
            return true
        }

        mutating func applyUnblockSucceeded() {
            block = block.onUnblockSucceeded()
            sessionBlockedByMe = false
            isUnblocking = false
        }

        /// Records a failed unblock and returns the text to show. `NOT_BLOCKER`
        /// moves the state to blocked by the peer; any other failure keeps it.
        mutating func applyUnblockFailure(_ error: Error) -> String {
            isUnblocking = false
            if BookingErrorMapper.code(for: error) == .notBlocker {
                block = block.onNotBlocker()
                sessionBlockedByMe = false
            }
            return ChatBlockState.actionErrorMessage(for: error)
        }
    }
}
