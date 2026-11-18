# Phase 7: Chat - Pattern Map

**Mapped:** 2026-11-17
**Files analyzed:** 25 (13 new, 12 modified)
**Analogs found:** 25 / 25 (4 are cross-repo Android ports)
**Revised:** 2026-11-17 at plan-check iteration 2: rows added for `ChatSendCoordinator`, `ChatItemMapper`, `ChatThreadLookup` and `ExpertProfileBlockViewModel`; the `handleMessageRead` mapping removed (D-17); the view-model size rule given a ceiling.

All iOS analog paths are under `/Users/LeonChen/Documents/ClickMe2026/` and git-tracked. Android analogs are under `/Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/chat/` (abbreviated `$A`) and are tracked source in that repo.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `ClickMe2026/Utils/ChatThreadReducer.swift` (new) | utility (pure) | transform | `$A/chatting/ThreadReducer.kt` | exact (port) |
| `ClickMe2026/Utils/ChatBlockState.swift` (new) | utility (pure) | transform | `$A/BlockState.kt` | exact (port) |
| `ClickMe2026/Utils/ChatComposerRules.swift` (new) | utility (pure) | transform | `ExpertBookingNoteViewModel.swift:85-105` | exact |
| `ClickMe2026/Utils/ChatUnreadRules.swift` (new) | utility (pure) | transform | `Utils/BookingErrorMapper.swift` (caseless enum of static funcs) | role-match |
| `ClickMe2026/Utils/ChatBookingRowRoute.swift` (new) | utility (pure) | request-response | `Utils/BookingErrorMapper.swift` + `HomeNavigationPath.swift:85,117` | role-match |
| `Views/Screens/Chat/Chatting/ChatSendCoordinator.swift` (new) | sibling type of the view model | request-response | `Client Mode/Booking Summary/RescheduleResponder.swift` (logic lifted out of a VM) + `$A/chatting/ChatThreadViewModel.kt` `deliver` (L226-299) | role-match |
| `ClickMe2026/Utils/ChatItemMapper.swift` (new) | utility (pure) | transform | `ChattingViewModel.swift` L475-620 (moved, not rewritten) | self (moved) |
| `ClickMe2026/Utils/ChatThreadLookup.swift` (new) | utility (read helper) | request-response | `Report and Block/ReportChatViewModel.swift` `loadBlockState()` L94-105 (the one-page `GET /chats` scan) + `$A/ChatsRepository.kt` `SCAN_LIMIT = 100` | role-match |
| `Client Mode/Expert Profile/ExpertProfileBlockViewModel.swift` (new) | view model | request-response | `Expert Mode/Booking Note/ExpertBookingNoteViewModel.swift` (injected `api`, `apiError`) + `RescheduleResponder.swift` L76-85 (`toasts: ToastCenter = .shared`) | role-match |
| `Model/UIModels/ChatDisplayModels.swift` (mod) | model | transform | itself (lines 35-57) | self |
| `Model/Responses/Children/ChatThreadItem.swift` (mod) | model | request-response | same file, CHAT-UNBLOCK §9 decode default | self |
| `Managers/ChatPresence.swift` (mod) | manager | event-driven | `Managers/ToastCenter.swift` (`@Observable`) | role-match |
| `Views/Screens/Chat/Chatting/ChattingViewModel.swift` (mod) | view model | CRUD + event-driven | itself, plus Android `ChatThreadViewModel.kt` | self |
| `Views/Screens/Chat/Chatting/ChattingView.swift` (mod) | view | request-response | itself (lines 80-130, 330-345) | self |
| `Chatting/Subviews/ChattingMessageBubble.swift` (mod) | view | transform | itself; Android `ThreadRows.kt` | self |
| `Chatting/Subviews/ChattingInputBar.swift` (mod) | view | request-response | itself | self |
| `Chatting/Subviews/ChattingBlockedBanner.swift` (new) | view | request-response | `Report and Block/Subviews/ReportChatBlockCard.swift` | role-match |
| `Chat/Conversations/ChatConversationsViewModel.swift` (mod) | view model | event-driven | itself (lines 120-175) | self |
| `Chat/Conversations/Subviews/ChatConversationRow.swift` (mod) | view | transform | itself; Android `ConversationRow.kt` `UnreadBadge` | self |
| `Chat/Conversations/ChatConversationsView.swift` (mod) | view | event-driven | itself (lines 70-74 `pushedChat`) | self |
| `Report and Block/ReportChatViewModel.swift` (mod) | view model | CRUD | itself (loadBlockState, submitReport) | self |
| `Report and Block/ReportChatView.swift` (mod) | view | request-response | itself (init lines 35-44) | self |
| `Report and Block/Subviews/ReportChatBlockCard.swift` (mod) | view | transform | itself | self |
| `Client Mode/Expert Profile/ExpertProfileView.swift` (mod) | view | request-response | itself (`handleOpenBlockFlow`) + `ToastCenter` | self |
| `ClickMe2026Tests/Chat/*` (new folder) | test | transform / request-response | `ExpertMode/ExpertBookingNoteViewModelTests.swift`, `Utils/BookingErrorMapperTests.swift`, `Push/PushForegroundPolicyTests.swift` | exact |

