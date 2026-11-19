# Phase 8: Release - Context

**Gathered:** 2026-11-19
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase produces one verified iOS build (1.1, build 7) containing every fix from Phases 1–7. It closes the remaining open gaps of major severity and above. It deploys every backend change this project made to production first, by fast-forward pushes of an iOS-only line onto `origin/main`. It proves the core paths in one TestFlight regression run against production with real money, then submits to the App Store.

The phase also takes on three folded todo groups: backend release gates, backend data and contract fixes, and the Android parity ports. See Folded Todos.

The phase starts from this state, as of 2026-11-19:
- **Phase 3:**
  - UAT is `partial`. Device checklist items 1–6 are done; items 7–24 were never run.
  - It has 3 open gaps: `G-03-1-ITEM1`, `G-03-1-ITEM1B` and `G-03-1-ITEM1C`, all in `03-UAT.md`.
  - `03-VERIFICATION.md` is `human_needed` and stale, because source files changed after the verifier ran.
- **Phase 4:**
  - UAT is `partial`: 3 passed, 20 skipped and 1 blocked. Its only gap, `G-04-3`, is resolved by 04-17.
  - `04-VERIFICATION.md` is `human_needed`.
- **Phases 1, 2, 5, 6 and 7:** UAT is complete and verification passed. All Phase 5 gaps are resolved.
- **Production backend:** `/health` reports `28da165`, the tip of `origin/main` with D-12 and CR-02. Backend `master` is 2 commits behind `origin/main` and 17 ahead of it. Those 17 are the backend's own Phase 31 and 32 work, including the one-way `20261113000100_drop_legacy_ledger.sql` migration and the FAQ fix. They also include this project's chat-reasons commits: `94d659b` (code) and `22b8967` (docs), from quick task `261119-miw`, which are not deployed.
- **Parked:** BACK-08 and BACK-13 are on backend branch `wave-3c` at `8407402`.

</domain>

<decisions>
## Implementation Decisions

### Release-ready bar
- **D-01:** The final TestFlight regression run replaces the unrun device items: Phase 3 checklist items 7–24 and Phase 4's 20 skipped UAT tests. Those items are not run on a device before submission. Their evidence is unit tests and code review, plus the regression run of the core paths.
  - This amends REL-01 and roadmap Phase 8 success criterion 1, which say every phase's checklist has passed on a real iPhone. The user approved recording the amendment.
  - Planning updates REQUIREMENTS.md REL-01 and the ROADMAP.md criterion to say so. It lists the uncovered items in the release record as "not run on device; covered by unit tests plus regression".
  - **Reversibility:** reversible — those items can still be run later; nothing ships that blocks running them.
- **D-02:** VoiceOver and accessibility steps are dropped from the device checklists entirely; the user will not test VoiceOver.
  - Examples: Phase 3 item 4 (BOOK-09 pill), item 11 (JOIN CALL hint), item 21 (D2 toast VoiceOver), and the VoiceOver parts of the UI-SPEC L2 backstops.
  - Record them in the release record as removed and untested on device. Never record them as passed.
  - Large Dynamic Type checks are not VoiceOver. They fall under D-01 (covered by the regression run and tests), not under this drop.
- **D-03:** Every open gap of major severity or above is fixed before submission. A minor or cosmetic gap may be deferred with a written reason.
  - The Phase 3 gaps:
    - `G-03-1-ITEM1B` (reasons in the chat, major): must ship.
    - `G-03-1-ITEM1C` (the decline push goes to the decliner, not the proposer, major): must ship.
    - `G-03-1-ITEM1` (the proposal push says "has been rescheduled", minor): may be deferred. It is backend-only, so it can ship in any backend deploy without the iOS build, and should if it's cheap.
- **D-04:** The regression run uses:
  - **Build:** the actual TestFlight release candidate (1.1, build 7), against production.
  - **Money:** a small real CAD charge.
  - **Sessions:** a paid in-app voice session, a free in-app voice session and one Skype/Zoom session.
  - **Second phone:** an Android peer as the other party.
  - **Path:** book → pay → join → run past the scheduled end → finish.
- **D-05:** Before Phase 8 closes, Phase 3's stale verification must be regenerated (`/gsd-execute-phase 03` resumes at the verification gates), and Phases 3 and 4 must move from `human_needed` to closed under the D-01 amendment.

