# Phase 06 — UI Review

**Audited:** 2026-11-16
**Baseline:** `06-UI-SPEC.md` (approved 2026-11-16, design contract) with the user-approved supersessions recorded in `06-05-SUMMARY.md` (Booking Confirmed hosted inside RequestDecisionView; nav-bar pins added) and `06-07-SUMMARY.md` (swipe-back lock always on). Not scored as violations.
**Screenshots:** not captured (native SwiftUI iOS app; no web dev server and no simulator capture was run). Code-only audit. Visual pillars are scored from source, and rendering-dependent items are listed as unverified.
**Interaction captures:** off (`interaction_capture: false`)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Every new contract string matches character for character; a dead `Accepted!` string is still in code |
| 2. Visuals | 3/4 | Hub dot, expired pill and Confirmed focal point match; `Back to Home` is a silent no-op if its environment closure is nil |
| 3. Color | 3/4 | Expired-card tokens and the 1,000 and 5,000 caps match; three hardcoded RGB values remain in files this phase edited |
| 4. Typography | 3/4 | No new off-scale sizes in the touched folders; the rendered Dynamic Type checks (LT3) are unrun |
| 5. Spacing | 3/4 | The 4 pt counter gap and the 4 pt ID-stack spacing are implemented; layout is not rendered, so rhythm is unverified |
| 6. Experience Design | 3/4 | Delete confirm, decimal price, 409 pop, discard prompt and draft Cancel are implemented; an expired push-opened request still offers Accept |

**Overall: 18/24**

No pillar scores 1, so no finding is a BLOCKER under the pillar rule. The 18/24 is a code-only ceiling: the device checks in the contract (D1 to D6, LT3, OV2, E7, PO1) have not been run, and each pillar's score is capped by that.

---

## Top 3 Priority Fixes

1. **Expired request still shows the Accept footer on a push-opened decision** (Pillar 6, contract violation of section 4, which says expired cards open a read-only decision screen). `RequestDecisionViewModel.swift:76-88` defaults `isExpired` to `false`, and `:151` maps the loaded detail with that flag, never with the request's own expiry time. `RequestDecisionView.swift:258-268` hides the footer only when `viewModel.isExpired` is true, so the push route shows Accept. User impact: the expert taps Accept on a closed request and gets a 409 alert after a round trip. Fix: derive `isExpired` from the loaded detail's expiry timestamp in `map(detail:)`, so every entry point agrees.

2. **Hardcoded RGB values remain in Phase 06 files, bypassing `Brand`** (Pillar 3, contract says values come from `Brand.swift`). `Confirmed/Subviews/BookingConfirmedCard.swift:37` (`Color(red: 0.14, green: 0.20, blue: 0.16)`), `Incoming Requests/Subviews/IncomingRequestAvatar.swift` (`Color(red: 0.12, green: 0.18, blue: 0.14)` placeholder plus `.white.opacity(0.15/0.20)`), and `Availability/AvailabilitySettingsView.swift:85` (`presentationBackground(Color(red: 0.10, green: 0.12, blue: 0.11).opacity(0.97))`). Each file was edited by this phase, so the drift is in scope. Fix: map to the nearest `Brand` token, or record a named exception in the contract.

3. **Phase 06 device backstops are unrun, and they gate the release** (Pillars 4, 5, 6). Items with no code-level proof: D1 (expired card readability before and after, EXP-12 is LIKELY), D4 (note swipe-lock added after appear, counter above keyboard), D6 (cross-account 409), D2 and LT3 (Save and Confirmed chevron under Reduce Transparency and Liquid Glass, and Dynamic Type at the largest size), D3 (`12,50` under Region Canada French). Fix: run `06-DEVICE-UAT-CHECKLIST.md` on a real iPhone with test accounts and a free topic before `/gsd-verify-work 06`.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

