---
phase: quick-261122-tcf
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - ClickMe2026/Model/Responses/RescheduleDeclineResponse.swift
  - ClickMe2026/Network/ClickMeAPI+Booking.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift
  - ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift
  - ClickMe2026Tests/Support/ClientBookingFixtures.swift
  - ClickMe2026Tests/Booking/RescheduleResponderTests.swift
  - ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift
  - ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift
  - ClickMe2026/Views/Screens/Chat/ChatStarter.swift
  - ClickMe2026Tests/Chat/ChatStarterTests.swift
  - ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsView.swift
  - ClickMe2026/Views/Screens/Expert Mode/Request decision/RequestDecisionView.swift
  - .planning/phases/03-booked-sessions-and-joining/03-REVIEW-DISPOSITION.md
  - .planning/phases/03-booked-sessions-and-joining/03-DEVICE-UAT-CHECKLIST.md
autonomous: true
requirements:
  - QUICK-261122-tcf

estimate:
  tokens: 120000
  raw_tokens: 120000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "T-03-23: after a 2xx decline on Upcoming Booking details, bookingStatus and statusRaw come from the response's data.status (for example pending_approval shows Pending approval, completed shows Completed), never a locally assumed confirmed. A status string this build does not know becomes .unknown with statusRaw kept, the same rule as the detail load. canJoin is reset to nil only when a status was returned"
    - "When the decline 200 has no data, data null, or no usable string status (missing, null, non-string, blank), the decline still succeeds: the 'Reschedule declined' toast shows, onResolved clears the proposal card, refetch runs, and apiError stays nil. bookingStatus, statusRaw and canJoin are left exactly as they were until the refetch lands"
    - "Booking Summary applies a returned decline status through its existing mapStatus (completed shows the Completed badge); with no usable status the badge is unchanged. On both screens a decline leaves the time unchanged and clears the card. Accept behavior is unchanged on both screens"
    - "WR-10: on the expert Booking Summary, the expert Upcoming Bookings list and Request Decision, a failed Message tap shows a 'Couldn't start chat' alert with an OK button: a 404 or NOT_FOUND reads 'This user is unavailable.' (ExpertProfileBlockViewModel.unavailableMessage), any other failure reads Error.userMessage, a cancelled request shows nothing. No optional-try swallows the initiate error"
    - "A second Message tap while the first initiate is in flight sends no second POST /chats/initiate, so the chat is pushed once. On the expert Booking Summary, Message Client shows a spinner and is disabled while the request runs"
    - "The expert Booking Summary reschedule Decline and Accept buttons are at least 44 pt tall, and their labels stay 'Decline' and 'Accept'"
    - "Android needs no change: its three expert Message controls already go through ChatEntryViewModel/ChatLauncher (single flight per peer, 404 unavailable copy, error dialog), and its client decline reloads instead of writing a status locally. This is re-checked at execution and recorded in the SUMMARY, and the Android repo gets no commit"
    - "03-REVIEW-DISPOSITION.md records IN-02 and WR-10 as fixed (open count 9), and 03-DEVICE-UAT-CHECKLIST.md has items 25 (T-03-23) and 26 (WR-10 and the 44 pt buttons), each with one Result line"
    - "The full iOS unit run passes, the Debug simulator build succeeds with no warning in a touched file, the code lands in two fix commits and the docs in one docs commit (all local, nothing pushed), and .planning/config.json, ClickMe2026/Localizable.xcstrings, .planning/state.json, .planning/milestone.lock and every .DS_Store stay unstaged"
  artifacts:
    - path: "ClickMe2026/Model/Responses/RescheduleDeclineResponse.swift"
      provides: "Tolerant decode of the decline 200 body plus a restoredStatus accessor (nil when absent or unusable)"
      contains: "restoredStatus"
    - path: "ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift"
      provides: "Resolution.declined(restoredStatus:) carrying the server's status to both owners"
      contains: "restoredStatus"
    - path: "ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift"
      provides: "applyResolution that writes the returned status, or leaves status untouched when none came back"
    - path: "ClickMe2026/Views/Screens/Chat/ChatStarter.swift"
      provides: "@MainActor @Observable single-flight initiateChat helper with isStarting and apiError"
      contains: "func start(peerId: UUID) async -> UUID?"
    - path: "ClickMe2026Tests/Chat/ChatStarterTests.swift"
      provides: "Success, 404, server-message, second-call and cancellation tests for ChatStarter"
    - path: "ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift"
      provides: "Message Client through ChatStarter with alert and busy state; 44 pt reschedule buttons"
      contains: "minHeight: 44"
  key_links:
    - from: "RescheduleResponder.decline(reason:)"
      to: "POST /client/bookings/:id/decline-reschedule 200 body data.status"
      via: "ClickMeAPI.declineClientReschedule returning RescheduleDeclineResponse"
      pattern: "onResolved?(.declined(restoredStatus:"
    - from: "RescheduleResponder.onResolved"
      to: "UpcomingBookingViewModel.applyResolution and BookingSummaryViewModel.applyResolution"
      via: "Resolution.declined(restoredStatus:) pattern match"
      pattern: "case .declined"
    - from: "ExpertBookingSummaryView / UpcomingBookingsView / RequestDecisionView handleMessage"
      to: "shell Chats tab"
      via: "ChatStarter.start(peerId:) then the existing openChatThread action"
      pattern: "chatStarter.start(peerId:"
---

<objective>
Close the Phase 03 review follow-ups the user approved on 2026-11-22.