### Unverified backend items
- **D-06:** The real-money smokes that never ran for BACK-06, BACK-07 and BACK-19 are folded into the D-04 regression run, in the same real-money session:
  - **BACK-06:** save exactly one card; it must become the default.
  - **BACK-07:** delete a card, then check that its connected-account clone is detached and can't be charged. Read the clone id from `connected_pm_clones` before removing the card (01-17 lesson).
  - **BACK-19:** the expert cancels a captured booking, which must fully refund, and a held booking, which must release the hold. Check this on the PaymentIntent state, not in the app (01-17 lesson).
  - Each requirement closes on that evidence.
- **D-07:** BACK-08 is deferred past this release, like BACK-13. The reason goes under REL-02: its gate returns 403 on `GET /expert/tax-profile` for client-only accounts, and it ships with BACK-13 once build 6 and the current Android build no longer rely on implicit promotion. `wave-3c` stays parked.
- **D-08:** BACK-15 closes on its mock and unit-test evidence, with the reason recorded (a phone cannot force a same-`booking_attempt_id` retry). PAY-02's iOS handling is covered by the regression run only if a timeout happens to occur.
- **D-09:** If any real-money check in the regression run fails:
  1. Stop the submission.
  2. If the fault is backend-only, deploy a backend fix and re-run only the failed check.
  3. If the fault is iOS, make a new build and run the full regression again.

### Backend deploy order
- **D-10:** Production gets an iOS-only line. This project's backend commits are cherry-picked onto `origin/main` and pushed as fast-forwards, the way D-12 and CR-02 shipped. Backend `master`'s own Phase 31 and 32 work, including the one-way legacy-ledger drop migration, is not deployed by this phase.
  - **Reversibility:** costly — deploying master's one-way migration could not be undone, which is why it stays out.
- **D-11:** The chat-reasons change (`94d659b`) is cherry-picked onto `origin/main`. If it doesn't apply cleanly, rebuild the same change with its tests on `origin/main` and keep the master commit for the later merge.
- **D-12:** Backend gap fixes deploy as they land, each one after the full suite passes. The backend then freezes before the TestFlight regression run, so that run tests the final production backend. Every backend change is live before the iOS build is submitted (REL-02).
- **D-13:** After each deploy, check that the live apps still work:
  - **Before the push:** the full backend suite passes, apart from the pre-existing Redis tests that need a live server.
  - **After the push:** a short live smoke on App Store build 6 and the current Android build: log in, open bookings, open chat, plus one path the change touches.
  - Every change must be additive for both live clients.
- **D-14:** Claude pushes backend deploys, but only after the user approves each one in the session. Each approval covers that one deploy only.
- **D-15:** If a gap fix needs a migration, the additive schema change is applied in a deploy before the code that uses it (the BACK-14 pattern). Nothing irreversible ships in this release: no drops and no renames.
  - **Reversibility:** one-way for any migration that does ship — plan a decision checkpoint before it.
- **D-16:** For rollback, record `/health` before every push and create a local rollback branch at that SHA. Roll back by redeploying that SHA on Railway.
- **D-17:** Backend `master` takes the D-12 merge during Phase 8. That means merging `origin/main` into `master` (D-12, CR-02 and every iOS-line commit), never rebasing or force-pushing, and keeping both `ios-p4` D-12 describe blocks passing. `master` itself is NOT deployed by this phase. This closes todo `2026-11-11-merge-d12-into-backend-master.md`.
  - Expected conflicts: `src/controllers/webhooks.controller.js` and `tests/webhooks.test.js` (31-05 vs D-12).
  - Re-derive the commit counts before merging.

### Build and submission
- **D-18:** The release is version 1.1, build 7: `MARKETING_VERSION = 1.1` and `CURRENT_PROJECT_VERSION = 7` for the app target. 1.0 is already on the App Store as build 6 and can't be reused.
- **D-19:** The build is made by CI. A pushed `release/1.1` branch triggers `.github/workflows/build.yml`, which builds, signs and uploads to TestFlight on `macos-26`. Before upload, the build must be clean in `xcodebuild` with no new warnings compared with the pre-project baseline. `Environments.plist` stays on Production.
- **D-20:** Only internal TestFlight testers (the user and the internal team) test the build, and they run the D-04 regression on it. There is no external beta group and no Beta App Review.
- **D-21:** The release goes to everyone immediately on approval: no phased release and no manual hold. The user chose this knowing there's no quick hotfix path. That makes D-04, D-06 and D-09 the only safety net.
  - **Reversibility:** one-way — once released to everyone, a regression can only be fixed by a new App Store review cycle.
- **D-22:** Claude drafts the App Store "What's New" text in plain language from the closed requirements, and the user approves it before submission.