## Pattern Assignments

### `Utils/ChatThreadReducer.swift` (utility, transform)

**Analog:** `$A/chatting/ThreadReducer.kt` (read in full). Port as `nonisolated enum ChatThreadReducer` of static funcs over `[ChatItem]` (project style: caseless enum namespace; header block; `UTF16Prefix.swift:15` shows `nonisolated enum` form).

Rules to copy, by function:
- `appendLocal` = `order(items + message)`.
- `ack(clientMsgId, serverId, timestamp)`: find own bubble by `clientMsgId`. If another row already has `serverId` (reload won the race), drop the bubble and keep that row (`clientMsgId = existing ?? bubble`). Otherwise mutate the bubble in place (keep `id`), set `serverId`, `timestamp`, `sendState = .sent`, keep `.read`.
- `mergePage`: for each incoming row, `indexOfMatch` = server id first, then (own messages only) `clientMsgId`; no match appends, match runs `reconcile` (incoming wins; `clientMsgId = existing ?? incoming`; `.read` never regresses). Always `order()`.
- `fail`/`retry` = `updateLocal(from:to:)` restricted to own, `serverId == nil`, state == `from`.
- `remove` never deletes a row with a `serverId`.
- `onIncoming`: ignore if `senderId == myId` or the server id already exists.
- `markRead(ids)`: not ported. D-17 closed CHAT-08 as not reproducible with no code change, so the shipped `ChattingViewModel.handleMessageRead(_:)` keeps that job and is left byte-for-byte as it is (it already updates own bubbles in place, which keeps their `id` under the new model).
- `unreadPeerIds(alreadyEmitted)`: peer, has `serverId`, not `.read`, not already emitted.
- `order`: server-backed rows stable-sorted by `createdAt`, then local unsent rows in current order.
- Compare ids case-insensitively. In Swift `UUID` equality already is, but `clientMsgId` is a `String`, so use `caseInsensitiveCompare`.

Android's `ThreadItem` has `Message` only for these paths. iOS `ChatItem` also has `.timestamp` and `.systemEvent`. Only `.message` cases are matched/replaced. Day separators and system events must pass through `order` unchanged. The planner must decide how `.timestamp` rows are produced; check how `ChattingViewModel` inserts them before wiring (see the mapping code from `ChattingViewModel.swift:475`, which plan 07-01 moves to `ChatItemMapper`).

**Model dependency (RESEARCH Pattern 1).** `ChatDisplayModels.swift:35-57` has `let id = UUID()` (not in memberwise init) and `let timestamp: Date`. Required change:

```swift
struct ChatMessage: Identifiable {
    var id = UUID()                 // was `let id = UUID()`; preserved by in-place copy
    var serverId: UUID?
    let sender: MessageSender
    let senderName: String
    let body: String
    let avatarURL: String
    var timestamp: Date             // was `let`; ack supplies server time
    var status: MessageStatus
    var clientMsgId: String?        // NEW
    var sendState: ChatSendState = .sent   // NEW: .sent | .sending | .failed, local only
}
```

