# Phase 8: Release - Pattern Map

**Mapped:** 2026-11-19
**Files analyzed:** 27 new/modified (iOS 13, backend 7, Android 7)
**Analogs found:** 25 / 27
**Tracked-source gate:** every analog below was checked with `git ls-files` (iOS, backend `events.js`/`longLeadChargeSweep.js`, Android chat/Money/strings files all tracked). Backend line numbers below come from the `master` checkout (which has `94d659b`) except where marked D12 (= `origin/main` `28da165`, no `94d659b`). Line numbers shift by a few lines after the cherry-pick; re-grep before editing.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `[backend] src/services/events.js` (`dispatchPushForEvent` BOOKING_DECLINED, BOOKING_RESCHEDULED wording, `injectEventMessage` marker) | service | event-driven | same file, `BOOKING_CANCELLED` / `BOOKING_RESCHEDULED` cases (`notify_user_id`) | exact |
| `[backend] src/controllers/clientBooking.controller.js` (declineReschedule call site, ~L770) | controller | request-response | same file, reschedule/cancel dispatch passing `notify_user_id` | exact |
| `[backend] src/controllers/expertBooking.controller.js` (declineReschedule call site, ~L1124) | controller | request-response | same | exact |
| `[backend] tests/events.test.js`, `clientBooking.test.js`, `expertBooking.test.js` | test | event-driven | existing `BOOKING_DECLINED decline note (BACK-02)` and `action reason` describes | exact |
| `[backend] src/cron/longLeadChargeSweep.js` (guarded stamp reset) | cron service | batch | same file `stampAttempt` + SCA branch | exact |
| `[backend] openapi/clickme-api.yaml`, `docs/ios/PUSH-ROUTING.md`, `docs/ios/STRIPE-INTEGRATION.md` | config/doc | n/a | the `94d659b` event_data doc edit | role-match |
| `[backend] src/controllers/expertTopics.controller.js` (`serializeTopic` currency), `src/schemas/userProfile.schema.js` (name messages) | serializer / schema | request-response | same files | exact |
| `ClickMe2026/Utils/ChatItemMapper.swift` | utility | transform | same file `bookingEvent(...)` | exact |
| `ClickMe2026/Model/UIModels/ChatDisplayModels.swift` (`BookingEvent`) | model | transform | same struct, trailing `var x = nil` fields (`serverId`, `createdAt`) | exact |
| `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingSystemEventRow.swift` | component | request-response | same file L43-60 | exact |
| `ClickMe2026Tests/.../ChatItemMapperTests.swift` | test | transform | same file helper `mappedEvent(durationMins:)` | exact |
| `ClickMe2026/Utils/Money.swift` + pinned tests (`MoneyTests`, `MoneyCallSiteTests`, `ClientProfileBookingCardTests`, `ClientProfileHistoryEarningsTests`) | utility | transform | same file symbol table | exact |
| `ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupTopicCard.swift` (`cardSymbol`), `TopicEditorViewModel.swift` (`currencySymbol`) | utility | transform | `Money.prefix(for:)` | role-match |
| `ClickMe2026/Utils/AccountDeletionCopy.swift`, `Views/.../Delete account/Subviews/DeleteAccountWarningHeader.swift`, `ClickMe2026Tests/Utils/AccountDeletionCopyTests.swift` | utility / component / test | transform | same files | exact |
| `ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift` L282 | view model | CRUD | n/a (one-line `_ =` fix) | exact |
| `.github/workflows/build.yml`, `test.yml`, `scripts/run-smoke-tests.sh`, `ExportOptions.plist` | config | batch | each file itself (stale `ClickMe2026.xcodeproj`, `teamID`) | exact |
| `ClickMe2026/Debug/PreviewSecrets.swift` (make tracked, token-free) | config | n/a | current gitignored file (DEBUG/else-nil pattern) | exact |
| `ClickMe.xcodeproj/project.pbxproj` (1.1 / 7) | config | n/a | lines 445/464 (Debug), 486/505 (Release) | exact |
| `scripts/release-build-check.sh` (new) | script | batch | `scripts/run-smoke-tests.sh` | role-match |
| `08-REGRESSION-CHECKLIST.md`, `08-RELEASE-RECORD.md` (new, `.planning/phases/08-release/`) | doc | n/a | `04-DEVICE-UAT-CHECKLIST.md` "D-11 real-money session" | role-match (no prior release record exists) |
| `[android] screens/chat/chatting/ChatMessageMapping.kt`, `ThreadItem.kt`, `subviews/SystemEventRow.kt` | utility / model / component | transform | same files | exact |
| `[android] test/.../testing/ChatFixtures.kt`, `ChatMessageMappingTest.kt` | test | transform | `chatEvent(...)` | exact |
| `[android] util/Money.kt`, `test/.../util/MoneyTest.kt` | utility / test | transform | same files | exact |
| `[android] res/values/strings_delete_account.xml` (+ `DeleteAccountComponents.kt`) | config | n/a | same file | exact |
| Android parity todos (settings/ports/availability/cancellation link) | various | various | see todo files | no analog mapped |

