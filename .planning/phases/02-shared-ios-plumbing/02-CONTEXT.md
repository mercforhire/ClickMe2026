# Phase 2: Shared iOS Plumbing - Context

**Gathered:** 2026-11-09
**Status:** Ready for planning

<domain>
## Phase Boundary

The app-wide rules that many iOS screens rely on are fixed in one shared place: call lifetime (CALL-01, CALL-04, CALL-05), the join window (CALL-02), trusted meeting-provider detection (CALL-09), money formatting (BOOK-10), booking-status decoding (BOOK-18), booking error codes and the 6-day picker cap (BOOK-14, PAY-05), and push routing (PUSH-01 to PUSH-04, BOOK-15, CHAT-09). iOS repo only. The backend contract was delivered in Phase 1 and is not changed here unless research finds a gap. In that case, say so, and make the change in the backend repo as a separate commit that stays safe for build 6 and current Android. CALL-01 is planned first.

</domain>

<decisions>
## Implementation Decisions

### Q3: long-lead SCA recovery (BOOK-15)
- **D-01:** **Q3 is settled as route only.** A tap on a `booking/payment_actions` push (`PAYMENT_ACTION_REQUIRED`) opens that booking's detail screen, as Android does. iOS does not build a recovery flow and does not call `POST /bookings/:id/recover-payment`. If the client does nothing, `scaRecoveryWindowSweep` cancels the booking. Reason: only paid long-lead bookings made before 2026-10-28 can reach this path, and that group shrinks every day. Update the BOOK-15 row in REQUIREMENTS.md and the Q3 row in ROADMAP.md to record the outcome.

### Push taps and mode switching (PUSH-01, PUSH-02, PUSH-03)
- **D-02:** When the push's `target_role` differs from the current mode, the app **switches mode silently** and then routes. It shows no confirmation. A missing `target_role` keeps the current mode (contract, Phase 1 D-02).
- **D-03:** When `target_role` is `expert` but the account can't use expert mode (it doesn't hold the expert role, or expert setup isn't complete), the app **stays in client mode and opens the notifications list**. It never forces a half-set-up account into expert mode. The Phase 5 SIGN-06 setup-hub gate is out of scope here.
- **D-04:** A destination opens on the **stack of the tab that owns it**: the app switches to that tab, resets its stack and pushes the destination, so Back returns to the tab's root. Examples: booking detail and leave-review on Bookings, a chat thread on Chats, account security and payouts on Profile, incoming requests on the expert tab that holds them. Every route pushed onto a stack must be registered on that stack's `navigationDestination`. Missing registration is the CR-01 failure: build 6 pushed `HomeRoute` onto a Bookings stack that only registers `BookingRoute`, and the user saw SwiftUI's warning page.
- **D-05:** iOS routes on `route_category` and `route_sub_category`, with `event_type` as a fallback for chat pushes. It must not read `category`, because the backend keeps sending `category` to Android only while build 6 is in use. An empty or unknown category opens the notifications list (PUSH-01). A `booking/requests` push opens that request by `booking_id` (PUSH-03).

### Logout push unregistration (PUSH-04)
- **D-06:** On logout, the app captures the device id and push token first, then **awaits** the unregister call with a short timeout, and only then clears the bearer token and the session. If the call fails or times out, logout still goes ahead. The pending unregister is saved and retried on the next launch or login. **Research flag:** `DELETE` needs the old account's bearer token, and that token is gone after logout. The researcher must check the backend device-token routes (`device_tokens` uniqueness on `device_id`, and whether a register from a new login rebinds the row) and pick a retry that actually works. Example: keep the old refresh token only long enough to make the retry. Another: rely on the next account's register replacing the row, if the backend keys rows by `device_id`. Report it if a working retry needs a backend change.