Ack/fail/retry mutate `items[i]` in place. Never route an ack through `mapToChatItem` (mints a new `id`).

---

### `Utils/ChatBlockState.swift` (utility, transform)

**Analog:** `$A/BlockState.kt` (read in full). Port as `nonisolated struct ChatBlockState: Equatable`.

Copy: `ScannedBlock`, `ComposerMode {normal, blockedByMe, blockedByPeer, unavailable}`, `ThreadMenuEntry {blockOrReport, unblockOrReport, reportOnly}`, and transitions `applyScan(found:sessionBlockedByMe:)`, `onBlockSucceeded` (blocked+mine), `onUnblockSucceeded` (clear), `onNotBlocker` (blocked, not mine), `onThreadBlocked` (`isBlocked = true`, keep `blockedByMe`).

```kotlin
// BlockState.kt: applyScan
found != null -> BlockState(isBlocked = found.isBlocked, blockedByMe = found.blockedByMe, ...)
sessionBlockedByMe -> BlockState(isBlocked = true, blockedByMe = true)
else -> this           // thread not listed is never read as "unblocked"
// composerMode: blocked wins over unavailable
block.isBlocked -> block.ownComposerMode ; recipientUnavailable -> Unavailable ; else Normal
```

**Deliberate divergence:** drop Android's `unblockDenied` latch (RESEARCH Pattern 2). After `NOT_BLOCKER` the state is `blockedByMe = false`, so `showsUnblock = isBlocked && blockedByMe` already hides Unblock. Delete `unblockDenied` from `ReportChatViewModel` and `ReportChatBlockCard` too.

**iOS addition (size rule):** a nested `ChatBlockState.Session` value holds what the thread view model would otherwise track by hand: the current `block`, `recipientUnavailable`, `sessionBlockedByMe`, `composerMode`, and the mutating `applyScan(found:)`, `applySendRefusal(_:) -> Bool`, `adopt(_:)`, `applyUnblockSucceeded()`, `applyUnblockFailure(_:) -> String`. The VM stores one `Session` and calls it.

---

### `Utils/ChatComposerRules.swift` (utility, transform)

**Analog:** `ClickMe2026/Views/Screens/Expert Mode/Booking Note/ExpertBookingNoteViewModel.swift:85-105`

```swift
static let noteLimit = 5000
static let counterFrom = 4500
func updateNote(_ raw: String) { noteText = UTF16Prefix.prefix(raw, limit: Self.noteLimit) }
var noteLength: Int { noteText.utf16.count }
var showsCounter: Bool { noteLength >= Self.counterFrom }
static func counterText(length: Int, locale: Locale = .current) -> String {
    "\(length.formatted(.number.locale(locale))) / \(noteLimit.formatted(.number.locale(locale)))"
}
```

Adapt: `limit = 10_000`, `counterFrom = 9_000`, static `cap(_:)` calling `UTF16Prefix.prefix` (`Utils/UTF16Prefix.swift:20-33`). Add `isAtLimit(length:)` for the red counter and the one-time announcement. Counter is `{n} / 10,000`.

---

### `Utils/ChatUnreadRules.swift` (utility, transform)

**Analog:** `Utils/BookingErrorMapper.swift` (caseless `enum` of `static` funcs, doc comments citing the contract; lines 10-20). Android reference: `$A/conversations/…ConversationRow.kt` `UnreadBadge` (cap 99).

Functions: `badgeLabel(_ count: Int) -> String?` (nil at 0, `"99+"` above 99), `accessibilityLabel(count:)` (`1 unread message`, `More than 99 unread messages`), `afterPeerMessage(count:)` (+1), `afterOpen` (0).

---

### `Utils/ChatBookingRowRoute.swift` (utility, request-response) [D-18]

**Analog:** `Views/Extensions/HomeNavigationPath.swift:85` (`@Entry var hostsClientBookingFlows: Bool = true`) and `:117` (`case expertBookingSummary(bookingId: UUID)`); `HomeExpertView.swift:262` sets the flag false, `:325` renders `.expertBookingSummary`. Current route code to replace, `ChattingView.swift:~336-345`:

```swift
if event.isTerminal { navPath.push(HomeRoute.bookingSummary(bookingId: bookingId)) }
else { navPath.push(HomeRoute.upcomingBooking(bookingId: bookingId)) }
```

Pure `route(isTerminal:bookingId:hostsClientBookingFlows:) -> HomeRoute`. Expert shell returns `.expertBookingSummary`. The client shell renders that case as `EmptyView`, so it keeps the two client routes. First task of its plan is the device repro gate (D-18).

---

### `Model/Responses/Children/ChatThreadItem.swift` (model, decode)

**Self.** Today (line ~44): `let blockedByMe: Bool?`. D-08: make it non-optional with a custom decode. Both existing call sites coalesce (`thread.blockedByMe ?? false` in `ReportChatViewModel.loadBlockState`), so update them.

```swift
// Pattern for a defaulting Decodable (per CHAT-UNBLOCK §9); keep convertFromSnakeCase key names
init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    ...
    blockedByMe = try c.decodeIfPresent(Bool.self, forKey: .blockedByMe) ?? false
}
```

No test constructs this type through its memberwise init, so the change is local (RESEARCH).

---

### `Managers/ChatPresence.swift` (manager, event-driven)

**Analog:** `Managers/ToastCenter.swift` (`@MainActor @Observable`, `static let shared`). Current file (lines 10-54) is a plain `@MainActor final class` with `private(set) var visibleThreadId: UUID?`; the doc comment says "not observable UI state", which must be rewritten. Add `@Observable`. Keep API unchanged: `chatAppeared(threadId:)`, `chatDisappeared(threadId:)`, `clearSessionData()`, `visibleThreadId`. `PushForegroundPolicyTests` drive the shared instance (A2: run that suite).

---

### `ChattingViewModel.swift` (view model, send/retry/event wiring)

**Analog:** itself. Current spots to change:

- `sendMessage()` lines 254-320. Wait-for-ack with `isSending` gate and `sendError`. `clientMsgId = UUID().uuidString` at line 275 is the seed. Replace with: append pending (`appendLocal`), clear composer, `scrollToBottomToken &+= 1`, then hand the POST to `ChatSendCoordinator` (see its section below), which calls the same `api.sendChatMessage(id:type:content:clientMsgId:)` (`Network/ClickMeAPI+Chats.swift:46`) and reports an `Outcome` back to the view model. The outcome switch the coordinator's classification encodes (RESEARCH "Code Examples"):

```swift
switch BookingErrorMapper.code(for: error) {
case .threadBlocked?, .recipientUnavailable?: // remove bubble, restore text, rescan, banner
default:
    if case let NetworkError.httpError(status, _) = error, status < 500 { /* remove, restore, sendError alert */ }
    else { /* ChatThreadReducer.fail */ }
}
```
  Typing-stop emit after success (lines 311-316) stays. Retry reuses the bubble's stored `clientMsgId`.
- `forceLoad()` line 179 `items = response.data.messages.map(mapToChatItem(_:))` becomes `ChatThreadReducer.mergePage`. Also add the `GET /chats` scan (`api.getChats(page:limit: 100)`, bounded to 3 pages) for peer id and block state.
- `hydratePeerUserIdIfNeeded` (216-226): keep as fallback; seed first from scan `partner.id` (D-10).
- `loadEarlier` 242-243 `items.insert(contentsOf: older, at: 0)` becomes `mergePage`; then emit reads (D-16).
- `handleMessageNew` 350-381 becomes `onIncoming`. Keep the `event.threadId == threadId` and `senderId == myUserId` guards and the `peerUserId == nil` latch (line 373).
- `handleMessageRead` 386-398 is unchanged (D-17: CHAT-08 closed as not reproducible, no code change). Do not route it through the reducer, rename it or change its access level; plans 07-01 and 07-08 guard that it stays byte-identical to the phase base 16fe88e.
- `emitReadForVisiblePeerMessages` 462-473 becomes `unreadPeerIds(alreadyEmitted:)` plus an `emittedReadIds` set; also call after each page and after `message.new`. Optional connected-flag replay (RESEARCH Open Q1; planner decision).
- `mapToChatItem` (line 477+) and the whole `// MARK: - Mapping` section move to `ChatItemMapper` (see its section); the mapper maps `item.clientMsgId` through (already decoded on `ChatMessageItem.clientMsgId`) and gives event rows their server id and created time. The view model keeps a one-line `mapToChatItem` forwarder.