1. T-03-23 (03-SECURITY.md, medium, regressed in 80f30d0): after a client declines an expert's reschedule, Upcoming Booking details sets the status to `confirmed` locally, but the server restores the prior status (`pending_approval`, `in_progress`, `completed` and so on) and already returns it as `data.status`. iOS throws that body away. The fix uses the returned status, and leaves the status unchanged until the refetch when none comes back. Booking Summary applies the returned status the same way. This regression touches BOOK-06 and BOOK-09.
2. WR-10 (03-REVIEW.md): the expert Message Client button on Booking Summary, and the same handler on the expert Upcoming Bookings list and Request Decision, swallow `initiateChat` failures and let a second tap push the chat twice. The fix is one shared single-flight `ChatStarter`, a "Couldn't start chat" alert and a busy state, mirroring the client fixes a74892c (IN-22) and f07660a (WR-12). The expert reschedule Decline and Accept buttons also go from 42 pt to a 44 pt minimum (03-UI-REVIEW item 3b).
3. Android parity: verified at planning time, no Android change is needed. The executor re-checks it and records the result.
4. Docs: IN-02 and WR-10 are marked fixed in 03-REVIEW-DISPOSITION.md, and two device-check items are added to 03-DEVICE-UAT-CHECKLIST.md.

Purpose: a client who declines a new time sees the booking's real state, and an expert who taps Message gets the chat once, or is told why it could not open. iOS only. No backend change, so the backend freeze and the live App Store build are unaffected.
Output: two iOS fix commits (13 code and test files plus one shared fixture file), one docs commit (two Phase 03 docs), no Android or backend commit, nothing pushed.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@CLAUDE.md
@.claude/CLAUDE.md
@.planning/phases/03-booked-sessions-and-joining/03-SECURITY.md
@.planning/phases/03-booked-sessions-and-joining/03-REVIEW.md
@.planning/phases/03-booked-sessions-and-joining/03-REVIEW-DISPOSITION.md

Verified facts (checked at planning time, do not re-derive):

- **Backend decline contract (no backend change).** `declineReschedule` in `../ClickMe2026 Backend/src/controllers/clientBooking.controller.js` (about lines 692-795, backend HEAD e36da57) answers every 200 with `{"status":"success","message":"Reschedule declined; the original booking time stands.","data":{"booking_id":"<uuid>","status":"<status>"}}`. That covers three paths: the normal decline, the idempotent 200 when the booking is no longer `pending_reschedule`, and the 0-rows race. On the normal path, `status` is `reschedule_prev_status || 'confirmed'`. The prior status can be `confirmed`, `pending_approval`, `completed` or `in_progress` (`src/utils/reschedule.js` NO_TIME_GATE_STATUSES and TIME_GATED_STATUSES). The idempotent path returns whatever the booking's current status is. `openapi/clickme-api.yaml` `/client/bookings/{id}/decline-reschedule` documents `data.booking_id` (uuid) and `data.status` (string). Android decodes the same body as `RescheduleResponseData(bookingId: String?, status: String?)` in `model/responses/BookingActionResponses.kt`.
- **iOS today.** `ClickMeAPI.declineClientReschedule(id:reason:)` (`ClickMe2026/Network/ClickMeAPI+Booking.swift` about line 210) returns `SuccessMessageResponse` (`status`, `message` only). The JSON decoder uses `.convertFromSnakeCase`, as `InitiateChatPayload.threadId` shows. `RescheduleResponder.Resolution` has the cases `.accepted` and `.declined`. `decline(reason:)` discards the response and calls `onResolved?(.declined)` (about line 171). `UpcomingBookingViewModel.applyResolution` (about lines 335-345) sets `bookingStatus = .confirmed`, `statusRaw = "confirmed"` and `canJoin = nil` for both cases. Its `apply` load path maps a raw status as `BookingStatus(rawValue: raw) ?? .unknown` and keeps `statusRaw = raw` (about line 399). `pendingProposal` is `bookingStatus == .pendingReschedule ? reschedule : nil`, so clearing `reschedule` hides the card whatever the status is. `BookingSummaryViewModel.applyResolution` (about line 267) never touches `status: PastBookingStatus?`, which is set through `private static func mapStatus(_:)` (about line 353).
- **iOS expert decline** (`ExpertBookingSummaryViewModel.declineReschedule`) writes no local status. It is out of scope.
- **Tests at HEAD.** `@Test` line counts: RescheduleResponderTests 33, UpcomingBookingViewModelTests 26, BookingSummaryViewModelTests 22. `ClientBookingFixtures.successMessage` is `{"status":"success","message":"ok"}`, which has no `data`. That is the "absent status" case. `RescheduleResponderTests.makeLoggingResponder` logs `"resolved \(resolution)"`, and `declineResolvesBeforeRefetch` expects `["resolved declined", "refetch"]`. `UpcomingBookingViewModelTests.declineWithFailedRefetchClearsProposal` asserts the status is not `.pendingReschedule` after a decline whose body has no `data`. That assertion encodes the old guess and must change. `failedRefetchIsRetriedOnce` still holds: a third GET returns `pending_approval`. Its comment about the screen assuming `confirmed` needs rewording. Both VM suites have a private `failingRefetchAPI()` that answers both answer POSTs with `Fixtures.successMessage`.
- **Chat start today.** All three expert handlers call `ClickMeAPI.shared.initiateChat` through an optional try, with no in-flight guard. The handlers are `ExpertBookingSummaryView.handleMessage(detail:)` (about line 849), `UpcomingBookingsView.handleMessage(for:)` (about line 358) and `RequestDecisionView.handleMessage()` (about line 278). Each guards `openChatThread` first. Baseline at HEAD: each file has 1 such call and 0 "Couldn't start chat". The reference implementation is `BookingSummaryViewModel.startChat()` (about lines 404-437): a single-flight flag, `apiError = nil` at the start, the `error.isCancellation` early return, a 404 status or `BookingErrorMapper.code == .notFound` mapped to `ExpertProfileBlockViewModel.unavailableMessage`, and otherwise `error.userMessage`. The alert pattern is `BookingSummaryView.swift` about lines 134-145 (title "Couldn't start chat", a `Button("OK", role: .cancel)`, `Text(message)`). The spinner pattern is the `isMessageBusy` button in `Client Mode/Booking Summary/Subviews/BookingSummaryActions.swift` about lines 49-72. The test pattern is `BookingSummaryViewModelTests` about lines 400-548 (`initiatePosts()`, `initiateSuccess`, `RequestGate`, `waitUntil`, and the cancellation row).
- **Precedent for an @Observable helper inside ObservableObject screens.** `RescheduleResponder` (`@MainActor @Observable`). The project uses synchronized folder groups (`PBXFileSystemSynchronizedRootGroup`), so a new Swift file needs no pbxproj edit.
- **Buttons.** `ExpertBookingSummaryView.rescheduleActionButtons` (about lines 654-697) has two 42 pt fixed-height frames, on Decline and Accept. Baseline at HEAD: `minHeight: 44` appears 0 times in the file. 03-UI-SPEC's "Accept New Time / Decline New Time" copy and the 44 pt exception are written for the client's shared reschedule response card. The expert summary pair is a different control, Android labels it "Accept", and renaming would add new catalog strings while Localizable.xcstrings has unrelated uncommitted changes. So the labels stay "Decline" and "Accept" (Claude's discretion, per the user's "do not scope-creep").
- **Android (../ClickMe_Android, HEAD e311a74c, `app/src` clean).** Expert Message controls call `chatEntry.open(ChatPeer(...))` in `screens/expertmode/bookingsummary/ExpertBookingSummaryScreen.kt` (about line 187), `screens/expertmode/upcomingbookings/ExpertBookingsScreen.kt` (about line 131) and `screens/expertmode/requestdecision/RequestDecisionScreen.kt` (about line 117). `screens/chat/ChatLauncher.kt` allows one initiate per peer (`AlreadyOpening`) and maps a 404 to `chat_entry_error_unavailable`. `ChatEntryViewModel` shows the error dialog and the busy state. For the client decline, `screens/clientmode/mybookings/RescheduleResponse.kt` routes `DeclineOutcome.Declined -> succeed(RescheduleNotice.Declined)`, and `succeed` calls `reload()`. No Android client view model writes a confirmed status. Both gaps are already handled on Android.
- **Docs baselines.** In 03-REVIEW-DISPOSITION.md, IN-02 and WR-10 are `open` and `open: 11`. 03-DEVICE-UAT-CHECKLIST.md has 24 `### ` items and 24 `^Result:` lines, and its last item is `### 24.`, followed by `---` and `## Sign-off`.