**Verified against the contract (exact match):**
- Delete prompt: `Delete this topic?`, message `\u{201C}\(topic.title)\u{201D} will be removed and clients won't be able to book it.`, buttons `Delete` (destructive) and `Cancel` (`TopicsSetupView.swift:91-103`).
- Currency lock caption and USD conversion-fee notice are character-identical to the contract (`TopicEditorView.swift:416`, `:420`).
- Price label built from `currencySymbol`, which returns `US$` or `CA$` (`TopicEditorViewModel.swift:110-116`).
- Below-floor copy, `Please fill in all required fields with valid values.`, `Couldn't save topic` (`TopicEditorView.swift:164`).
- Discard prompt: `Discard changes?`, `Keep editing` (cancel role), `Discard` (destructive), body `Your changes to this note won't be saved.` (`ExpertBookingNoteView.swift:44-48`).
- Note placeholder, `My Note` title, `Couldn't save note`, `Couldn't load note`, `Loading note…`, `Retry` (`ExpertBookingNoteView.swift:56, 69-70, 135, 219-246`).
- Accept submit alert `Couldn't update request` (`RequestDecisionView.swift:166-167`); the 409 pop is keyed to `ErrorCode.alreadyProcessed` (`RequestDecisionViewModel.swift:300-303`).
- Confirmed: nav title `Booking Confirmed` (`RequestDecisionView.swift:158`), headline `Booking Confirmed!` (`BookingConfirmedHeadline.swift:16`), body sentence (`ExpertBookingConfirmationContent.swift:69`).
- Calendar title `ClickMe \u{00B7} {topic} with {client}` with `Session` and `Client` fallbacks (`ExpertBookingConfirmationContent.swift:30-33`).
- Booking Summary ID line uses `BookingShortID` via `bookingIdLabel` (`ExpertBookingSummaryView.swift:378`).
- Android: `topic_editor_currency_label`, `topic_editor_currency_locked` and `topic_editor_usd_notice` match the iOS strings (`ClickMe_Android/.../strings_expert_topics.xml:58-60`).

**Findings:**
- WARNING: dead copy `Accepted!` is still in `Request decision/Subviews/RequestDecisionActionFooter.swift:60`. The contract says no `Accepted!` frame and no copy after success. It is unreachable, because `RequestDecisionView.swift:146` swaps the whole content for Confirmed once `confirmation` is set. Remove the branch so the string cannot return unnoticed.
- INFO: the topic-delete failure alert keeps the generic title `Something went wrong` (`TopicsSetupView.swift:52`). The contract keeps this parent alert unchanged, so this is not a violation.

### Pillar 2: Visuals (3/4)

**Verified:**
- Expert hub: `isOnline: false` is passed at `ExpertProfileHomeScreen.swift:197` and `:299`; `ExpertProfileHomeViewModel` holds no presence state. The client hub's `ClientProfileHomeUserCard` still renders its dot (`ClientProfileHomeUserCard.swift:84`), as U2 requires.
- Expired pill (`IncomingRequestCard.swift:60-67`): EXPIRED text with `.subheadline` Bold, tracking 1.2, `Brand.onSurfaceVariant`, `Brand.overlayWhite10` capsule.
- Booking Note back control: `chevron.left` in a 44 × 44 frame with `contentShape`, accessibility label `Back` (`ExpertBookingNoteView.swift:169-175`).
- Booking Confirmed focal point: check icon and headline are unchanged; Add to Calendar and Back to Home stay in the contract order.

**Findings:**
- WARNING: `RequestDecisionView.swift:152` uses `onBackToHome: { returnToDashboard?() }`. If the `returnToDashboard` environment value is not injected, the visible Back to Home button does nothing and gives no feedback. It is installed only by `HomeExpertView.swift:83`. Reachability of `RequestDecisionView` outside that shell was not verified in this audit. Fix: assert in debug, or fall back to a sensible route.
- INFO: Availability time buttons stay 88 × 40 pt and slot-delete remains a bare icon. Both are contract waiver U4.

### Pillar 3: Color (3/4)

