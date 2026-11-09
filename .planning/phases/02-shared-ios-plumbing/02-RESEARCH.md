# Phase 2: Shared iOS Plumbing - Research

**Researched:** 2026-11-09
**Domain:** SwiftUI / Swift 6 strict concurrency (iOS 18+): call lifetime (Agora RTC 4.6.2), join window, money formatting, tolerant enum decoding, booking error mapping, push routing (FCM/APNs), logout hygiene
**Confidence:** HIGH for what the code, backend and SDK headers say (all read this session). MEDIUM for SwiftUI/FCM runtime behavior that needs a device check (flagged `[ASSUMED]` in the Assumptions Log).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Claude's Discretion
- **Unknown booking status (BOOK-18):** `BookingStatus` gets `rescheduled` and an unknown fallback case, so decoding never fails. A realtime `booking.update` with an unknown or `rescheduled` status refetches the open booking, and the screen shows a neutral label until the refetch finishes.
- **Error copy (PAY-05, BOOK-14):** one shared booking error mapper, used by the paid and free paths, branching on `ErrorCode`. The paid path's copy is the base. Add `LONG_LEAD_NOT_AVAILABLE` and `RESCHEDULE_TOO_FAR_AHEAD` with clear copy, and remove the fall-through to `performLongLeadBooking` (`MakeABookingViewModel.swift:458`).
- **6-day cap (BOOK-14):** paid booking and reschedule pickers hide slots and days beyond now + 6 days, rather than showing them disabled.
- Cold-launch push taps are queued until the shell and mode are ready, then routed.
- The full category-to-destination table follows `docs/ios/PUSH-ROUTING.md` and the existing `PushRouter.destination(for:)` map.
- **CHAT-09:** the foreground banner is suppressed only when the push's `thread_id` matches the chat thread on screen.
- **CALL-04:** send at least 1 second on `/end`. **CALL-05:** confirm on a device first; if it reproduces, handle Agora connection failed or aborted in `AgoraManager`. **CALL-09:** host equals the domain or ends with `.domain`, with no raw-string fallback.
- Where the shared helpers live (for example under `Utils/` or `Model/UIModels/`), and how they're split for unit tests.

### Deferred Ideas (OUT OF SCOPE)
- Long-lead SCA recovery UI (`recover-payment` with 3D Secure on iOS): not built, by Q3 decision D-01.
- Topic price input with decimals and the topic's own currency: Phase 6 (EXP-02, EXP-03).
- Gating Expert mode on complete setup: Phase 5 (SIGN-06).
- Reviewed todos not folded: "Check the Android push prompt after a reinstall" (Android work); "Show the suspension message on a cold launch" (auth/splash, not reproduced).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CALL-01 | Call runs until end + 60 min, not 5 | Pure `CallOvertimePolicy` (cutoff 3600, warn at 3300); server `/end` stays valid until end + 70 (Pattern 1) |
| CALL-02 | Join from start − 60 min to max(end, start + 60 min) | Shared `JoinWindow` helper; backend `evaluateJoinWindow` is the same rule (Pattern 2) |
| CALL-04 | `/end` accepts a 0-second leg | Server schema is `.positive()`; send `max(1, d)` (Pattern 1) |
| CALL-05 | Call screen reaches Ended on Agora failure/abort | Root cause confirmed: `didOfflineOfUid` is remote-only; use `rtcEngine(_:connectionChangedTo:reason:)` with `.failed` (Pattern 1) |
| CALL-09 | Provider detection matches the real host only | Exact-or-suffix host match, no raw fallback (Pattern 3) |
| BOOK-10 | One money formatter, correct decimals | Pure integer-math `Money` enum; 16 display sites listed (Pattern 4) |
| BOOK-14 | 6-day cap on paid booking/reschedule pickers; long-lead codes | `PaidBookingWindow` + two new `ErrorCode` cases (Pattern 6) |
| BOOK-15 | `booking/payment_actions` push opens the booking | Route only (D-01); push table (Pattern 7) |
| BOOK-18 | `rescheduled`/unknown `booking.update` decoded and applied | Tolerant `BookingStatus` decode; all three subscribers already refetch (Pattern 5) |
| PAY-05 | Paid and free paths show the same slot-taken/meeting-link copy | One `BookingErrorMapper` (Pattern 6) |
| PUSH-01 | Any push tap opens the right screen; unknown opens list | `route_category` parser + planner + stack registration (Patterns 7, 8) |
| PUSH-02 | Tap switches mode before routing | `target_role` plan with pending-destination gating (Patterns 7, 8) |
| PUSH-03 | Booking-request push opens that request | `booking_id` equals `request_id` (verified); new `HomeRoute` case (Pattern 8) |
| PUSH-04 | After logout the device stops getting the old account's pushes | Awaited DELETE + FCM `deleteToken`; no backend change needed (Pattern 9) |
| CHAT-09 | No banner for the chat on screen | Visible-thread tracker + `willPresent` policy (Pattern 10) |
</phase_requirements>

## Summary

Phase 2 is iOS-only and needs **no backend change**. Everything it depends on shipped in Phase 1: push routing keys and `target_role`, the two-tier join gate with `can_join`, `/end` after completion, `consultation_fee.label` with real symbols and digits. The research found no contract gap that blocks the phase. Three backend observations are logged for the planner but are not required: the client **list** has no `can_join`, the client **detail** returns it but iOS does not decode it yet, and the backend's `formatPriceLabel` trims trailing zeros for topic price labels (so iOS must format from `amount` and `currency`, never from `price.label`).

The work splits into ten shared helpers or fixes. The four highest-risk items are: (1) **CALL-01**, a one-line revert plus a pure policy so it stays testable; (2) **PUSH-01/02/03 plus CR-01**, which is a navigation problem, not a parsing problem. The client Bookings and Search stacks and the expert Topics stack do not register `HomeRoute` at all, and the existing shell code pushes `.notificationsList`, `.incomingRequests` and payouts onto stacks without selecting their tab; (3) **PUSH-04**, where the root cause is that `logout()` starts a `Task` and then nils the bearer on the next line, so `unregisterPushTokenIfAny()` always hits `guard hasStoredToken` and returns; (4) **BOOK-10**, where 16 sites format money three different ways and four of them take major-unit `Double`s while the rest take minor-unit `Int`s.

The answer to the D-06 research flag is: **keep no credentials after logout.** `registerToken` on the backend deletes every row for the caller and evicts the submitted token from any other account, so the next login on this device rebinds the row. For the gap before that login, copy Android's proven approach: await the DELETE with a short timeout while the bearer is still valid, then always call Firebase `deleteToken` so a missed DELETE cannot keep delivering. A deleted FCM token makes the backend's own stale-token reaper delete the row on the first push. Keeping the old refresh token for a retry is rejected (ASVS V3: session termination must not leave a usable credential).

**Primary recommendation:** Plan CALL-01 first as its own plan (pure `CallOvertimePolicy`, revert `5 * 60`, `max(1, d)`, test). Then build the pure helpers (`JoinWindow`, `Money`, `ExternalMeetingProvider` fix, tolerant `BookingStatus`, `PaidBookingWindow`, `BookingErrorMapper`, push planner) test-first with `nonisolated` types, and only then wire shells, logout and the call/Agora callback. Every helper must be `nonisolated` because the app target defaults to `MainActor` isolation.

## Project Constraints (from CLAUDE.md)

Extracted from `/Users/LeonChen/Documents/ClickMe2026/CLAUDE.md` and `.claude/CLAUDE.md`; same authority as locked decisions.

- Swift 6 strict concurrency, iOS 18+, Xcode 26; no rewrites. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (app target), so pure helpers need `nonisolated`.
- Branch on `ErrorCode`, never string-match `message`. Use `Error.userMessage`; do not add a new private `errorMessage(for:)`.
- No `try?` for writes or requests whose failure must be shown. `try?` is allowed for best-effort reads.
- Wrap new debug logging in `#if DEBUG`. Never log tokens, passwords, full user payloads. Do not copy the existing `print("push: TAP received. Full userInfo:")`.
- Use `DateUtil` / `NetworkService` date helpers; do not create new `DateFormatter`s for shared formatting.
- Identifiers spelled `Id`. New screens use the `...View` suffix; subviews keep the screen prefix. Folder names with spaces under `Views/Screens/`.
- Every Swift file starts with the Xcode header block. `// MARK: -` sections. `///` docs explain why, not what.
- View models are long; extract new logic into helpers or sibling types.
- Backend changes additive and safe for build 6 and current Android; one commit per repo per change; say so if another repo needs a change.
- Definition of done: unit tests where logic is testable, clean `xcodebuild` with no new warnings, device check on a real iPhone via UAT checklist, backend tests for backend changes.
- Production data: the backend is live production. Payment and refund code paths need care (this phase touches none directly).
- GSD workflow: no direct repo edits outside a GSD command.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Overtime cutoff and warning (CALL-01) | Pure helper (`nonisolated`) | `MeetingCallViewModel` timer, `MeetingCallView` banner | Policy must be unit-testable; the VM only applies it |
| `/end` duration clamp (CALL-04) | Pure helper | `MeetingCallViewModel.handleEndCall` | Server schema `.positive()` is the contract |
| Agora failure to Ended (CALL-05) | `AgoraManager` (delegate) | `MeetingCallViewModel.wireAgoraStateSync` | Only the SDK delegate sees `connectionChangedTo` |
| Join window (CALL-02) | Pure helper | Booking cards/dashboards (views), server `can_join` | Local rule drives first join; server flag extends reconnect |
| Provider detection (CALL-09) | Pure helper (`ExternalMeetingProvider`) | Call view | URL host logic only |
| Money formatting (BOOK-10) | Pure helper | ~16 view models/views | One place; callers pass minor units or major units explicitly |
| Status decoding (BOOK-18) | Model enum | `RealtimeService` decode, view models | Decode never fails; subscribers already refetch |
| 6-day cap, error copy (BOOK-14, PAY-05) | Pure helpers | `MakeABookingViewModel`, `RescheduleViewModel`, calendar/slot cards | Server is the authority (422 backstop); client hides |
| Push parse and plan (PUSH-01..03, BOOK-15) | Pure planner | `PushRouter` (state), `UserManager.setMode`, shells | Parse + plan testable; shells only execute |
| Stack/tab execution, `HomeRoute` registration (D-04) | SwiftUI shells | `HomeNavigationPath` | Only shells own tab selection and stacks |
| Logout push cleanup (PUSH-04) | `UserManager` + small cleanup type | Firebase Messaging, backend `DELETE` | Needs bearer before it is cleared |
| Foreground banner policy (CHAT-09) | AppDelegate (`willPresent`) | Visible-thread tracker set by `ChatView` | Decision needs "which thread is on screen" |
| Auth of every API call | Backend | — | `target_role` and `can_join` are display hints only |