Working-tree rules: execute sequentially on the main tree. Another session may be committing Phase 08 docs, so never touch `.planning/phases/08-release/*`, `.planning/STATE.md` or `.planning/ROADMAP.md` from a task. Stage only by explicit path (never `git add -A`, `git add .` or `git commit -a`). Never stage `.planning/config.json`, `ClickMe2026/Localizable.xcstrings`, `.planning/state.json`, `.planning/milestone.lock` or any `.DS_Store`, even if a build rewrites the catalog. Add no new user-facing strings: reuse "Couldn't start chat", "OK" and `ExpertProfileBlockViewModel.unavailableMessage`. Push nothing in any repo.
</context>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: Decline uses the server's restored status, end to end (T-03-23)</name>
  <files>ClickMe2026/Model/Responses/RescheduleDeclineResponse.swift, ClickMe2026/Network/ClickMeAPI+Booking.swift, ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift, ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift, ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift, ClickMe2026Tests/Support/ClientBookingFixtures.swift, ClickMe2026Tests/Booking/RescheduleResponderTests.swift, ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift, ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift</files>
  <read_first>The ~line ranges named in context for RescheduleResponder.swift (whole file), UpcomingBookingViewModel.swift 310-410, BookingSummaryViewModel.swift 250-360, RescheduleResponderTests.swift 14-66 and 380-445, UpcomingBookingViewModelTests.swift 325-435, BookingSummaryViewModelTests.swift 115-200, ClientBookingFixtures.swift 90-120, and one neighbouring response model in ClickMe2026/Model/Responses for the header and doc-comment style.</read_first>
  <behavior>
    - Responder: a decline 200 whose body has data.status "pending_approval" calls onResolved with .declined(restoredStatus: "pending_approval"), then refetch, with no apiError
    - Responder: a decline 200 with no data (Fixtures.successMessage) calls onResolved with .declined(restoredStatus: nil), still shows the "Reschedule declined" toast, refetches once and sets no apiError
    - Responder: a decline 200 with "data":null, or with a non-string or blank status (for example 5 or "  "), still succeeds with restoredStatus nil (parameterized is fine)
    - Responder: the existing call-order test now expects the log entries "resolved declined nil" then "refetch". The accept rows still log "resolved accepted"
    - Upcoming: a decline returning "pending_approval", with every later detail GET failing, leaves bookingStatus .pendingApproval, statusRaw "pending_approval", canJoin nil, reschedule nil, pendingProposal nil, the start time unchanged and state .loaded. This replaces the old not-pendingReschedule assertion
    - Upcoming: a decline with no data, with every later GET failing, keeps bookingStatus .pendingReschedule and statusRaw "pending_reschedule", but reschedule and pendingProposal are nil and apiError is nil
    - Upcoming: a decline returning an unknown string (for example "on_hold") gives bookingStatus .unknown with statusRaw "on_hold"
    - Booking Summary: a decline returning "completed", with failing refetches, sets status .completed and keeps dateTime. A decline with no data leaves status as it was after load (nil for the pending_reschedule detail)
    - All existing accept rows on the three suites pass unchanged
  </behavior>
  <action>Write the new and changed test rows above first (RED: they fail to compile or fail), then implement. All of this implements T-03-23 and keeps the WR-01 and WR-08 call order (onResolved before refetch, never on failure).