(Android paths are under `/Users/LeonChen/Documents/ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/` and `.../app/src/test/java/...`.)

## Pattern Assignments

### Backend: `events.js` BOOKING_DECLINED recipient and wording (ITEM1C, D-31) and BOOKING_RESCHEDULED wording (ITEM1)
**Analog:** `src/services/events.js` `BOOKING_RESCHEDULED` case (L412-431) for `notify_user_id` routing.

**Routing pattern to copy** (L412-431):
```javascript
const notifyId = booking.notify_user_id;
if (notifyId) {
  await sendPushToUser(notifyId, {
    title:        'Booking Rescheduled',          // ITEM1: change to 'Reschedule Requested'
    body:         'A booking has been rescheduled.',
    category:     EVENT_CATEGORY[eventType],
    sub_category: EVENT_SUBCATEGORY[eventType],   // 'reschedules'
    target_role:  targetRoleFor(booking, notifyId),
    data:         { booking_id: booking.id, event_type: eventType },
  });
} else {
  console.warn('[events] BOOKING_RESCHEDULED: no notify_user_id provided; skipping push');
}
```
**Current code to change** (L318-336): `BOOKING_DECLINED` always calls `sendPushToUser(client_id, {... title:'Booking Declined', sub_category: EVENT_SUBCATEGORY[eventType], data: declinedData, ...(declineText ? { in_app_meta: ... } : {}) })`. Keep `declinedData = { booking_id, event_type }` unchanged for request declines. For the marker case use `notify_user_id` as recipient, `sub_category: 'reschedules'` (D-31; iOS `PushRouter` L292 sends `declines` to read-only `bookingSummary`, `reschedules` to `bookingDetail`), and never put `reason_text` in `data` or `in_app_meta`.

**Call sites** (add `notify_user_id` + marker; keep `reason_text`/`reason_by`):
`clientBooking.controller.js` ~L770-781 (proposer = `booking.expert_id`) and `expertBooking.controller.js` ~L1124-1135 (proposer = `booking.client_id`):
```javascript
await dispatchBookingEvent('BOOKING_DECLINED', {
  id: booking.id, client_id: booking.client_id, expert_id: booking.expert_id,
  // quick 261119-miw: the decline reason goes into the chat event only (never push data).
  reason_text: reason, reason_by: 'client',     // 'expert' in the other file
  // ADD: notify_user_id: <proposer>, reschedule_decline: true   (name is planner's call; document in OpenAPI)
});
```

