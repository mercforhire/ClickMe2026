# Phase 7: Chat - Research

**Researched:** 2026-11-17
**Domain:** SwiftUI chat thread state (optimistic send, block state, unread counts) against the live Express/Supabase chat contract
**Confidence:** HIGH (every contract point was read in the backend source; the pure-logic design is a port of shipped Android code)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Send, failure and retry (CHAT-01)**
- **D-01:** **Copy Android 12 D-01.** A sent message appears immediately as a pending bubble keyed by `client_msg_id`. On a network error or 5xx it stays in place, dimmed, with a red "!" and "Not sent. Tap to retry". Retry reuses the **same `client_msg_id`** so the server removes duplicates. A long-press offers Delete, which removes the bubble locally. The send ack replaces the pending bubble by `client_msg_id`, and a `message.new` echo or page load with the same server id or `client_msg_id` never creates a duplicate.
- **D-02:** **No offline queue (Android D-02).** Failed bubbles live in memory only and are gone when the thread closes or the app restarts.
- **D-03:** **403 `THREAD_BLOCKED` / `RECIPIENT_UNAVAILABLE` on send (Android D-03):** remove the pending bubble, put its text back in the composer, reload this thread's block state from `GET /chats` (CHAT-UNBLOCK §6), and switch the composer to its banner state (D-07). `RECIPIENT_UNAVAILABLE` shows "This user is unavailable."
- **D-04:** **Composer cap at 10,000 characters** (backend `chat.schema.js` `content: z.string().min(1).max(10000)`), with a character counter shown near the limit, matching Android D-04.

**Block and report (CHAT-02, CHAT-03, CHAT-04)**
- **D-05:** **Fix the copy, not the backend.** Blocking only sets `chats.is_blocked`, which stops chat messages. Every block description (the `ReportChatBlockCard` body that claims profile and booking hiding, and the profile dialog) describes only that: they can't message you, and they aren't notified. No backend enforcement on profiles or bookings.
- **D-06:** **Profile Block copies Android 12 D-05/D-07.** The Expert Profile ⋯ "Block {name}" opens a confirm alert, "Block {name}? They won't be able to message you.", instead of the combined Report & Block screen. On confirm: `initiateChat`, then `chatAction(threadId, "block")`, with a progress indicator and repeat taps ignored. On success, stay on the profile and show a short confirmation. The menu always shows "Block {name}" (no block-state lookup; re-block is a 200 no-op). Unblocking happens in the chat.
- **D-07:** **Blocked thread follows the CHAT-UNBLOCK §5 matrix.** The composer is replaced by a banner:
  - `is_blocked && blocked_by_me`: "You blocked this conversation", with an **Unblock button on the banner**.
  - `is_blocked && !blocked_by_me`: "You can't reply to this conversation", with no Unblock anywhere.
  - The Report & Block screen (⋯ menu) follows the same rules: Unblock only for the blocker. Local state after each outcome follows §6, including `403 NOT_BLOCKER`.
- **D-08:** **Legacy blocks follow CHAT-UNBLOCK §7.** `blocked_by_me` missing or false on a blocked thread means "You can't reply…" and no Unblock for either side. This removes iOS's current "legacy-safe" Unblock for the blocked side (inventory H3). `blocked_by_me` decodes with a default of `false`.
- **D-09:** **CHAT-02:** chat reports send `UserReportReason` raw values (as the profile report already does), not display labels.
  - **Note 2026-11-17:** the UI-SPEC (assumption A13, not yet confirmed by the user) has the chat report picker show the six `UserReportReason` labels in enum order, replacing the current chat-only labels that don't map to the enum.
- **D-19 (added 2026-11-17, user decision at the UI-SPEC probe):** the Report & Block details field is capped at **1,000 characters** with an always-visible `{n}/1000` counter and trimmed on submit, matching Android and the profile `ReportUserSheet`. The backend allows 2,000; an uncapped iOS field could get a 422.

**Thread open (CHAT-05, CHAT-06)**
- **D-10:** Seed `peerUserId` from `ChatThreadItem.partner.id` when the thread opens, so typing and View Profile work before any peer message arrives (inventory H5). Keep the existing never-from-admin-rows rule as the fallback.
- **D-11:** `loadEarlier` filters out messages whose server id is already loaded before prepending (inventory H6).

**Unread badge (CHAT-07)**
- **D-12:** **Set the row's count to 0 locally when its thread opens.** The next quiet reload of `GET /chats` re-syncs.
- **D-13:** **Add 1 locally** to a row's count on a `message.new` for a thread that isn't open, for peer messages only, never own echoes, along with the existing move-to-top. `GET /chats` corrects any drift.
- **D-14:** **Badge style:** a brand-coloured count pill on the right of the row, "99+" above 99, hidden at 0. The row's name and preview are bold while unread.
- **D-15:** **No Chats tab icon badge** (Android 12 D-16 parity).
- **D-16:** **Send `message.read` for unread peer messages on every page loaded**, including `loadEarlier`, not only page 1. No backend change. Accepted gap: in a thread with more than 30 unread messages where the user never scrolls up, the server count stays above 0 and the badge comes back after a reload (backend 01-14 marks nothing read on open).

**Read label (CHAT-08)**
- **D-17:** **Closed as not reproducible** after the user's device re-test on 2026-11-17. No code change. The device UAT keeps one two-device regression row. If that row ever fails, start with the backend (`message.read` delivery: room membership, emit target, thread/message-id check), since BUG-13 was seen in both apps.