1. Fixtures: add to `ClientBookingFixtures` a static helper `declineSuccess(status:)` that returns the backend's decline 200 body. The body carries `data.booking_id` equal to `bookingId` and `data.status` equal to the given string. Add a raw-JSON variant, or let the tests inline literals for the null-data and non-string-status cases.

2. Model: create `ClickMe2026/Model/Responses/RescheduleDeclineResponse.swift` with the standard Xcode header. It declares `struct RescheduleDeclineResponse: Decodable` with `status: String`, `message: String?` and `data: RescheduleResponseData?`, plus a nested or file-level `RescheduleResponseData` that keeps only `status: String?`. Name it to match Android's `RescheduleResponseData`, and leave out booking_id because nothing reads it and a non-UUID value must never fail the decode. Decoding must never turn a 2xx into a failure because of `data`. Write a custom `init(from:)` that reads `data`, and the payload's `status`, as best-effort optional reads. A missing key, `null`, a non-object `data` or a non-string `status` each yields nil. A best-effort optional read is the documented allowed use in CLAUDE.md. Add a computed `restoredStatus: String?` that returns the status trimmed of whitespace, or nil when it is empty. In the doc comment, cite `/client/bookings/{id}/decline-reschedule` in `openapi/clickme-api.yaml` and say why the decode is tolerant.

3. Network: `declineClientReschedule(id:reason:)` returns `RescheduleDeclineResponse`. Update its doc comment: the 200 carries `data.status`, which is the restored `reschedule_prev_status` (or `confirmed` for pre-migration rows), or the current status on the idempotent 200. Android reads the same field.

4. Responder: change `Resolution.declined` to `case declined(restoredStatus: String?)`, keeping it `Equatable`. Rewrite both case doc comments: accept means the server set `confirmed`. Decline carries the status the server restored, or nil when the body did not say, in which case the owner must leave its status alone. In `decline(reason:)`, keep the response and call `onResolved?(.declined(restoredStatus: response.restoredStatus))`. Leave the toast, the refetch, the error path and the accept paths unchanged.

5. Upcoming: in `applyResolution`, switch over the resolution. `.accepted` keeps today's behavior: the times move to the proposal, `bookingStatus` becomes `.confirmed`, `statusRaw` becomes "confirmed", and `canJoin` becomes nil. `.declined(let raw)`: when raw is non-nil, set `bookingStatus = BookingStatus(rawValue: raw) ?? .unknown` and `statusRaw = raw` (the same rule as the load path), and set `canJoin = nil`. When raw is nil, leave `bookingStatus`, `statusRaw` and `canJoin` untouched. In every case set `reschedule = nil`. Replace the doc comment's line that `confirmed` stands in until the refetch with the new rule, and keep the WR-01 and WR-08 references.

6. Booking Summary: in `applyResolution`, `.accepted` is unchanged. For `.declined(let raw)`, when raw is non-nil set `status = Self.mapStatus(raw)`. The time is unchanged in every case, and `reschedule` is always set to nil. Update the doc comment.

7. Tests: in `RescheduleResponderTests.makeLoggingResponder`, map the resolution through a switch to stable strings: "resolved accepted", or "resolved declined " followed by the status or "nil". Update `declineResolvesBeforeRefetch` to match. Give each VM suite's `failingRefetchAPI` a `declineBody: Data = Fixtures.successMessage` parameter used only for the decline POST, keeping the accept POST on `successMessage`. Reword the `failedRefetchIsRetriedOnce` comment so it no longer says the screen assumed `confirmed`. Add the rows in behavior. Expected `@Test` counts afterwards: at least 36 / 28 / 24.

