---
phase: "07"
slug: "chat"
audited: "2026-11-18 (re-audit)"
baseline: "07-UI-SPEC.md (approved) + 07-CONTEXT.md D-01..D-19"
overall_score: 18
max_score: 24
blockers: 0
screenshots: none (native SwiftUI app; code-only audit; no HTTP response on localhost ports 3000, 5173 or 8080 at audit time)
---

# Phase 07 — UI Review

**Audited:** 2026-11-18 re-audit by gsd-ui-auditor (code-only; no screenshots, interaction capture off).
**Re-audit scope:** the first review of 2026-11-18 (18/24, 0 blockers) was re-checked against HEAD after the two code-review rounds (commits 82050a4..aea7ecb; 07-REVIEW.md, 07-REVIEW-FIX.md) and against the device UAT (07-UAT.md: 6 passed, 0 issues; 07-DEVICE-UAT-CHECKLIST.md). Every previous finding was re-verified at file:line. The UI-SPEC was not changed. VoiceOver checks were not run and are deferred to backlog item 999.5.
**Read coverage:** UI-SPEC, CONTEXT, REVIEW, REVIEW-FIX, UAT and the device checklist in full; the current code in the files listed under Files Audited.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Unchanged score. Expert Profile menu label still has no blank-name fallback; the unavailable banner copy is still open (IN-06); 10 new literal keys are in the catalog only as an uncommitted working-tree edit |
| 2. Visuals | 3/4 | Unchanged score. Thread toolbar icon button still has no accessibility label; empty labels on sent bubbles removed (IN-04) |
| 3. Color | 3/4 | Unchanged. Accent use matches the reserved list; Report & Block alias enum still hard-codes two reds |
| 4. Typography | 3/4 | Unchanged. Phase 07 text is inside the contract (12/15/17 pt, Regular/Bold, none added); the chat folder's pre-existing out-of-contract styling remains |
| 5. Spacing | 3/4 | Unchanged. Composer counter still sits 16 pt inside the field edge (`ChattingInputBar.swift:91`); the banner's 44 pt capsule is exactly as the contract states |
| 6. Experience Design | 3/4 | Unchanged score. Device UAT now confirms the delta states; open: Report & Block card has no in-flight feedback, 408/429 send-failure behaviour drifts from the contract, unavailable-banner recovery hint open, VoiceOver not run |

**Overall: 18/24.** No pillar score moved. The device UAT moved most open items from "unverified" to "verified on a device", but the code gaps that hold each pillar at 3 are still present. No pillar was raised, and none was lowered. No BLOCKER.

---

## Top 3 Priority Fixes

1. **The Report & Block card gives no in-flight feedback on Block or Unblock.** `ReportChatBlockCard.swift:61` only applies `.disabled(isWorking)`, while the banner's busy capsule (`ChattingBlockedBanner.swift:69-73`) shows a spinner and the "Unblocking" label. A user who taps `Unblock User` sees nothing change until the request returns, and a double-tap is only blocked by `disabled`. Fix: when `isWorking`, swap the button label for `ProgressView().controlSize(.small).tint(Brand.primary)` with an accessibility label of "Unblocking" or "Blocking" (both keys exist in the catalog).

2. **The composer counter is 16 pt inside the field's right edge.** `ChattingInputBar.swift:91` adds `.padding(.trailing, 16)` inside the bar's own 14 pt horizontal padding (`ChattingInputBar.swift:26`). The counter therefore ends 30 pt from the screen edge, while the field ends 14 pt from it. UI-SPEC section "Spacing Scale" item 3 says 16 pt "so it ends under the field's right edge", and that arithmetic does not hold for this bar. Fix: remove the trailing padding (use 0), and amend UI-SPEC item 3 to match.

3. **The unavailable banner gives no path to recovery.** `ChatBlockState.swift:126` reads "This user is unavailable.". Pull-to-refresh now clears the state (WR-02, `505068c`), but nothing on screen says so, and the device check for that path (UAT item 6, step 4) was not run. This is the copy decision IN-06 that was skipped in the fix round. Suggested copy: "This user is unavailable. Pull down to try again." If approved, change `ChatBlockState.bannerTitle(for:)`, the one assertion in `ChatBlockStateTests`, and the Android string in the same step.

Retired from the previous top 3: the banner capsule at 44 pt. The first review misquoted the contract as a "44 pt minimum". The contract says 44 pt tall, and device check C9 (UAT item 13, largest Dynamic Type) passed with the capsule at 44 pt. See the status table below.

---

## Previous Findings: Status

Each finding from the 2026-11-18 first review, and each UI-relevant item from the re-review and fix round, checked against the current code.