**Error branching** (copy, `Utils/BookingErrorMapper.swift:30-35`):

```swift
static func code(for error: Error) -> ErrorCode? {
    guard case let NetworkError.httpError(_, data) = error,
          let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
    else { return nil }
    return response.code
}
```
`ErrorCode` already has `.threadBlocked`, `.notBlocker`, `.recipientUnavailable`, `.tooManyRequests` (`Model/Enums/ErrorCode.swift:83,87,179,185`).

Size rule (07-CONTEXT code_context; CLAUDE.md Function Design): the VM is 624 lines at the phase base and must not grow past that; plans 07-01 to 07-04 and the 07-08 gate check `wc -l` at or under 624. List logic goes in `ChatThreadReducer`, sends in flight in `ChatSendCoordinator`, row mapping in `ChatItemMapper`, the thread scan in `ChatThreadLookup`, block bookkeeping in `ChatBlockState.Session`; the VM only wires.

---

### `Chatting/ChatSendCoordinator.swift` (sibling type, request-response)

**Analog:** `Client Mode/Booking Summary/RescheduleResponder.swift` (a `@MainActor final class` lifted out of a view model so the money path lives once; header docs explain why it is separate). Android: `$A/chatting/ChatThreadViewModel.kt` `deliver` / `handleSendFailure` (L226-299).

Plain `final class` at the module default isolation (no view state, so not observable). Owns `inFlight: [String: Task<Void, Never>]` keyed by `client_msg_id`, the POST, and the classification through `ChatThreadReducer.sendFailure(for:)` into `Outcome { acked, keptAsFailed, refused(code:message:) }`. `send(...)` ignores an id already in flight. The VM passes an `onOutcome` closure that holds it weakly and applies the reducer. `nonisolated static func restoredText(refused:draft:)` is the Android `restoreToComposer` join; plan 07-02 passes it through `ChatComposerRules.cap`. No logging, no persistence, no `try?`.

### `Utils/ChatItemMapper.swift` (utility, transform)

**Analog:** itself: `ChattingViewModel.swift` L475-620 moved as is (event builder, `isTerminal`, `extract*` helpers, the two existing ISO 8601 formatters; no new formatter). The VM's identity fields arrive as an `Identity` value. New in the move: `clientMsgId` on messages, `serverId` / `createdAt` on booking events (so `mergePage` can dedupe them).

### `Utils/ChatThreadLookup.swift` (read helper, request-response)

**Analog:** `Report and Block/ReportChatViewModel.swift` `loadBlockState()` L94-105 (one page of `getChats(page: 1, limit: 50)`, coalesced flag). Generalise to `find(threadId:api:maxPages:)` over `limit: 100` (backend `Math.min(100, …)`; Android `$A/ChatsRepository.kt` `SCAN_LIMIT = 100`), stopping on an empty page, missing pagination, the last page or 3 pages; errors propagate so callers can tell "not listed" from "failed" (CHAT-UNBLOCK §6).

---

### `ChattingView.swift` (view)

**Analog:** itself.
- Composer swap: `content` switch (lines ~119-130) calls `inputBar` in every state; replace by `composerMode` branch that renders `ChattingBlockedBanner` instead of `ChattingInputBar` (D-07). Hide the "Send a message" capsule in `ChattingEmptyState(onSendMessage:)` when no composer is shown (RESEARCH Pitfall 8).
- Menu (lines ~80-84): entries by `ChatBlockState.menuEntry`: `Block or Report` (destructive), `Unblock or Report`, `Report`. Current: `Button("Block or Report", role: .destructive) { showingBlockReport = true }`.
- `ReportChatView(...)` at lines 85-95 passes `onBlock`/`onUnblock` that only close; add `onBlockStateChange: (ChatBlockState) -> Void`, seed `initialIsBlocked`/`initialBlockedByMe`.
- `.alert("Couldn't send message", ...)` driven by `viewModel.sendError` stays, now only for other 4xx.
- `openBookingDetail(for:)` (lines ~336-345) uses `ChatBookingRowRoute`.
- Keep the three nav-bar pins (UI-SPEC "Nav-bar pins").