**Verified against the contract:**
- Expired card fill `Brand.surfaceContainerLowest` (`IncomingRequestCard.swift:84`); iris border `borderOpacity` 0.35 for expired (`:15`, `:88`); whole-card opacity removed, confirmed by a code comment at `:95-96`.
- Avatar dims the photo only: the `.opacity(request.isExpired ? 0.55 : 1)` modifier follows the `AsyncImage` chain and does not reach the ring (`IncomingRequestAvatar.swift`, last modifier).
- Booking Note counter: `Brand.error` only at `noteLimit`, otherwise `Brand.onSurfaceMuted` (`ExpertBookingNoteView.swift:186`).
- Accept counter: muted, `Brand.error` at 1000 (`RequestDecisionAcceptSheet.swift:88-90`).
- No new accent use outside the contract's reserved list.

**Findings:**
- WARNING: hardcoded RGB in Phase 06 touched files, each carrying existing drift from Brand:
  - `Confirmed/Subviews/BookingConfirmedCard.swift:37` `Color(red: 0.14, green: 0.20, blue: 0.16)`
  - `Incoming Requests/Subviews/IncomingRequestAvatar.swift` `Color(red: 0.12, green: 0.18, blue: 0.14)` and `.white.opacity(0.15)` and `.white.opacity(0.20)` (ring)
  - `Availability/AvailabilitySettingsView.swift:85` `Color(red: 0.10, green: 0.12, blue: 0.11).opacity(0.97)`
- INFO: the wider Expert Mode folder has many more `Color(red:…)` declarations in `Cancellation/` and `Settings/`. Phase 06 did not edit those files, so they are out of this audit's scope.

### Pillar 4: Typography (3/4)

**Verified:**
- No `.font(.system(size:` in the Incoming Requests, Booking Note, Availability or Confirmed folders (grep count 0).
- New text uses Brand-scaled styles: counter `.brand(.caption)`, ID line `.brand(.caption)`, EXPIRED `.brand(.subheadline, weight: .bold)`.

**Findings:**
- WARNING: the `Accepted!` branch still uses `.font(.subheadline.weight(.semibold))` (`RequestDecisionActionFooter.swift:55-59`). It is unreachable and should go with the dead copy.
- INFO: pre-existing Semibold and Medium text on these screens is out of contract by declaration and was not scored against it.
- Not verified: LT3 (largest Dynamic Type wrapping of the lock caption, USD notice and hints) needs a device.

### Pillar 5: Spacing (3/4)

**Verified:**
- Booking Note counter sits under the editor in `VStack(spacing: 4)` (`ExpertBookingNoteView.swift:98-100`), which is the contract's xs gap.
- Booking Summary client header `VStack(alignment: .leading, spacing: 4)` (`ExpertBookingSummaryView.swift:359`), moved from 5 to 4 as the contract requires.
- Availability Add hours disabled state is `.opacity(0.45)` and `.disabled` (`AvailabilityDayRow.swift:131-132`).
- No new off-grid value was introduced by Phase 06 in the files audited.

**Findings:**
- INFO: touched screens still carry pre-existing off-grid values (`spacing: 20`, `.padding(.horizontal, 20)`, `.padding(.bottom, 40)` in `ExpertBookingNoteView.swift`). The contract lists these as out of contract and says not to fix them.
- Not verified: visual rhythm and the 44 pt hit targets for the new Back button and picker row need a render or device check.

### Pillar 6: Experience Design (3/4)

**Verified:**
- Topic delete: the card's Delete calls `requestDelete` (`TopicsSetupTopicCard.swift:46-47`). Only the alert's `Delete` button calls `confirmDelete`; `Cancel` sends nothing (`TopicsSetupView.swift:98-101`). Mutation tests cover these paths (06-02 summary).
- Decimal price and floor: `.decimalPad` while fraction digits are greater than 0, else `.numberPad` (`TopicEditorView.swift:108`). `updateRate` filters input through `TopicPriceRules` (`:106`).
- Double-submit guard: `guard !isAccepted, !isDeclined` and `isSubmitting` in `RequestDecisionViewModel.swift:166-173`. Accept sheet cap uses `UTF16Prefix` at 1,000 units (`:310-317`).
- 409 `ALREADY_PROCESSED` pops on OK; other errors stay (`RequestDecisionViewModel.swift:300-303`, `RequestDecisionView.swift:166-170`).
- Availability Cancel: the sheet edits `@State draft` and commits only through `onDone(draft)` (`TimeRangePickerSheet.swift:18, 102`). Add hours is nil at 23:00 or later and clamps to 23:30 (`AvailabilitySlotRules.swift:60-69`).
- Note cap, dirty state, discard prompt and Back: `needsDiscardPrompt = hasChanges || isSaving` (`ExpertBookingNoteViewModel.swift:46`); Back presents the alert only when needed (`ExpertBookingNoteView.swift:160-165`).
- Loading, error and retry states are present on the note screen; 26 expert files reference load, error or loading state.