| ID | Finding (first review) | Status | Current evidence |
|----|------------------------|--------|------------------|
| P1-W1 | Expert Profile menu item has no blank-name fallback | UNCHANGED | `ExpertProfileView.swift:243` still `Label("Block \(expert.name)", …)`. The alert title at line 269 does use `ExpertProfileBlockViewModel.displayName` |
| P1-W2 | New literals not in `Localizable.xcstrings` | CHANGED (partly done, not committed) | 10 of the new literal keys are now in the working-tree catalog (`Sending…`, `Not sent. Tap to retry`, `Unblock`, `Blocking`, `Couldn't block user`, `Couldn't unblock user`, `Retry sending`, `Delete message`, `Unblocking`, `Send message`); none are in HEAD. The catalog diff (+173/−116) is still uncommitted and mixes with edits that predate the phase. Five contract strings are absent from the catalog: `Unblock User`, `You blocked this conversation`, `You can't reply to this conversation`, `This user is unavailable.` and `Couldn't send report` |
| P2-W1 | Thread toolbar icon button has no accessibility label | UNCHANGED | `ChattingView.swift:86-91`; `Image(systemName: "line.3.horizontal")` at line 88 with no `.accessibilityLabel` |
| P2-W2 | Failed glyph sits outside the tap target | ACCEPTED | `ChattingMessageBubble.swift:131-139` unchanged. The user judged the glyph not being tappable acceptable at UAT item 1(b) |
| P3-W1 | Alias enums hard-code RGB; Block uses `errorRed` while failed text uses `Brand.error` | UNCHANGED | `ReportChatBrand.swift:15-30` (`errorRed` line 22). Out of scope per UI-SPEC "Per-screen brand enums" |
| P4-W1 | Chat folder uses 8 text styles and 5 weights (pre-existing) | UNCHANGED | Phase 07 added no semibold or medium weight (0 added against 15 in base `16fe88e`) and only 12/15/17 pt text. The remaining styling is pre-existing and recorded as out of contract |
| P5-W1 | Counter sits 16 pt inside the field edge | UNCHANGED | `ChattingInputBar.swift:91` `.padding(.trailing, 16)`; bar padding 14 at line 26 |
| P5-W2 | Banner capsule fixed at 44 pt (`.frame(height: 44)`) | RE-CLASSIFIED (not a defect) | `ChattingBlockedBanner.swift:81` unchanged. The contract says 44 pt tall, not a minimum, so the first review's "minimum" wording was wrong. UAT item 13 (largest Dynamic Type) passed with the capsule at 44 pt and the title wrapping. `minHeight` is optional hardening |
| P6-W1 | Report & Block card has no in-flight state beyond `.disabled` | UNCHANGED | `ReportChatBlockCard.swift:61` only. No `ProgressView` in the card. `ReportChatView.swift:170` is the thread-resolving spinner, not the card's |
| P6-W2 | Failed status line lacks `.fixedSize(horizontal:vertical:)` | RESOLVED by device evidence | `ChattingMessageBubble.swift:146-151` unchanged. UAT item 13 PASS: the status line wraps without truncation |
| RV-WR-05 | Late `GET /chats` overwrote a live row's preview, time and order | FIXED (`f914364`) | UAT item 6, steps 1 to 3 PASS on device |
| RV-WR-06 | First message of a new thread dropped while a load was in flight | FIXED (`04962f2`) | UAT item 6, "new account during a refresh" PASS on device |
| RV-WR-02 | `recipientUnavailable` never cleared on pull-to-refresh | FIXED in code (`505068c`); device path NOT RUN | UAT item 6, step 4 not run (no unavailable test account); covered by unit tests only |
| RV-IN-01 | `sendFailure` treats 408 and 429 as refusals | FIXED in code (`e42d16f`); CONTRACT DRIFT | `ChatThreadReducer.swift:43-47, 57, 62`: 408 and 429 keep the bubble Failed with Retry, with no alert and no text restore. UI-SPEC section 1 ("any other 4xx removes the bubble, restores the text, shows the alert") and assumption A3 are no longer true for these two codes. See Experience Design |
| RV-IN-02 | `.timestamp` rows sorted after server rows | FIXED (comment only, `cb412f2`) | No UI change |
| RV-IN-03 | `Int(d)` could trap on an out-of-range double | FIXED (`9c024fd`) | No UI change |
| RV-IN-04 | Empty accessibility label on every sent bubble | FIXED (`500c9a1`) | `ChattingMessageBubble.swift:69-70` now `accessibilityLabel(Text(verbatim:), isEnabled: isPending)`. The VoiceOver check is deferred |
| RV-IN-05, RV-IN-07 | Test timing helpers and duplicate `Gate` | FIXED (`aea7ecb`, `3ac5cfe`) | Test-only; no UI change |
| RV-IN-06 | Unavailable banner has no pull-to-refresh hint | OPEN (copy decision) | `ChatBlockState.swift:126`. Top fix 3 |

