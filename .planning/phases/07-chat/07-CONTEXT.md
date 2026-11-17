# Phase 7: Chat - Context

**Gathered:** 2026-11-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the existing iOS chat so messages appear immediately and can be retried, block state is obvious to both sides, unread state is visible on conversation rows, and chat reports reach the backend as enum values. Requirements: CHAT-01 to CHAT-08 (CHAT-09 was delivered in Phase 2). Plus the folded todo: expert-mode chat booking rows open the wrong screen.

In scope: optimistic send with failed/retry state and a composer cap (CHAT-01), report-reason enum on chat reports (CHAT-02), blocked-thread composer banner and Unblock rules (CHAT-03), profile Block confirm dialog and truthful block copy (CHAT-04), seeding the peer id on open (CHAT-05), de-duplicated `loadEarlier` (CHAT-06), unread badge on conversation rows (CHAT-07), and the expert chat-row routing fix.

**CHAT-08 is closed as not reproducible.** The user re-tested the live "Read" label on devices after Phase 1 shipped and it works (Q8 settled 2026-11-17). No fix plan; the device UAT keeps one regression row for it.

Not in scope: any backend change (the backend already increments and resets `unread_count` per BACK-18, lists empty threads per BACK-16, and enforces block only on chat). Enforcing block on profiles or bookings, a Chats tab badge, an offline send queue, and a backend mark-all-read are all out (see Deferred).

Android: Android Phase 12 already implements most of this behaviour, and iOS is catching up to it. Where Android ported iOS behaviour that this phase changes (the block-card copy, the unread badge, or `message.read` on `loadEarlier`), the researcher checks `../ClickMe_Android` and flags any matching Android change, which is committed separately in that repo.

</domain>

<decisions>
## Implementation Decisions

### Send, failure and retry (CHAT-01)
- **D-01:** **Copy Android 12 D-01.** A sent message appears immediately as a pending bubble keyed by `client_msg_id`. On a network error or 5xx it stays in place, dimmed, with a red "!" and "Not sent. Tap to retry". Retry reuses the **same `client_msg_id`** so the server removes duplicates. A long-press offers Delete, which removes the bubble locally. The send ack replaces the pending bubble by `client_msg_id`, and a `message.new` echo or page load with the same server id or `client_msg_id` never creates a duplicate.
- **D-02:** **No offline queue (Android D-02).** Failed bubbles live in memory only and are gone when the thread closes or the app restarts.
- **D-03:** **403 `THREAD_BLOCKED` / `RECIPIENT_UNAVAILABLE` on send (Android D-03):** remove the pending bubble, put its text back in the composer, reload this thread's block state from `GET /chats` (CHAT-UNBLOCK §6), and switch the composer to its banner state (D-07). `RECIPIENT_UNAVAILABLE` shows "This user is unavailable."
- **D-04:** **Composer cap at 10,000 characters** (backend `chat.schema.js` `content: z.string().min(1).max(10000)`), with a character counter shown near the limit, matching Android D-04.

### Block and report (CHAT-02, CHAT-03, CHAT-04)
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

### Thread open (CHAT-05, CHAT-06)
- **D-10:** Seed `peerUserId` from `ChatThreadItem.partner.id` when the thread opens, so typing and View Profile work before any peer message arrives (inventory H5). Keep the existing never-from-admin-rows rule as the fallback.
- **D-11:** `loadEarlier` filters out messages whose server id is already loaded before prepending (inventory H6).

### Unread badge (CHAT-07)
- **D-12:** **Set the row's count to 0 locally when its thread opens.** The next quiet reload of `GET /chats` re-syncs.
- **D-13:** **Add 1 locally** to a row's count on a `message.new` for a thread that isn't open, for peer messages only, never own echoes, along with the existing move-to-top. `GET /chats` corrects any drift.
- **D-14:** **Badge style:** a brand-coloured count pill on the right of the row, "99+" above 99, hidden at 0. The row's name and preview are bold while unread.
- **D-15:** **No Chats tab icon badge** (Android 12 D-16 parity).
- **D-16:** **Send `message.read` for unread peer messages on every page loaded**, including `loadEarlier`, not only page 1. No backend change. Accepted gap: in a thread with more than 30 unread messages where the user never scrolls up, the server count stays above 0 and the badge comes back after a reload (backend 01-14 marks nothing read on open).