## Standard Stack

No new libraries. Everything uses what the app already ships.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift Testing (`import Testing`) | Xcode 26.5 toolchain | Unit tests (`@Test`, `#expect`) | Project convention for `ClickMe2026Tests/` [VERIFIED: ClickMe2026Tests/Network/Discovery/ClientHomeFeedTests.swift `@Suite(...) @MainActor struct`] |
| FirebaseMessaging | 12.17.0 | `Messaging.messaging().deleteToken` for PUSH-04 | Already linked [VERIFIED: firebase-ios-sdk checkout 12.17.0, `FIRMessaging.h:335` `- (void)deleteTokenWithCompletion:(void (^)(NSError *_Nullable error))completion;`] |
| AgoraRtcKit | 4.6.2 | `rtcEngine(_:connectionChangedTo:reason:)` for CALL-05 | Already linked [VERIFIED: `AgoraRtcEngineDelegate.h:200` `connectionChangedToState:... NS_SWIFT_NAME(rtcEngine(_:connectionChangedTo:reason:))`] |
| UserNotifications | iOS 18 SDK | `willPresent` options for CHAT-09 | Already the delegate |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SwiftUI `TimelineView(.periodic)` | iOS 18 | Live Join button flip | Already used on `UpcomingBookingCard`; reuse for expert/dashboard cards |
| `NavigationPath(_:)` init from a sequence | iOS 16+ | Replace a stack in one mutation (reset + push) | D-04 tab-stack execution `[ASSUMED]` (see A1) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Pure-integer `Money` | `NumberFormatter(.currency)` | Locale changes symbols (`US$` vs `$`) and drops `.00` unless every call site sets digits; D-10 forbids locale |
| FCM `deleteToken` as PUSH-04 fallback | Keep old refresh token for a retry | Retaining a post-logout credential violates session-termination hygiene; rejected |
| Per-tab `.navigationDestination(for: HomeRoute.self)` | One registration helper used by all tabs | Helper makes a missing registration impossible (recommended) |

**Installation:** none. **Version verification:** Agora 4.6.2 and Firebase 12.17.0 match `Package.resolved` per CLAUDE.md and were confirmed from the checked-out SDK sources/headers this session.

## Package Legitimacy Audit

This phase installs no external packages, so no `package-legitimacy check` was needed.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none added) | — | — | — | — | — | — |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
PUSH TAP (PUSH-01..04, BOOK-15, CHAT-09)

 APNs/FCM --userInfo--> AppDelegate
     |  willPresent: PushForegroundPolicy(event, visibleThreadId) -> [] | [.banner,.list,.sound,.badge]
     |  didReceive : PushEvent(userInfo)  (route_category / route_sub_category / target_role / ids)
     v
 PushRoutePlanner.plan(event, currentMode, canUseExpert)      <- pure, nonisolated, unit-tested
     |  -> .route(PushDestination, targetMode?)   or  .notificationsList (D-03 / unknown)
     v
 PushRouter.pending = PendingPush(destination, mode)           <- queue; survives cold launch
     |
     +-- shell for the WRONG mode sees pending.mode != its mode:
     |       UserManager.setMode(pending.mode)  -> ClickMe2026App swaps shell (route mirror)
     +-- shell for the RIGHT mode (onAppear/onChange):
             select owning tab -> path.replace([HomeRoute...]) -> clear pending
             every HomeRoute is registered on every tab stack (single helper)

LOGOUT (PUSH-04)
 user taps Log out --> capture {deviceId, bearer valid?} --> await DELETE /notifications/tokens/:device_id (<=3 s)
   --> Messaging.deleteToken (always) --> clear bearer/session --> (marker kept if either step failed)
 involuntary logout (401/403 suspension/refresh fail): skip DELETE (it would 401), still deleteToken

CALL LIFETIME (CALL-01/04/05)
 1 s Timer -> CallOvertimePolicy.action(scheduledEnd, now): .none | .warn (end+55) | .end (end+60)
 Agora delegate connectionChangedTo(.failed) -> AgoraConnectionMapper -> myConnectionState = .disconnected -> callStatus .ended
 handleEndCall -> POST /end {actual_duration: max(1, d)}
```

### Recommended Project Structure
```
ClickMe2026/
├── Utils/
│   ├── Money.swift                  # BOOK-10 (nonisolated enum)
│   ├── JoinWindow.swift             # CALL-02 (nonisolated enum)
│   ├── CallOvertimePolicy.swift     # CALL-01/04 (nonisolated enum)
│   ├── PaidBookingWindow.swift      # BOOK-14 6-day cap (nonisolated enum)
│   └── BookingErrorMapper.swift     # PAY-05/BOOK-14 copy (nonisolated enum)
├── Managers/
│   ├── PushRoutePlanner.swift       # pure plan: event + mode -> destination/mode
│   ├── PushRouter.swift             # (edit) pending queue, PendingPush
│   ├── PushForegroundPolicy.swift   # CHAT-09 pure decision
│   └── PushTokenCleanup.swift       # PUSH-04 awaited unregister + deleteToken + marker
├── Model/Push/PushEvent.swift       # (edit) route_category parse, never nil
└── Model/Enums/BookingStatus.swift  # (edit) rescheduled + unknown, tolerant init(from:)
ClickMe2026Tests/
├── Utils/ (MoneyTests, JoinWindowTests, CallOvertimePolicyTests, PaidBookingWindowTests, BookingErrorMapperTests)
├── Calls/ (ExternalMeetingProviderTests, AgoraConnectionMappingTests)
├── Model/ (BookingStatusDecodingTests)
└── Push/ (PushEventTests, PushRoutePlannerTests, PushForegroundPolicyTests, PushTokenCleanupTests)
```
New files are picked up automatically: both the app and test targets use `PBXFileSystemSynchronizedRootGroup` [VERIFIED: ClickMe.xcodeproj/project.pbxproj:53-77 and 149-152, 179-181].

### Pattern 1: Call lifetime policy (CALL-01, CALL-04, CALL-05) — plan first
**What:** Move the cutoff into a pure type; the VM only applies the result.
**Evidence:** `MeetingCallViewModel.swift:532` is `let overtimeCutoffSeconds: TimeInterval = 5 * 60 // TEMP: was 3600`. `MeetingCallViewModel.swift:692` is `actualDuration: max(0, duration),`. Server: `src/schemas/call.schema.js:29` is `actual_duration: z.number().int().positive(), // seconds`. After the cron completes a booking at end + 15, `/end` with `completed` is still accepted until end + 70 [CITED: backend docs/ios/CALL-END-SEMANTICS.md "returns `200` while now is at or before `end_time + 70min`"], and the Agora token expires at end + 70, so end + 60 is inside both.
```swift
// Source: derived from MeetingCallViewModel.enforceMaxOvertimeCutoff (this repo) + CONTEXT D-08
nonisolated enum CallOvertimePolicy {
    static let cutoff: TimeInterval = 60 * 60        // end + 60
    static let warningLead: TimeInterval = 5 * 60    // notice at end + 55
    enum Action: Equatable { case none, warn, end }
    static func action(scheduledEnd: Date?, now: Date) -> Action {
        guard let scheduledEnd else { return .none }
        let over = now.timeIntervalSince(scheduledEnd)
        if over >= cutoff { return .end }
        if over >= cutoff - warningLead { return .warn }
        return .none
    }
    /// Server rejects 0 (`.positive()`); a hang-up inside the first second must still send 1.
    static func endDuration(joinStart: Date?, now: Date) -> Int {
        max(1, joinStart.map { Int(now.timeIntervalSince($0)) } ?? 0)
    }
}
```
- Banner: `MeetingCallView.bannerText` (line ~221) currently says "Scheduled time complete — you can wrap up when ready." after the end. Keep it until end + 55, then show D-08 text "This call will end in 5 minutes" (`VM` exposes `isOvertimeWarning`). `enforceMaxOvertimeCutoff` also runs only while the 1 s timer runs; the Skype/Zoom path loses the timer while the app is backgrounded, which is acceptable (cutoff applies on return).
- **CALL-05 root cause (confirmed):** `AgoraManager.swift:279` is `if uid == 0 {` inside `didOfflineOfUid`, but the SDK documents that callback as remote-only: "This callback is triggered when a remote user (in the communication profile) or host (in the live streaming profile) leaves a channel." [VERIFIED: AgoraRtcEngineDelegate.h:679-680]. The local user is never reported through it, so `myConnectionState = .disconnected` never happens. Fix: implement `nonisolated func rtcEngine(_:connectionChangedTo:reason:)` and map **only `AgoraConnectionState.failed` (5)** to `.disconnected`. `.disconnected` (1) is also the initial state and the state after `leaveChannel`, so mapping it would end a call that is just starting or that the user ended [VERIFIED: AgoraEnumerates.h:2555-2563]. `.failed` is documented as terminal ("The SDK stops trying to rejoin the channel. You must call `leaveChannel:`", header :2594-2599) and fires for join failed (reason 4), banned (3), invalid/expired token (8, 9), rejected (10) [VERIFIED: AgoraEnumerates.h:3141-3211]. Keep the mapping in a pure function so it is unit-tested.
- The existing VM branch `case (.disconnected, _): self.callStatus = .ended` only sets the status; its comment says "run teardown" but nothing does. Recommend the new `.failed` path also runs the normal end path with `EndReason.dropped` (the enum already has it) so the screen does not sit on "Call Ended" with a live hang-up button. Planner choice; flagged in Open Questions.
- CALL-05 is LIKELY. `.failed` arrives only after the SDK has retried for 20 minutes [VERIFIED: AgoraEnumerates.h:2586-2591], so a device repro is slow. See Open Question 3.