Do not touch the expert reschedule paths, `SuccessMessageResponse` (other endpoints use it), the accept call, or any view file. Follow the file-header, `// MARK:` and `///` conventions of the neighbouring files.</action>
  <verify>
    <automated>xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests/RescheduleResponderTests -only-testing:ClickMe2026Tests/UpcomingBookingViewModelTests -only-testing:ClickMe2026Tests/BookingSummaryViewModelTests 2>&1 | tee /tmp/261122-tcf-t1.log | tail -30 && grep -Eq 'Test run with [1-9][0-9]* tests? in [0-9]+ suites? passed' /tmp/261122-tcf-t1.log && test "$(grep -c '@Test' ClickMe2026Tests/Booking/RescheduleResponderTests.swift)" -ge 36 && test "$(grep -c '@Test' ClickMe2026Tests/Booking/UpcomingBookingViewModelTests.swift)" -ge 28 && test "$(grep -c '@Test' ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift)" -ge 24 && test -f ClickMe2026/Model/Responses/RescheduleDeclineResponse.swift && grep -q 'restoredStatus' ClickMe2026/Model/Responses/RescheduleDeclineResponse.swift && grep -q 'case declined(restoredStatus: String?)' 'ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift' && grep -q 'onResolved?(.declined(restoredStatus:' 'ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift' && grep -q 'async throws -> RescheduleDeclineResponse' ClickMe2026/Network/ClickMeAPI+Booking.swift && test -z "$(grep -E 'warning:' /tmp/261122-tcf-t1.log | grep -E '/(RescheduleDeclineResponse|ClickMeAPI\+Booking|RescheduleResponder|UpcomingBookingViewModel|BookingSummaryViewModel|ClientBookingFixtures)(Tests)?\.swift')"</automated>
  </verify>
  <done>The three suites pass with at least 36 / 28 / 24 tests. A decline that returns a status shows that status on Upcoming details (and the mapped badge on Booking Summary), and a decline without one leaves the status alone while the card still goes. No touched file has a warning. Commit exactly these nine files, staged by explicit path, as `fix(quick-261122-tcf): use the server's restored status after a reschedule decline (T-03-23)`.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Expert Message buttons report failures and ignore a second tap; 44 pt reschedule buttons (WR-10)</name>
  <files>ClickMe2026/Views/Screens/Chat/ChatStarter.swift, ClickMe2026Tests/Chat/ChatStarterTests.swift, ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift, ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsView.swift, ClickMe2026/Views/Screens/Expert Mode/Request decision/RequestDecisionView.swift</files>
  <read_first>BookingSummaryViewModel.swift about lines 400-438 (the reference startChat), BookingSummaryView.swift about lines 120-146 and 305-322 (alert and handler), Subviews/BookingSummaryActions.swift about lines 40-73 (busy button), BookingSummaryViewModelTests.swift about lines 395-548 (the chat test harness), RescheduleResponder.swift lines 1-90 (the @Observable helper shape), and in each expert view its handleMessage and the existing alert modifiers on its body. In ExpertBookingSummaryView also read messageClientButton (about lines 777-830) and rescheduleActionButtons (about lines 654-697).</read_first>
  <behavior>
    - start(peerId:) on success sends one POST /chats/initiate whose JSON peer_id is the given id, returns the thread id, and leaves isStarting false and apiError nil
    - A 404 NOT_FOUND returns nil and sets apiError to ExpertProfileBlockViewModel.unavailableMessage
    - A 500 with a server message returns nil and sets apiError to that message (Error.userMessage)
    - A second start while the first is held in flight returns nil at once, and the recorded POST count stays 1. The first call then completes with the thread id
    - A cancelled request returns nil and leaves apiError nil
    - A new start clears a previous apiError before it sends
  </behavior>
  <action>Implements WR-10 from 03-REVIEW.md and UI-REVIEW item 3b. It mirrors the client fixes a74892c (IN-22) and f07660a (WR-12), using one shared helper so the 404 mapping is not copied into three more view models (CLAUDE.md: extract new logic into a sibling type).

1. Create `ClickMe2026/Views/Screens/Chat/ChatStarter.swift`. It holds a `@MainActor @Observable final class ChatStarter` with `private(set) var isStarting = false`, `var apiError: String?`, and an `@ObservationIgnored private let api: ClickMeAPI` injected via `init(api: ClickMeAPI = .shared)`. Its `func start(peerId: UUID) async -> UUID?` ports `BookingSummaryViewModel.startChat()` exactly. It returns nil when `isStarting` is already true, with no request. Otherwise it sets the flag (reset in `defer`), clears `apiError`, and returns `try await api.initiateChat(peerId:).data.threadId` inside do/catch. In the catch, a cancellation returns nil silently. A 404 status or `BookingErrorMapper.code(for:) == .notFound` sets `ExpertProfileBlockViewModel.unavailableMessage`. Anything else sets `error.userMessage`. Then it returns nil. The doc comment says why: one in-flight initiate per screen, and the error is shown, never swallowed (WR-10). Leave the two client view models' own startChat untouched.

2. Write `ClickMe2026Tests/Chat/ChatStarterTests.swift` first (RED) as `@Suite("Chat starter", .serialized) @MainActor struct ChatStarterTests` with the rows in behavior, at least 5 `@Test`. Build on the BookingSummaryViewModelTests chat harness: `APITestFactory.make`, `ClientBookingFixtures.response(for:status:body:)` and `errorBody(code:message:)`, `MockURLProtocol.recordedRequests`, `URLRequest.jsonBodyForTest()`, `RequestGate` and `waitUntil`, plus its cancellation technique. Then implement ChatStarter until GREEN.

3. In each of the three expert views, add `@State private var chatStarter = ChatStarter()`. Rewrite the view's handleMessage so that, after the existing `openChatThread` guard (and in RequestDecisionView the `viewModel.clientId` guard), it starts a `Task` that awaits `chatStarter.start(peerId:)` with the same client id as today, returns on nil, and then calls `openChatThread(threadId:peerName:peerAvatarURL:)` with today's name and avatar values. Remove the silent optional-try initiate call entirely, and do not quote it in a comment. Next to the view's existing alerts, attach a "Couldn't start chat" `.alert` bound to `chatStarter.apiError` (the same Binding get/set, `presenting:`, `Button("OK", role: .cancel) {}` and `Text(message)` shape as BookingSummaryView). Update each handler's doc comment to say a failure raises the alert and a second tap while one runs is ignored.

4. ExpertBookingSummaryView only: in messageClientButton, show a small `ProgressView` tinted to the label colour in place of the `bubble.left.fill` icon while `chatStarter.isStarting`, and add `.disabled(chatStarter.isStarting)`, as BookingSummaryActions does. Keep the existing outlined and filled styles. UpcomingBookingsView and RequestDecisionView keep their row and footer subviews unchanged, and rely on the single-flight guard plus the alert.

5. ExpertBookingSummaryView rescheduleActionButtons: on both the Decline and the Accept labels, replace the fixed 42 pt height frame with `.frame(minHeight: 44)` (03-UI-SPEC: no control under 44 pt). Keep the labels "Decline" and "Accept", the 10 pt radius, colours and disabled logic unchanged (UI-SPEC copy contract is for the client card; see context).

