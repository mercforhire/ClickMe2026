---
phase: "07"
slug: "chat"
audited: "2026-11-18"
baseline: "07-UI-SPEC.md (approved) + 07-CONTEXT.md D-01..D-19"
overall_score: 18
max_score: 24
blockers: 0
screenshots: none (native SwiftUI app; code-only audit)
---

# Phase 07 — UI Review

**Audited:** 2026-11-18 by gsd-ui-auditor (code-only; no screenshots, interaction capture off).
Read coverage: UI-SPEC, CONTEXT and all nine SUMMARY files in full; the implementation was checked against the contract (the nine PLAN files were not read in full).

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Contract strings present and exact; the profile menu item has no blank-name fallback; new literals are not in the String Catalog |
| 2. Visuals | 3/4 | Failed-bubble, banner and pill hierarchy matches the contract; the thread menu icon button has no accessibility label (pre-existing) |
| 3. Color | 3/4 | Accent use follows the reserved list; per-screen alias enums keep hard-coded RGB (accepted out of scope) |
| 4. Typography | 3/4 | New text uses only 12/15/17 pt, Regular/Bold; the chat folder still has 8 text styles and 5 weights (pre-existing) |
| 5. Spacing | 3/4 | New values on the 4-pt grid, but the counter sits 16 pt inside the field edge and the banner capsule is a fixed 44 pt height |
| 6. Experience Design | 3/4 | All new states coded; the Report & Block card gives no in-flight feedback; device checks unrun |

**Overall: 18/24.** No BLOCKER; every pillar has WARNING-level findings.

## Top 3 Priority Fixes

1. **Report & Block card has no in-flight feedback on Block/Unblock.** `ReportChatBlockCard.swift` only sets `.disabled(isWorking)`, while the banner capsule shows a spinner and "Unblocking". Fix: show a small `ProgressView` tinted `Brand.primary` with a "Blocking"/"Unblocking" label while disabled.
2. **Banner Unblock capsule is fixed at 44 pt.** `ChattingBlockedBanner.swift:81` uses `.frame(height: 44)`; at accessibility text sizes the `.subheadline` Bold label can outgrow it. The contract asks for a 44 pt minimum. Fix: `.frame(minHeight: 44)`; check the `.accessibility3` preview and device check C9.
3. **Composer counter misaligned with the field.** `ChattingInputBar.swift:91` adds `.padding(.trailing, 16)` on top of the bar's 14 pt padding, so the counter ends 30 pt from the edge while the field ends at 14 pt. The contract says it "ends under the field's right edge". Fix: remove the extra trailing padding, or correct the contract if intended.

## Detailed Findings

### Pillar 1: Copywriting (3/4)
Verified present and exact: `Sending…`, `Not sent. Tap to retry`, `Delete`, `Send message`, `Message length limit reached`, `Couldn't send message`, `You blocked this conversation`, `You can't reply to this conversation`, `This user is unavailable.`, `Unblock`, `Unblock or Report`, `Block User` / `Unblock User`, `Couldn't block user`, `Couldn't unblock user`, `Couldn't send report`, `Check your connection and try again.`, `Your report wasn't sent…`, `Only the person who blocked this conversation can unblock it.`, `Block {name}?`, `They won't be able to message you.`, `They won't be notified.`, `Blocking`, `99+`. The stale copy (`Spam or scam`, `Fake profile`, `This conversation is blocked`, profile/appointment claims) is gone.
- WARNING: `ExpertProfileView.swift:243` renders `Label("Block \(expert.name)", …)` with no fallback; a blank name shows "Block ". The alert and toast use `ExpertProfileBlockViewModel.displayName`. Fix: use `displayName(expert.name)` here.
- WARNING: none of the new literals are in `ClickMe2026/Localizable.xcstrings`. The catalog already had uncommitted changes before this phase, so extract the strings with an Xcode build and commit the catalog deliberately.

### Pillar 2: Visuals (3/4)
Focal points match the contract; icon-only controls are labelled (send button) or hidden (failed glyph, banner icon).
- WARNING (pre-existing at `16fe88e`): the thread toolbar button (`ChattingView.swift:87-91`, `line.3.horizontal`) has no accessibility label; the profile's equivalent has `More options`.
- WARNING: the failed glyph sits outside the `Button` hit area (`ChattingMessageBubble.swift:131-139`); tapping it does nothing (07-02 observation b). Accept, or move it inside the group.

### Pillar 3: Color (3/4)
`Brand.primary` appears only on the reserved list (send icon, `· Read`, composer tint, online dot, Retry capsule, pill, Unblock capsule/stroke). The failed bubble (`myBubble` 40%, `Brand.onSurface` text, `Brand.error` 50% border, `Brand.destructive` glyph) and the at-cap counter (`Brand.error`) match the contract.
- WARNING: `ReportChatBrand.swift` and other alias enums hard-code `Color(red:…)`; the Block button uses `errorRed` (#ff614d) while failed text uses `Brand.error`. Later cleanup, not this phase.

### Pillar 4: Typography (3/4)
New text uses `caption` (12), `subheadline` (15) or `callout`, Regular or Bold, per contract.
- WARNING (pre-existing, out of contract): the chat folder uses 8 text styles and 5 weights.

### Pillar 5: Spacing (3/4)
New values are on the 4-pt grid (banner 16/8 padding, 56 min height; failed glyph 20 pt with 8 pt gap; pill 8 pt padding, 24 pt min).
- WARNING: counter misalignment (fix 3). WARNING: fixed 44 pt capsule (fix 2). Pre-existing off-grid values (14, 10, 11, 42) are recorded in the contract and correctly left alone.

### Pillar 6: Experience Design (3/4)
Covered in code: optimistic send with an enabled composer; failed bubble with a 44 pt tap-to-retry group, Delete context menu and VoiceOver actions; blocked/unavailable banner with blocker-only Unblock; profile Block confirm alert, scrim, toast and per-step errors; unread pill (`99+`, single VoiceOver element, bold preview); reports with enum raw values, 1,000-unit cap and counter.
- WARNING: Report & Block card has no in-flight state beyond `.disabled` (fix 1).
- WARNING: the failed status line (`ChattingMessageBubble.swift:146-151`) lacks the `.fixedSize(horizontal: false, vertical: true)` the contract's Dynamic Type section asks for. Low risk.

Scores are provisional: the 18 device checks in `07-DEVICE-UAT-CHECKLIST.md` (scrim, VoiceOver, toast over the tab bar, failed-state visuals) are unrun.

## Files Audited

- `ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift`
- `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingMessageBubble.swift`
- `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingInputBar.swift`
- `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingBlockedBanner.swift`
- `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingEmptyState.swift` (grep only)
- `ClickMe2026/Utils/ChatComposerRules.swift`, `ChatUnreadRules.swift`, `ChatBlockState.swift`
- `ClickMe2026/Views/Screens/Chat/Conversations/Subviews/ChatConversationRow.swift`
- `ClickMe2026/Views/Screens/Chat/Report and Block/ReportChatView.swift`, `ReportChatViewModel.swift` (grep only)
- `ClickMe2026/Views/Screens/Chat/Report and Block/Subviews/ReportChatBlockCard.swift`, `ReportChatReasonField.swift`, `ReportChatDescriptionField.swift`
- `ClickMe2026/Views/Screens/Client Mode/Expert Profile/ExpertProfileView.swift`, `ExpertProfileBlockViewModel.swift`
- `ClickMe2026/Localizable.xcstrings` (grep only)
- Base-commit comparison at `16fe88e` for pre-existing checks