### Pattern 2: One join-window rule (CALL-02)
**Evidence:** Backend constants `JOIN_LEAD_MS = 60 * 60 * 1000`, `JOIN_GRACE_MS = 60 * 60 * 1000`, `FIRST_JOIN_MIN_SPAN_MS = 60 * 60 * 1000` [VERIFIED: src/services/agora.js:54-56]; `latest = alreadyJoined ? endMs + JOIN_GRACE_MS : Math.max(endMs, startMs + FIRST_JOIN_MIN_SPAN_MS)` [VERIFIED: agora.js `evaluateJoinWindow`]. Joinable statuses: `const JOINABLE_BOOKING_STATUSES = Object.freeze(['confirmed', 'in_progress', 'completed']);` and the comment "`pending_reschedule` is deliberately NOT joinable" [VERIFIED: src/utils/bookingStatusSets.js:52 and its doc block].
```swift
nonisolated enum JoinWindow {
    static let lead: TimeInterval = 3600, minFirstJoinSpan: TimeInterval = 3600, reconnectGrace: TimeInterval = 3600
    /// `serverCanJoin` is the booking's `can_join` when the payload has one (client detail, expert list/detail).
    static func isOpen(status: BookingStatus, start: Date, end: Date, now: Date, serverCanJoin: Bool?) -> Bool {
        switch status { case .confirmed, .inProgress, .completed: break; default: return false }
        guard now >= start.addingTimeInterval(-lead) else { return false }
        if now <= max(end, start.addingTimeInterval(minFirstJoinSpan)) { return true }       // first-join tier (local rule, D-07)
        return now <= end.addingTimeInterval(reconnectGrace) && serverCanJoin == true         // reconnect tier needs the server flag
    }
}
```
- **D-07 research flag answered:** `GET /client/bookings` (list) does **not** return `can_join`. `can_join` appears only at `clientBooking.controller.js:1119` (detail), `expertBooking.controller.js:292` (list) and `:399` (detail) [VERIFIED: grep]. iOS decodes it only on the expert side (`ExpertBookingItem.Actions.canJoin`, `ExpertBookingDetail.Actions.canJoin`); `ClientBookingDetail` has no `canJoin` field. Add `let canJoin: Bool?` (optional, additive) to `ClientBookingDetail`; the client list passes `nil` and uses the local rule only. A client who dropped during overtime can reconnect from the detail screen but not from the list; acceptable under D-07.
- **Sites to replace (all use `±3600` around start today):** `UpcomingBooking.swift:62-67` (`isWithinJoinWindow`, with a special `.completed` branch), `UpcomingBookingsView.swift:64-67` (expert `UpcomingSession.isWithinJoinWindow`), `ExpertDashboardView.swift:531-534` (`private static func isWithinJoinWindow`), and the callers that read them (`UpcomingBookingCard`, `ExploreTodaysSessionsSection:81`, `UpcomingBookingsSessionCard:39,126`). `ExpertDashboardViewModel.isStartingNow` and `ExploreTodaysSessionsSection.isStartingNow` are a different thing (the "starting now" pill); leave them.
- **Behavior change to confirm:** `ExploreClientViewModel.isJoinable` and `ExpertDashboardViewModel.isJoinable` treat `.pendingReschedule` as joinable. The server refuses it. The new helper follows the server (Assumption A4).
- The expert `ExpertBookingItem.Actions.canJoin` doc says "within 5 minutes before start_time up to end_time" and `UpcomingBookingsView` says the server flag "is tighter (~5 min)". Both are stale since BACK-09. Update the comments when touching the code.

### Pattern 3: Provider host matching (CALL-09)
**Evidence:** `ExternalMeetingProvider.swift:40-41` is `if host.contains("skype.com") { return .skype }` / `if host.contains("zoom.us") || host.contains("zoom.com") { return .zoom }`, followed by a raw-string fallback (`raw.contains("skype")`, ...). `evilzoom.us` and `zoom.us.evil.com` both match today.
```swift
private static func host(_ host: String, isOrEndsWith domain: String) -> Bool {
    host == domain || host.hasSuffix("." + domain)
}
// strip a single trailing "." (FQDN form) and lowercase before comparing; delete the raw-string fallback block entirely.
```
Domains: `skype.com`, `zoom.us`, `zoom.com`, `meet.google.com`, `teams.microsoft.com`, `teams.live.com`. Keep the native scheme switch (`skype`, `zoommtg`, `zoomus`, `msteams`). A scheme-less string such as `zoom.us/j/1` has no `URL.host`, so it becomes `.unknown` (intended: generic "Open Meeting" copy). `URL(string:)` userinfo tricks (`https://zoom.us@evil.com`) yield host `evil.com`, which is correct.

### Pattern 4: Money (BOOK-10)
**Evidence for rules:** zero-decimal set `const ZERO_DECIMAL_CURRENCIES = new Set(['JPY', 'KRW', 'VND', 'CLP', 'ISK', 'XOF', 'XAF']);` and `return ZERO_DECIMAL_CURRENCIES.has((currency || '').toUpperCase()) ? 0 : 2;` [VERIFIED: src/utils/earnings.js:25,35]. Symbols: `USD: '$', EUR: '€', GBP: '£', CAD: 'CA$', AUD: 'A$', JPY: '¥', INR: '₹', CHF: 'CHF'` [VERIFIED: src/utils/pricing.js:71-80]. Use the **backend's** digits rule, not `NumberFormatter`/ICU: the server computes minor units with its own set, and ICU disagrees for currencies such as KWD (3 digits), which would mis-scale.
```swift
// ClickMe2026/Utils/Money.swift
nonisolated enum Money {
    private static let zeroDecimal: Set<String> = ["JPY","KRW","VND","CLP","ISK","XOF","XAF"]
    private static let symbols: [String: String] = ["USD":"$","CAD":"CA$","AUD":"A$","EUR":"€","GBP":"£","JPY":"¥","INR":"₹"]
    static func fractionDigits(_ code: String) -> Int { zeroDecimal.contains(code.uppercased()) ? 0 : 2 }
    static func format(minorUnits: Int, currency: String) -> String {      // BOOK-10: integers in, no floating point
        let code = currency.uppercased(), digits = fractionDigits(code)
        let sign = minorUnits < 0 ? "-" : ""
        let abs = minorUnits.magnitude, scale = Int(pow(10, Double(digits)))   // 1 or 100
        let whole = digits == 0 ? "\(abs)" : "\(abs / UInt(scale))"
        let frac = digits == 0 ? "" : "." + String(format: "%02d", Int(abs % UInt(scale)))
        let prefix = symbols[code] ?? "\(code)\u{00A0}"                       // CHF and unknown codes: ISO code + nbsp
        return "\(sign)\(prefix)\(whole)\(frac)"
    }
    /// For fields the server already divided (see site table). Rounds half away from zero.
    static func format(major: Double, currency: String) -> String {
        format(minorUnits: Int((major * pow(10, Double(fractionDigits(currency)))).rounded()), currency: currency)
    }
}
```
**Sites to convert (grep of `/ 100`, `/100`, `NumberFormatter.currency`, `"$\(`, this session):**