**Chat event marker** - add next to the existing reason block in `injectEventMessage` (L192-215):
```javascript
if (REASON_TEXT_EVENT_TYPES.has(eventType)) {
  const reasonText = typeof booking.reason_text === 'string' ? nonEmptyString(booking.reason_text.trim()) : null;
  if (reasonText) {
    event_data = { ...event_data, reason_text: reasonText };
    if (REASON_BY_ROLES.has(booking.reason_by)) event_data = { ...event_data, reason_by: booking.reason_by };
  }
}
// ADD (additive key only): if (booking.reschedule_decline === true) event_data = { ...event_data, reschedule_decline: true };
```
**Test analog:** `tests/events.test.js` describe `BOOKING_DECLINED decline note (BACK-02)` (~L807) and `action reason` (~L906). Cases: client declines -> push to `expert_id`; expert declines -> push to `client_id`; request decline unchanged (`data` deep-equals `{ booking_id, event_type }`); no free text in `data`/`in_app_meta`; no `notify_user_id` -> warn and skip. Run the suite from a path with no dot-directory (`.../ClickMe2026 Backend D12` is fine; research saw `adminConsole` 404s under `~/.claude/jobs/`).

---

### Backend: `longLeadChargeSweep.js` guarded stamp reset (D-29)
**Analog:** same file, `stampAttempt` (L159-175) is the pattern for a status-guarded conditional UPDATE; error branch at L388-446 (D12 checkout).