### Join button and overtime ending (CALL-01, CALL-02)
- **D-07:** Join visibility uses **one shared local rule plus the server reconnect flag**. The local CALL-02 rule, [start − 60 min, max(end, start + 60 min)], decides the first join, so the button updates live as time passes. After the scheduled end, the button stays available until end + 60 when the server's `can_join` says the user may reconnect, based on that party's joined_at (Phase 1 D-03/D-06). The server keeps the final say on `/join`. `pendingApproval` never opens the window. The rule lives in one shared helper that replaces `UpcomingBooking.isWithinJoinWindow` and the expert-side local windows (Phase 3 wires the remaining screens to it). **Research flag:** `can_join` is returned on client booking detail and on the expert list and detail. Check whether the client bookings list returns it. Where it's missing, the list uses the local rule only.
- **D-08:** CALL-01 restores the overtime cutoff to **end + 60 min** (revert the TEMP `5 * 60` in `MeetingCallViewModel.swift:532`). At **end + 55** the call shows a small in-call notice ("This call will end in 5 minutes"). At end + 60 it ends through the normal end path and reaches the Ended screen.

### Money display (BOOK-10)
- **D-09:** One shared formatter takes minor units and a currency code, and **always shows the currency's full minor digits**: $12.00, $12.50, ¥1200. It never drops `.00`.
- **D-10:** Symbols are **disambiguated with fixed formatting, not the device locale**: `$` for USD and `CA$` for CAD, matching the backend's BACK-05 `consultation_fee.label`. Other currencies get an unambiguous symbol or their ISO code.
- **D-11:** Phase 2 builds the formatter **and converts every `/100` money display site**, on the client and expert sides (about 13 files, including `BookingTopic`, `UpcomingBookingViewModel`, `ExpertProfileViewModel`, `ExploreClientViewModel`, `BookingSummaryViewModel`, `ClientCancellationViewModel`, `ExpertDashboardViewModel`, `PayoutsViewModel`, `TopicsSetupTopicCard` and `IncomingRequestsViewModel`). Topic price **input** parsing in `TopicEditorViewModel` (decimals, the topic's own currency) belongs to Phase 6 (EXP-02, EXP-03). Phase 2 only routes that file's display through the formatter. The `/100` in Splash shapes is not money.

### Plan-phase decisions (2026-11-09, after research)
- **D-12:** The shared join-window helper **follows the server's joinable statuses** (`confirmed`, `in_progress`, `completed`). `pending_reschedule` is not joinable, so Join disappears for those bookings on the Explore and expert dashboard strips. List this in the Phase 2 UAT as an intentional change.
- **D-13:** The BOOK-14 6-day cap applies to the **client** paid booking and reschedule pickers in Phase 2. The shared error mapper handles the long-lead codes on both sides. The **expert** reschedule picker cap ships with EXP-13 in Phase 3.
- **D-14:** CALL-05 closes on a **unit-tested Agora connection-state mapping** (`.failed` → Ended) plus a regression check on one normal call on the device. The UAT does not include a 20-minute airplane-mode repro.
- **D-15:** Phase 2 is planned **without a UI-SPEC** (`--skip-ui` equivalent). It changes logic and copy, not layouts. The only new UI is the CALL-01 in-call notice at end + 55, which uses the existing call-screen styling.
- **D-16:** When `route_category` is missing, the `event_type` fallback uses **Android's full event_type table** (chat, booking, payout, account and review types), not chat only. This widens D-05 to match Android. Anything still unmatched opens the notifications list.
- **D-17:** The PUSH-04 cleanup retries only at **launch and login**. The user **accepts the residual window** after an offline logout: the old account's pushes can arrive until the next launch or login. There is no foreground retry.
- **D-18 (amends D-06):** The saved retry covers **Firebase `deleteToken` only**. The server `DELETE /notifications/tokens/:device_id` is not retried, because the old bearer is gone after logout. The backend evicts the token when another account registers it and deletes dead tokens on send (research Pattern 9). Together with D-17, this is the accepted PUSH-04 design.
- **D-19 (amends D-11):** Phase 2 may touch the `TopicEditorViewModel` **save path for one purpose only**: when the price field still holds its lossless seed, the save sends the topic's **stored minor amount and stored currency** unchanged, so an untouched save never re-prices a topic. Decimal input parsing and choosing a currency for typed prices stay in Phase 6 (EXP-02, EXP-03).

### Claude's Discretion
- **Unknown booking status (BOOK-18):** `BookingStatus` gets `rescheduled` and an unknown fallback case, so decoding never fails. A realtime `booking.update` with an unknown or `rescheduled` status refetches the open booking, and the screen shows a neutral label until the refetch finishes.
- **Error copy (PAY-05, BOOK-14):** one shared booking error mapper, used by the paid and free paths, branching on `ErrorCode`. The paid path's copy is the base. Add `LONG_LEAD_NOT_AVAILABLE` and `RESCHEDULE_TOO_FAR_AHEAD` with clear copy, and remove the fall-through to `performLongLeadBooking` (`MakeABookingViewModel.swift:458`).
- **6-day cap (BOOK-14):** paid booking and reschedule pickers hide slots and days beyond now + 6 days, rather than showing them disabled.
- Cold-launch push taps are queued until the shell and mode are ready, then routed.
- The full category-to-destination table follows `docs/ios/PUSH-ROUTING.md` and the existing `PushRouter.destination(for:)` map.
- **CHAT-09:** the foreground banner is suppressed only when the push's `thread_id` matches the chat thread on screen.
- **CALL-04:** send at least 1 second on `/end`. **CALL-05:** confirm on a device first; if it reproduces, handle Agora connection failed or aborted in `AgoraManager`. **CALL-09:** host equals the domain or ends with `.domain`, with no raw-string fallback.
- Where the shared helpers live (for example under `Utils/` or `Model/UIModels/`), and how they're split for unit tests.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and inventory
- `.planning/ROADMAP.md` (Phase 2 section): goal, success criteria, notes, Q3 row
- `.planning/REQUIREMENTS.md`: CALL-01, CALL-02, CALL-04, CALL-05, CALL-09, BOOK-10, BOOK-14, BOOK-15, BOOK-18, PAY-05, PUSH-01 to PUSH-04, CHAT-09
- `.planning/IOS-BUG-INVENTORY.md`: rows C1, C2, C4, C5, C9, B10, B14, B15, B18, P6, H9, N1 to N4 (file:line evidence)
- `.planning/STATE.md`: Pending Todos (the PUSH-01 `route_category` and stack-registration rule), Phase 1 decisions on BACK-09, BACK-15, BACK-17
- `.planning/phases/01-backend-fixes/01-CONTEXT.md`: D-01 to D-06 (push contract, join gate, cron)

### Backend contract (in `../ClickMe2026 Backend`)
- `docs/ios/PUSH-ROUTING.md`: push data keys, `route_category` versus `category`, `target_role` rules, the sender table, build 6 behavior. **Must read for PUSH-01 and PUSH-02.**
- `docs/ios/CALL-END-SEMANTICS.md`: `/end` semantics (CALL-04, overtime)
- `docs/ios/RESCHEDULE-PAYMENT-CONVERSION.md`: long-lead and reschedule payment rules (BOOK-14)
- `docs/SOCKET-CONTRACT.md`: the `booking.update` statuses, including `rescheduled` (BOOK-18)
- `openapi/clickme-api.yaml`: error code enum (`LONG_LEAD_NOT_AVAILABLE`, `RESCHEDULE_TOO_FAR_AHEAD`, `SESSION_NOT_ACTIVE`), the `can_join` fields, the device-token routes (PUSH-04)
- `src/services/agora.js`, `src/controllers/call.controller.js`: the `/join` two-tier gate (D-07)
- `src/controllers/clientBooking.controller.js` (~L1119), `src/controllers/expertBooking.controller.js` (~L292, ~L399): where `can_join` is computed
- `src/utils/reschedule.js` (~L76-83), `src/controllers/booking.controller.js` (~L477, ~L718): the long-lead and 6-day refusals
- `src/schemas/call.schema.js` (~L29): `/end` duration `.positive()` (CALL-04)

### iOS code touched
- `ClickMe2026/Views/Screens/Call/Calling/MeetingCallViewModel.swift` (~L527-533 cutoff, ~L689 `/end` duration)
- `ClickMe2026/Model/UIModels/UpcomingBooking.swift` (~L62 `isWithinJoinWindow`)
- `ClickMe2026/Managers/AgoraManager.swift` (~L276, CALL-05)
- `ClickMe2026/Views/Screens/Call/Calling/ExternalMeetingProvider.swift` (~L40, CALL-09)
- `ClickMe2026/Model/Enums/BookingStatus.swift`, `ClickMe2026/Realtime/RealtimeEvents.swift` (~L56)
- `ClickMe2026/Model/Enums/ErrorCode.swift`, `ClickMe2026/Views/Screens/Client Mode/Make a Booking/MakeABookingViewModel.swift` (~L396, ~L452-462, ~L600-630)
- `ClickMe2026/Model/Push/PushEvent.swift`, `ClickMe2026/Managers/PushRouter.swift`, `ClickMe2026/ClickMe2026AppDelegate.swift` (~L149-189)
- `ClickMe2026/Views/Screens/Client Mode/Home/HomeClientView.swift` (~L128-171), `ClickMe2026/Views/Screens/Expert Mode/Home/HomeExpertView.swift` (~L81-132)
- `ClickMe2026/Managers/UserManager.swift` (`logout()` ~L293, `unregisterPushTokenIfAny()` ~L652)
- `ClickMe2026/Model/Responses/Children/CurrencyItem.swift` (`minorUnitDigits`)
- `ClickMe2026/Views/Screens/Notification/NotificationsListView.swift`: the fallback destination

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PushRouter.destination(for:)` already maps booking, session, message, review, payout and account to `PushDestination` cases, including `.notificationsList`. Phase 2 makes `PushEvent` feed it from `route_category` and adds the mode switch and the nil fallback.
- `PushRouter.pendingDestination` is observed by both home shells, which is the hook for D-04 tab selection.
- `CurrencyItem.minorUnitDigits` exists but nothing uses it. The formatter can use it, or a local ISO 4217 digits table.
- `ExpertBookingDetail.actions.canJoin` and `ExpertBookingItem.canJoin` are already decoded on the expert side.
- `Error.userMessage` (`Network/Error+UserMessage.swift`) and `ErrorCode` are the base for the shared booking error mapper.

### Established Patterns
- Managers and view models are `@MainActor`, under Swift 6 strict concurrency. Shared formatters must be callable from views and view models with no isolation errors.
- Each tab owns its navigation path (`HomeNavigationPath`), and routes are typed `Hashable` values. Registering every route on each stack is the CR-01 lesson.
- Branch on `ErrorCode`, never on the message string.
- Swift Testing (`#expect`) for unit tests: the overtime cutoff, the join window, the formatter, status decoding, provider host matching, error mapping, push parsing and routing.

### Integration Points
- Push: AppDelegate → `PushEvent` → `PushRouter` → `UserManager` mode switch → home shell tab and stack.
- The join helper is used by client and expert booking screens. Phase 3 wires the remaining screens (CALL-03, CALL-08, CALL-10).
- The formatter is used by Phases 3, 4 and 6 afterwards.
- The logout path in `UserManager` is shared with suspension and the auth-rejection logout.

</code_context>

<specifics>
## Specific Ideas

- CR-01 (2026-11-08, device-reproduced) is the regression to guard against: a pushed route with no registered destination shows SwiftUI's warning page. A test or checklist step should cover a booking push tap in client mode and in expert mode.
- The overtime warning text: "This call will end in 5 minutes".
- Money examples: $12.00, $12.50, CA$12.50, ¥1200.

</specifics>

<deferred>
## Deferred Ideas

- Long-lead SCA recovery UI (`recover-payment` with 3D Secure on iOS): not built, by Q3 decision D-01.
- Topic price input with decimals and the topic's own currency: Phase 6 (EXP-02, EXP-03).
- Gating Expert mode on complete setup: Phase 5 (SIGN-06).

### Reviewed Todos (not folded)
- "Check the Android push prompt after a reinstall": Android-repo work, not iOS plumbing. Stays pending.
- "Show the suspension message on a cold launch": an auth/splash issue, not yet reproduced, and outside this phase's push and call scope. Stays pending.

</deferred>

---

*Phase: 02-shared-ios-plumbing*
*Context gathered: 2026-11-09*