Add no new user-facing strings. Do not touch ExpertBookingSummaryViewModel, UpcomingBookingsViewModel, RequestDecisionViewModel or the row and footer subviews.</action>
  <verify>
    <automated>E='ClickMe2026/Views/Screens/Expert Mode'; S="$E/Booking Summary/ExpertBookingSummaryView.swift"; U="$E/Upcoming Bookings/UpcomingBookingsView.swift"; R="$E/Request decision/RequestDecisionView.swift"; xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests/ChatStarterTests 2>&1 | tee /tmp/261122-tcf-t2.log | tail -30 && grep -Eq 'Test run with [1-9][0-9]* tests? in [0-9]+ suites? passed' /tmp/261122-tcf-t2.log && test "$(grep -c '@Test' ClickMe2026Tests/Chat/ChatStarterTests.swift)" -ge 5 && grep -q 'func start(peerId: UUID) async -> UUID?' ClickMe2026/Views/Screens/Chat/ChatStarter.swift && test "$(grep -c 'try? await ClickMeAPI.shared.initiateChat' "$S")" -eq 0 && test "$(grep -c 'try? await ClickMeAPI.shared.initiateChat' "$U")" -eq 0 && test "$(grep -c 'try? await ClickMeAPI.shared.initiateChat' "$R")" -eq 0 && grep -q 'chatStarter.start(peerId:' "$S" && grep -q 'chatStarter.start(peerId:' "$U" && grep -q 'chatStarter.start(peerId:' "$R" && grep -q "Couldn't start chat" "$S" && grep -q "Couldn't start chat" "$U" && grep -q "Couldn't start chat" "$R" && grep -q 'disabled(chatStarter.isStarting)' "$S" && test "$(grep -c 'frame(height: 42)' "$S")" -eq 0 && test "$(grep -c 'minHeight: 44' "$S")" -ge 2 && test -z "$(grep -E 'warning:' /tmp/261122-tcf-t2.log | grep -E '/(ChatStarter|ExpertBookingSummaryView|UpcomingBookingsView|RequestDecisionView)(Tests)?\.swift')"</automated>
  </verify>
  <done>ChatStarterTests passes with at least 5 tests. All three expert Message handlers go through ChatStarter, raise "Couldn't start chat" on failure and send one request per in-flight tap. Message Client on the expert Booking Summary shows a spinner and is disabled while it runs. The reschedule Decline and Accept buttons are at least 44 pt tall with unchanged labels, and no touched file has a warning. Commit exactly these five files, staged by explicit path, as `fix(quick-261122-tcf): expert Message buttons show errors and ignore a second tap; 44 pt reschedule buttons (WR-10)`.</done>
</task>

<task type="auto">
  <name>Task 3: Record Android parity, update the Phase 03 docs, run the full gate</name>
  <files>.planning/phases/03-booked-sessions-and-joining/03-REVIEW-DISPOSITION.md, .planning/phases/03-booked-sessions-and-joining/03-DEVICE-UAT-CHECKLIST.md</files>
  <precondition>../ClickMe_Android exists and its app/src has no uncommitted changes (git -C ../ClickMe_Android status --short -- app/src prints nothing).</precondition>
  <read_first>03-REVIEW-DISPOSITION.md (whole file), 03-DEVICE-UAT-CHECKLIST.md lines 1-30 and 294-392 (setup, the item format, the last item and Sign-off).</read_first>
  <action>1. Android parity (no code change; scope authorized from the planning-time observation in context). Run the first automated block's Android greps. If they all pass, record in the SUMMARY that Android already handles both items and that the Android repo is untouched. Name the files: ChatEntryViewModel/ChatLauncher on ExpertBookingSummaryScreen.kt, ExpertBookingsScreen.kt and RequestDecisionScreen.kt, plus the client decline's succeed() reload in RescheduleResponse.kt. If any Android grep fails, Android has changed since planning. Do not edit the Android repo under this plan. Record the failing check in the SUMMARY as an open Android follow-up and tell the user.

2. 03-REVIEW-DISPOSITION.md (doc-only). In the frontmatter, set `disposition: fixed` for IN-02 and for WR-10, and change `open: 11` to `open: 9`. Leave `total` and `recorded` alone. In the table, set the IN-02 row to `| IN-02 | info | fixed | HomeClientView.swift:394-398 comment records the pop(2) invariant (03-REVIEW.md) (not in the current review) |`. Set the WR-10 row to `| WR-10 | warning | fixed | quick 261122-tcf (ChatStarter on the three expert Message buttons) |`. Change no other row.

3. 03-DEVICE-UAT-CHECKLIST.md: insert two items after item 24's `Result:` line and before the `---` that precedes `## Sign-off`, in the same format: a `**Status:** PENDING. Added by quick task 261122-tcf.` line, `Steps:`, `Expected:` and an empty `Result:` line.
   - `### 25. T-03-23 — declining a reschedule shows the booking's restored status (quick 261122-tcf)`. Step 1: on a booking that is Pending approval (if neither app lets B propose a new time on a pending request, use a completed session whose original end time has not passed), B proposes a new time from the second device, and A taps Decline New Time on Upcoming details. Expected: the "Reschedule declined" toast, the card gone, and the pill showing that booking's earlier status (Pending approval, or Completed), never Confirmed. Join follows that status. Step 2: repeat on a Confirmed booking. Expected: the pill reads Confirmed. If step 1's booking cannot be set up, record SKIPPED (why) for that step only.
   - `### 26. WR-10 — expert Message errors and second taps; 44 pt reschedule buttons (quick 261122-tcf)`. Step 1: as B on the expert Booking Summary, double-tap Message Client. Expected: one chat opens, one Back returns, and a spinner shows with the button disabled while the request runs. Step 2: in airplane mode, tap Message Client. Expected: a "Couldn't start chat" alert with a readable message, and OK dismisses it. Step 3: repeat steps 1 and 2 from a Bookings-tab Upcoming row's Message and from a pending request's Request Decision Message. Expected: the same single open and the same alert (no spinner on these two). Step 4: on a booking where A proposed a new time, open the expert Booking Summary. Expected: Decline and Accept are at least 44 pt tall and easy to hit, and the labels are unchanged.
   Afterwards the file has 26 `### ` items and 26 `^Result:` lines. Leave Sign-off unchanged.