Device UAT (2026-11-19, 07-UAT.md): 6 of 6 passed, 0 issues. Judgements 15 to 17 answered KEEP. VoiceOver is the only device area not run (checklist item 12, VoiceOver parts of items 3 and 4, and the IN-04 check), deferred to 999.5.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

Re-verified verbatim against the UI-SPEC: the Report & Block card headline, body and button strings (`ReportChatBlockCard.swift:77-96`, including the three body variants); the profile alert title, message, `Block` and `Cancel` buttons, and the `Couldn't block user` error alert (`ExpertProfileView.swift:268-291`); and the unavailable banner title (`ChatBlockState.swift:126`). The stale strings (`Spam or scam`, profile and appointment claims) are gone from the Chat screens.

- WARNING (unchanged): `ExpertProfileView.swift:243` renders `Label("Block \(expert.name)", systemImage: "hand.raised")` with no fallback. A blank name shows "Block ". The alert on line 269 already uses `ExpertProfileBlockViewModel.displayName(expert.name)`. Fix: use the same helper on line 243.
- WARNING (open decision): `ChatBlockState.swift:126` "This user is unavailable." has no recovery hint. See Top fix 3.
- WARNING (changed, not committed): the String Catalog holds 10 of the new literal keys only as an uncommitted working-tree edit. Five contract strings are not in the catalog at all: `Unblock User`, `You blocked this conversation` and `You can't reply to this conversation` come from computed values (`ReportChatBlockCard.swift:76-97`, `buttonText` at line 95), and `This user is unavailable.` comes from `bannerTitle(for:)`. Swift `String` values are not extracted, so these will not be localised. The app ships in English only, so the effect is small. Fix: commit the catalog in its own change, and move the computed copy to `LocalizedStringResource` or literal `Text` if localisation is wanted.

### Pillar 2: Visuals (3/4)

The focal points match the contract. The failed bubble is the only own bubble with a glyph and a red line (`ChattingMessageBubble.swift:121-140`). The banner title is followed by the one accent element, the Unblock capsule (`ChattingBlockedBanner.swift:72-82`). On the Chats list the unread pill is the only accent on a row (`ChatConversationRow.swift:96-105`). Sent bubbles no longer carry an empty VoiceOver label (IN-04 fix, `ChattingMessageBubble.swift:69-70`).

- WARNING (unchanged): the thread toolbar button `ChattingView.swift:86-91` is icon-only (`line.3.horizontal`, line 88) with no `.accessibilityLabel`. VoiceOver reads it as an unnamed button. Fix: add a label such as "Thread options".
- ACCEPTED: the failed glyph is outside the 44 pt tap group (`ChattingMessageBubble.swift:131-139`). The user accepted that at UAT item 1(b). No change is needed.

### Pillar 3: Color (3/4)

Accent use follows the reserved list. `Brand.primary` appears on the pill fill (`ChatConversationRow.swift:102`), the Unblock label and stroke (`ChattingBlockedBanner.swift:72, 77, 82`), and the existing elements. The failed bubble uses `ChattingBrand.myBubble` at 40% (`ChattingMessageBubble.swift:173`), a 1 pt `Brand.error` border at 50% (line 123), a `Brand.destructive` glyph (line 136) and `Brand.error` status text (line 151). The counter at the cap uses `Brand.error` (`ChattingInputBar.swift:90`). None of this is a finding.

- WARNING (unchanged): `ReportChatBrand.swift:15-30` hard-codes `Color(red:)` values. The Block User button uses `errorRed` (`#ff614d`, line 22), while the failed status line in the thread uses `Brand.error`. Out of scope per the UI-SPEC; recorded for a later cleanup.

### Pillar 4: Typography (3/4)

Phase 07 text is inside the contract. New or changed text uses `.caption` 12 pt (counter, failed status, pill count), `.subheadline` 15 pt (banner title, Unblock label, unread preview, bubble text) and the system alert 17 pt, with Regular and Bold only. The git diff against base `16fe88e` adds no semibold or medium weight. The one non-brand size is the banner icon, `.system(size: 20)` (`ChattingBlockedBanner.swift:50`), which the contract specifies.

- WARNING (unchanged, pre-existing): the chat folder still renders caption2, callout, title2 and title3 styles and semibold and medium weights (15 pre-existing semibold or medium uses in base). The UI-SPEC records this as out of contract and says not to change it, so it is not a Phase 07 defect. It is the reason the pillar stays at 3.

### Pillar 5: Spacing (3/4)

New values are on the 4-pt grid. The failed glyph is 20 pt with an 8 pt gap (`ChattingMessageBubble.swift:43-44`). The failed group has `frame(minHeight: 44)` with `contentShape` (lines 92-93). The banner uses 16/8 pt padding (`ChattingBlockedBanner.swift:34-35`), a 56 pt minimum row height (line 36), an 8 pt title-to-icon gap (line 47), 16 pt in the horizontal row (line 24) and a 44 pt capsule (line 81). The pill has 8 pt horizontal padding and a `@ScaledMetric` 24 pt minimum (`ChatConversationRow.swift:18, 100-101`).