### Claude's Discretion
- Exact visuals of the pending, failed and banner states and the counter, using the existing `ChattingBrand` / `Brand` tokens (adapt from Android; no pixel parity). The UI-SPEC phase may refine them.
- The wording and form of the profile-block success confirmation (a toast/overlay or an inline notice).
- At what point the counter appears (Android's threshold is fine).

### Folded Todo
- **D-18:** Expert-mode chat row opens the client booking screen and fails to load (`.planning/todos/pending/2026-11-16-expert-chat-row-opens-client-booking-screen.md`, major). `ChattingView.swift:341-343` pushes `HomeRoute.bookingSummary` / `.upcomingBooking`, which load `GET /client/bookings/:id`, so an expert gets a 404. Confirm on a device first. If it reproduces, send expert-mode booking rows to `ExpertBookingSummaryView`, matching Android `ExpertBookingSummaryKey`. iOS only. Use the existing `hostsClientBookingFlows` environment flag or the shell mode to pick the route.

### Deferred Ideas (OUT OF SCOPE)
- Enforce block on the backend (hide profile / stop bookings for a blocked user).
- Backend mark-all-read (`message.read` with `up_to`, or mark all on thread open).
- Chats tab total unread badge (D-15).
- Offline send queue / failed messages kept across restarts (D-02).
- Reviewed, not folded: `2026-11-13-android-delete-account-copy-and-blockers.md`, `2026-11-13-decide-saved-cards-on-account-deletion.md`, `2026-11-16-usd-symbol-us-dollar-prefix.md`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CHAT-01 | Pending / failed / retry send | `ChatThreadReducer` port of Android `ThreadReducer`; `ChatMessage` needs a stable `id`, `clientMsgId`, `sendState`; backend dedupes on `(thread_id, sender_id, client_msg_id)` and returns the existing row with 201 |
| CHAT-02 | Chat report sends enum values | Backend `actionsSchema.reason` is a free `z.string().max(500)`; reuse `UserReportReason.rawValue`; cap `details` with `UTF16Prefix` at 1,000 |
| CHAT-03 | Blocked thread banner, Unblock only for the blocker | `ChatBlockState` port of Android `BlockState`; `GET /chats` scan (limit 100) is the only source of `blocked_by_me`; no socket event for block changes |
| CHAT-04 | Profile Block confirm and truthful copy | Extract a testable `initiateChat` then `chatAction("block")` helper; copy table in 07-UI-SPEC; `initiateChat` 404 for a suspended peer |
| CHAT-05 | Typing and View Profile from open | Seed `peerUserId` from the thread-open `GET /chats` scan (works for every entry route, including `HomeRoute.chat`, which carries no partner id) |
| CHAT-06 | `loadEarlier` never duplicates | Merge by server id (then own `client_msg_id`) in the reducer |
| CHAT-07 | Unread badge | Backend `unread_count` verified (BACK-18); list VM +1 / 0 rules; `ChatPresence` hook so every open route zeroes the row |
| CHAT-08 | Read label live | Closed (D-17): one regression row in the device UAT, no code |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Swift 6, strict concurrency complete, iOS 18+, Xcode 26: no rewrites. New pure helpers are `nonisolated` value types; view models and managers stay `@MainActor`. [VERIFIED: ./.claude/CLAUDE.md]
- The backend owns the API contract; iOS is the behaviour source of truth and Android is a port. Backend changes (none planned here) must be additive and safe for the current Android build. If a task needs a change in another repo, say so. [VERIFIED: ./CLAUDE.md]
- Definition of done: unit tests where logic is testable, clean `xcodebuild` with no new warnings, a device check via a UAT checklist, backend tests for backend changes. One iOS release at the end of the project; no hotfix build. [VERIFIED: ./.claude/CLAUDE.md]
- Production backend: Block, Unblock and Report change real accounts. Device checks use two test accounts. [VERIFIED: 07-UI-SPEC.md "Live-data warning"]
- Conventions: errors display through `Error.userMessage`; branch on `ErrorCode`, never on message text; `apiError` for view-model errors; no `try?` on writes; no `try!`, `fatalError` or `as!`; `// MARK: -` sections; Xcode file header; `///` docs that explain the contract; `#if DEBUG` around debug logging; do not log message content or tokens; new subviews take the screen prefix (`Chatting…`, `ChatConversation…`, `ReportChat…`); Identifiers spelled `Id`; shared singletons `static let shared`; extract new logic into helpers rather than growing 600+ line view models. [VERIFIED: ./.claude/CLAUDE.md]
- Do not edit `ClickMe2026/Debug/PreviewSecrets.swift`. SwiftLint runs in CI and blocks PRs to `main`. [VERIFIED: ./.claude/CLAUDE.md]

## Summary

Phase 7 is a bug-fix phase on one existing feature, with **no backend change and no new dependency**. Everything the phase needs on the server is already shipped and was re-read in the backend source this session: `client_msg_id` idempotent send (`UNIQUE(thread_id, sender_id, client_msg_id)`, duplicate returns the existing row with 201 and does no emit), `THREAD_BLOCKED` and `RECIPIENT_UNAVAILABLE` on send, `blocked_by_me` on `GET /chats`, per-thread `unread_count` recomputed on send / `message.read` / page-1 open, and a `message.read` handler that marks only the listed `message_ids`. Android Phase 12 already ships every behaviour iOS is catching up to, and its two pure-logic types (`ThreadReducer`, `BlockState`) can be ported almost line for line into testable Swift value types.

The design that keeps `ChattingViewModel` from growing (it is 624 lines) is three small pure types plus thin wiring: a `ChatThreadReducer` (append / ack / fail / retry / remove / merge-page / incoming / mark-read / unread-ids), a `ChatBlockState` struct (the CHAT-UNBLOCK §5 to §7 rules including `NOT_BLOCKER` and "scan did not list the thread"), and small rules enums for the composer cap and the unread badge. Most of the phase's real risk is in details the CONTEXT does not spell out and that were found by reading the code: `ChatMessage.id` is a random `let id = UUID()` that cannot be preserved through a memberwise copy (so "same SwiftUI identity on ack" needs a model change); `reload()` replaces `items` wholesale and would delete pending and failed bubbles; `message.new` carries no `client_msg_id` and is never echoed to the sender; `HomeRoute.chat` carries no partner id, so D-10 must come from a `GET /chats` scan on open, not from the route; popping a chat opened by `HomeRoute.chat` does not trigger the list's `silentReload`; emits are silently dropped while the socket is not connected; and the Report & Block screen's block state never reaches the thread view model.

**Primary recommendation:** Port Android's `ThreadReducer` and `BlockState` as `nonisolated` pure types under `ClickMe2026/Utils/`, make `ChatMessage` carry `clientMsgId` and a local `sendState` with a stable id, drive thread open from one `GET /chats` scan (limit 100) that supplies peer id and block state, and test the pure types and the stubbed view models in a new `ClickMe2026Tests/Chat/` folder.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Idempotent send, dedupe, block enforcement on send | API / Backend | Client (retry reuses the same id) | Server owns `client_msg_id` dedupe and `THREAD_BLOCKED`; the client only has to resend the identical string [VERIFIED: chatMessages.js:52-72, chats.controller.js:385-387] |
| Pending / failed bubble state | Client (view model, in memory) | — | D-02: never persisted; the server never sees a failed send |
| Block state source of truth | API / Backend (`GET /chats`) | Client (local transitions per CHAT-UNBLOCK §6) | `blocked_by_me` is caller-relative and only on the list endpoint |
| Unread count | API / Backend (recomputed from message status) | Client (local 0 on open, +1 on live message) | Server value is authoritative; client math is a display optimisation corrected by the next reload |
| Marking messages read | Realtime (socket `message.read`, no REST fallback) | Client (decides which ids to emit) | Server marks only the ids emitted [VERIFIED: socket.js `handleMessageRead`] |
| Report reason validity | Client (enum list) | API (accepts any string up to 500) | The server does not validate the enum on the chat route, so the client is the only guard |
| Composer cap / counter | Client | API (422 over 10,000) | Cap on a UTF-16 boundary prevents the 422 |
| Booking-row route in chat | Client (shell selects the route) | API (`/client/bookings/:id` is client-scoped) | Expert endpoint is `/expert/bookings/:id/…` |

## Standard Stack

No new libraries. Everything is in-repo or already linked.

### Core (reuse, do not re-create)
| Item | Location | Purpose | Notes |
|------|----------|---------|-------|
| `UTF16Prefix.prefix(_:limit:)` | `ClickMe2026/Utils/UTF16Prefix.swift` | Cap text on a whole-character UTF-16 boundary | Server zod `.max()` counts UTF-16 units [VERIFIED: file header] |
| `UserReportReason` | `ClickMe2026/Model/Enums/UserReportReason.swift` | Report reason enum with `displayLabel` | Raw values quoted below |
| `ErrorCode` | `ClickMe2026/Model/Enums/ErrorCode.swift` | `.threadBlocked`, `.recipientUnavailable`, `.notBlocker`, `.tooManyRequests` | All four already exist |
| `BookingErrorMapper.code(for:)` | `ClickMe2026/Utils/BookingErrorMapper.swift:31` | Reads the `ErrorCode` out of a `NetworkError.httpError` body | Reuse for send and block errors; do not write a new decoder |
| `Error.userMessage` | `ClickMe2026/Network/Error+UserMessage.swift` | Display string | Returns the fixed "Something went wrong. Please try again." for non-HTTP `NetworkError` cases, and `URLError.localizedDescription` for transport errors |
| `ToastCenter.shared.show(_:systemImage:)` | `ClickMe2026/Managers/ToastCenter.swift` | Profile Block success toast | Already hosted by both shells (`.modifier(ToastHost())` in `HomeClientView.swift:126`, `HomeExpertView.swift:99`) |
| `ChatPresence.shared` | `ClickMe2026/Managers/ChatPresence.swift` | Which thread is on screen | See Pattern 5 for the observation gap |
| `PressScaleButtonStyle` | `Views/Components/ButtonStyles/` | Capsule buttons | Per UI-SPEC |
| `MockURLProtocol`, `APITestFactory`, `URLRequest.jsonBodyForTest()` | `ClickMe2026Tests/Support/` | Stubbed HTTP tests | Same seam as Phase 6 |

Verbatim values used by this phase (quoted from the files opened this session):

```swift
// ClickMe2026/Model/Enums/UserReportReason.swift:14-19
case harassment           = "harassment"
case spam                 = "spam"
case inappropriateContent = "inappropriate_content"
case scamOrFraud          = "scam_or_fraud"
case impersonation        = "impersonation"
case other                = "other"
```
```swift
// ClickMe2026/Model/Enums/ErrorCode.swift:83, 87, 179, 185
case threadBlocked           = "THREAD_BLOCKED"
case notBlocker              = "NOT_BLOCKER"
case recipientUnavailable    = "RECIPIENT_UNAVAILABLE"
case tooManyRequests         = "TOO_MANY_REQUESTS"
```
```js
// ClickMe2026 Backend/src/schemas/chat.schema.js:37-47
content:       z.string().min(1).max(10000),
client_msg_id: z.string().uuid(),
reason:  z.string().max(500).optional(),
details: z.string().max(2000).optional(),
```

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Pure `ChatThreadReducer` | Mutating `items` inline in `ChattingViewModel` | Inline repeats the 624-line growth the CONTEXT forbids and cannot be unit-tested without the whole VM |
| Separate local `sendState` on `ChatMessage` | Add `.sending` / `.failed` cases to `MessageStatus` | `MessageStatus` is a server `Decodable` enum (`sent`, `delivered`, `read`); polluting it forces every switch to handle local-only cases. Keep it separate |
| `GET /chats` scan on open | Add `partnerId` and block flags to `HomeRoute.chat` | The route enum is built in 6 places across both shells and the `OpenChatThreadAction` closure; a scan serves every entry route (push tap, Message button, list row) with one code path |

**Installation:** none. No packages are added. **Package Legitimacy Audit:** not applicable, because no external package is installed this phase; the `package-legitimacy` gate was not run.

## Architecture Patterns

### System Architecture Diagram

```
 entry routes                 ChatView (@StateObject ChattingViewModel)                    backend
 -----------                  -------------------------------------------                  -------
 list row tap  ───┐
 HomeRoute.chat ──┼─▶ open ─▶ [A] forceLoad: GET /chats/:id/messages?page=1&limit=30 ───▶ messages(+client_msg_id)
 (push, Message)  ┘            │   merge via ChatThreadReducer.mergePage (keeps local rows)
                               │   emit message.read for unread peer ids on THIS page ──▶ socket (dropped if not connected)
                               ├─▶ [B] thread scan: GET /chats?limit=100 (find threadId) ─▶ partner.id, is_blocked, blocked_by_me
                               │       -> peerUserId (D-10) + ChatBlockState.applyScan
                               │
 composer Send ─▶ sendMessage: append pending bubble (clientMsgId = new UUID string), clear composer, scroll
                               └─▶ POST /chats/:id/send {type, content, client_msg_id} ──▶ 201 {message_id,status,timestamp}
                                     ├ 201            -> ChatThreadReducer.ack (same bubble id, now sent)
                                     ├ network / 5xx  -> .fail (stays in place; tap = retry, same client_msg_id)
                                     ├ 403 THREAD_BLOCKED / RECIPIENT_UNAVAILABLE -> remove bubble, restore text, rescan [B]
                                     └ other 4xx      -> remove bubble, restore text, "Couldn't send message" alert
 socket message.new ─▶ ChatThreadReducer.onIncoming (id dedupe) + emit message.read
 socket message.read ─▶ ChatThreadReducer.markRead (my bubbles -> read)
 ⋯ menu ─▶ ReportChatView(initial block state) ─▶ block / unblock / report ──▶ POST /chats/:id/actions
            └─ onBlockStateChange(ChatBlockState) ─▶ thread VM adopts it (banner / composer swap, no reload)

 ChatConversationsViewModel
   GET /chats?limit=50 ─▶ rows(unreadCount)          message.new (peer, thread != visible) ─▶ +1, move to top
   ChatPresence.visibleThreadId changes ─▶ row -> 0 (D-12); returns to nil ─▶ silentReload (re-sync)
```

### Recommended Project Structure
```
ClickMe2026/
├── Utils/
│   ├── ChatThreadReducer.swift        # NEW pure list rules (port of Android ThreadReducer)
│   ├── ChatBlockState.swift           # NEW pure block rules (port of Android BlockState)
│   ├── ChatComposerRules.swift        # NEW cap 10,000, counter from 9,000, counter text
│   └── ChatUnreadRules.swift          # NEW "99+" label, VoiceOver label, +1 / zero rules
├── Model/UIModels/ChatDisplayModels.swift   # CHANGED ChatMessage (stable id, clientMsgId, sendState)
├── Model/Responses/Children/ChatThreadItem.swift  # CHANGED blockedByMe defaults to false
├── Managers/ChatPresence.swift        # CHANGED observable so the list can react (Pattern 5)
└── Views/Screens/Chat/
    ├── Chatting/ChattingViewModel.swift         # wiring only; send/retry/scan call the reducer
    ├── Chatting/Subviews/ChattingBlockedBanner.swift   # NEW (UI-SPEC)
    ├── Conversations/…                          # row pill + VM count rules
    └── Report and Block/…                       # UserReportReason picker, matrix card, state callback
ClickMe2026Tests/Chat/                           # NEW folder (no chat tests exist today)
```

### Pattern 1: `ChatThreadReducer` (CHAT-01, CHAT-06)

**What:** A caseless `nonisolated enum` of static functions over `[ChatItem]`, mirroring Android `ThreadReducer.kt` [VERIFIED: ThreadReducer.kt read in full]. Rules to port:
- Match a server row to an existing row by **server id first, then, for own messages, by `client_msg_id`**; a match is replaced by the server row but keeps the existing bubble's identity.
- A `.read` message never goes back to `.sent` on a later merge.
- Existing rows with no match are kept (older pages, pending and failed bubbles).
- Order = server-backed rows by `createdAt` (stable sort), then local unsent bubbles in their current order.
- `ack` when a reload already added the server row: collapse the two into that row.
- `onIncoming`: ignore when `senderId == myId` or when the server id is already present.
- `remove` never deletes a row that already has a server id.
- `unreadPeerIds(items, alreadyEmitted:)`: ids of peer messages not yet read.
- Compare ids case-insensitively.

**Why:** the iOS gaps are real. `loadEarlier` does `items.insert(contentsOf: older, at: 0)` with no filter [VERIFIED: ChattingViewModel.swift:242-243]; `forceLoad` does `items = response.data.messages.map(...)` which would discard pending and failed bubbles on pull-to-refresh or Retry [VERIFIED: ChattingViewModel.swift:179]; `ChatMessage` has no `clientMsgId` [VERIFIED: ChatDisplayModels.swift:35-57].

**Model change required (verified need):**
```swift
// ChatDisplayModels.swift today (lines 35-57): `let id = UUID()`, `let timestamp: Date`
// `id` has an inline default, so it is NOT in the memberwise init. A copy built through the
// memberwise init therefore gets a NEW id, and the ForEach would remove and re-insert the bubble.
// Required: make id assignable (`var id: UUID = UUID()` or an explicit init parameter),
// make `timestamp` a `var` (the ack supplies the server time), add:
var clientMsgId: String?     // nil for server rows from older payloads and peer rows
var sendState: ChatSendState // .sent (default) | .sending | .failed ; local only, never decoded
```
Ack, fail and retry must **mutate in place** (copy the struct, change fields, write it back at the same index) so the id is kept. Never route an ack through `mapToChatItem`, which mints a fresh id.

**Wire details that shape the reducer:**
- `message.new` has no `client_msg_id` and is never sent to the sender; the server emits only to the recipient's room. So `client_msg_id` matching only ever happens when REST pages are merged. [VERIFIED: chatMessages.js `io.to(recipientId).emit('message.new', {…})`; SOCKET-CONTRACT.md §3 "you do not receive your own message back over the socket"]
- `GET /chats/:id/messages` selects `client_msg_id` [VERIFIED: chats.controller.js:298] and iOS already decodes it as `ChatMessageItem.clientMsgId: String?` [VERIFIED: ChatMessageItem.swift]. `mapToChatItem` currently drops it; map it through.
- The DB column is `client_msg_id TEXT` [VERIFIED: 20260609010000_create_messages.sql:42], so the server stores and returns the exact string. Generate it once per bubble (`UUID().uuidString`, accepted by `z.string().uuid()`), store that string, and resend that exact string on retry. Compare case-insensitively anyway (Android does).

### Pattern 2: `ChatBlockState` (CHAT-03, CHAT-04)

Port Android `BlockState.kt` [VERIFIED: read in full] as a `nonisolated struct` with the same transitions:
- `block` 200 -> `isBlocked = true, blockedByMe = true`; `unblock` 200 -> both false; `unblock` 403 `NOT_BLOCKER` -> `isBlocked = true, blockedByMe = false`; send 403 `THREAD_BLOCKED` -> `isBlocked = true` (who blocked is unknown, keep `blockedByMe`) then rescan. [VERIFIED: CHAT-UNBLOCK.md §6]
- `applyScan(found:sessionBlockedByMe:)`: when the thread is found, the scan wins; when it is **not** listed, do not read that as "unblocked" (keep the current state, or blocked-by-me if this session blocked it).
- `showsUnblock = isBlocked && blockedByMe`; menu entry is `blockOrReport` / `unblockOrReport` / `reportOnly`; `composerMode` is blocked-by-me / blocked-by-peer / unavailable / normal, with **blocked winning over unavailable** (the server checks `THREAD_BLOCKED` first [VERIFIED: chats.controller.js:385-396]).
- Drop the existing iOS `unblockDenied` latch: after `NOT_BLOCKER` the state is `blockedByMe = false`, which already hides Unblock, and the server's later scans also report `false`.

**Decode default (D-08):** `ChatThreadItem.blockedByMe` is `Bool?` today [VERIFIED: ChatThreadItem.swift]. Change to a non-optional `Bool` with a custom `init(from:)` using `decodeIfPresent(Bool.self, forKey: .blockedByMe) ?? false`, exactly as CHAT-UNBLOCK §9 shows. The type has no memberwise initialiser use in tests today, so the change is local. Note `convertFromSnakeCase` is applied by the network layer, so the key is `blockedByMe`.

**Thread-open scan (CHAT-05 + CHAT-03):** One `GET /chats` call per open supplies `partner.id` (D-10), `partner.roles`, `is_blocked` and `blocked_by_me`. Use `limit: 100`, which is the backend maximum (`Math.min(100, …)` [VERIFIED: chats.controller.js:156]); the existing iOS code scans `limit: 50` in `ReportChatViewModel.loadBlockState` [VERIFIED: ReportChatViewModel.swift:98], and Android scans 100 [VERIFIED: ChatsRepository.kt `SCAN_LIMIT = 100`]. The list is ordered by `last_msg_at desc nulls last`, so a thread outside the first page is an older one; if not found and `pagination.currentPage < totalPages`, request the next page (bounded, for example 3 pages). A failed scan keeps the normal composer (safe default, the server still rejects) and never blocks opening. BACK-16 is shipped, so empty threads are now listed [VERIFIED: chats.controller.js:140-141 comment and the `order` call], but still treat "not found" as "leave state alone".

Re-run the scan: after a `THREAD_BLOCKED` send rejection, when the chat view reappears (Android re-reads on `ON_RESUME`), on pull-to-refresh, and after a `block` 200 (the server keeps the original blocker, so a peer who blocked first leaves the caller with `blocked_by_me = false` even though the call returned 200 [VERIFIED: chats.controller.js:477 "if (thread.is_blocked) break;"; CHAT-UNBLOCK.md §6]). There is no socket event for block changes, so a peer unblocking while the "can't reply" banner is on screen is only discovered by one of these re-scans.

### Pattern 3: Composer rules (CHAT-01 / D-04)

Copy the Phase 6 note pattern [VERIFIED: ExpertBookingNoteViewModel.swift:85-105]: a static `limit = 10_000`, `counterFrom = 9_000`, a `cap(_:)` that calls `UTF16Prefix.prefix(raw, limit:)`, a `showsCounter(length:)` on `text.utf16.count`, and a `counterText(length:locale:)` returning `{n} / 10,000` with locale-formatted numbers (UI-SPEC copy). Apply the cap where the text is set (the text binding or an `onChange` that reassigns the capped value), and test the pure function. The cap runs before trimming; trimming happens at send (existing `trimmingCharacters`). Counter and announcement behaviour is in 07-UI-SPEC.

### Pattern 4: Report & Block (CHAT-02, CHAT-03, CHAT-04)

- `ReportChatViewModel.selectedReason: String` and `reasons: [String]` hold display labels today and `submitReport` sends the selected label as `reason` [VERIFIED: ReportChatViewModel.swift:149-156, 256-263]. Change to `selectedReason: UserReportReason?` and send `reason.rawValue`; the picker lists `UserReportReason.allCases` with `displayLabel`. The preview init still needs a default.
- Details: cap with `UTF16Prefix.prefix(_, limit: 1000)` (not `String.prefix(1000)`, which counts Characters: `ReportUserSheet` uses `String(newValue.prefix(maxDetailsLength))` [VERIFIED: ReportUserSheet.swift:59-60], and a run of ZWJ emoji can exceed the backend's 2,000 UTF-16 units while staying under 1,000 Characters). Trim on submit (existing).
- Error mapping for report: `429 TOO_MANY_REQUESTS` is the shared 10 reports/hour limiter [VERIFIED: USER-REPORTING.md §2 and §1 table]; branch with `BookingErrorMapper.code(for:)` and show the UI-SPEC copy, not a generic alert. `422 CANNOT_REPORT_SELF` means a legacy self-thread: hide Report when `partner.id` equals the signed-in user id (USER-REPORTING §2 and §3 "Self-targeting guards").
- Block card: replace the state matrix comment and copy per 07-UI-SPEC; delete `unblockDenied`; show the button only for not-blocked (Block User, red) and blocked-by-me (Unblock User, accent). The current logic shows Unblock for every blocked state unless denied, which is exactly H3 [VERIFIED: ReportChatBlockCard.swift:79-82].
- State must flow back to the thread: `ChattingView` passes `onBlock`, `onUnblock` closures that only close the screen [VERIFIED: ChattingView.swift:85-95], and the NOT_BLOCKER path calls neither. Add one `onBlockStateChange: (ChatBlockState) -> Void` callback fired after every outcome, seed `ReportChatView` with the thread's current state (`initialIsBlocked`, `initialBlockedByMe` already exist as init parameters [VERIFIED: ReportChatView.swift:35-44]), and let the thread VM adopt it. Also re-run the scan when the pushed screen disappears as a backstop.

### Pattern 5: Unread badge (CHAT-07)

- Backend semantics verified: `unread_count` is the count of the other party's messages whose `status` is not `read`, recomputed (never incremented) on send for the recipient, on `message.read` for the reader, and on `GET /chats/:id/messages` page 1 for the caller (which marks nothing read) [VERIFIED: SOCKET-CONTRACT.md §6; chatMessages.js `countUnreadFor`; socket.js `recomputeUnreadFor`].
- List VM rules: open -> row 0 (D-12); `message.new` for a thread that is not the visible one and `senderId != myId` -> +1 and move to top (D-13); otherwise leave the count. Today the merge copies `unreadCount: existing.unreadCount` in both `handleMessageNew` and `handleUserStatus` [VERIFIED: ChatConversationsViewModel.swift:154,173]. `ChatPreview.unreadCount` is a `let` on a `Hashable` struct, so mutation means rebuilding the row (as the file already does) or making it `var`.
- **How the list learns a thread opened.** The list view only triggers `silentReload` when `pushedChat` goes from non-nil to nil [VERIFIED: ChatConversationsView.swift:70-74]. A thread opened through `HomeRoute.chat` (push tap, profile Message button, `openChatThread`) never sets `pushedChat`, so neither D-12 nor the pop-back refresh would happen. `ChatPresence` is deliberately a plain holder, "not observable UI state" [VERIFIED: ChatPresence.swift doc comment]. Recommended change: make `ChatPresence` `@Observable` (same style as `ToastCenter`, and the project's rule for new shared managers) and have `ChatConversationsView` react to `ChatPresence.shared.visibleThreadId` with `onChange`: a new id zeroes that row; a return to `nil` runs `silentReload()`. This one hook serves every open route and also lets `handleMessageNew` read `visibleThreadId` for the +1 guard. `PushForegroundPolicyTests` drive the shared `ChatPresence` [VERIFIED: PushForegroundPolicyTests.swift header], so keep its API (`visibleThreadId`, `chatAppeared`, `chatDisappeared`, `clearSessionData`) unchanged.
- Label rules (`99+` above 99, hidden at 0, VoiceOver singular and "More than 99") as pure functions in `ChatUnreadRules` so they are unit-tested rather than device-checked.

### Pattern 6: Profile Block (CHAT-04 / D-06)

Extract `initiateChat(peerId)` then `chatAction(id:action:"block")` into a small `@MainActor` helper (or a method on a tiny view model) so the order and the error mapping are testable; `ExpertProfileView` today runs it inside a `Task` in the view [VERIFIED: ExpertProfileView.swift:425-441]. Map `404` from `initiateChat` (the backend refuses a **new** thread with a suspended or terminated peer, returning `404 NOT_FOUND` "User not found." [VERIFIED: chats.controller.js:113-116]) to "This user is unavailable." (UI-SPEC). An existing thread with a suspended peer returns 201 and the block succeeds. Remove `blockThreadId`, `ReportThreadIdentifier` and the `.sheet(item:)` that hosts `ReportChatView` from the profile, and the `Couldn't open block flow` alert title. Guard against double taps with the in-flight flag. The `isSameAsCurrentUser` guard already prevents `CANNOT_BLOCK_SELF` and `CANNOT_CHAT_WITH_SELF` [VERIFIED: ExpertProfileView.swift:115-125].

### Pattern 7: Expert booking row (D-18)

Make the route choice a pure function `ChatBookingRowRoute.route(isTerminal:bookingId:hostsClientBookingFlows:) -> HomeRoute` so it is testable. Expert shell (`hostsClientBookingFlows == false`, set at `HomeExpertView.swift:262`) returns `.expertBookingSummary(bookingId:)`, which that shell renders with `ExpertBookingSummaryView(bookingId:)` [VERIFIED: HomeExpertView.swift:316-324 region and HomeNavigationPath.swift:117]. The client shell renders `.expertBookingSummary` as `EmptyView()` [VERIFIED: HomeClientView.swift expert-only case], so the client shell must keep the two client routes. `GET /client/bookings/:id` is `roleCheck('client')` [VERIFIED: clientBooking.js:27], which is why an expert gets an error there. `BookingEvent` already carries `bookingId` and `isTerminal`; the event payload also carries `client_id` and `expert_id` [CITED: ChattingViewModel.swift doc comment on `bookingEvent`, not re-verified on the wire], which would allow a per-viewer route for dual-role users (see Open Question 2). The CONTEXT requires confirming the failure on a device before changing the route; keep that gate as the first task of its plan.

### Anti-Patterns to Avoid
- **Rebuilding the pending bubble through `mapToChatItem` on ack.** It mints a new `id`, so SwiftUI removes and re-inserts the row (the flash UI-SPEC forbids).
- **`items = server page` in `forceLoad`.** Use `mergePage` so pending and failed bubbles survive reload and pull-to-refresh.
- **One `isSending` gate.** The current `guard !trimmed.isEmpty, !isSending` serialises sends and disables the field [VERIFIED: ChattingViewModel.swift:256, ChattingInputBar.swift `.disabled(isSending)`]. The new design allows several in flight, tracked per `client_msg_id`.
- **Treating "thread not in the scan" as "unblocked".**
- **Parsing `message` text to detect `THREAD_BLOCKED`.** Branch on `ErrorCode`.
- **A new decoder for the error body.** Use `BookingErrorMapper.code(for:)`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| UTF-16-safe truncation | `String.prefix(n)` | `UTF16Prefix.prefix(_:limit:)` | `prefix` counts Characters; the server counts UTF-16 units |
| Reading `ErrorCode` from a failed call | New JSON decode in each VM | `BookingErrorMapper.code(for:)` | One tested path; unknown codes decode to nil |
| Display string for an error | Per-VM helper | `Error.userMessage` | Project convention |
| Transient confirmation | New toast or overlay | `ToastCenter.shared.show` | Already hosted by both shells |
| Idempotent resend | Client-side dedupe timers | Same `client_msg_id` | Server enforces `UNIQUE(thread_id, sender_id, client_msg_id)` |
| Block rules inside views | `if isBlocked && …` in SwiftUI bodies | `ChatBlockState` | Three call sites (banner, menu, card) must agree |
| Report reason list | Hard-coded labels | `UserReportReason.allCases` | The enum is already the profile report's source of truth |

**Key insight:** every hard part of this phase is a small state machine. Keep them as pure value types with tests; the SwiftUI and view-model layers become thin wiring, which is also what keeps `ChattingViewModel` from growing.

## Common Pitfalls

### Pitfall 1: Pending bubbles deleted by a reload
**What goes wrong:** pull-to-refresh, the error-state Retry, or `reload()` calls `forceLoad`, which assigns `items = response.data.messages.map(...)` [VERIFIED: ChattingViewModel.swift:179]. Any pending or failed bubble disappears; a bubble whose ack has not arrived is replaced by its server twin, producing a flash and possibly a duplicate once the ack lands.
**How to avoid:** `forceLoad` uses `ChatThreadReducer.mergePage`; `ack` collapses into an existing server row. Test: pending bubble + page containing the same `client_msg_id` -> one bubble.
**Warning signs:** the failed bubble vanishes when pulling down.

### Pitfall 2: Bubble identity changes on ack
**What goes wrong:** `ChatMessage.id` is `let id = UUID()` and `ChatItem.id` is derived from it [VERIFIED: ChatDisplayModels.swift:16-20, 36]. Any new `ChatMessage` is a new row.
**How to avoid:** the model change in Pattern 1, and in-place mutation. A unit test asserts `id` is unchanged across append -> ack -> markRead.

### Pitfall 3: `HomeRoute.chat` carries no partner id
**What goes wrong:** `ChatView(threadId:peerName:peerAvatarURL:)` is built from `HomeRoute.chat(threadId, peerName, peerAvatarURL)` in both shells [VERIFIED: HomeClientView.swift:365-370, HomeExpertView.swift:315-320]. Seeding `peerUserId` from `ChatPreview.partnerId` only covers list-row opens.
**How to avoid:** seed from the open-time scan (Pattern 2), optionally also from `ChatPreview.partnerId` and its block flags as an instant seed for list opens to avoid a composer-then-banner flash.

### Pitfall 4: Emits are silently dropped while the socket is not connected
**What goes wrong:** `RealtimeService.emitMessageRead` does `socket?.emit(...)`. In socket.io-client-swift, `emit` returns early with "Tried emitting when not connected" unless the status is `.connected` [VERIFIED: SourcePackages/checkouts/socket.io-client-swift/Source/SocketIO/Client/SocketIOClient.swift:309-313]. Opening a chat from a cold-launch push tap can race the connection, so the first `emitReadForVisiblePeerMessages()` is lost and the badge never clears. Android records an id as emitted only when the socket was `Connected` and replays pending ids on connect [VERIFIED: ChatThreadViewModel.kt `emitPendingReads`, ConnectionState handling].
**How to avoid:** treat this as part of D-16: expose a connected flag from `RealtimeService`, keep an `emittedReadIds` set in the thread VM, and re-run the emit after a `message.new`, after each page, and on socket connect. This is a small addition beyond the CONTEXT's wording; see Open Question 1.

### Pitfall 5: `message.read` only covers the ids listed
**What goes wrong:** the server marks only `message_ids` and recounts [VERIFIED: socket.js `handleMessageRead`]. Page 1 is 30 messages, so a thread with more than 30 unread keeps a non-zero count (D-16, accepted). The current helper scans **all** `items` each call [VERIFIED: ChattingViewModel.swift:462-473], so with `loadEarlier` it would re-emit page 1 ids; harmless but wasteful.
**How to avoid:** emit via `unreadPeerIds(items, alreadyEmitted:)` after every page; record emitted ids.

### Pitfall 6: Pop-back refresh races the read recount
**What goes wrong:** on pop, the list runs `silentReload` immediately; the `message.read` DB update and recount may not have finished for a user who opens and leaves within a second, so the badge briefly reappears.
**How to avoid:** accept per D-12 ("the next quiet reload re-syncs") and cover it in device check C6; optionally also run one delayed silent reload (about 2 s) after a pop. Not worth extra machinery unless C6 shows it.

### Pitfall 7: Report & Block state does not reach the thread
See Pattern 4. Without `onBlockStateChange`, the thread keeps showing the old composer or banner after returning, and the `NOT_BLOCKER` outcome never updates it.

### Pitfall 8: The empty-state "Send a message" button is dead on a blocked thread
`ChattingEmptyState` always shows a "Send a message" capsule that focuses the composer [VERIFIED: ChattingView.swift:129, ChattingEmptyState.swift]. When the banner replaces the composer, the button does nothing. 07-UI-SPEC EM2 says the empty state stays; the planner should hide the capsule (not the message) whenever the composer is not shown.

### Pitfall 9: A second send while one is in flight, and out-of-order acks
Concurrent sends can ack in any order. The bubble keeps its append position (local rows sort after server rows), and a later reload re-sorts by server `createdAt`. Do not re-sort on ack beyond the reducer's `order` rule.

### Pitfall 10: Failure kinds
- `NetworkError.httpError(status < 500)`: remove bubble, restore text, alert (A3), or banner for the two 403 codes. `status >= 500`, `URLError`, `decodingFailed`, `invalidResponse`: Failed bubble (Android's split at 500 [VERIFIED: ChatThreadViewModel.kt `SERVER_ERROR_FROM`]).
- The request timeout is 120 s [VERIFIED: NetworkService.swift:63], so "Sending…" can last up to two minutes on a dead network before it flips to Failed. See Open Question 3.
- Restoring text puts it **ahead of** anything typed since, separated by a newline, then capped (Android `restoreToComposer`), so a refused message is never lost and a new draft is never overwritten.
- The send `Task` created in the view keeps running if the user leaves; a failure after the screen closed has no bubble to show. D-02 accepts this; Android additionally returns the text on the next open (its WR-03), which is out of scope here.

### Pitfall 11: `try?` and write paths
`hydrateIdentityIfNeeded` already uses `try?` for reads. Do not use `try?` for send, block, unblock or report; they must surface errors (project convention).

## Code Examples

Shapes only. Values are quoted above; copy strings come from 07-UI-SPEC.

```swift
// Source: port of ClickMe_Android .../chatting/ThreadReducer.kt (read this session)
nonisolated enum ChatThreadReducer {
    /// A pending own bubble is appended; local rows always sort after server rows.
    static func appendLocal(_ items: [ChatItem], _ message: ChatMessage) -> [ChatItem]
    /// Same bubble id, now carries serverId + server timestamp; Read stays Read.
    static func ack(_ items: [ChatItem], clientMsgId: String, serverId: UUID, timestamp: Date) -> [ChatItem]
    static func fail(_ items: [ChatItem], clientMsgId: String) -> [ChatItem]    // sending -> failed
    static func retry(_ items: [ChatItem], clientMsgId: String) -> [ChatItem]   // failed -> sending
    static func remove(_ items: [ChatItem], clientMsgId: String) -> [ChatItem]  // never removes a serverId row
    static func mergePage(_ items: [ChatItem], page: [ChatItem]) -> [ChatItem]  // serverId, then own clientMsgId
    static func onIncoming(_ items: [ChatItem], _ message: ChatMessage, myId: UUID?) -> [ChatItem]
    static func markRead(_ items: [ChatItem], ids: Set<UUID>) -> [ChatItem]
    static func unreadPeerIds(_ items: [ChatItem], alreadyEmitted: Set<UUID>) -> [UUID]
}
```

```swift
// Send outcome mapping (thread VM wiring). Codes are the verified ErrorCase values above.
catch let error {
    switch BookingErrorMapper.code(for: error) {
    case .threadBlocked?:        // 403: remove bubble, restore text, rescan block state, banner
    case .recipientUnavailable?: // 403: remove bubble, restore text, banner "This user is unavailable."
    default:
        if case let NetworkError.httpError(status, _) = error, status < 500 {
            // other 4xx: remove bubble, restore text, "Couldn't send message" alert via error.userMessage
        } else {
            // network error, 5xx, decode failure: ChatThreadReducer.fail -> Failed bubble
        }
    }
}
```

```swift
// Unit-test shape for the retry rule (Swift Testing, stubbed API, .serialized suite).
// Source for the helper: ClickMe2026Tests/Support/URLRequest+Body.swift (jsonBodyForTest)
let sends = MockURLProtocol.recordedRequests.filter { $0.url?.path.hasSuffix("/send") == true }
let ids = sends.compactMap { $0.jsonBodyForTest()?["client_msg_id"] as? String }
#expect(ids.count == 2 && ids[0] == ids[1])
```

## State of the Art

| Old (iOS today) | Target | Impact |
|-----------------|--------|--------|
| Wait for ack, composer disabled while sending | Optimistic pending bubble, several in flight | CHAT-01 |
| Chat report sends display labels | Sends `UserReportReason.rawValue` | CHAT-02 (the backend accepts any string, so mixed moderation data today) |
| Unblock shown on every blocked state | §5 matrix, blocker only | CHAT-03 |
| Block copy claims profile and booking hiding | Chat-only, "They won't be notified" | CHAT-04 / D-05 |
| Unread count ignored by the row | Pill + local math | CHAT-07 |

**Deprecated here:** the profile's combined Report & Block sheet (replaced by the alert), `ReportChatViewModel.defaultReasons` labels, the `unblockDenied` latch, the `isSending` composer spinner.

## Runtime State Inventory

Not a rename or migration phase. Omitted per the protocol. For completeness: no stored data changes (failed bubbles are memory-only, D-02), no live-service config, no OS-registered state, no secrets or env var names, and no build artifacts change.

## Android parity (checked this session against `../ClickMe_Android`)

| Item | Finding | Android change? |
|------|---------|-----------------|
| Block-card copy | `block_card_body`, `blocked_by_peer_body`, `unblock_body`, `block_dialog_message`, `unblock_error_not_blocker` are chat-only and match 07-UI-SPEC [VERIFIED: res/values/strings_chat_report_block.xml:6-26] | none |
| Unread badge | Android overlays a session-local count on the server count (`localUnread` in `ConversationsViewModel`) and clears it on open [VERIFIED: ConversationsUiState.kt:16-32, ConversationsViewModel.kt:171,208] | none (iOS D-12 / D-13 mutate the count directly; the user chose that) |
| `message.read` on `loadEarlier` | Android already calls `emitPendingReads()` after each `loadEarlier` page [VERIFIED: ChatThreadViewModel.kt:352] | none |
| Read emission while offline | Android holds ids until the socket is `Connected` [VERIFIED: ChatThreadViewModel.kt:394-400] | none; this is an iOS gap (Pitfall 4) |
| Block-state re-read | Android re-reads on screen shown and `ON_RESUME` [VERIFIED: `onScreenShown`/`refreshBlockState`] | none |

**Cross-repo summary:** no Android edit is required by Phase 7, and no backend edit. If the D-18 device check reveals that the Android expert shell also mis-routes, that would be a separate Android commit; the todo says Android already uses `ExpertBookingSummaryKey`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `JSONDecoder` `.iso8601` in `RealtimeService` decodes fractional-second `message.new` timestamps on iOS 18 devices. Proven only on the macOS 26 host toolchain this session (all four formats decoded); the shipped app's working live messages and the user's D-17 re-test are consistent with it | Pitfalls (context for D-13) | If false, `message.new` would never decode and neither the thread nor the list +1 would fire; a device row (C6) would show it immediately |
| A2 | `ChatPresence` can become `@Observable` without breaking `PushForegroundPolicyTests` | Pattern 5 | Test compile failure; mitigated by keeping the API unchanged and running that suite |
| A3 | The booking event's `event_data` carries `client_id` and `expert_id` (taken from a doc comment in `ChattingViewModel`, not from a live payload) | Pattern 7 | Only affects the optional per-viewer route in Open Question 2 |
| A4 | A delayed second `silentReload` after pop is not needed | Pitfall 6 | Badge may flicker back for users who leave a thread within about a second; caught by C6 |
| A5 | Scanning up to 3 pages of `GET /chats?limit=100` is enough to find any thread | Pattern 2 | A user with more than 300 threads could miss a block state; the composer stays normal and the server still rejects the send |
| A6 | Making the profile-block confirm an `.alert` (UI-SPEC) shows correctly from a `Menu` source on iPad | Pattern 6 | Presentation only; checked by C3 |

## Open Questions (RESOLVED)

1. **Hold `message.read` until the socket is connected (Pitfall 4).** D-16 only says to emit on every page. The silent-drop behaviour is verified in the library source and Android already guards against it. Recommendation: include it (expose `isConnected` on `RealtimeService`, `emittedReadIds` in the thread VM, replay on connect). Low cost, no contract change. Needs the planner's go-ahead because it widens D-16 slightly.
   - **Disposition:** taken in plan 07-03 (Task 2: `RealtimeService.isConnected` and `onConnect`, `emittedReadIds`, replay on connect).
2. **Dual-role users in the D-18 route.** A user in the expert shell can have a booking where they are the client (and vice versa in the client shell, where `.expertBookingSummary` is an `EmptyView`). The shell flag is right for single-role threads. If the device check shows dual-role breakage, route by comparing `event_data.expert_id` with the signed-in user id and add the expert case to the client shell. Recommendation: shell flag only for this phase (the CONTEXT's instruction); log the edge.
   - **Disposition:** shell flag only (plan 07-09 Task 2); the dual-role edge is logged as a pending todo by plan 07-09 Task 3 and not built.
3. **Send timeout.** The 120 s request timeout (`NetworkService.swift:63`) delays the Failed state on a dead connection. A per-request shorter timeout (about 15 to 20 s) would show Failed sooner, and retry is idempotent so a late success is harmless. Needs a small `NetworkService` option; not required by any decision. Recommendation: leave at 120 s unless the C1 device check feels wrong, because a shorter timeout creates duplicate-delivery risk that only the dedupe covers.
   - **Disposition:** keep the 120 s timeout this phase (plan 07-01 assumptions). Device check C1 records how it feels, as a KEEP or CHANGE item in the 07-08 checklist; a CHANGE answer becomes a follow-up todo, not a Phase 7 code change.
4. **Seed from `ChatPreview`.** Adding `isBlocked` / `blockedByMe` to `ChatPreview` and a `ChatView` init parameter avoids a one-frame composer before the banner. Optional polish; UI-SPEC L2 accepts the flash.
   - **Disposition:** not taken (plan 07-03 assumptions); UI-SPEC L2 accepts the composer showing until the scan answers.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / `xcodebuild` | All iOS plans | yes | Xcode 26.5 (17F42) | none |
| iOS Simulator `iPhone 17` | Test commands | yes (one `iPhone 17` listed; UUID `41616BCF-5D20-4046-8DDB-38B1A084BC7E`) | iOS runtime from Xcode 26.5 | Pass the device UUID if `name=iPhone 17,OS=latest` is ambiguous |
| Backend repo / Node | Not needed (no backend change) | n/a | — | — |
| Real iPhones, two test accounts (one client, one expert) | Device UAT C1 to C10 | user-supplied | — | Realtime checks cannot be done in the simulator |
| New SPM packages | none | n/a | — | — |

**Missing dependencies with no fallback:** none for automated work. Device checks need the user's phones.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`), target `ClickMe2026Tests`; `MockURLProtocol` for HTTP [VERIFIED: 06-VALIDATION.md, ClickMe2026Tests/Support] |
| Config file | `ClickMe2026/AllTests.xctestplan`; the test group is a file-system-synchronized group, so new files under `ClickMe2026Tests/` need no project edit [VERIFIED: `grep -c PBXFileSystemSynchronizedRootGroup project.pbxproj` = 6] |
| Quick run command | `set -o pipefail; xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests/<Suite> 2>&1 \| tee /tmp/<log> \| tail -30 && grep -Eq 'Test run with [1-9][0-9]* tests? in [0-9]+ suites? passed' /tmp/<log>` (form copied from 06-VALIDATION.md) |
| Full suite command | Same with `-only-testing:ClickMe2026Tests -skip-testing:ClickMe2026Tests/AuthSmokeTests -skip-testing:ClickMe2026Tests/SignupSmokeTests` and `MakeABookingAvailabilityTests.swift` added to `EXCLUDED_SOURCE_FILE_NAMES` (known flake). Smoke suites hit production: never run |
| Build gate | `xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` then `BUILD SUCCEEDED` and no new warnings in touched files (before/after `comm -13`) |
| Rules | A run counts only with a non-zero test count; `MockURLProtocol` suites are `.serialized`; one suite per `xcodebuild` in task runs; suites that never call the API must not use `APITestFactory` (STATE 02-07) |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command / Suite | File Exists? |
|--------|----------|-----------|---------------------------|--------------|
| CHAT-01 | Reducer: append, ack keeps bubble id, fail, retry, remove (never a server row), mergePage by serverId then clientMsgId, Read never regresses, order (server by time, local last) | unit (pure) | `ChatThreadReducerTests` | Wave 0 |
| CHAT-01 | Send: pending appended before the request completes; composer cleared; URLError -> Failed; 5xx -> Failed; retry resends the **same** `client_msg_id`; ack replaces in place; 4xx -> removed, text restored ahead of a new draft, alert | unit (stubbed, `.serialized`) | `ChattingViewModelSendTests` | Wave 0 |
| CHAT-01 | Reload keeps pending and failed bubbles | unit (stubbed) | `ChattingViewModelSendTests` (reload rows) | Wave 0 |
| CHAT-01 / D-04 | Cap at 10,000 UTF-16, emoji not split, counter from 9,000, `{n} / 10,000` text | unit (pure) | `ChatComposerRulesTests` | Wave 0 |
| CHAT-02 | Report POST body has `reason == rawValue` for each of the six cases; `details` cut to 1,000 UTF-16 and trimmed; 429 mapping | unit (stubbed, `.serialized`) | `ReportChatViewModelTests` | Wave 0 |
| CHAT-03 | `ChatBlockState`: §5 matrix, §6 transitions, NOT_BLOCKER, legacy, scan with thread not listed, blocked beats unavailable, menu entry | unit (pure) | `ChatBlockStateTests` | Wave 0 |
| CHAT-03 | `ChatThreadItem` decodes with `blocked_by_me` missing -> false | unit | `ChatThreadItemDecodingTests` | Wave 0 |
| CHAT-03 | THREAD_BLOCKED / RECIPIENT_UNAVAILABLE on send -> banner state, bubble removed, rescan request issued | unit (stubbed) | `ChattingViewModelSendTests` | Wave 0 |
| CHAT-04 | Profile block helper: `POST /chats/initiate` then `POST /chats/:id/actions {"action":"block"}`, in that order, once; 404 -> "This user is unavailable."; repeat taps ignored | unit (stubbed, `.serialized`) | `ProfileBlockActionTests` | Wave 0 |
| CHAT-04 | Block copy has no profile or booking claim | grep gate | `! grep -rniE "see your profile|book appointments" ClickMe2026/Views/Screens/Chat ClickMe2026/Views/Screens/Client\ Mode/Expert\ Profile` | n/a |
| CHAT-05 | After open, `peerUserId` equals `partner.id` before any message; admin rows never set it; typing guard has an id | unit (stubbed) | `ChattingViewModelOpenTests` | Wave 0 |
| CHAT-06 | `loadEarlier` page overlapping page 1 adds only new rows | unit (pure + stubbed) | `ChatThreadReducerTests`, `ChattingViewModelOpenTests` | Wave 0 |
| CHAT-07 | Label `99+`, VoiceOver label, hidden at 0; open -> 0; peer message on a closed thread -> +1 and top; open thread -> no +1; own sender -> no +1; reload resyncs | unit | `ChatUnreadRulesTests`, `ChatConversationsUnreadTests` | Wave 0 |
| D-16 | Read ids are emitted per page (inject the emit closure), not re-emitted, held until connected (if Open Question 1 is accepted) | unit | `ChattingViewModelReadEmitTests` | Wave 0 |
| D-18 | Route function: expert shell -> `.expertBookingSummary`; client shell keeps `.bookingSummary` / `.upcomingBooking` | unit (pure) | `ChatBookingRowRouteTests` | Wave 0 |
| CHAT-08 | "Read" label live between two devices | manual only (realtime, two accounts) | Device UAT regression row C6 | n/a |

### Sampling Rate
- **Per task commit:** the one suite for the touched type (quick run).
- **Per plan wave:** suites touched in the wave + build gate + regressions `PushForegroundPolicyTests`, `HomeNavigationPathTests`, `ToastCenterTests`, `ExpertBookingNoteViewModelTests` (shares the cap pattern).
- **Phase gate:** full suite green, grep gates pass, device UAT checklist C1 to C10 run before `/gsd-verify-work`.
- **Estimated runtime:** about 2 to 4 minutes per single-suite run (simulator boot dominates), 4 to 8 minutes for the full suite.

### Wave 0 Gaps
- [ ] `ClickMe2026Tests/Chat/` does not exist (no chat tests today) — create it with the suites above.
- [ ] Test seams on `ChattingViewModel`: identity injection (`myUserId`, `myName`) on the runtime init so no `UserManager.shared` or `/me` stub is needed; an injectable read-emit closure; the incoming-message handlers (`handleMessageNew`, `handleMessageRead`) made `internal` or routed through the reducer. `RealtimeMessageNewEvent` and `RealtimeMessageReadEvent` are plain `Decodable` structs with `let` fields, so `@testable` code can build them with the synthesised initialiser.
- [ ] Same on `ChatConversationsViewModel`: expose the incoming-message and open-thread entry points as `internal`.
- [ ] A small fixture helper for `GET /chats` and `GET /chats/:id/messages` JSON (`ChatFixtures`), in the style of `ClientBookingFixtures`.
- [ ] Framework install: none.

## Security Domain

`security_enforcement` is enabled in `.planning/config.json` (ASVS level 1, block on high). [VERIFIED: config.json]

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (unchanged; existing refresh interceptor) | existing |
| V3 Session Management | no | existing |
| V4 Access Control | yes | Block, Unblock and send are enforced server-side (participant check, `THREAD_BLOCKED`, `NOT_BLOCKER`). The client banner is a UI hint only; never rely on it |
| V5 Input Validation | yes | Cap `content` at 10,000 and `details` at 1,000 on UTF-16 boundaries (server `.max()` 10,000 / 2,000, `.strict()` schemas); send enum raw values for `reason`; the server would accept any string, so the client list is the only guard |
| V6 Cryptography | no | none added |
| V7 Error handling and logging | yes | Do not log message content, tokens or full payloads; wrap any new debug logging in `#if DEBUG` |
| V8 Data protection | yes | Failed message text lives in memory only (D-02); nothing is written to disk or `UserDefaults` |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Duplicate delivery from retry | Tampering | Same `client_msg_id`; server unique constraint returns the existing row, no second emit or push [VERIFIED: chatMessages.js] |
| Unblock by the non-blocker | Elevation of privilege | Server returns `403 NOT_BLOCKER` [VERIFIED: chats.controller.js:511]; client hides the button and handles the code |
| Report spam / moderation abuse | DoS | Shared 10 reports/hour limit, `429 TOO_MANY_REQUESTS`; client shows a clear message and does not auto-retry |
| Self-targeting | Tampering | `CANNOT_BLOCK_SELF`, `CANNOT_REPORT_SELF`, `CANNOT_CHAT_WITH_SELF`: hide Block and Report on self-threads and own profile (existing `isSameAsCurrentUser` guard) |
| IDOR on thread ids | Information disclosure | Server participant checks on send, actions and `message.read`; client only uses ids it was given |
| Sensitive text in logs | Information disclosure | The existing `print("push: TAP received…")` pattern must not be copied into chat flows |

## Sources

### Primary (HIGH confidence, read this session)
- Backend: `src/controllers/chats.controller.js` (list, messages, send, actions, initiate), `src/services/chatMessages.js`, `src/services/socket.js` (`handleMessageRead`), `src/schemas/chat.schema.js`, `docs/SOCKET-CONTRACT.md` §3, §4, §6, `docs/ios/CHAT-UNBLOCK.md` (all), `docs/ios/USER-REPORTING.md` §1 to §3, `supabase/migrations/20260609010000_create_messages.sql`, `src/routes/clientBooking.js`.
- iOS: `ChattingViewModel.swift`, `ChattingView.swift`, `ChattingInputBar.swift`, `ChattingMessageBubble.swift`, `ChattingBrand.swift`, `ChattingEmptyState.swift`, `ChatConversationsViewModel.swift`, `ChatConversationsView.swift`, `ChatConversationRow.swift`, `ReportChatViewModel.swift`, `ReportChatView.swift`, `ReportChatBlockCard.swift`, `ReportChatReportCard.swift`, `ReportChatReasonField.swift`, `ReportChatDescriptionField.swift`, `ExpertProfileView.swift`, `ChatDisplayModels.swift`, `ChatThreadItem.swift`, `ChatMessageItem.swift`, `ClickMeAPI+Chats.swift`, `ClickMeAPI.swift` (payloads), `RealtimeService.swift`, `RealtimeEvents.swift`, `ChatPresence.swift`, `ToastCenter.swift`, `UserReportReason.swift`, `ErrorCode.swift`, `UTF16Prefix.swift`, `Error+UserMessage.swift`, `BookingErrorMapper.swift`, `NetworkService.swift`, `HomeNavigationPath.swift`, `HomeClientView.swift`, `HomeExpertView.swift`, `ExpertBookingNoteViewModel.swift`.
- Android: `ThreadReducer.kt`, `BlockState.kt`, `TextCap.kt`, `ChatThreadViewModel.kt`, `ChatsRepository.kt`, `ConversationsUiState.kt`, `ConversationsViewModel.kt`, `strings_chat_report_block.xml`.
- Library: `socket.io-client-swift` `SocketIOClient.swift:309-313` (emit while not connected).
- Project: 07-CONTEXT.md, 07-UI-SPEC.md, REQUIREMENTS.md, STATE.md, IOS-BUG-INVENTORY.md (H1 to H9, Q8), 06-VALIDATION.md, todo `2026-11-16-expert-chat-row-opens-client-booking-screen.md`.

### Secondary / Tertiary
- None. No web search was needed; no external documentation is involved. The research-plan and package-legitimacy seams were not run because no external library or package is in scope.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, because nothing new is added and every reused symbol was opened.
- Architecture: HIGH for the reducer and block state (ports of shipped, tested Android code against a contract read in the backend); MEDIUM for the `ChatPresence` observation change (Assumption A2).
- Pitfalls: HIGH, each tied to a file and line read this session; Pitfall 6 is a prediction.

**Research date:** 2026-11-17
**Valid until:** 2026-12-17 (stable; revisit if the backend chat controller or the socket contract changes)