### Claude's Discretion
- How the remaining work is grouped into plans and waves:
  - the Phase 3 gaps: backend first, then iOS and Android display;
  - the folded todos and the Android ports;
  - the backend deploy waves;
  - the build and submission.
- The exact regression-run checklist layout, and how the BACK-06, 07 and 19 steps slot into the sessions in D-04.
- The `event_data` rendering design for the chat reasons, within the existing chat event-row patterns. Label each reason by `reason_by`, and for request declines fall back to `reason_text ?? decline_reason_text`.

### Folded Todos
The user selected all three groups. Each item keeps its own todo file in `.planning/todos/pending/`; close each todo when its work lands.

**Backend release gates**
- `2026-11-11-merge-d12-into-backend-master.md`: merge `origin/main` (D-12 + CR-02) into backend `master`. The how is in D-17.
- `2026-11-12-long-lead-sweep-transient-errors-after-stamp.md`: in the long-lead T-24h sweep, transient errors after the stamp still cancel at 6 h. This is a payments bug on the live line, so it ships on the iOS-only line (D-10) under the D-12 and D-13 rules.

**Backend data and contract fixes** (each must be additive for build 6 and Android, per D-13)
- `2026-11-16-backend-null-topic-currency.md`: the backend sends `price.currency: ""` instead of null for a topic stored with no currency.
- `2026-11-14-backend-profile-name-validation.md`: `PATCH /user/profile` name validation: the min(1) copy, contract drift, and what to do about an empty last name.
- `2026-11-13-decide-saved-cards-on-account-deletion.md`: decide what happens to saved cards when an account is deleted. This is a decision; ask the user during planning.
- `2026-11-16-usd-symbol-us-dollar-prefix.md`: decide whether USD renders as `$` (the shipped Money table) or `US$`. This is a decision; ask the user during planning.

**Android parity follow-ups** (in `../ClickMe_Android`, one commit per change in that repo; the Android release itself is not part of this phase)
- `2026-11-16-android-phase-6-parity-follow-ups.md`: Add hours at end of day, off-grid rows, the 409, and the client hub dot.
- `2026-11-13-android-phase-5-parity-check.md`: other behavior changes iOS made in Phase 5.
- `2026-11-13-android-cancellation-policy-link.md`: the cancellation policy link and the corrected policy copy (D-12).
- `2026-11-13-android-delete-account-copy-and-blockers.md`: the Delete Account copy and the 409 blocker alert.
- `2026-11-13-android-remember-login-email.md`: port branch `0c9ecc55` the way iOS ported `b0629d9` (D-16).
- `2026-11-14-android-profile-settings-empty-name-save.md`: Profile Settings saves on an account with an empty name. Port the G-05-6 iOS rules.
- `2026-11-15-android-expert-settings-clear-meeting-link.md`: clearing the expert meeting link is never sent. Port the CR-01 iOS rule.
- `2026-11-08-check-the-android-push-prompt-after-a-reinstall.md`: check the Android push prompt after a reinstall.
- New from this session: Android must render the chat reasons (`G-03-1-ITEM1B`) in `screens/chat/chatting/ChatMessageMapping.kt`, with fixtures in `ChatFixtures.kt`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirements
- `.planning/ROADMAP.md` § Phase 8: the goal, the success criteria (criterion 1 is amended by D-01) and the notes on BACK-08 and BACK-13.
- `.planning/REQUIREMENTS.md`:
  - REL-01 (amended by D-01) and REL-02 (with the BACK-08 and BACK-13 deferral reasons).
  - The unchecked BACK-06, 07, 08, 15 and 19 rows.
  - The Pending rows for Phase 4 (BOOK-01 to BOOK-05, BOOK-19, PAY-01 to PAY-04, EXPL-01 to EXPL-07).
- `.planning/PROJECT.md`: the constraints: one release at the end, backend changes compatible with the current Android build, one commit per repo, production data.
- `.planning/STATE.md` § Decisions: the history of every deploy wave, the rollback SHAs, and the reasons the smokes were not run.

### Open gaps and verification
- `.planning/phases/03-booked-sessions-and-joining/03-UAT.md` § Gaps: `G-03-1-ITEM1`, `ITEM1B` (with `backend_progress`, `client_work_open` and `noticed_not_fixed`) and `ITEM1C`.
- `.planning/phases/03-booked-sessions-and-joining/03-DEVICE-UAT-CHECKLIST.md`: item results 1–6. Items 7–24 are covered by D-01; their VoiceOver steps are dropped by D-02.
- `.planning/phases/03-booked-sessions-and-joining/03-VERIFICATION.md`: `human_needed` and stale (D-05).
- `.planning/phases/04-booking-payment-and-discovery/04-UAT.md`, `04-DEVICE-UAT-CHECKLIST.md` and `04-VERIFICATION.md`: the 20 skipped tests and 1 blocked test covered by D-01.