4. Run the second automated block (full unit run and the Debug build). Then commit the two docs files only, staged by explicit path, as `docs(quick-261122-tcf): mark IN-02 and WR-10 fixed; add device checks 25-26`. Then run the third block (commit shape). Push nothing. Stage nothing outside these paths, even if a build rewrote the string catalog.</action>
  <verify>
    <automated>A=../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens; grep -q 'chatEntry.open(ChatPeer(' "$A/expertmode/bookingsummary/ExpertBookingSummaryScreen.kt" && grep -q 'chatEntry.open(ChatPeer(' "$A/expertmode/upcomingbookings/ExpertBookingsScreen.kt" && grep -q 'chatEntry.open(ChatPeer(' "$A/expertmode/requestdecision/RequestDecisionScreen.kt" && grep -q 'AlreadyOpening' "$A/chat/ChatLauncher.kt" && grep -q 'status == STATUS_NOT_FOUND' "$A/chat/ChatLauncher.kt" && grep -q 'DeclineOutcome.Declined -> succeed(RescheduleNotice.Declined)' "$A/clientmode/mybookings/RescheduleResponse.kt" && grep -A2 'private suspend fun succeed' "$A/clientmode/mybookings/RescheduleResponse.kt" | grep -q 'reload()' && test -z "$(grep -nE 'CONFIRMED|"confirmed"' "$A/clientmode/upcomingbooking/UpcomingBookingViewModel.kt" "$A/clientmode/bookingsummary/BookingSummaryViewModel.kt")" && test -z "$(git -C ../ClickMe_Android status --short -- app/src)" && D=.planning/phases/03-booked-sessions-and-joining/03-REVIEW-DISPOSITION.md && grep -A2 'id: IN-02' "$D" | grep -q 'disposition: fixed' && grep -A2 'id: WR-10' "$D" | grep -q 'disposition: fixed' && grep -q '^open: 9$' "$D" && grep -q '^| IN-02 | info | fixed |' "$D" && grep -q '^| WR-10 | warning | fixed | quick 261122-tcf' "$D" && K=.planning/phases/03-booked-sessions-and-joining/03-DEVICE-UAT-CHECKLIST.md && test "$(grep -n '^### ' "$K" | wc -l | tr -d ' ')" -eq 26 && test "$(grep -n '^Result:' "$K" | wc -l | tr -d ' ')" -eq 26 && grep -q '^### 25\. T-03-23' "$K" && grep -q '^### 26\. WR-10' "$K" && test "$(awk '/^### 25\./,/^## Sign-off/' "$K" | grep -n '^Result:' | wc -l | tr -d ' ')" -eq 2</automated>
    <automated>xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests 2>&1 | tee /tmp/261122-tcf-full.log | tail -30 && grep -Eq 'Test run with [1-9][0-9]* tests? in [0-9]+ suites? passed' /tmp/261122-tcf-full.log && touch ClickMe2026/Model/Responses/RescheduleDeclineResponse.swift ClickMe2026/Network/ClickMeAPI+Booking.swift 'ClickMe2026/Views/Screens/Client Mode/Booking Summary/RescheduleResponder.swift' 'ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details/UpcomingBookingViewModel.swift' 'ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift' ClickMe2026/Views/Screens/Chat/ChatStarter.swift 'ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift' 'ClickMe2026/Views/Screens/Expert Mode/Upcoming Bookings/UpcomingBookingsView.swift' 'ClickMe2026/Views/Screens/Expert Mode/Request decision/RequestDecisionView.swift' && xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 2>&1 | tee /tmp/261122-tcf-build.log | tail -5 && grep -q 'BUILD SUCCEEDED' /tmp/261122-tcf-build.log && test -z "$(grep -hE 'warning:' /tmp/261122-tcf-full.log /tmp/261122-tcf-build.log | grep -E '/(RescheduleDeclineResponse|ClickMeAPI\+Booking|RescheduleResponder|UpcomingBookingViewModel|BookingSummaryViewModel|ClientBookingFixtures|ChatStarter|ExpertBookingSummaryView|UpcomingBookingsView|RequestDecisionView)(Tests)?\.swift')"</automated>
    <automated>FIX=$(git log --format=%H --grep='^fix(quick-261122-tcf)') && DOC=$(git log -1 --format=%H --grep='^docs(quick-261122-tcf)') && test "$(printf '%s\n' $FIX | wc -l | tr -d ' ')" -eq 2 && test -n "$DOC" && FF=$(for c in $FIX; do git show --format= --name-only "$c" || exit 1; done) && DF=$(git show --format= --name-only "$DOC") && test "$(printf '%s\n' "$FF" | sed '/^$/d' | wc -l | tr -d ' ')" -eq 14 && test "$(printf '%s\n' "$DF" | sed '/^$/d' | wc -l | tr -d ' ')" -eq 2 && test -z "$(printf '%s\n' "$DF" | grep -v '^\.planning/phases/03-booked-sessions-and-joining/03-\(REVIEW-DISPOSITION\|DEVICE-UAT-CHECKLIST\)\.md$')" && test -z "$(printf '%s\n' "$FF" "$DF" | grep -E 'Localizable\.xcstrings|config\.json|\.DS_Store|milestone\.lock|state\.json|phases/08-release|STATE\.md|ROADMAP\.md')" && test -z "$(git status --short -- ClickMe2026/Model/Responses ClickMe2026/Network 'ClickMe2026/Views/Screens/Client Mode/Booking Summary' 'ClickMe2026/Views/Screens/Client Mode/Upcoming Booking Details' ClickMe2026/Views/Screens/Chat 'ClickMe2026/Views/Screens/Expert Mode' ClickMe2026Tests/Booking ClickMe2026Tests/Chat ClickMe2026Tests/Support .planning/phases/03-booked-sessions-and-joining)"</automated>
    <human-check>Later, on a real iPhone: 03-DEVICE-UAT-CHECKLIST.md items 25 and 26. Not run by Claude.</human-check>
  </verify>
  <done>The Android checks pass and the SUMMARY records that Android needed no change (no Android commit). The disposition shows IN-02 and WR-10 fixed with open 9. The checklist has items 25 and 26 and 26 Result lines. The full unit run passes and the Debug build succeeds with no warning in a touched file. There are two `fix(quick-261122-tcf)` commits holding the 14 code and test files, and one `docs(quick-261122-tcf)` commit holding only the two Phase 03 docs. The touched paths are clean, the unrelated dirty files are still unstaged, and nothing is pushed.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| backend decline 200 to iOS UI | `data.status` from `POST /client/bookings/:id/decline-reschedule` now drives the status pill, the Join card state and the Booking Summary badge |