- WARNING (unchanged): the counter has `.padding(.trailing, 16)` (`ChattingInputBar.swift:91`) on top of the bar's 14 pt padding (line 26). It ends 30 pt from the edge while the field ends 14 pt from it. Fix: set the trailing padding to 0 and amend UI-SPEC section "Spacing Scale" item 3.
- NOT A FINDING: the banner capsule is exactly 44 pt, as the contract states (see Top fix 3 retirement note above).
- NOT A FINDING: the Report & Block card capsule is 42 pt (`ReportChatBlockCard.swift:55`). The UI-SPEC records it as pre-existing and says to leave it.

### Pillar 6: Experience Design (3/4)

The device UAT (2026-11-19) confirmed the delta states on two real iPhones: the pending and failed bubble with retry and Delete (items 1 and 2), the cap and counter (item 3, without VoiceOver), the blocked and unavailable banners on both sides (items 7 and 8), the profile Block confirm, overlay and toast (items 4 and 5), the unread pill live (item 10), the live `· Read` receipt (item 11), largest Dynamic Type (item 13), the expert booking row (item 14) and the filled-state sweep (item 18).

- WARNING (unchanged): the Report & Block card has no busy state beyond `.disabled`. `ReportChatBlockCard.swift:61`. The banner has a busy capsule, and the card does not. UAT item 6 passed without recording this. Fix: see Top fix 1.
- WARNING (new, contract drift from the code-review fix IN-01): 408 and 429 now keep the bubble Failed with Retry (`ChatThreadReducer.swift:43-47, 57, 62`). The UI-SPEC says any other 4xx removes the bubble, restores the text and shows the `Couldn't send message` alert (section 1, the copy table, A3). The new behaviour is reasonable: both codes mean "try again" and the send is idempotent on `client_msg_id`. The code documents the choice. The UI-SPEC still says otherwise, and no device check covers it. Fix: amend UI-SPEC section 1 and A3 for 408 and 429, or revert the mapping. Do not leave the two out of step.
- WARNING (open): unavailable-banner recovery hint (`ChatBlockState.swift:126`). Top fix 3.
- WARNING (not run): pull-to-refresh recovery of the unavailable state (WR-02) has unit tests only. UAT item 6, step 4 was not run.
- VERIFICATION GAP (not scored as a defect): VoiceOver was not run (checklist item 12, VoiceOver parts of items 3 and 4, IN-04). The labels and actions the UI-SPEC requires exist in code: `ChattingMessageBubble.swift:69-70, 92-104`; `ChattingInputBar.swift:64, 86-93`; `ChattingBlockedBanner.swift:43, 52, 73, 88`; `ChatConversationRow.swift:79-89`; `ExpertProfileView.swift:295-309`. Their behaviour on a device is unverified until backlog 999.5 runs. This is the reason the pillar stays at 3 rather than rising on device evidence.

---

## Files Audited

- `ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift` (toolbar 86-91, banner slot 176-190, menu 94-106)
- `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingMessageBubble.swift` (full)
- `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingInputBar.swift` (full)
- `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingBlockedBanner.swift` (full)
- `ClickMe2026/Views/Screens/Chat/Conversations/Subviews/ChatConversationRow.swift` (full)
- `ClickMe2026/Views/Screens/Chat/Report and Block/Subviews/ReportChatBlockCard.swift` (full)
- `ClickMe2026/Views/Screens/Chat/Report and Block/Subviews/ReportChatDescriptionField.swift` (counter, line 53)
- `ClickMe2026/Views/Screens/Chat/Report and Block/ReportChatViewModel.swift` (details cap, lines 21-25, 54, 90)
- `ClickMe2026/Views/Screens/Chat/Report and Block/Subviews/ReportChatBrand.swift` (colour tokens)
- `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift` (menu 243, alert 268-291, overlay 295-309)
- `ClickMe2026/Utils/ChatBlockState.swift` (unavailable copy, line 126)
- `ClickMe2026/Utils/ChatThreadReducer.swift` (send-failure classification, lines 28-62)
- `ClickMe2026/Utils/ChatComposerRules.swift` (counter text, thresholds)
- `ClickMe2026/Localizable.xcstrings` (working-tree and HEAD key presence)
- Git: `16fe88e..HEAD` diff for typography and weights; `82050a4^..aea7ecb` for the review-fix range
- Not re-read in full this pass: `ChattingViewModel.swift`, `ChatConversationsViewModel.swift`, `RealtimeService.swift`, `ChatItemMapper.swift` (logic changes; verified through the review-fix report and UAT)