---

### `Chatting/Subviews/ChattingBlockedBanner.swift` (view, new)

**Analog:** `Report and Block/Subviews/ReportChatBlockCard.swift` (capsule button, `PressScaleButtonStyle`, `isWorking` disable) and `ChattingInputBar.swift` (slot, 1pt top hairline `Color.white.opacity(0.06)`, `ChattingBrand.navBg`).

```swift
// ReportChatBlockCard.swift:50-65: capsule button to copy (swap red for Brand.primary label/stroke per A7)
Button(action: isBlocked ? onUnblockTap : onBlockTap) {
    Text(buttonText)
        .font(.brand(.subheadline, weight: .bold))
        .foregroundColor(ReportChatBrand.errorRed)
        .padding(.horizontal, 20)
        .frame(height: 42)
        .overlay(Capsule().stroke(ReportChatBrand.errorBorder, lineWidth: 1.5))
}
.buttonStyle(PressScaleButtonStyle())
.disabled(isWorking)
```
Use `ChattingBrand` aliases (this file's screen), `ViewThatFits` for the stacked form, `.fixedSize(horizontal: false, vertical: true)` on the title. Use 44pt capsule height per UI-SPEC.

---

### `ChattingMessageBubble.swift` / `ChattingInputBar.swift` (views)

**Analog:** themselves. Input bar currently takes `let isSending: Bool` (line 17), `.disabled(isSending)` (line 31), spinner (35), `.animation(... value: isSending)` (57). Remove the `isSending` disable/spinner (composer stays enabled and focused), add the counter line under the row. Bubble: add pending (`Sending…` in the timestamp row), failed (40% fill, `Brand.onSurface` text, 1pt `Brand.error` 50% border, `exclamationmark.circle.fill` glyph, `Not sent. Tap to retry`, 44pt tap group, `.contextMenu { Button("Delete", systemImage: "trash", role: .destructive) }`, accessibility custom actions). Android reference for the failed-row treatment: `$A/chatting/ThreadRows.kt`.

---

### `ChatConversationsViewModel.swift` (view model, event-driven)

**Analog:** itself, lines 120-175. Current comment says unread is left to the server (lines 128-134); rewrite. The merge rebuilds `ChatPreview` copying `unreadCount: existing.unreadCount` (line ~154, and in `handleUserStatus` ~173):

```swift
let updated = ChatPreview(threadId: existing.threadId, partnerId: existing.partnerId, name: existing.name,
    lastMessage: event.content ?? existing.lastMessage, timeLabel: Self.relativeTimeLabel(from: event.timestamp),
    imageURL: existing.imageURL, isOnline: existing.isOnline, unreadCount: existing.unreadCount)
chats.remove(at: idx); chats.insert(updated, at: 0)
```
Change `unreadCount` to `ChatUnreadRules.afterPeerMessage(...)` only when `event.threadId != ChatPresence.shared.visibleThreadId` and `event.senderId != myId`; add a `markOpened(threadId:)` that zeroes the row (D-12). `ChatPreview.unreadCount` is a `let`; rebuild the row as the file does, or make it `var`.

### `ChatConversationsView.swift`

Currently `silentReload` fires only when `pushedChat` goes non-nil to nil (lines 70-74). Add `.onChange(of: ChatPresence.shared.visibleThreadId)`: new id zeroes that row; return to nil runs `silentReload()`. Works for every open route, including `HomeRoute.chat`.

### `ChatConversationRow.swift` (view)

**Analog:** itself (lines 12-65). Add pill after the preview `Text` (line 44 block) in an `HStack` (8pt gap), `.fixedSize()`, `Brand.primary` fill / `Brand.onPrimary` caption bold, `@ScaledMetric` min 24. Preview becomes `.subheadline` bold in `ChatConversationsBrand.onSurface` when `chat.unreadCount > 0`. Keep name `.callout` bold. Combine accessibility via `ChatUnreadRules.accessibilityLabel`. Opacity transition 0.2s.

---

### `ReportChatViewModel.swift` (view model, CRUD)

**Analog:** itself.
- `loadBlockState()` lines 94-105: `getChats(page: 1, limit: 50)` becomes the shared scan with `limit: 100`, and applies `ChatBlockState.applyScan`.
- `selectedReason: String` plus `defaultReasons` (lines ~256-263) become `selectedReason: UserReportReason?`. Send `reason.rawValue` to `api.chatAction(id:action:reason:details:)`. Picker lists `UserReportReason.allCases` + `displayLabel` (same source as profile report `ReportUserSheet`).
- `NOT_BLOCKER` branch at lines ~235-246 decodes the body by hand:
```swift
if case let NetworkError.httpError(status, data) = error, status == 403,
   let envelope = try? JSONDecoder().decode(StandardErrorResponse.self, from: data),
   envelope.code == .notBlocker { self.isBlocked = true; self.blockedByMe = false; self.unblockDenied = true }
```
  Replace with `BookingErrorMapper.code(for:) == .notBlocker` and `ChatBlockState.onNotBlocker()`; drop `unblockDenied`. Fire `onBlockStateChange` after every outcome.
- Details cap 1,000 via `UTF16Prefix.prefix` (D-19). Do NOT copy `ReportUserSheet.swift:59-60` (`String(newValue.prefix(maxDetailsLength))`, Characters not UTF-16); copy its `"\(details.count)/\(maxDetailsLength)"` counter shape (line 66) but use `details.utf16.count`.
- Report `429 TOO_MANY_REQUESTS` mapped via `BookingErrorMapper.code(for:)`; hide Report when `partner.id == myUserId` (`CANNOT_REPORT_SELF`).

### `ReportChatBlockCard.swift`

**Analog:** itself. Rewrite the matrix comment (lines ~15-24) and the three copy getters (`headlineText`, `bodyText`, `buttonText`, lines 82-98) to the three-row table in UI-SPEC. `shouldShowButton` becomes `!isBlocked || blockedByMe`. Not blocked: Block User (red outline). Blocked by me: Unblock User (`Brand.primary` label+stroke). Else: no button. Remove `unblockDenied` parameter.

### `ReportChatView.swift`

**Analog:** itself, init lines 35-44 (`initialIsBlocked`, `initialBlockedByMe` already exist). Add `onBlockStateChange`.

---

### `ExpertProfileView.swift` (view, request-response)

**Analog:** itself, `handleOpenBlockFlow` lines ~420-441 (shown above). Replace the `blockThreadId` sheet route with a centred `.alert` and in-flight scrim; sequence `initiateChat(peerId:)` then `chatAction(id:action:"block")` in a testable helper (`ExpertProfileBlockViewModel`, see below).

### `Client Mode/Expert Profile/ExpertProfileBlockViewModel.swift` (view model, request-response, new)

**Analog:** `Expert Mode/Booking Note/ExpertBookingNoteViewModel.swift` (`@MainActor` view model, `init(bookingId:api:)` with `api: ClickMeAPI = .shared`, published `apiError`, `do`/`catch` writes) and `Client Mode/Booking Summary/RescheduleResponder.swift` L76-85 (`toasts: ToastCenter = .shared` injected so tests read `current`). One in-flight guard as the first statement, a stored `Task` with an `awaitBlock()` test seam, error copy by step (`initiateChat` 404 gives "This user is unavailable."). Map `initiateChat` 404 to "This user is unavailable.". Success: `ToastCenter.shared.show("You blocked \(name)", systemImage: "checkmark.circle.fill")` (`ToastCenter.swift:63`; both shells host `ToastHost`). Remove `ReportThreadIdentifier` sheet and the `Couldn't open block flow` title. Keep `isSameAsCurrentUser` guard (lines ~115-125).

---

### Tests: `ClickMe2026Tests/Chat/` (new)

**Analogs:**
- Pure-type tests: `ClickMe2026Tests/Utils/BookingErrorMapperTests.swift` (header, `@testable import ClickMe2026`, `@Suite`, `@Test("...")`, `#expect`, `httpError(status:code:message:)` helper lines 18-22). Port Android `ThreadReducerTest.kt` and `BlockStateTest.kt` (both exist under `app/src/test/.../screens/chat/`) case-for-case into `ChatThreadReducerTests` and `ChatBlockStateTests` (skip the `markRead` cases: D-17 keeps the shipped Read handler); add "id unchanged across append, ack, fail, retry and mergePage".
- Stubbed VM tests: `ClickMe2026Tests/ExpertMode/ExpertBookingNoteViewModelTests.swift:14-70`:
```swift
@Suite("...", .serialized) @MainActor struct ...Tests {
    let api = APITestFactory.make { request in ... Fixtures.response(for: request, status:, body: Fixtures.errorBody(code:, message:)) }
    let viewModel = ...(api: api)
    // body assertion: request.jsonBodyForTest()?["note"]
}
```
  Use for: retry reuses the same `client_msg_id` (`MockURLProtocol.recordedRequests` filtered by path suffix `/send`), `THREAD_BLOCKED` restores text, report sends `rawValue`, profile block order (initiate then action).
- `PushForegroundPolicyTests.swift`: re-run after `ChatPresence` becomes `@Observable`.

## Shared Patterns

### Error code branching (all chat VMs)
**Source:** `Utils/BookingErrorMapper.swift:30-35` (`code(for:)`), `Network/Error+UserMessage.swift`. Never match on message text. No new decoder. No `try?` on send/block/unblock/report writes.

### Cap / counter (composer and report details)
**Source:** `Utils/UTF16Prefix.swift:20-33`. Server `.max()` counts UTF-16 units.

### Transient confirmation
**Source:** `Managers/ToastCenter.swift:63` `show(_:systemImage:)`. No new toast.

### Capsule buttons and pressed state
**Source:** `Views/Components/ButtonStyles/PressScaleButtonStyle.swift`; block card capsule above.

### Per-screen brand aliases
Use `ChattingBrand`, `ChatConversationsBrand`, `ReportChatBrand` in their own screens (do not merge); use `Brand.error`, `Brand.destructive`, `Brand.primary`, `Brand.onPrimary`, `Brand.onSurface` directly where no alias exists (UI-SPEC).

### File conventions
Xcode header block, `// MARK: -` sections, `///` docs citing the contract (CHAT-UNBLOCK section, SOCKET-CONTRACT), `nonisolated` for pure types, `@MainActor` for VMs, `#if DEBUG` around any logging, never log message content.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| (none) | | | Every file has an in-repo or Android analog. Note: no chat tests exist in iOS today, so `ClickMe2026Tests/Chat/` uses the Phase 6 test shape above. |

Gaps flagged for the planner (not missing analogs):
- `RealtimeService.emitMessageRead` drops emits while the socket is not connected (RESEARCH Pitfall 4 / Open Q1). Android's `emitPendingReads` in `ChatThreadViewModel.kt:394-400` is the reference if the planner takes it on.
- `ChatItem.timestamp` day-separator rows exist only on iOS; the reducer port must pass them through `order` (see `ChatThreadReducer` note).

## Metadata

**Analog search scope:** `ClickMe2026/Views/Screens/Chat`, `Client Mode/Expert Profile`, `Managers`, `Model/UIModels`, `Model/Responses/Children`, `Utils`, `Network/ClickMeAPI+Chats.swift`, `ClickMe2026Tests/**`, Android `screens/chat/**`.
**Files scanned:** about 30 read (full or targeted ranges). `ChattingViewModel.swift` lines 1-149 and 475-624, `ChatConversationsView.swift`, `ChattingInputBar.swift`, and `ChattingMessageBubble.swift` were not opened in this pass; line references for them come from CONTEXT/RESEARCH/UI-SPEC and the grep results, so the planner should re-verify those ranges when writing tasks.
**Pattern extraction date:** 2026-11-17