### Backend contract and deploy
- `../ClickMe2026 Backend/openapi/clickme-api.yaml`: the REST contract. Chat `event_data` keys `reason_text` and `reason_by` were added in `94d659b`.
- `../ClickMe2026 Backend/docs/SOCKET-CONTRACT.md`: the WebSocket events.
- `../ClickMe2026 Backend/src/services/events.js`:
  - `injectEventMessage`: the chat event's `event_data`.
  - `dispatchPushForEvent`: the `BOOKING_DECLINED` push recipient (ITEM1C) and the `BOOKING_RESCHEDULED` wording (ITEM1).
- `../ClickMe2026 Backend/docs/ios/STRIPE-INTEGRATION.md`: D-12 and CR-02 behavior, and the long-lead sweep.
- `.planning/todos/pending/2026-11-11-merge-d12-into-backend-master.md`: the merge facts, the expected conflicts and the baseline test counts.
- Phase 1 smoke checklists (01-17 real card, 01-19 expert-cancel refund), whose steps are folded into the regression per D-06: under `.planning/phases/01-backend-fixes/`.

### Build and release
- `.github/workflows/build.yml`: the TestFlight deploy on a `release/**` push or a manual dispatch.
- `ExportOptions.plist` and `.github/actions/code-signing-setup/action.yml`: signing and export.
- `ClickMe.xcodeproj/project.pbxproj`: `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` for the app target (D-18).
- `ClickMe2026/Environments.plist`: stays on `Current = Production`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- iOS chat event rendering: `ClickMe2026/Utils/ChatItemMapper.swift`, `ClickMe2026/Model/UIModels/ChatDisplayModels.swift` and the event row views under `ClickMe2026/Views/Screens/Chat/`. `event_data` decodes as `JSONValue`, so the new keys need no change to the wire model.
- Android chat: `screens/chat/chatting/ChatMessageMapping.kt`. `ChatPayloads.kt` already keeps `eventData` as a plain map.
- Backend push routing: `BOOKING_CANCELLED` and `BOOKING_RESCHEDULED` already route to the non-initiator through `notify_user_id`. ITEM1C should reuse that pattern for reschedule declines.

### Established Patterns
- **Backend deploys:** fast-forward pushes onto `origin/main` (D-12 and CR-02 did this), each with a local `*-rollback` branch at the previous `/health` SHA.
- **Free text in events:** goes into chat `event_data` and push `in_app_meta` only, never the FCM/APNs `data` map (BACK-02 and `94d659b`).
- **Additive contract rule:** new optional keys only. Never rename or remove a key or change validation in a way that rejects an existing client payload.
- **Release:** one iOS build at the end (no hotfix), signed and uploaded by CI.

### Integration Points
- A reschedule decline and a request decline are both `BOOKING_DECLINED`. A reschedule decline with no reason can't be told apart from a request decline, which a backend marker would fix (noted in `G-03-1-ITEM1B`). The ITEM1C fix needs to tell them apart for routing and wording anyway.
- `BOOKING_RESCHEDULED` `event_data` has no proposed time. This was noticed and not fixed, and is not required by D-03.

</code_context>

<specifics>
## Specific Ideas

- The user wants every reason a user gives with an action to become part of the chat ("All the reasons for actions should become part of the chat", 2026-11-19). The backend part is committed in `94d659b`; the iOS and Android rendering is still open.
- Push wording for a proposal should read as a reschedule request, not as a completed reschedule.

</specifics>

<deferred>
## Deferred Ideas

- **BACK-08 and BACK-13:** deferred past this release (D-07). `wave-3c` stays parked.
- **`G-03-1-ITEM1` (proposal push wording):** may be deferred under D-03 if it isn't shipped in a backend deploy.
- **`BOOKING_RESCHEDULED` `event_data`:** add the proposed time. Not requested.
- **Phased App Store release:** not used (D-21).

### Reviewed Todos (not folded)
None. The user folded all three groups that matched. Two pending todos did not match Phase 8 and were not reviewed: `2026-11-13-flaky-make-a-booking-availability-test.md` and `2026-11-17-chat-booking-row-dual-role-route.md`.

</deferred>

---

*Phase: 08-release*
*Context gathered: 2026-11-19*