| # | File (under `ClickMe2026/`) | Input unit | Note |
|---|------|-----------|------|
| 1 | `Model/UIModels/BookingTopic.swift:32` | minor | prints `"\(currency) \(priceAmount / 100)"`, drops cents |
| 2 | `Views/.../Upcoming Booking Details/UpcomingBookingViewModel.swift:185` | minor | same pattern |
| 3 | `Views/.../Expert Profile/ExpertProfileViewModel.swift:195` | minor | `formatSessionPrice` |
| 4 | `Views/.../Explore/ExploreClientViewModel.swift:277` | minor | `formatPrice`; keep its "Free" and "—" branches |
| 5 | `Views/.../Booking Summary/BookingSummaryViewModel.swift:356` | minor | `formatPrice` |
| 6 | `Views/.../Cancellation/ClientCancellationViewModel.swift:132` | minor | refund preview (Phase 3 changes the policy, not the formatting) |
| 7 | `Views/.../Expert Dashboard/ExpertDashboardViewModel.swift:345` | minor | `currencyLabel`, used by `ExpertDashboardView:677,682` |
| 8 | `Views/.../Payouts/PayoutsViewModel.swift:259` | minor | `currencyLabel`, used by `PayoutsView:548,553` |
| 9 | `Views/.../Topics/Subviews/TopicsSetupTopicCard.swift:26` | minor | |
| 10 | `Model/Responses/Children/ClientTransactionItem.swift:140` | minor | already digits-aware via `NumberFormatter`, still locale symbol |
| 11 | `Views/.../Payouts/Subviews/EarningsTransactionRow.swift:134` | minor | same |
| 12 | `Views/.../Topics/Topic Editor/TopicEditorViewModel.swift:343` | minor | display only (D-11); input parsing stays Phase 6 |
| 13 | `Views/.../Incoming Requests/IncomingRequestsViewModel.swift:133` | **major** `Double` | `75.0` renders `$75`; use `format(major:)` |
| 14 | `Views/.../Upcoming Bookings/UpcomingBookingsViewModel.swift:301` | **major** `Double` | `formatCurrency` |
| 15 | `Views/.../Request decision/Subviews/RequestDecisionEarningsSection.swift:229` | **major** `Double` | |
| 16 | `Views/.../Expert Mode/Client Profile/Subviews/ClientProfileBookingCard.swift:33` | unknown type | hard-coded `"$\(booking.amount)"`; EXP-14 (Phase 6) owns the real fix, only note here |

D-11 names about 13 files; this list is 15 conversions plus 1 deferral. **Leave alone:** `ExpertBookingSummaryViewModel.feeLabel` uses the server `consultation_fee.label` (`"${currencySymbolFor(currency)}${major.toFixed(digits)} / session"`, [VERIFIED: expertBooking.controller.js:145]), which already matches D-10. Do not use `ExpertTopicItem.price.label` when `amount` and `currency` exist: the backend `formatPriceLabel` trims trailing zeros (`amount.toFixed(digits).replace(/\.?0+$/, '')`, [VERIFIED: src/utils/formatPrice.js]), so `12.50` becomes `$12.5`. `PaymentIntentResponse.summary` amounts are major-unit doubles but are never displayed (only stored in `MakeABookingViewModel.paymentSummary`).

### Pattern 5: Tolerant `BookingStatus` (BOOK-18)
**Evidence:** `BookingStatus` is `enum BookingStatus: String, Decodable` with nine cases and no `rescheduled` [VERIFIED: BookingStatus.swift:14-24]. `RealtimeBookingUpdateEvent.status: BookingStatus` [VERIFIED: RealtimeEvents.swift:56]. `RealtimeService.decode` is `try? decoder.decode(T.self, from: data)` and the socket handler does `guard let event ... else { return }` (RealtimeService.swift:265-270, 293-295), so one unknown status drops the whole event. The contract lists the wire values `pending_approval, confirmed, declined, cancelled, rescheduled, completed, expired` [CITED: backend docs/SOCKET-CONTRACT.md "`status` enum values"]. Note `rescheduled` exists only on the socket; the database never stores it (DB statuses per `bookingStatusSets.js` header).
```swift
enum BookingStatus: String, Decodable {
    /* existing nine cases */
    case rescheduled           // socket-only value
    case unknown               // any future/unrecognised value
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = BookingStatus(rawValue: raw) ?? .unknown
    }
}
```
- This also hardens `EndCallData`, `ConfirmConnectionData`, `BookingRequestData`, `ConfirmBookingData`, which all decode `status: BookingStatus`.
- **Exhaustive-switch blast radius:** the compiler will flag `ExploreClientViewModel.isJoinable`, `ExpertDashboardViewModel.isJoinable`, `ClientProfileViewModel.mapStatus`, `BookingSummaryViewModel` (the status switch near line 333-340), `PastBookingCard`/badges. Treat `.rescheduled` and `.unknown` as "not joinable / not past".
- All three realtime subscribers already ignore the status and refetch (`UpcomingBookingViewModel.swift:81-84`, `BookingSummaryViewModel.swift:111-114`, `MyBookingsViewModel:55`, `UpcomingBookingsViewModel:78`), so no handler change is required beyond the decode. The CONTEXT "neutral label until refetch" is already satisfied because those VMs only change the pill on reload; do not add a new label state unless a screen reads `event.status` directly.

### Pattern 6: Paid 6-day window and one booking error mapper (BOOK-14, PAY-05)
**Server rule (read this session):** `const LONG_LEAD_THRESHOLD_MS = 6 * 24 * 60 * 60 * 1000;` (`src/utils/reschedule.js:37`); reschedule refusal is `proposedStartMs - now.getTime() > LONG_LEAD_THRESHOLD_MS` (strictly greater, so exactly 6 days is allowed) and only for `isPaidBooking(...)`. Paid long-lead creation: `LONG_LEAD_NOT_AVAILABLE` (confirm without a PaymentIntent for a paid topic) and `LONG_LEAD_REQUIRES_SAVED_CARD` (payment-intent, kept "ONLY for client compatibility ... terminal: callers must not fall through to a no-PI confirm"). `RESCHEDULE_TOO_FAR_AHEAD` message: "Paid sessions can be rescheduled up to 6 days ahead. Please choose a time within the next 6 days." `LONG_LEAD_NOT_AVAILABLE` message: "Paid sessions can be booked up to 6 days ahead." [VERIFIED: booking.controller.js:477-482, :1210-1218; reschedule.js:76-85].
- `ErrorCode.swift` has `longLeadRequiresSavedCard` (line 120) but neither new code [VERIFIED]. `StandardErrorResponse` decodes an unknown code to `nil`, so today both new codes silently fall through to the server message. Add `longLeadNotAvailable = "LONG_LEAD_NOT_AVAILABLE"` and `rescheduleTooFarAhead = "RESCHEDULE_TOO_FAR_AHEAD"`.
- **Delete the fall-through:** `MakeABookingViewModel.swift:458-460` calls `performLongLeadBooking` on `.longLeadRequiresSavedCard`. Delete `performLongLeadBooking` entirely and route `.longLeadRequiresSavedCard` and `.longLeadNotAvailable` to one clear message ("Paid sessions can be booked up to 6 days ahead. Please choose an earlier time.").
- **Cap helper** (mirror of Android `BookingSlots.kt`, inclusive upper bound, `latestStart = now + 6 d` for paid, `nil` for free):
```swift
nonisolated enum PaidBookingWindow {
    static let maxLead: TimeInterval = 6 * 24 * 3600
    static func latestStart(isPaid: Bool, now: Date) -> Date? { isPaid ? now.addingTimeInterval(maxLead) : nil }
    static func allows(_ start: Date, latestStart: Date?) -> Bool { latestStart.map { start <= $0 } ?? true }
}
```
  Time moves forward between pick and submit, so a slot allowed at pick time stays allowed at submit.
- **`isPaid` for reschedule:** use `paymentStatus != "none" || !topic.isFree`, as Android does ("The client detail's `payment_status` is derived and reads `none` for a long-lead paid booking with no payment intent yet, so the topic's free flag closes that gap. Over-capping is safe" [VERIFIED: Android RescheduleRules.kt:72-80]). Over-capping is safe; under-capping hits the 422 backstop.
- **Where to apply:** `MakeABookingViewModel` (`slotsForSelectedDate`, `isPastDate`, the calendar cell and slot chip in `MakeABookingCalendarCard.swift:94` / `MakeABookingTimeSlotsCard.swift:132`) when the selected topic is not free; `RescheduleViewModel.slotsForSelectedDate` / `hasSlots(on:)`. The expert reschedule picker also hits `RESCHEDULE_TOO_FAR_AHEAD` server-side for paid bookings (openapi lists it at four sites); at minimum map the code through the shared mapper there; capping the expert picker needs a paid flag from `ExpertBookingDetail` and is Phase 3 (EXP-13) territory. See Open Question 5.
- **"Hide" semantics:** hide slot chips beyond the window and render day cells beyond the window blank and non-interactive (CONTEXT says hide, not disabled-gray).
- **One mapper (PAY-05):** the paid handler (`handlePaidFlowError`, `MakeABookingViewModel.swift:~590-640`) already has the good copy ("That time slot was just taken. Please pick another." at :614, "The expert hasn't set up their Skype/Zoom link yet. Please choose in-app voice instead." at :622) while the free path just does `bookingError = Self.message(for: error)` (:396). Extract `BookingErrorMapper.message(for code: ErrorCode?, fallback: String) -> String` (pure, copy table), call it from both paths and from `RescheduleViewModel.rescheduleErrorMessage`. Delete the private `message(for:)` helpers in `MakeABookingViewModel` and use `Error.userMessage` for the fallback (CLAUDE.md rule).