**Findings:**
- WARNING: expired push-opened decision offers Accept. `RequestDecisionViewModel.swift:76-88` defaults `isExpired` to `false`, and `:151` maps the loaded detail with that flag, so expiry is never read from the request itself. `RequestDecisionView.swift:258-268` therefore renders the footer for a push route. Contract section 4 says an expired card opens a read-only decision screen. The server answers 409 and the alert handles it, so no charge occurs, but the user hits a dead end. Source: the 06-05 summary flagged this as a residual; code confirms it.
- WARNING: `Back to Home` depends on an environment closure that may be nil (see Pillar 2).
- Not verified (device gates, per contract): D1, D2, D3, D4, D5, D6, LT3, OV2, E7, PO1.

---

## Files Audited

Source (iOS, `ClickMe2026/`):
- `Views/Screens/Expert Mode/Topics/TopicsSetupView.swift`, `TopicsSetupViewModel.swift`, `Subviews/TopicsSetupTopicCard.swift`
- `Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorView.swift`, `TopicEditorViewModel.swift`
- `Utils/TopicPriceRules.swift`, `Utils/AvailabilitySlotRules.swift`, `Utils/ExpertBookingConfirmationContent.swift`, `Utils/BookingShortID.swift`
- `Model/Requests/ExpertTopicRequest.swift`, `Network/ClickMeAPI+ExpertProfile.swift` (comments only)
- `Views/Screens/Expert Mode/Availability/AvailabilitySettingsView.swift`, `Subviews/AvailabilityDayRow.swift`, `Subviews/TimeRangePickerSheet.swift`
- `Views/Screens/Expert Mode/Request decision/RequestDecisionView.swift`, `RequestDecisionViewModel.swift`, `Subviews/RequestDecisionActionFooter.swift`, `Subviews/RequestDecisionAcceptSheet.swift`
- `Views/Screens/Expert Mode/Confirmed/BookingConfirmedView.swift`, `Subviews/BookingConfirmedHeadline.swift`, `BookingConfirmedCard.swift`, `BookingConfirmedActionButtons.swift`
- `Views/Screens/Expert Mode/Home/HomeExpertView.swift`
- `Views/Screens/Expert Mode/Incoming Requests/Subviews/IncomingRequestCard.swift`, `IncomingRequestAvatar.swift`
- `Views/Screens/Expert Mode/Profile/ExpertProfileHomeViewModel.swift`, `ExpertProfileHomeScreen.swift`
- `Views/Screens/Client Mode/Profile/Subviews/ClientProfileHomeUserCard.swift` (client hub, unchanged, checked for U2)
- `Views/Screens/Expert Mode/Booking Note/ExpertBookingNoteView.swift`, `ExpertBookingNoteViewModel.swift`
- `Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift`, `ExpertBookingSummaryViewModel.swift`

Android (`ClickMe_Android/`):
- `app/src/main/java/.../screens/expertmode/topics/editor/subviews/TopicCurrencyPicker.kt`
- `app/src/main/res/values/strings_expert_topics.xml`

Planning artifacts read:
- `06-UI-SPEC.md` (full), `06-CONTEXT.md` (full)
- `06-01-SUMMARY.md` to `06-10-SUMMARY.md` (all ten)

Not read in full: `06-01-PLAN.md` to `06-10-PLAN.md`. Their intended behaviour was checked through the summaries and the code, not line by line. The plan files total about 280 KB and were out of budget for this audit. A gap between a plan and its summary would not be caught here.

Scope note: Pillar scores are a code-only ceiling. Rendering, Dynamic Type, Reduce Transparency, Liquid Glass and the cross-account 409 are contract items for the device checklist, not yet run.
