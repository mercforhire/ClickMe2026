//
//  ChatConversationsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ChatConversationsViewModel: ObservableObject {


    // MARK: View state
    @Published var searchText: String
    @Published var loadState: LoadState = .idle

    // MARK: Data
    @Published var chats: [ChatPreview]

    // MARK: Dependencies

    private let api: ClickMeAPI

    /// Test seam: the signed-in user's id, so a message the user sent
    /// never counts as unread (CHAT-07, D-13).
    private let currentUserId: () -> UUID?

    /// Test seam: the thread on screen right now, so a message for the
    /// open thread never counts as unread (CHAT-07, D-13).
    private let visibleThreadId: () -> UUID?

    // MARK: Reload bookkeeping

    /// `GET /chats` requests in flight. A response can predate local changes made
    /// while it travelled, so those changes are remembered until the last one ends.
    private var reloadsInFlight = 0

    /// Number of `fetchChats()` calls started so far. The latest call's number stamps
    /// every change recorded after it.
    private var fetchCounter = 0

    /// One local change to a row, with the number of the newest fetch that had started
    /// when it was made. Only a fetch started at or before that number may apply it.
    private struct LocalRowChange {
        let threadId: UUID
        let fetchNumber: Int
        var unreadCount: Int?
        var lastMessage: String?
        var timeLabel: String?
        var movedToTop = false
    }

    /// Row changes made by `markOpened` and live peer messages while a reload was in
    /// flight, oldest first. A response applies the ones made after its own request
    /// started over the server's row, so a late page never brings back a pill the user
    /// just cleared or an older preview. A request that started later may carry newer
    /// server values, so it does not take changes made before it (IN-10). A change can
    /// be recorded for a thread the list does not hold yet (the first load is running).
    private var changesDuringReload: [LocalRowChange] = []

    /// An unknown thread's message arrived while a load was running. That load's
    /// response may predate the message, so one more fetch runs when it ends. If that
    /// follow-up fails, the flag is set again and the next `load()` or `silentReload()`
    /// retries it once. Every fetch clears the flag when it starts, because it starts
    /// after the message, so a failed retry is the only way the flag survives.
    private var needsReloadAfterLoad = false

    // MARK: Realtime

    /// Held for the VM's lifetime; auto-cancel on deallocation.
    private var realtimeSubscriptions: [RealtimeSubscription] = []

    // MARK: Init

    /// Runtime init — starts empty, `.task { load() }` populates from
    /// `GET /chats`.
    init(
        searchText: String = "",
        chats: [ChatPreview] = [],
        api: ClickMeAPI = .shared,
        currentUserId: @escaping () -> UUID? = { UserManager.shared.me?.id ?? UserManager.shared.authUser?.id },
        visibleThreadId: @escaping () -> UUID? = { ChatPresence.shared.visibleThreadId }
    ) {
        self.searchText = searchText
        self.chats = chats
        self.api = api
        self.currentUserId = currentUserId
        self.visibleThreadId = visibleThreadId
        // Subscribe eagerly so events landing before the first fetch
        // completes aren't dropped; the handlers tolerate an empty
        // `chats` array.
        self.realtimeSubscriptions = [
            RealtimeService.shared.onMessageNew { [weak self] event in
                Task { @MainActor in self?.handleMessageNew(event) }
            },
            RealtimeService.shared.onUserStatus { [weak self] event in
                Task { @MainActor in self?.handleUserStatus(event) }
            }
        ]
    }

    /// Preview seam — installs canned data as if the fetch had succeeded.
    static func previewSeed(
        chats: [ChatPreview] = ChatPreview.samples
    ) -> ChatConversationsViewModel {
        let vm = ChatConversationsViewModel(chats: chats)
        vm.loadState = .loaded
        return vm
    }

    // MARK: Derived

    var filteredChats: [ChatPreview] {
        guard !searchText.isEmpty else { return chats }
        return chats.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.lastMessage.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: Actions

    func clearSearch() {
        searchText = ""
    }

    // MARK: - Load

    /// Fetches `GET /chats` and maps each thread to a `ChatPreview`.
    /// Idempotent — skips when already loaded so preview seeds aren't
    /// clobbered.
    ///
    func load() async {
        if case .loaded = loadState {
            // A failed follow-up (IN-08) left a thread missing: retry it once.
            if needsReloadAfterLoad { await silentReload() }
            return
        }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    /// Re-fetches `GET /chats` without flipping `loadState` to `.loading`
    /// — so the UI doesn't flash the full-screen spinner. Used when the
    /// user pops back from a chat and we want the row's last-message /
    /// unread-count to reflect their activity. Fetch failures leave the
    /// existing list intact. A failure also keeps a pending follow-up (see
    /// `needsReloadAfterLoad`) pending, so the next load retries it.
    func silentReload() async {
        guard case .loaded = loadState else {
            // Nothing meaningful to preserve yet — fall through to the
            // normal loader so a spinner shows.
            await forceLoad()
            return
        }
        let followUpOwed = needsReloadAfterLoad
        needsReloadAfterLoad = false
        do {
            chats = try await fetchChats()
        } catch {
            if followUpOwed { needsReloadAfterLoad = true }
        }
    }

    private func forceLoad() async {
        // This fetch starts after any message that set the flag earlier, so it covers it.
        needsReloadAfterLoad = false
        loadState = .loading
        do {
            chats = try await fetchChats()
            loadState = .loaded
        } catch {
            needsReloadAfterLoad = false
            loadState = .failed(error.userMessage)
            return
        }
        if needsReloadAfterLoad {
            await silentReload()
        }
    }

    /// One `GET /chats` page mapped to rows. Rows changed locally after the request
    /// started keep those changes (see `changesDuringReload`).
    private func fetchChats() async throws -> [ChatPreview] {
        reloadsInFlight += 1
        fetchCounter += 1
        let fetchNumber = fetchCounter
        defer {
            reloadsInFlight -= 1
            if reloadsInFlight == 0 {
                changesDuringReload.removeAll()
            }
        }
        let response = try await api.getChats(page: 1, limit: 50)
        let rows = response.data.threads.map(Self.mapThread(from:))
        return applyLocalChanges(to: rows, startedAt: fetchNumber)
    }

    /// Puts the changes made after the request started back over the server's rows:
    /// unread count, preview text and time label, then the rows a live message moved
    /// go first, newest first. Of several changes to one field the latest wins.
    ///
    /// - Parameter fetchNumber: The number `fetchChats()` took when it started. A change
    ///   stamped with a lower number was made before this request was sent, so the
    ///   response already accounts for it.
    private func applyLocalChanges(to rows: [ChatPreview], startedAt fetchNumber: Int) -> [ChatPreview] {
        let applicable = changesDuringReload.filter { $0.fetchNumber >= fetchNumber }
        guard !applicable.isEmpty else { return rows }
        let patched = rows.map { row -> ChatPreview in
            let mine = applicable.filter { $0.threadId == row.threadId }
            guard !mine.isEmpty else { return row }
            return ChatPreview(
                threadId: row.threadId,
                partnerId: row.partnerId,
                name: row.name,
                lastMessage: mine.last { $0.lastMessage != nil }?.lastMessage ?? row.lastMessage,
                timeLabel: mine.last { $0.timeLabel != nil }?.timeLabel ?? row.timeLabel,
                imageURL: row.imageURL,
                isOnline: row.isOnline,
                unreadCount: mine.last { $0.unreadCount != nil }?.unreadCount ?? row.unreadCount
            )
        }
        var movedIds: [UUID] = []
        for change in applicable.reversed() where change.movedToTop && !movedIds.contains(change.threadId) {
            movedIds.append(change.threadId)
        }
        let moved = movedIds.compactMap { id in patched.first { $0.threadId == id } }
        let rest = patched.filter { !movedIds.contains($0.threadId) }
        return moved + rest
    }

    /// Remembers a local unread count when a reload is in flight.
    private func noteLocalUnread(_ count: Int, threadId: UUID) {
        guard reloadsInFlight > 0 else { return }
        changesDuringReload.append(LocalRowChange(threadId: threadId, fetchNumber: fetchCounter, unreadCount: count))
    }

    /// Remembers a live message's effect on its row when a reload is in flight.
    ///
    /// - Parameters:
    ///   - hasContent: Whether the event carried text. Without it the row's preview is
    ///     just the old one, so recording it would override a newer preview from the
    ///     server (WR-07).
    private func noteLocalActivity(_ row: ChatPreview, hasContent: Bool) {
        guard reloadsInFlight > 0 else { return }
        changesDuringReload.append(
            LocalRowChange(
                threadId: row.threadId,
                fetchNumber: fetchCounter,
                unreadCount: row.unreadCount,
                lastMessage: hasContent ? row.lastMessage : nil,
                timeLabel: row.timeLabel,
                movedToTop: true
            )
        )
    }

    // MARK: - Realtime

    /// Patches the matching thread's row for a live-arrived message: swap
    /// `lastMessage`, refresh `timeLabel`, and move the row to the top so the
    /// list stays sorted by most-recent activity.
    ///
    /// Unread count (CHAT-07, D-13): the server's `unread_count` is the
    /// authority and every `GET /chats` replaces the local value. Between
    /// fetches the row adds 1 only for a message from someone other than the
    /// signed-in user on a thread that is not on screen. A message for the
    /// open thread, or one the user sent, leaves the count as it was.
    func handleMessageNew(_ event: RealtimeMessageNewEvent) {
        guard let idx = chats.firstIndex(where: { $0.threadId == event.threadId }) else {
            // Unknown thread — probably a first-message-from-new-peer
            // scenario. Trigger a full silent refresh to pick up the
            // brand-new row without flashing a spinner. While a load is
            // running (first load or pull-to-refresh) its response may predate
            // the message, so remember it and fetch once more when the load
            // ends. With no load running (idle, failed) the next load fetches
            // the message anyway.
            guard case .loaded = loadState else {
                if case .loading = loadState { needsReloadAfterLoad = true }
                return
            }
            Task { await silentReload() }
            return
        }
        let existing = chats[idx]
        let isPeerMessageOnClosedThread = event.threadId != visibleThreadId()
            && event.senderId != currentUserId()
        let updated = ChatPreview(
            threadId: existing.threadId,
            partnerId: existing.partnerId,
            name: existing.name,
            lastMessage: event.content ?? existing.lastMessage,
            timeLabel: Self.relativeTimeLabel(from: event.timestamp),
            imageURL: existing.imageURL,
            isOnline: existing.isOnline,
            unreadCount: isPeerMessageOnClosedThread
                ? ChatUnreadRules.afterPeerMessage(count: existing.unreadCount)
                : existing.unreadCount
        )
        chats.remove(at: idx)
        chats.insert(updated, at: 0)
        noteLocalActivity(updated, hasContent: event.content != nil)
    }

    /// The thread for `threadId` just became the visible thread, from any
    /// route: set its row's count to 0 locally with no request (CHAT-07,
    /// D-12). The next quiet `GET /chats` re-syncs with the server.
    ///
    /// A reload in flight remembers the open even when the row is not listed yet
    /// (the first load is running), so its response does not bring the pill back.
    func markOpened(threadId: UUID) {
        noteLocalUnread(ChatUnreadRules.afterOpen, threadId: threadId)
        guard let idx = chats.firstIndex(where: { $0.threadId == threadId }) else { return }
        chats[idx].unreadCount = ChatUnreadRules.afterOpen
    }

    /// A conversation partner's presence changed. Flip the matching row's
    /// online dot in place — we don't need a full refetch for this.
    private func handleUserStatus(_ event: RealtimeUserStatusEvent) {
        guard let idx = chats.firstIndex(where: { $0.partnerId == event.userId }) else { return }
        let existing = chats[idx]
        chats[idx] = ChatPreview(
            threadId: existing.threadId,
            partnerId: existing.partnerId,
            name: existing.name,
            lastMessage: existing.lastMessage,
            timeLabel: existing.timeLabel,
            imageURL: existing.imageURL,
            isOnline: event.status == .online,
            unreadCount: existing.unreadCount
        )
    }

    // MARK: - Mapping

    private static func mapThread(from item: ChatThreadItem) -> ChatPreview {
        ChatPreview(
            threadId: item.threadId,
            partnerId: item.partner.id,
            name: item.partner.name ?? "Chat",
            lastMessage: item.lastMessage ?? "",
            timeLabel: relativeTimeLabel(from: item.lastMsgAt),
            imageURL: item.partner.avatarUrl ?? "",
            isOnline: item.isOnline,
            unreadCount: item.unreadCount
        )
    }

    /// `"10:23 AM"` for today, `"Yesterday"` for yesterday, otherwise
    /// `"MMM d"`. Empty string when nil.
    private static func relativeTimeLabel(from date: Date?) -> String {
        guard let date else { return "" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return f.string(from: date)
        }
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    // MARK: - Error mapping

}