| iOS client to backend `POST /chats/initiate` | The client sends a peer id taken from a loaded booking or request. The server authenticates the caller and decides whether a thread may exist |
| backend error body to iOS alert | The server `message` is shown in "Couldn't start chat" |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-261122-tcf-01 | Spoofing | Upcoming details pill after a decline (T-03-23) | medium | mitigate | The pill follows the server's `data.status` through `BookingStatus(rawValue:) ?? .unknown`. `.unknown` renders neutral (`BookingStatusPill` uses an exhaustive switch). With no usable status nothing is guessed, and the status stays until the refetch. The server still gates joining (`can_join`, `/join`). Covered by the Task 1 Upcoming rows |
| T-261122-tcf-02 | Tampering / Denial of service | Decoding the decline 200 | low | mitigate | `RescheduleDeclineResponse` reads `data` and `status` as best-effort optionals, so an unexpected body shape can never turn a completed decline into an error or a stale card that invites a retry. A repeat decline gets the server's idempotent 200. Covered by the Task 1 null and non-string rows |
| T-261122-tcf-03 | Repudiation | Expert Message buttons failing silently (WR-10) | low | mitigate | No optional-try on initiate. Every non-cancellation failure sets `ChatStarter.apiError`, which raises the alert. Covered by the ChatStarter 404 and 500 rows |
| T-261122-tcf-04 | Denial of service / Tampering | Repeated Message taps pushing duplicate chats | low | mitigate | `ChatStarter.isStarting` single-flight guard, plus `.disabled` on the expert Booking Summary button. Server `ON CONFLICT` idempotency returns the same thread anyway. Covered by the second-call row |
| T-261122-tcf-05 | Information disclosure | "Couldn't start chat" alert text | low | mitigate | The alert shows only `ExpertProfileBlockViewModel.unavailableMessage` or `Error.userMessage` (the server `message`, else a localized description). No new logging, and no token, id or payload is printed |
| T-261122-tcf-06 | Spoofing / Elevation | Peer id sent to `/chats/initiate` | low | accept | The ids are the same ones used today (`detail.client.id`, `session.clientId`, `viewModel.clientId`), and all come from authenticated server reads. The server refuses suspended or removed peers (404) and self-chat (422) |
| T-261122-tcf-SC | Tampering | npm/pip/cargo/SPM installs | low | accept | No package is installed or updated, and `Package.resolved` is untouched |
</threat_model>

<verification>
- Task 1 `<automated>`: the RescheduleResponder, Upcoming and Booking Summary suites pass with the new rows, the decline model and the responder gates hold, and no touched file has a warning.
- Task 2 `<automated>`: ChatStarterTests passes, no optional-try initiate remains in the three expert views, each has the alert, Booking Summary has the busy state, the 42 pt frames are gone and there are at least two 44 pt minimums.
- Task 3 `<automated>` (first): the Android parity greps (a confirmation that nothing changed), the disposition and checklist gates.
- Task 3 `<automated>` (second): full unit run (smoke and login files excluded) and a clean Debug build.
- Task 3 `<automated>` (third): commit shape (2 fix commits, 14 files; 1 docs commit, 2 files; no unrelated or Phase 08 file; touched paths clean).
- Manual (later, by the user): 03-DEVICE-UAT-CHECKLIST.md items 25 and 26 on a real iPhone.
</verification>

<success_criteria>
- Declining an expert's new time on Upcoming details shows the status the server restored (Pending approval, In progress, Completed and so on), not a guessed Confirmed. With no status in the reply, nothing is guessed until the refetch.
- Message on the three expert screens opens the chat once per tap burst, and tells the expert when it cannot.
- The expert reschedule Decline and Accept buttons meet the 44 pt minimum.
- Android is confirmed to need no change, the backend is unchanged, and nothing is pushed.
- IN-02 and WR-10 are recorded as fixed, and the device checks are queued as checklist items 25 and 26.
</success_criteria>

<output>
Create `.planning/quick/261122-tcf-fix-phase-3-review-follow-ups-decline-st/261122-tcf-SUMMARY.md` when done. Record the three commit hashes, the test counts from `/tmp/261122-tcf-t1.log`, `/tmp/261122-tcf-t2.log` and `/tmp/261122-tcf-full.log`, the Android parity finding (files named, no Android commit), that the backend needed no change (decline already returns `data.status`), the label decision for the expert reschedule buttons, and that checklist items 25 and 26 await the device run. Note that T-03-23 in 03-SECURITY.md is still marked open until the next `/gsd-secure-phase 3` re-audit.
</output>