### Read label (CHAT-08)
- **D-17:** **Closed as not reproducible** after the user's device re-test on 2026-11-17. No code change. The device UAT keeps one two-device regression row. If that row ever fails, start with the backend (`message.read` delivery: room membership, emit target, thread/message-id check), since BUG-13 was seen in both apps.

### Claude's Discretion
- Exact visuals of the pending, failed and banner states and the counter, using the existing `ChattingBrand` / `Brand` tokens (adapt from Android; no pixel parity). The UI-SPEC phase may refine them.
- The wording and form of the profile-block success confirmation (a toast/overlay or an inline notice).
- At what point the counter appears (Android's threshold is fine).

### Folded Todos
- **Expert-mode chat row opens the client booking screen and fails to load** (`.planning/todos/pending/2026-11-16-expert-chat-row-opens-client-booking-screen.md`, major). `ChattingView.swift:341-343` pushes `HomeRoute.bookingSummary` / `.upcomingBooking`, which load `GET /client/bookings/:id`, so an expert gets a 404. **D-18:** confirm on a device first (as an expert, open a chat that has a booking and tap the booking row). If it reproduces, send expert-mode booking rows to `ExpertBookingSummaryView`, matching Android `ExpertBookingSummaryKey`. iOS only. Use the existing `hostsClientBookingFlows` environment flag or the shell mode to pick the route. Note that Phase 3 stubbed the expert shell routes and hid the client actions rather than rerouting (STATE, Phase 03 entry).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Backend contracts
- `../ClickMe2026 Backend/docs/ios/CHAT-UNBLOCK.md`: `blocked_by_me`, the §5 UI matrix (D-07), §6 local state, §7 legacy blocks (D-08), `NOT_BLOCKER` / `THREAD_BLOCKED`
- `../ClickMe2026 Backend/docs/ios/USER-REPORTING.md`: the report reason enum values (D-09), `RECIPIENT_UNAVAILABLE`, self-targeting guards, the report rate limit
- `../ClickMe2026 Backend/docs/SOCKET-CONTRACT.md`: `message.new`, `message.read`, typing events
- `../ClickMe2026 Backend/src/schemas/chat.schema.js`: send `content` max 10000 (D-04); report `reason` / `details` limits
- `../ClickMe2026 Backend/src/services/socket.js` (message.read handler, around lines 225-275): marks only the listed `message_ids`, which is why D-16 sends per page
- `../ClickMe2026 Backend/src/controllers/chats.controller.js`: send, `client_msg_id` dedupe, `unread_count` recalculation (BACK-18)

### Android reference (behaviour to match)
- `../ClickMe_Android/.planning/phases/12-chat-report-block/12-CONTEXT.md`: D-01 to D-05, D-07 to D-10, D-16 (the source of D-01 to D-07 and D-15 here)
- `../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/chat/chatting/ThreadReducer.kt`, `ChatThreadViewModel.kt`, `ThreadRows.kt`: optimistic send, failed state and reconciliation
- `../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/chat/BlockState.kt`: the §5 matrix in code
- `../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/chat/TextCap.kt`: the composer cap and counter
- `../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/chat/conversations/ConversationsScreen.kt`: the row unread badge

### Project
- `.planning/IOS-BUG-INVENTORY.md` rows H1 to H8 (lines 117-124) and Q8 (line 194)
- `.planning/REQUIREMENTS.md` CHAT-01 to CHAT-08
- `.planning/todos/pending/2026-11-16-expert-chat-row-opens-client-booking-screen.md`: the folded todo (D-18)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ClickMe2026/Model/Enums/UserReportReason.swift`: already used by the profile report (`Expert Profile/Subviews/ReportUserSheet.swift`); reuse it in `ReportChatViewModel` (D-09).
- `ClickMe2026/Model/Responses/Children/ChatThreadItem.swift`: already decodes `unreadCount`, `isBlocked`, `blockedByMe` (optional) and `partner`. D-08 needs `blockedByMe` treated as `false` when missing.
- `ClickMe2026/Views/Screens/Chat/Report and Block/Subviews/ReportChatBlockCard.swift`: the state matrix comment and the copy (lines 20-24, 82-98) to rewrite for D-05, D-07 and D-08.
- `ChattingViewModel.sendMessage()` (line 254) already generates a `clientMsgId` (line 275): this is where the pending bubble starts.
- `ClickMe2026/Managers/ChatPresence.swift`: `visibleThreadId` tells the conversations list which thread is open (D-12, D-13).
- `ClickMe2026/Views/Extensions/HomeNavigationPath.swift`: `hostsClientBookingFlows` environment entry (line 85), used for D-18.

### Established Patterns
- View models are `@MainActor ObservableObject` with `@Published` state and an `apiError` string; errors display through `Error.userMessage`, and branch on `ErrorCode` (add `THREAD_BLOCKED`, `RECIPIENT_UNAVAILABLE` or `NOT_BLOCKER` if missing), never on message text.
- Subviews are prefixed with their screen name (`Chatting…`, `ChatConversation…`, `ReportChat…`). New pieces such as a failed-bubble footer or a blocked banner follow that.
- `ChattingViewModel.swift` is 624 lines: put the send/retry state into a helper type (Android uses a `ThreadReducer`), so it is unit-testable and the view model doesn't grow.

### Integration Points
- `ChattingView.swift:104-127`: the composer is always shown today; D-07 swaps it for the banner.
- `ChattingView.swift:341-343`: booking row navigation (D-18).
- `ChatConversationsViewModel.swift:154,173`: the `message.new` merge keeps the existing `unreadCount`; D-13 changes it to +1 for peer messages.
- `ChatConversationRow.swift`: currently ignores `unreadCount`; the D-14 badge goes here.
- `Client Mode/Expert Profile/ExpertProfileView.swift:246, 420-425` (`handleOpenBlockFlow`): replace the combined-screen route with the D-06 alert.
- `ChattingViewModel.swift:216-227, 373, 429`: `peerUserId` latching (D-10); `loadEarlier` at line 230 (D-11, D-16).

</code_context>

<specifics>
## Specific Ideas

- Profile block alert text: "Block {name}? They won't be able to message you." (Android D-05).
- Banner text: "You blocked this conversation" / "You can't reply to this conversation" / "This user is unavailable." (CHAT-UNBLOCK §5, Android D-03).
- Failed bubble: dimmed, red "!", "Not sent. Tap to retry", long-press Delete (Android D-01).
- Realtime checks need two devices or accounts (ROADMAP note).

</specifics>

<deferred>
## Deferred Ideas

- **Enforce block on the backend** (hide the profile from the blocked user and stop bookings), so a block means more than chat. A new cross-repo capability, rejected for this phase in favour of honest copy (D-05).
- **Backend mark-all-read** (`message.read` with `up_to`, or mark all on thread open), to close the D-16 gap for threads with more than 30 unread. Needs a backend change and a matching Android change.
- **Chats tab total unread badge**: left out for parity (D-15).
- **Offline send queue / failed messages kept across restarts**: left out (D-02).

### Reviewed Todos (not folded)
- `2026-11-13-android-delete-account-copy-and-blockers.md`: account area, Android-only; not chat.
- `2026-11-13-decide-saved-cards-on-account-deletion.md`: account and payments; not chat.
- `2026-11-16-usd-symbol-us-dollar-prefix.md`: money formatting; not chat.

</deferred>

---

*Phase: 07-chat*
*Context gathered: 2026-11-17*