**Guard pattern to mirror for the reset:**
```javascript
const { data, error } = await supabaseAdmin
  .from('bookings')
  .update({ off_session_attempted_at: nowIso })
  .eq('id', booking.id)
  .eq('payment_status', 'scheduled')
  .in('status', CHARGEABLE_BOOKING_STATUSES)
  .is('off_session_attempted_at', null)
  .select('id');
```
Reset = same shape with `{ off_session_attempted_at: null }`, `.eq('off_session_attempted_at', nowIso)` (this run's stamp), `.is('payment_intent_id', null)`, and a deadline check (`start_time` more than 6 h away, using the existing SCA window constant `SCA_RECOVERY_WINDOW_MS`) before resetting. Apply only to errors thrown strictly before `createManualPI` (L372); the step order after the stamp (L342) is `getOrCreateConnectedCustomer`, `getOrCreateClonedPaymentMethod`, `recheckStillChargeable`, `createManualPI`, `confirmPIOffSession`.

**Branch to leave unchanged** (L388-446): `authentication_required` keeps the stamp as the 6 h anchor; other `StripeCardError` -> `cancelAndRelease`; the final `throw err;` (L446, comment at L443-445 documents the known exposure and must be rewritten) is where pre-PI errors need the reset before rethrow. Tests: extend `tests/cron/longLeadChargeSweep.test.js` next to `describe('transient platform-card error is retried on the next run (ios-p4 CR-02)')`. Update `docs/ios/STRIPE-INTEGRATION.md`. Needs a decision checkpoint and a deploy-approval checkpoint (D-14).

---

### iOS: chat reason rendering (`ChatItemMapper.swift`, `ChatDisplayModels.swift`, `ChattingSystemEventRow.swift`)
**Analog:** `ClickMe2026/Utils/ChatItemMapper.swift` `bookingEvent(from:content:eventData:)` (L71-119).

**Extraction pattern** (L71-80, add the new reads here once, above the switch):
```swift
let bookingId = extractBookingId(from: eventData)
let topicTitle = extractString(from: eventData, key: "topic_title")
let startTime = extractDate(from: eventData, key: "start_time")
let durationMins = extractInt(from: eventData, key: "duration_mins")
let terminal = isTerminal(event)
// ADD: reason_text ?? decline_reason_text (trim, nil if blank), reason_by, reschedule_decline marker
```
Every switch case builds `BookingEvent(icon:title:subtitle:isAccepted:avatarURL:bookingId:isTerminal:topicTitle:startTime:durationMins:)`; set the new fields after construction (like `chatItem` does for `serverId`/`createdAt`) or pass them in each case. For `.bookingDeclined` with the marker, use title "Reschedule Declined".

**Model** (`ChatDisplayModels.swift` L107-148): add trailing `var reasonText: String? = nil`, `var reasonBy: String? = nil` (and marker) after `var createdAt: Date? = nil`, so the memberwise init call sites (`ChattingView` previews ~L435/457, `ChatThreadReducerTests.swift:58`) stay compiling.

**Row** (`ChattingSystemEventRow.swift` L43-60): the title/topic `VStack(alignment: .leading, spacing: 2)`; add one caption line below it in the same style:
```swift
Text(...)   // plain String, never LocalizedStringKey/Markdown
    .font(.brand(.caption, weight: .regular))
    .foregroundColor(ChattingBrand.onSurfaceVar)
```
with a generous `lineLimit` (server caps are 500/1000 chars). Label by `reason_by` using neutral "Client"/"Expert" wording (the mapper has no viewer role). For request declines also reuse `DeclineNote.reasonLine(for:)` (`ClickMe2026/Utils/DeclineNote.swift`) for `decline_reason_code`.
**Tests:** `ClickMe2026Tests/.../ChatItemMapperTests.swift`, add a sibling to helper `mappedEvent(durationMins:)` that takes an `eventData` object. Swift Testing, `#expect`.

---

### Android: chat reason rendering
**Analog:** `screens/chat/chatting/ChatMessageMapping.kt` L10-30:
```kotlin
val data = eventData.orEmpty()
return ThreadItem.SystemEvent(
    serverId = id,
    kind = SystemEventKind.fromWire(eventType),
    bookingId = data["booking_id"] as? String,
    topic = (data["topic_title"] as? String)?.takeIf { it.isNotBlank() },
    startTime = (data["start_time"] as? String)?.let { runCatching { Instant.parse(it) }.getOrNull() },
    content = content,
    createdAt = createdAt,
)
```
Add `reasonText = ((data["reason_text"] ?: data["decline_reason_text"]) as? String)?.trim()?.takeIf { it.isNotEmpty() }` and `reasonBy`. `ThreadItem.SystemEvent` (`ThreadItem.kt` L88-100) is a `data class` with an explicit `toString` listing fields: add nullable fields with defaults and decide whether to extend `toString` (text is user content, keep it out of `toString`). Render in `subviews/SystemEventRow.kt` (the `Text(` blocks near L119-126; helper near L186 for the subtitle). Fixture: extend `chatEvent(...)` in `app/src/test/.../testing/ChatFixtures.kt` L71-95 with optional `reasonText`, `reasonBy`, `declineReasonText`, using the existing `data["x"] = it` pattern (`topic?.let { data["topic_title"] = it }`). Add rows to `ChatMessageMappingTest.kt`.

---

### iOS: Money `US$` (D-24)
**Analog:** `ClickMe2026/Utils/Money.swift` L36-44, the table to change (`"USD": "$"` -> `"US$"`):
```swift
private static let symbols: [String: String] = [
    "USD": "$", "CAD": "CA$", "AUD": "A$", "EUR": "€", "GBP": "£", "JPY": "¥", "INR": "₹"
]
```
`prefix(for:)` (L57-62) is the lookup used elsewhere; update the type doc comment (L14-17 says "`$` is USD"). Fold `TopicsSetupTopicCard.cardSymbol(for:)` (L25, currently `currency == "USD" ? "US$" : Money.prefix(for:)`) onto `Money.prefix`; `TopicEditorViewModel.currencySymbol` (L117-123) keeps its `default: return currency`. Pinned tests to rewrite (examples): `MoneyCallSiteTests` L24-25 `"$12.50"`, `"$12.00"`; `MoneyTests` L30-52, 92-93, 101, 122, 133-136, 172-173; `ClientProfileBookingCardTests:23`; `ClientProfileHistoryEarningsTests:80`. Re-run `grep -rn '"\$' ClickMe2026Tests` after the change. Leave preview-only `$250` strings.

**Android equivalent:** `util/Money.kt` `format(...)` L48-64 builds a `NumberFormat.getCurrencyInstance(locale)` and sets `currency`. Per D-32, override only the symbol on a copy of the locale's symbols, keeping placement and grouping:
```kotlin
val formatter = NumberFormat.getCurrencyInstance(locale).apply {
    this.currency = currency; minimumFractionDigits = digits; maximumFractionDigits = digits
}
// ADD: (formatter as? DecimalFormat)?.let { df -> val s = df.decimalFormatSymbols
//   s.currencySymbol = when (code) { "USD" -> "US$"; "CAD" -> "CA$"; else -> s.currencySymbol }
//   df.decimalFormatSymbols = s }
```
Update the six `Locale.US` rows in `MoneyTest.kt` (L15, 20, 40, 60, 67, 82; `"$50.00"` -> `"US$50.00"`; `"$1,234,567,890.12"` at L60 stays grouped). `formatMajor` delegates to `format`, so it follows automatically.

---

### iOS + Android: AccountDeletionCopy saved-cards line (D-23)
**Analog:** `ClickMe2026/Utils/AccountDeletionCopy.swift` (flat `static let` strings in a `nonisolated enum`, doc comment lines 17-18 say "The copy makes no claim about saved cards"; update that comment and the Android-port note).
```swift
static let keptTitle = "Kept"
static let keptBody = "Messages and reviews you've written stay visible to the other person, shown as from \"Deleted user\". Payment records are kept."
// ADD: static let savedCardsNote = "..."
```
**Render:** `DeleteAccountWarningHeader.swift` L28-35, inside `if showsDetails { ... }` after the three `group(...)` calls, using the existing `bodyText(_:)` helper (L40-44).
**Test conflict (Pitfall 5):** `AccountDeletionCopyTests.noFalseClaims` (L46-52) lowercases every string in `Self.all` and forbids `removed`, `saved card`, `payment details`. The example line "Saved cards are not removed by deleting your account." trips two of them. Either reword (no `removed`, and either avoid `saved card` or carve out) or exclude `savedCardsNote` from only the `saved card` check and keep `removed`/`payment details` forbidden. Add an exact-string `#expect` like the existing ones (L35-40 style). Android: `res/values/strings_delete_account.xml` `delete_account_body` still claims "payment details, will be permanently removed" (the false claim); replace per the Android delete-account todo and add the same final string word for word (escape apostrophes as `\'`, as in `delete_account_error_title`).

---

### Release config files
**`.github/workflows/build.yml`** L22: `XCODE_PROJECT: ClickMe2026.xcodeproj` -> `ClickMe.xcodeproj` (same stale name in `test.yml` L13 and `scripts/run-smoke-tests.sh` L23 `PROJECT="${PROJECT:-ClickMe2026.xcodeproj}"`). Triggers: `workflow_dispatch` plus `push: branches: 'release/**'`; `concurrency` cancels same-ref runs; runs on `[macos-26]`. Use `workflow_dispatch` on a non-release branch for the dry run (a `release/**` name triggers the real deploy).
**`ExportOptions.plist`**: `<key>teamID</key><string>XXXXXXXXXX</string>` -> `V68J585TK5`; note `manageAppVersionAndBuildNumber` is `true` (uploaded build number may differ from 7; record the actual one).
**`PreviewSecrets.swift`** (currently gitignored via `.gitignore` L4; 38 files reference it in `#Preview`, a clean checkout fails to compile): keep the existing shape for the tracked version but with no tokens:
```swift
enum PreviewSecrets {
    #if DEBUG
    static let clientBearerToken: String? = ProcessInfo.processInfo.environment["CLICKME_PREVIEW_CLIENT_TOKEN"]
    #else
    static let clientBearerToken: String? = nil
    #endif
    // same for expert token and any other members the 38 call sites use
}
```
Remove it from `.gitignore` only after the local token copy is moved out of the tree (for example into an untracked override); `git grep eyJhbGciOi` must show only the two test-fixture files (`ClickMe2026Tests/Fixtures/Auth/login_success.json`, `ClickMe2026Tests/Network/Auth/LoginTests.swift`) before any push (D-25, D-26). Match the members by grepping `PreviewSecrets\.` first.
**`project.pbxproj`** (D-18): app target only, bundle id `com.uptrendinvestments.clickmeapp`. Debug block L445 `CURRENT_PROJECT_VERSION = 6;` / L464 `MARKETING_VERSION = 1.0;`; Release block L486 / L505. Test targets (L525-579) unchanged. Gate: `grep -c 'MARKETING_VERSION = 1.1;'` = 2 and `grep -c 'CURRENT_PROJECT_VERSION = 7;'` = 2 (after verifying the test targets use other values).
**Warning fix:** `FavoritesViewModel.swift:282`, inside the `withAnimation` closure change `list.remove(key: expert.pagingKey)` to `_ = list.remove(key: expert.pagingKey)` (`PagedList.remove(key:)` at `Utils/PagedList.swift:101` returns a tuple, no `@discardableResult`).
**New `scripts/release-build-check.sh`:** copy the header, `set -euo pipefail`, env-var-with-default (`SCHEME`, `PROJECT`, `CONFIGURATION`) and usage-comment style of `scripts/run-smoke-tests.sh` (L1-23). Body per RESEARCH "Clean-checkout Release build" and "Warnings diff" examples, baseline commit `a48c664`, and the `comm -13 base.txt cand.txt` empty-diff gate.

---

### Release documents (new)
**No prior release record exists** in `.planning/phases/` (searched for `*RELEASE*`/`*record*`). Nearest format analog for `08-REGRESSION-CHECKLIST.md`: `.planning/phases/04-booking-payment-and-discovery/04-DEVICE-UAT-CHECKLIST.md`.
Structure to copy: title; intro paragraph stating who runs what ("Claude runs only local tests and builds: every production step is yours"); `## Setup` (device, build, backend deploy state with SHAs, accounts A/B, second device, Dashboard/SQL open, "Recording results: fill the `Result:` line with `PASS`, `FAIL (what happened)` or `SKIPPED (why)`, and the date. Never write a `pm_` id, client secret or card number; for a PaymentIntent write only the last six characters of its `pi_` id"); `## Notes before you start`; `## Items` with `### N. REQ-ID - title`, `**Status:**`, `Steps:` numbered, `Expected:` bullets, `Result:` line. Reuse the "D-11 real-money session" block (L335-552) for BACK-06/07/19: Setup (cheapest paid CAD topic, one saved card S, bookings 2 to 5 days out, never joined or rescheduled, one hold at a time, prove the hold gone in Stripe), read-only queries Q1 (booking) and Q2 (`connected_pm_clones` by `stripe_payment_method_id`, saved before removing the card), stop conditions S-A..S-E, lettered steps a-h with an end-state table. Q1/Q2 SQL (copy verbatim):
```sql
select id, status, payment_status, stripe_payment_method_id, payment_intent_id, stripe_account_id, refund_failed
from bookings where client_id = (select id from auth.users where email = '<client email>')
order by created_at desc limit 1;

select clone_payment_method_id, connected_account_id, connected_customer_id
from connected_pm_clones where platform_payment_method_id = '<pm id from Q1>';
```
Per D-27, the BACK-19 captured-refund branch is not exercised; record hold-release evidence plus mocked tests. Per D-28 add items for Phase 6 Liquid Glass (items 13, 16), Phase 5 items 24 and 45, and the Phase 2 Android `call.ended` check (wait to end+60 on the paid session). Per D-02 never list VoiceOver steps as passed. `08-RELEASE-RECORD.md` has no analog; sections come from the RESEARCH Wave 0 list (not-run-on-device list, VoiceOver removals, BACK-08/13 deferral, BACK-15 reason, deferred review infos, warnings diff, deploy SHAs and rollback branches).

---

## Shared Patterns

### Additive-only contract (D-13, D-15)
**Source:** `src/services/events.js` `injectEventMessage` (L185-215): new keys added with `event_data = { ...event_data, key: value }`, only when present. **Apply to:** all backend changes. Never rename, remove or change validation so an existing client payload is rejected. Push `data` keeps `booking_id` and `event_type`; free text goes to chat `event_data` and `in_app_meta` only (BACK-02, `94d659b`).

### Backend deploy (D-10, D-14, D-16)
**Source:** RESEARCH Pattern 1. **Apply to:** every backend wave. Work in `/Users/LeonChen/Documents/ClickMe2026 Backend D12` (clean, `node_modules`, path has no dot directory). Record `/health` (`curl https://clickme-backend-production.up.railway.app/health`), `git branch ios-p8-<wave>-rollback origin/main`, `git checkout -b ios-p8-<wave> origin/main`, `git cherry-pick -x 94d659b` (clean; do not take `22b8967`), `npm test -- --silent` (expect only the 6 `redis.test.js` failures; baseline on `28da165`: 3803 pass), stop for user approval, `git push origin ios-p8-<wave>:main` (never `--force`, never `master:main`), poll `/health` until the 7-char SHA matches. Then the live smoke on build 6 and Android. D-17 merge: `git merge-tree --write-tree --name-only master origin/main` first (exit 0 expected), then `git merge origin/main` on `master`, then the three D-12/CR-02 describes and the full suite.

### Error and display text
**Source:** `ClickMe2026/Network/Error+UserMessage.swift` (`Error.userMessage`). **Apply to:** any new iOS network error display; do not add a private `errorMessage(for:)`. Reason text from the chat is rendered as a plain `String`, never Markdown or `AttributedString(markdown:)`, never logged.

### iOS test commands (project convention, Swift Testing)
**Source:** RESEARCH "iOS test and build commands". `xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' 'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' -only-testing:ClickMe2026Tests/<Suite>`; success grep `Test run with [1-9][0-9]* tests? in [0-9]+ suites? passed`. Android: `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew -Pkotlin.daemon.jvmargs=-Xmx3g :app:testDevDebugUnitTest --tests '<FQCN>' ktlintCheck`.

### File header and style
Every new Swift file starts with the Xcode header block (`//  File.swift / ClickMe2026 / Copyright © 2026 Uptrend Investments Inc. All rights reserved.`), 4-space indent, `// MARK: -` sections, `///` doc comments that explain why. One commit per repo per change; never assume the other repo has a change.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `08-RELEASE-RECORD.md` | doc | n/a | No earlier release-style record in `.planning/phases/`; use RESEARCH Wave 0 list for sections |
| `scripts/release-build-check.sh` | script | batch | Only `run-smoke-tests.sh` (different purpose) exists; copy its style only |
| Android parity todos (availability, cancellation policy link, remember-login-email, push prompt check, profile/meeting-link settings) | various | various | Not mapped here; each todo under `.planning/todos/pending/` names its files; read the matching iOS rule first (G-05-6, CR-01, `b0629d9`) |

## Metadata

**Analog search scope:** iOS `ClickMe2026/Utils`, `Model/UIModels`, `Views/Screens/Chat`, `Views/Screens/Settings/Delete account`, `.github`, `scripts`, `ClickMe2026Tests/Utils`; backend `src/services/events.js`, `src/cron/longLeadChargeSweep.js`, booking controllers (the `Backend D12` worktree for `origin/main`); Android `util/Money.kt`, `screens/chat/chatting/**`, `res/values/strings_delete_account.xml`, test fixtures; `.planning/phases/04-*/04-DEVICE-UAT-CHECKLIST.md`.
**Files scanned:** about 30 read in part (large files by targeted ranges).
**Pattern extraction date:** 2026-11-19