### Pattern 7: Push parse, plan and mode (PUSH-01, PUSH-02, PUSH-03, BOOK-15)
**Evidence:** `PushEvent.swift:63-82` reads `category`, else an `event_type` switch (`NEW_MESSAGE`, `NEW_BOOKING_REQUEST`/`BOOKING_REQUEST`/`REQUEST_CREATED`), else `return nil`. `ClickMe2026AppDelegate.swift:185-190` then does nothing on nil (the N1 bug). The backend sends iOS tokens `route_category`/`route_sub_category` (never `category`) plus `target_role` [VERIFIED: src/services/push.js: `{ route_category: String(category || ''), route_sub_category: String(sub_category || '') }` for non-Android; docs/ios/PUSH-ROUTING.md "Build 6 behavior"]. iOS device tokens are registered with `platform: "ios"` (UserManager.swift `registerPushToken`).
- **Parser (D-05):** `PushEvent.init(userInfo:)` becomes non-failable: read `data["route_category"]`/`["route_sub_category"]`, trim, lowercase the category; if empty, fall back through `event_type` for the table in `PUSH-ROUTING.md` (chat is required; copy Android's full `EVENT_TYPE_FALLBACK` table as a safety net, it costs nothing). **Never read `category`.** Read `target_role` (accept only `client`/`expert`, else nil). Validate every id with `UUID(uuidString:)` (already the pattern). A nil category means "open the notifications list".
- **Planner (pure):**
```swift
nonisolated struct PushPlan: Equatable { var destination: PushDestination; var mode: AppMode? }  // mode nil = stay
nonisolated enum PushRoutePlanner {
    static func plan(_ event: PushEvent, currentMode: AppMode, canUseExpertMode: Bool) -> PushPlan {
        let dest = PushRouter.destination(for: event) ?? .notificationsList          // PUSH-01 fallback
        guard let target = event.targetRole else { return .init(destination: dest, mode: nil) }   // D-02
        if target == .expert && !canUseExpertMode { return .init(destination: .notificationsList, mode: nil) } // D-03
        return .init(destination: dest, mode: target == currentMode ? nil : target)
    }
}
```
- **Table:** keep `PushRouter.destination(for:)` mapping; make three changes: (a) `booking/requests` carries the id: `.incomingRequest(bookingId:)` (PUSH-03); a missing id still opens the hub; (b) `booking/payment_actions` falls into the generic `booking/*` → booking detail case, which already satisfies D-01 (no new code, but add a test row); (c) split booking detail by `sub_category`: `declines`, `cancellations`, `expirations`, `refunds` go to the summary route (terminal bookings), the rest to the upcoming-detail route. `UpcomingBookingView` for a cancelled booking would show an "Upcoming Booking" title and a Join card. `NotificationsListViewModel.destination(for:)` maps rows to the same enum and must be updated in lockstep.
- **Request id:** `request_id` returned by the incoming-requests API is the bookings row id (`request_id: row.id`, [VERIFIED: bookingRequests.controller.js:109], rows from `from('bookings')`), and `RequestDecisionView(requestId:isExpired:)` loads `GET /expert/booking-requests/:id`. So the push's `booking_id` is usable directly; `isExpired` defaults to false and the detail load maps real state.
- **`canUseExpertMode` (D-03):** `userManager.me?.roles.contains(.expert) == true` and `expertProfile?.setupCompleted == true`. `expertProfile` is only populated by splash/login/settings refreshes; if it is nil and the role is present, fetch with `try? await refreshExpertProfile()` once and treat failure as "cannot" (conservative: notifications list). `AppMode`/`ModeSwitchView` allows either mode regardless of role today, so this guard is new.
- **Pending queue (cold launch):** replace `pendingDestination: PushDestination?` with `pending: PendingPush?` (`destination` + `mode`), both `Equatable`. Cold launch: `didReceive` runs before splash finishes and before any shell exists; `SplashViewModel.resolveLandingMode` calls `setMode(...)` and would overwrite an early switch, so **only the shells consume**, in `onAppear`/`onChange`, after the user is logged in. Clear `pending` on logout (a tap for an account that is no longer signed in must not route). `NotificationsListView.swift:158` sets `pendingDestination` directly with no mode; keep that working (mode `nil`).

### Pattern 8: Shell execution and `HomeRoute` registration (D-04, CR-01)
**What is broken today (read this session):**
- `HomeClientView` registers `navigationDestination(for: HomeRoute.self)` on Explore (:191), Chats (:218) and Profile (:228) only. **Search and Bookings do not** (`searchTab` :198, `bookingsTab` :205). `MyBookingsView` registers only its private `BookingRoute`. The shell then pushes `HomeRoute.upcomingBooking`/`.bookingSummary` onto `bookingsPath` (:142, :159). Same defect as CR-01.
- `HomeExpertView` registers `HomeRoute` on Dashboard, Bookings, Chats and Profile; **Topics does not** (:164).
- Pushes that never select their tab: client `.incomingRequests`/`.payouts`/`.kycOnboarding`/`.notificationsList` call `explorePath.push(HomeRoute.notifications)` without `selectedTab = .explore` (:147, :164, :169); expert `.notificationsList` calls `dashboardPath.push(...)` without `selectedTab = .dashboard` (:130). The user stays on the visible tab and sees nothing.
- Nothing resets a stack before pushing, so Back does not return to the tab root.

**Fix pattern (do it once, in both shells):**
1. One helper per shell, `homeStack(path:root:)`, that wraps the root view in `NavigationStack(path:)`, registers `.navigationDestination(for: HomeRoute.self)` exactly once and sets `.environment(\.homeNavigationPath, path)`. All five tabs use it, so a missing registration cannot happen. Do not register `HomeRoute` twice on the same stack (SwiftUI warns on duplicates).
2. `HomeNavigationPath.replace(with:)` assigns `path = NavigationPath([route])` in one mutation (reset + push without an intermediate empty state). `[ASSUMED]` A1: verify on device; fall back to `reset()` then `push()` on the next run-loop turn if it misbehaves.
3. Add `HomeRoute.requestDecision(requestId: UUID)` (expert shell → `RequestDecisionView(requestId:)`; client shell → `EmptyView()` like the other expert-only cases). The `homeRouteDestination` switch is exhaustive in both shells.
4. Shell `handlePush(_ pending:)`: if `pending.mode` is non-nil and differs from this shell's mode, call `userManager.setMode(pending.mode)` and **return without clearing** (the other shell mounts via `ClickMe2026App.onChange(of: currentMode)` and consumes it in `onAppear`). If it matches (or is nil), select the owning tab, `replace(with:)`, then clear `pending`. This avoids the race where the outgoing shell consumes the destination during its own teardown.
5. Tab ownership table: client: booking detail/summary/leave-review → Bookings; chat → Chats; account security → Profile; notifications list → Explore (bell lives there); client has no payouts/requests (fall to notifications list). Expert: incoming requests and request decision → Dashboard (it owns the requests entry); booking detail/leave-review → Bookings; payouts/KYC → Dashboard; chat → Chats; account security → Profile; notifications list → Dashboard.

**Known limitation (Phase 3, not Phase 2):** `HomeRoute.upcomingBooking` builds `UpcomingBookingView(bookingId:)` with default `{}` callbacks (`UpcomingBookingView.swift` init defaults), so Join, Cancel and Reschedule are inert when reached from a push or a chat row; `HomeRoute.bookingSummary` has the same for Leave Review/Book Again. CALL-03 and BOOK-06/16/17 own that wiring. State it in the UAT checklist so the CR-01 test ("booking push opens the screen, no warning page") is not read as "all buttons work".

### Pattern 9: Logout push cleanup (PUSH-04) — D-06 research flag answered
**Root cause:** `UserManager.logout()` runs `Task { [weak self] in await self?.unregisterPushTokenIfAny() }` (line 305) and then, synchronously, `api.bearerToken = nil` (line 311). The task body starts after that, and `unregisterPushTokenIfAny` begins with `guard hasStoredToken else { return }` (line 653), where `hasStoredToken` is `api.bearerToken != nil`. It always returns. N4 is therefore not a flaky call, it is never made.

**Backend facts (read this session):**
- `DELETE /notifications/tokens/:device_id` is authenticated and deletes `.eq('user_id', req.user.id).eq('device_id', device_id)` (notifications.controller.js `deregisterToken`). It cannot be called without the old account's bearer.
- `POST /notifications/tokens` (`registerToken`) deletes **every** row of the caller, then `.delete().eq('token', token).neq('user_id', req.user.id)` (line 72) to evict the same token from other accounts, then inserts one row. So "last registration wins", keyed by **token**, not only by `device_id`. A new login on this device with the same FCM token removes the old account's row. A rotated token does not.
- When FCM reports the token dead, the sender reaps it: `isStaleTokenError` returns true for `messaging/registration-token-not-registered` and `messaging/invalid-registration-token` and the device ids are batch-deleted (push.js).

**Recommended design (no backend change, no retained credentials):**
1. User-initiated logout (the two profile VMs' `logOut()`, the delete-account "Back to Login", `AccountSecurityView`'s `onBackToLogin`): new `func logout() async`-style entry (keep a sync wrapper for UI closures): capture `deviceId` (`UIDevice.identifierForVendor`) and the live bearer, set `isLoggingOut = true` (so `registerPushToken`/`refreshPushTokenBinding` do nothing; `applicationDidBecomeActive` can fire during the await), **await** `api.unregisterDeviceToken(deviceId:)` raced against a 3 s timeout, then **always** `await Messaging.messaging().deleteToken()`, then clear the local session exactly as `logout()` does today.
2. Involuntary logouts (`handleAccountSuspended`, `tryAutoLogin` auth rejection, `performRefreshCycle` 401, missing refresh token): the bearer is rejected, so the DELETE would 401/403. Skip it, run `deleteToken()` fire-and-forget, then clear locally. These paths must stay synchronous and idempotent (suspension fires concurrently).
3. **Retry marker (D-06):** if the DELETE failed or timed out, or `deleteToken` failed, persist `pendingPushCleanup = true` in `UserDefaults`. On next launch (and at login before the first register), if the marker is set, call `deleteToken()` again and clear it. This is the retry that actually works: it needs no credential. If the same device logs in as anyone, `registerToken` evicts the old row for an unchanged token anyway.
4. Mirrors Android's shipped solution: "`[unregister] gives the DELETE UNREGISTER_TIMEOUT_MS (3000L) ... then deletes the FCM token so a missed DELETE cannot keep delivering the previous user's pushes on a shared device`" and "a register that runs after unregister in the same session ... is skipped" [VERIFIED: Android FcmPushTokenRegistrar.kt:25-30, 71-86, 94-96].

Residual gap (document, do not fix): if the DELETE fails and `deleteToken` also fails (offline), the old row stays until the next push to that account fails with UNREGISTERED or until someone logs in on this device. The marker retries `deleteToken` on next launch.

**Testing seam:** put the sequence behind a small type with injected closures (`unregister: () async throws -> Void`, `deleteToken: () async throws -> Void`, `clearSession: () -> Void`, `clock`) so a test asserts the order (unregister before clear), that a thrown/slow unregister still clears, and that the marker is set on failure.

### Pattern 10: Foreground banner policy (CHAT-09)
`ClickMe2026AppDelegate.willPresent` always returns `[.banner, .list, .sound, .badge]` (lines 147-159). Add `PushForegroundPolicy.options(for event: PushEvent, visibleChatThreadId: UUID?) -> UNNotificationPresentationOptions`: suppress (return `[]`, no banner and no sound) only when `event.category == "message"` and `event.threadId == visibleChatThreadId`; otherwise unchanged. `ChatView` sets and clears a main-actor `ChatPresence.visibleThreadId` in `.onAppear`/`.onDisappear` (the thread id is `ChattingViewModel.threadId`, an optional UUID that is nil in preview seeds). Read the value and call the completion handler synchronously inside `willPresent` (the class is main-actor under the project default), because iOS expects a prompt callback. Do not suppress `handleForegroundArrival` (the notifications list tick still needs to refresh). Whether `.onDisappear` fires when the user switches tabs inside `TabView` is `[ASSUMED]` (A3): if it does not, a chat left open on another tab would suppress its own banners; verify on device and, if needed, also clear the id when `selectedTab` changes.

### Anti-Patterns to Avoid
- **Reading `category` on iOS:** the backend deliberately keeps it away from iOS tokens while build 6 is live (CR-01 hotfix `215adcb`). Use `route_category`.
- **Mapping Agora `.disconnected` to Ended:** it is the initial and post-`leaveChannel` state.
- **`NumberFormatter(.currency)` for display:** locale-dependent symbol and digit handling, forbidden by D-10.
- **Consuming a mode-targeted push in the outgoing shell:** lost destination on mode switch.
- **`try?` around the logout DELETE:** acceptable only because the failure is recorded in the marker; do not swallow without recording.
- **Adding `Date()`/`Locale.current` reads inside helpers:** pass `now` and fixed formats in, so tests are deterministic.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Invalidating a device's push identity at logout | A retry that stores the old refresh token | `Messaging.messaging().deleteToken` (+ backend's existing stale-token reaper) | No retained credential; Android already ships this |
| Stack reset + push | `path.removeLast(path.count)` loops | One assignment `NavigationPath([route])` via a `replace(with:)` method | Avoids intermediate states (A1) |
| Live Join button | A custom `Timer` per card | `TimelineView(.periodic(from:by:))` (already on `UpcomingBookingCard`) | Lifecycle handled by SwiftUI |
| Host matching | `String.contains` or regex on the full URL | `URL.host` equality or `"." + domain` suffix | The current bug is exactly `contains` |
| UUID validation of push ids | Regex | `UUID(uuidString:)` | Already used in `PushEvent` |
| Currency digits | ICU/`NumberFormatter` digits | Backend's zero-decimal set | Server computes minor units with that set |
| Error-code copy | Branching on `message` text | `ErrorCode` + one `BookingErrorMapper` | CLAUDE.md rule |

**Key insight:** every one of these bugs exists because the same rule was copied into several screens (`±3600` in five places, `/100` in 16, `message(for:)` in four view models). The fix is one tiny pure type per rule, called from all sites, covered by a table test.

## Common Pitfalls

### Pitfall 1: Pure helpers inherit `MainActor`
**What goes wrong:** a new `enum Money { static func ... }` is `@MainActor` because the app target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` [VERIFIED: project.pbxproj:472, 513]. Calling it from a nonisolated test or a delegate callback fails to compile under Swift 6.
**How to avoid:** mark every helper `nonisolated enum`/`nonisolated struct`. Tests either call nonisolated code directly or are `@MainActor struct` suites like `ClientHomeFeedTests`.
**Warning signs:** "call to main actor-isolated static method in a synchronous nonisolated context".

### Pitfall 2: CR-01 returns through a tab nobody registered
**What goes wrong:** the new build pushes a `HomeRoute` onto Bookings, Search or (expert) Topics and the user sees SwiftUI's warning page.
**How to avoid:** the single `homeStack` helper (Pattern 8). **Warning signs:** a destination pushed from the shell that is not in that tab's registration.

### Pitfall 3: Mode switch consumed by the wrong shell
**What goes wrong:** the outgoing shell clears `pending` while it is being torn down; the incoming shell finds nothing.
**How to avoid:** `PendingPush` carries its mode; a shell only clears it when it executes it.

### Pitfall 4: `logout()` ordering looks right but is not
**What goes wrong:** code that "awaits the unregister" but still calls `api.bearerToken = nil` synchronously first (as today).
**How to avoid:** capture state, await, then clear. Test the order. Also set `isLoggingOut` so a foreground `refreshPushTokenBinding()` cannot re-register during the await.

### Pitfall 5: Minor versus major units
**What goes wrong:** `Money.format(minorUnits:)` called with a server value that is already major (`IncomingRequests` earnings, `RequestDecisionEarningsSection`, `UpcomingBookingsViewModel`, expert `consultation_fee.amount`) shows 100x too small.
**How to avoid:** two named entry points; the site table above marks each unit; tests cover both.

### Pitfall 6: Adding `BookingStatus` cases breaks exhaustive switches silently elsewhere
**What goes wrong:** a `default:` branch hides `.rescheduled`/`.unknown` as "upcoming".
**How to avoid:** let the compiler list every site (Pattern 5) and decide each explicitly; no `default` on these switches.

### Pitfall 7: Join helper keeps statuses the server refuses
**What goes wrong:** Join shows for `pending_reschedule`, then `/join` returns `403 SESSION_NOT_ACTIVE`.
**How to avoid:** use the server's joinable set (A4, confirm with the user).

### Pitfall 8: Overtime `.end` fires `completed` against a booking the cron already completed
**What goes wrong:** none if the timing holds, which is why it matters: `/end` `completed` on an already-completed booking is only accepted until end + 70. The cutoff is end + 60; do not raise it.
**How to avoid:** keep `cutoff` at 3600 s and a test that pins it.

### Pitfall 9: Paid cap computed once at view creation
**What goes wrong:** `now + 6 d` captured in `init` goes stale if the screen stays open overnight.
**How to avoid:** compute `latestStart` from `Date()` at each evaluation (or a ticking `now`).

### Pitfall 10: Test target does not compile
**What goes wrong:** `LoginTests.swift`, `AuthSmokeTests.swift`, `SignupSmokeTests.swift` fail to compile at HEAD (10 errors), so a plain `xcodebuild test` fails before any new test runs [CITED: .planning/quick/261109-323.../SUMMARY "Excluded on the command line only"].
**How to avoid:** use the `EXCLUDED_SOURCE_FILE_NAMES` command below, or fix the first two (small) in a Wave 0 task (Open Question 6).

## Code Examples

### Tolerant realtime decode test (BOOK-18)
```swift
// Source: mirrors RealtimeService.decoder config [VERIFIED: RealtimeService.swift:56-61]
@MainActor @Suite("BookingStatus decoding") struct BookingStatusDecodingTests {
    private func decode(_ status: String) throws -> RealtimeBookingUpdateEvent {
        let d = JSONDecoder(); d.keyDecodingStrategy = .convertFromSnakeCase; d.dateDecodingStrategy = .iso8601
        let json = #"{"booking_id":"11111111-1111-4111-8111-111111111111","status":"\#(status)"}"#
        return try d.decode(RealtimeBookingUpdateEvent.self, from: Data(json.utf8))
    }
    @Test(arguments: ["rescheduled", "something_new"]) func neverThrows(status: String) throws {
        let e = try decode(status)
        #expect(e.status == (status == "rescheduled" ? .rescheduled : .unknown))
    }
}
```

### Push tap plan matrix (PUSH-01/02/03, BOOK-15)
```swift
@Test func requestPushOpensThatRequest() {
    let id = UUID()
    let e = PushEvent(userInfo: ["route_category": "booking", "route_sub_category": "requests",
                                 "booking_id": id.uuidString, "target_role": "expert"])
    let plan = PushRoutePlanner.plan(e, currentMode: .client, canUseExpertMode: true)
    #expect(plan == PushPlan(destination: .incomingRequest(bookingId: id), mode: .expert))
}
@Test func expertPushOnHalfSetUpAccountStaysClientAndOpensList() {
    let e = PushEvent(userInfo: ["route_category": "booking", "route_sub_category": "requests", "target_role": "expert"])
    #expect(PushRoutePlanner.plan(e, currentMode: .client, canUseExpertMode: false)
            == PushPlan(destination: .notificationsList, mode: nil))
}
@Test func categoryKeyIsIgnored() {          // D-05
    let e = PushEvent(userInfo: ["category": "booking", "sub_category": "requests"])
    #expect(e.category == nil)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| iOS routes on `category` | iOS routes on `route_category`; `category` is Android-only | 2026-11-08 (CR-01 hotfix, backend `215adcb`) | Build 6 taps do nothing until the new build; new build must use `route_*` |
| Hang-up completes the booking | Booking stays live; cron completes at end + 15; `/end` accepted until end + 70 | Aug 2026, extended by BACK-09 | Overtime to end + 60 is safe |
| Join window start ± 60 min | First join `max(end, start+60)`, reconnect to end + 60 once joined | BACK-09 (Phase 1) | iOS local rule must equal the server rule |
| Paid long-lead bookings via `confirm` without PI | Retired: `LONG_LEAD_NOT_AVAILABLE` | 2026-10-28 (quick 261028-uph) | iOS must not fall through to `performLongLeadBooking` |

**Deprecated/outdated:** the iOS comments saying the server `canJoin` is "~5 min" (`UpcomingBookingsView.swift:55-57`, `ExpertBookingItem.Actions` doc, `ExpertDashboardView.swift:475`); `docs/ios/CALL-END-SEMANTICS.md` title text still says "Not yet deployed" but BACK-09 sections are current.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Assigning `NavigationPath([route])` in one mutation shows the destination reliably without an intermediate empty-stack frame. Not tested here. | Pattern 8 | Reset and push could visibly flash or drop; fall back to reset then push next run-loop turn. Needs a device check. |
| A2 | After `Messaging.deleteToken`, FCM returns UNREGISTERED for the old token, so the backend reaper (`isStaleTokenError`) deletes the row on the next push. The SDK header confirms deletion of the token (FIRMessaging.h:322-335); the server-side effect is from Firebase's documented behavior, not tested here. | Pattern 9 | The old account could keep getting pushes until a new login on this device. Verify in the UAT (see Validation Architecture). |
| A3 | `ChatView.onDisappear` fires when the user switches tabs inside `TabView`, so `visibleThreadId` clears. | Pattern 10 | Banner suppressed for a chat that is on another tab. Verify on device. |
| A4 | The user accepts that Join no longer shows for `pending_reschedule` bookings (today's Explore/dashboard strips treat it as joinable). The server refuses it, so this is a correctness fix, but it changes visible behavior. | Pattern 2 | Users see a missing Join button on a booking with a pending reschedule. |
| A5 | No thousands separator in `Money` output (CONTEXT specifics show `¥1200`). Grouping would give `¥1,200`. | Pattern 4 | A test written from the CONTEXT example fails if grouping is added; or output looks unpolished for large amounts. |
| A6 | Suppressed foreground chat push uses `[]` (no banner, no sound, not in Notification Center). `[.list]` would keep it in Notification Center. | Pattern 10 | Minor UX difference. |
| A7 | CALL-05 ends the call through the normal end path with `EndReason.dropped` on `.failed`; the existing VM branch only sets the status. | Pattern 1 | If the planner only sets `.ended`, the screen stays on "Call Ended" with a live End button. |
| A8 | `canUseExpertMode` treats a failed `expertProfile` fetch as "cannot" (opens the notifications list). | Pattern 7 | An established expert on a flaky network lands on the list instead of the request. |

## Open Questions

1. **Thousands separators (A5).**
   - What we know: D-09/specifics show `¥1200` and the backend labels also have none.
   - What's unclear: whether `$1,200.00` is wanted for large amounts.
   - Recommendation: build without grouping (matches the locked example) behind one `Money` constant so it is a one-line flip.

2. **Join for `pending_reschedule` (A4).**
   - Recommendation: follow the server (not joinable) and list it in the Phase 2 UAT as an intentional change.

3. **CALL-05 device confirmation.**
   - What we know: the root cause is confirmed from the SDK header (`didOfflineOfUid` is remote-only), but `.failed` only appears after 20 minutes of failed reconnects or on join-failed/banned/token reasons, so a manual repro is slow.
   - Recommendation: fix with the unit-tested mapping; ask the user whether a 20-minute airplane-mode device check is required or whether the unit test plus one normal call regression check is enough to close it (REQUIREMENTS marks it "likely, may close as not reproducible").

4. **Client Cancel/Reschedule/Join/Leave Review are inert on push-opened detail screens (Phase 3 wiring).**
   - Recommendation: do not widen Phase 2. Record it in the Phase 2 UAT notes so the CR-01 pass criterion is "opens the screen, no warning page".

5. **Expert reschedule picker 6-day cap.**
   - What we know: server refuses paid reschedules beyond 6 days from both sides; Phase 3 owns EXP-13.
   - Recommendation: Phase 2 maps the code through the shared mapper on both sides and caps the client picker; the expert picker cap rides with EXP-13 unless the user wants it now.

6. **Broken test files.**
   - What we know: three test files do not compile; the workaround is a command-line exclusion.
   - Recommendation: keep the exclusion for Phase 2; optionally fix `LoginTests` and `AuthSmokeTests` (small) in Wave 0. Do not touch `SignupSmokeTests` (removed APIs).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / `xcodebuild` | Build, tests | ✓ | 26.5 (17F42) | — |
| iOS Simulator `iPhone 17` | Unit tests | ✓ | Shutdown, available | any iPhone 17 variant |
| Real iPhone | Push, Agora call, CR-01, logout UAT | not probeable from here | — | none (REL-01 requires it) |
| `swiftformat` | Manual formatting | ✓ | `/opt/homebrew/bin/swiftformat` | — |
| `swiftlint` | Lint (CI only) | ✗ locally | — | CI via `cirruslabs/swiftlint-action` |
| Node | Backend tests, only if a backend change appears | ✓ | v26.8.1 | none needed (no backend change planned) |
| Production backend / FCM / APNs | Push and logout UAT | live | `d86bf97` per STATE | — |

**Missing dependencies with no fallback:** none for planning. UAT needs a real iPhone and a second account to test cross-account push after logout.
**Missing dependencies with fallback:** SwiftLint (CI only).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`@Suite`, `@Test`, `#expect`), target `ClickMe2026Tests` (Swift 6.0) |
| Config file | `ClickMe2026/AllTests.xctestplan` (container fixed to `ClickMe.xcodeproj` in quick 261109-323) |
| Quick run command | `xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests/<Suite>` [VERIFIED: .planning/quick/261109-323-explore-home-feed-free-topic-decode/261109-323-PLAN.md:131] |
| Full suite command | same command without `-only-testing` |
| Build gate | `xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'`, then confirm no new warnings in touched files |

A targeted run includes simulator boot and build, so expect minutes, not the usual 30 seconds; the pure-helper suites themselves run in milliseconds. Use `set -o pipefail` and require a non-zero test count (`Test run with [1-9]`), as the previous quick task did.

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command (`-only-testing:`) | File Exists? |
|--------|----------|-----------|--------------------------------------|-------------|
| CALL-01 | `.none` before end+55, `.warn` at end+55, `.end` at end+60, nil end `.none`; cutoff constant is 3600 | unit | `ClickMe2026Tests/CallOvertimePolicyTests` | ❌ Wave 0 |
| CALL-04 | `endDuration` is ≥ 1 for a 0 s leg and nil join time | unit | `ClickMe2026Tests/CallOvertimePolicyTests` | ❌ Wave 0 |
| CALL-05 | (`.failed`, any) → `.disconnected`; (`.disconnected`, `.leaveChannel`) and initial `.disconnected` → no change; `.connected` → `.ready` | unit (mapping); device for the delegate | `ClickMe2026Tests/AgoraConnectionMappingTests` | ❌ Wave 0 |
| CALL-02 | matrix: start−61 m closed, start−60 m open, end open, long session at start+90 m open, end+30 m with server flag true/false/nil, `pendingApproval`/`pendingReschedule`/`cancelled` closed | unit | `ClickMe2026Tests/JoinWindowTests` | ❌ Wave 0 |
| CALL-09 | `us02web.zoom.us` zoom; `evilzoom.us`, `zoom.us.evil.com`, `notskype.com` unknown; case-insensitive; native schemes; nil; scheme-less string unknown | unit | `ClickMe2026Tests/ExternalMeetingProviderTests` | ❌ Wave 0 |
| BOOK-10 | 1250 USD `$12.50`; 1200 USD `$12.00`; 1250 CAD `CA$12.50`; 1200 JPY `¥1200`; 5 USD `$0.05`; negative; unknown code `XYZ 12.50`; `format(major:)` 75.5 → `$75.50` | unit | `ClickMe2026Tests/MoneyTests` | ❌ Wave 0 |
| BOOK-18 | `rescheduled` and unknown statuses decode, known ones unchanged, `EndCallData` tolerant | unit | `ClickMe2026Tests/BookingStatusDecodingTests` | ❌ Wave 0 |
| BOOK-14 | exactly 6 d allowed, 6 d + 1 s hidden, free topic uncapped; both new codes decode and map to clear copy | unit | `ClickMe2026Tests/PaidBookingWindowTests`, `ClickMe2026Tests/BookingErrorMapperTests` | ❌ Wave 0 |
| PAY-05 | same `ErrorCode` gives identical copy from the free and paid callers | unit | `ClickMe2026Tests/BookingErrorMapperTests` | ❌ Wave 0 |
| PUSH-01 | `route_category` parsed; `category` ignored; empty/unknown → notifications list; `event_type` fallback for chat | unit | `ClickMe2026Tests/PushEventTests`, `ClickMe2026Tests/PushRoutePlannerTests` | ❌ Wave 0 |
| PUSH-02 | role differs → mode switch; same or absent → stay; expert + cannot → list, stay client | unit | `ClickMe2026Tests/PushRoutePlannerTests` | ❌ Wave 0 |
| PUSH-03 | `booking/requests` + `booking_id` → `.incomingRequest(bookingId:)`; missing id → hub | unit | `ClickMe2026Tests/PushRoutePlannerTests` | ❌ Wave 0 |
| BOOK-15 | `booking/payment_actions` + `booking_id` → booking detail | unit | `ClickMe2026Tests/PushRoutePlannerTests` | ❌ Wave 0 |
| PUSH-04 | unregister runs before the session clears; timeout and failure still clear and set the marker; marker retry calls `deleteToken` once | unit with fakes; device for the real push | `ClickMe2026Tests/PushTokenCleanupTests` | ❌ Wave 0 |
| CHAT-09 | message push for the visible thread → `[]`; other thread, non-message, nil visible → full options | unit | `ClickMe2026Tests/PushForegroundPolicyTests` | ❌ Wave 0 |
| D-04 / CR-01 | booking push in client mode and in expert mode opens the screen with no warning page, warm and cold | device UAT (manual-only: SwiftUI navigation registration is not unit-testable) | UAT checklist | n/a |

### Sampling Rate
- **Per task commit:** the single suite for that task (command above).
- **Per wave merge:** full suite (with the exclusion) plus `xcodebuild build`.
- **Phase gate:** full suite green, no new warnings, device UAT of: CALL-01 overtime (call past end+55 shows the notice and ends at end+60), join button at the window edges, a payment-action push, a booking-request push in client and expert mode (cold and warm), logout then a push to the old account does not arrive on this device, a foreground push for the open chat shows no banner.

### Wave 0 Gaps
- [ ] All test files listed above under `ClickMe2026Tests/{Utils,Calls,Model,Push}/` (none exist).
- [ ] Decide the broken-test exclusion (Open Question 6); command above works today.
- [ ] A fake-injectable `PushTokenCleanup` and a pure `PushRoutePlanner` must exist before their tests can.
- [ ] UAT checklist file for the device checks, including the CR-01 booking-push step.

## Security Domain

`security_enforcement` is enabled (ASVS level 1).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (no credential flow changes) | — |
| V3 Session Management | yes (logout) | Await server-side unregister with the live bearer, invalidate the FCM token, then clear Valet tokens; retain no credential after logout (Pattern 9) |
| V4 Access Control | yes | `target_role` and `can_join` are display hints; every API call is authorized server-side [CITED: docs/ios/PUSH-ROUTING.md "a wrong hint cannot grant access"]. Do not gate anything sensitive on them client-side |
| V5 Input Validation | yes | Push `userInfo` is untrusted input: validate ids with `UUID(uuidString:)`, accept only `client`/`expert` for `target_role`, ignore unknown keys; host matching by exact/suffix, not `contains` |
| V6 Cryptography | no | — |
| V8 Data Protection | yes | Push payloads carry no free text (Phase 1 `in_app_meta` rule); do not log tokens or `userInfo`; existing DEBUG-only dump stays DEBUG-only and is not copied |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Next user receives the previous account's pushes on a shared device (PUSH-04) | Information disclosure | Awaited DELETE + `deleteToken` + marker retry; register guard during logout |
| Lookalike meeting URL labelled as a trusted provider (CALL-09) | Spoofing | Exact-or-suffix host match; no raw-string fallback |
| Crafted push payload navigates to an unregistered route or stale account state | Tampering / DoS | Planner maps only known categories; unknown → notifications list; pending cleared on logout; all `HomeRoute`s registered |
| Push for a different signed-in account routes into the wrong data | Information disclosure | Clear `pending` on logout; server authorizes every fetch (`GET /client/bookings/:id` 404s for others) |
| Booking error text from the server rendered unescaped | Tampering | Plain `Text`; branch on `ErrorCode`, not message |

## Sources

### Primary (HIGH confidence)
- iOS source read this session: `Model/Push/PushEvent.swift`, `Managers/PushRouter.swift`, `ClickMe2026AppDelegate.swift`, `HomeClientView.swift`, `HomeExpertView.swift`, `HomeNavigationPath.swift`, `MyBookingsView.swift`, `Managers/UserManager.swift`, `Managers/AgoraManager.swift`, `Managers/CallCenter.swift`, `MeetingCallViewModel.swift`, `MeetingCallView.swift`, `ExternalMeetingProvider.swift`, `UpcomingBooking.swift`, `BookingStatus.swift`, `RealtimeEvents.swift`, `RealtimeService.swift`, `ErrorCode.swift`, `StandardErrorResponse.swift`, `MakeABookingViewModel.swift`, `RescheduleViewModel.swift`, all money sites in Pattern 4, `ClickMe.xcodeproj/project.pbxproj`.
- Backend source and docs read this session: `docs/ios/PUSH-ROUTING.md`, `docs/ios/CALL-END-SEMANTICS.md`, `docs/SOCKET-CONTRACT.md`, `src/services/push.js`, `src/services/agora.js`, `src/controllers/notifications.controller.js`, `src/controllers/clientBooking.controller.js`, `expertBooking.controller.js`, `booking.controller.js`, `bookingRequests.controller.js`, `src/utils/{reschedule,pricing,earnings,formatPrice,bookingStatusSets}.js`, `src/schemas/call.schema.js`, `openapi/clickme-api.yaml` (long-lead and `can_join` sections).
- SDK headers/sources in DerivedData: `AgoraEnumerates.h` (`AgoraConnectionState`, `AgoraConnectionChangedReason`), `AgoraRtcEngineDelegate.h` (`connectionChangedToState`, `didOfflineOfUid`), `FIRMessaging.h` (`deleteTokenWithCompletion`), firebase-ios-sdk checkout 12.17.0.
- Android reference: `util/Money.kt`, `screens/push/PushEvent.kt`, `PushDestination.kt`, `makeabooking/BookingSlots.kt`, `reschedule/RescheduleRules.kt`, `ProposeErrors.kt`, `managers/FcmPushTokenRegistrar.kt`.
- Planning artifacts: `02-CONTEXT.md`, `REQUIREMENTS.md`, `STATE.md`, `ROADMAP.md`, `IOS-BUG-INVENTORY.md`, quick 261109-323 plan and summary.

### Secondary (MEDIUM confidence)
- None used.

### Tertiary (LOW confidence)
- Training knowledge for `NavigationPath` initializer behavior, FCM server-side behavior after `deleteToken`, and `TabView` lifecycle callbacks; all listed in the Assumptions Log. No web search or Context7 call was made: every checkable fact was available from local source or SDK headers, and no new library is introduced.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, no new dependencies; SDK APIs confirmed in headers.
- Architecture: HIGH for pure helpers and the CR-01/PUSH-04 root causes (read from code); MEDIUM for SwiftUI navigation behavior (A1, A3).
- Pitfalls: HIGH, each traced to a file and line.
- Backend contract: HIGH, read directly; no backend change needed.

**Research date:** 2026-11-09
**Valid until:** 2026-12-09 (the backend is live and Android launches ~2026-12-13; re-check `docs/ios/PUSH-ROUTING.md` if the backend changes push keys before this phase executes)
