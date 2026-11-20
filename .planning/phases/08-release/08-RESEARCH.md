# Phase 8: Release - Research

**Researched:** 2026-11-19
**Domain:** Cross-repo release engineering (iOS TestFlight/App Store build, production backend fast-forward deploys, chat-reason display on iOS and Android, folded backend and Android parity todos)
**Confidence:** HIGH on repo facts verified this session; MEDIUM on CI secrets and App Store Connect state (not inspectable from here)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Release-ready bar**
- **D-01:** The final TestFlight regression run replaces the unrun device items: Phase 3 checklist items 7-24 and Phase 4's 20 skipped UAT tests. Those items are not run on a device before submission. Their evidence is unit tests and code review, plus the regression run of the core paths.
  - This amends REL-01 and roadmap Phase 8 success criterion 1, which say every phase's checklist has passed on a real iPhone. The user approved recording the amendment.
  - Planning updates REQUIREMENTS.md REL-01 and the ROADMAP.md criterion to say so. It lists the uncovered items in the release record as "not run on device; covered by unit tests plus regression".
  - **Reversibility:** reversible - those items can still be run later; nothing ships that blocks running them.
- **D-02:** VoiceOver and accessibility steps are dropped from the device checklists entirely; the user will not test VoiceOver.
  - Examples: Phase 3 item 4 (BOOK-09 pill), item 11 (JOIN CALL hint), item 21 (D2 toast VoiceOver), and the VoiceOver parts of the UI-SPEC L2 backstops.
  - Record them in the release record as removed and untested on device. Never record them as passed.
  - Large Dynamic Type checks are not VoiceOver. They fall under D-01 (covered by the regression run and tests), not under this drop.
- **D-03:** Every open gap of major severity or above is fixed before submission. A minor or cosmetic gap may be deferred with a written reason.
  - `G-03-1-ITEM1B` (reasons in the chat, major): must ship.
  - `G-03-1-ITEM1C` (the decline push goes to the decliner, not the proposer, major): must ship.
  - `G-03-1-ITEM1` (the proposal push says "has been rescheduled", minor): may be deferred. It is backend-only, so it can ship in any backend deploy without the iOS build, and should if it's cheap.
- **D-04:** The regression run uses:
  - **Build:** the actual TestFlight release candidate (1.1, build 7), against production.
  - **Money:** a small real CAD charge.
  - **Sessions:** a paid in-app voice session, a free in-app voice session and one Skype/Zoom session.
  - **Second phone:** an Android peer as the other party.
  - **Path:** book -> pay -> join -> run past the scheduled end -> finish.
- **D-05:** Before Phase 8 closes, Phase 3's stale verification must be regenerated (`/gsd-execute-phase 03` resumes at the verification gates), and Phases 3 and 4 must move from `human_needed` to closed under the D-01 amendment.

**Unverified backend items**
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

**Backend deploy order**
- **D-10:** Production gets an iOS-only line. This project's backend commits are cherry-picked onto `origin/main` and pushed as fast-forwards, the way D-12 and CR-02 shipped. Backend `master`'s own Phase 31 and 32 work, including the one-way legacy-ledger drop migration, is not deployed by this phase.
  - **Reversibility:** costly - deploying master's one-way migration could not be undone, which is why it stays out.
- **D-11:** The chat-reasons change (`94d659b`) is cherry-picked onto `origin/main`. If it doesn't apply cleanly, rebuild the same change with its tests on `origin/main` and keep the master commit for the later merge.
- **D-12:** Backend gap fixes deploy as they land, each one after the full suite passes. The backend then freezes before the TestFlight regression run, so that run tests the final production backend. Every backend change is live before the iOS build is submitted (REL-02).
- **D-13:** After each deploy, check that the live apps still work:
  - **Before the push:** the full backend suite passes, apart from the pre-existing Redis tests that need a live server.
  - **After the push:** a short live smoke on App Store build 6 and the current Android build: log in, open bookings, open chat, plus one path the change touches.
  - Every change must be additive for both live clients.
- **D-14:** Claude pushes backend deploys, but only after the user approves each one in the session. Each approval covers that one deploy only.
- **D-15:** If a gap fix needs a migration, the additive schema change is applied in a deploy before the code that uses it (the BACK-14 pattern). Nothing irreversible ships in this release: no drops and no renames.
  - **Reversibility:** one-way for any migration that does ship - plan a decision checkpoint before it.
- **D-16:** For rollback, record `/health` before every push and create a local rollback branch at that SHA. Roll back by redeploying that SHA on Railway.
- **D-17:** Backend `master` takes the D-12 merge during Phase 8. That means merging `origin/main` into `master` (D-12, CR-02 and every iOS-line commit), never rebasing or force-pushing, and keeping both `ios-p4` D-12 describe blocks passing. `master` itself is NOT deployed by this phase. This closes todo `2026-11-11-merge-d12-into-backend-master.md`.
  - Expected conflicts: `src/controllers/webhooks.controller.js` and `tests/webhooks.test.js` (31-05 vs D-12). **(Research finding: this expectation is stale, see Summary item 2.)**
  - Re-derive the commit counts before merging.

**Build and submission**
- **D-18:** The release is version 1.1, build 7: `MARKETING_VERSION = 1.1` and `CURRENT_PROJECT_VERSION = 7` for the app target. 1.0 is already on the App Store as build 6 and can't be reused.
- **D-19:** The build is made by CI. A pushed `release/1.1` branch triggers `.github/workflows/build.yml`, which builds, signs and uploads to TestFlight on `macos-26`. Before upload, the build must be clean in `xcodebuild` with no new warnings compared with the pre-project baseline. `Environments.plist` stays on Production.
- **D-20:** Only internal TestFlight testers (the user and the internal team) test the build, and they run the D-04 regression on it. There is no external beta group and no Beta App Review.
- **D-21:** The release goes to everyone immediately on approval: no phased release and no manual hold. The user chose this knowing there's no quick hotfix path. That makes D-04, D-06 and D-09 the only safety net.
  - **Reversibility:** one-way - once released to everyone, a regression can only be fixed by a new App Store review cycle.
- **D-22:** Claude drafts the App Store "What's New" text in plain language from the closed requirements, and the user approves it before submission.

**Decisions made at planning time (2026-11-19)**
- **D-23:** Saved cards on account deletion: **disclose it**. Add a line to the Delete Account copy on iOS (`AccountDeletionCopy`) and port it to Android, for example `Saved cards are not removed by deleting your account.` (UI-SPEC row U3 wording). No backend or payment change. Update the `AccountDeletionCopy` tests that currently forbid `saved card`. Closes todo `2026-11-13-decide-saved-cards-on-account-deletion.md`.
- **D-24:** USD renders as **`US$` everywhere**, with CAD as `CA$`, as `docs/ios/USD-TOPIC-PRICING.md` §0 item 5 specifies. Change the iOS `Money` symbol table (`ClickMe2026/Utils/Money.swift`) and update the pinned tests (`MoneyCallSiteTests`, `ClientProfileHistoryEarningsTests` and any other `$42.50`-style pins). Fold `TopicsSetupTopicCard.cardSymbol(for:)` onto `Money` if it becomes redundant. Android `util/Money.kt` must match: an explicit `US$` / `CA$` table, not the device locale. Closes todo `2026-11-16-usd-symbol-us-dollar-prefix.md`.

### Claude's Discretion
- How the remaining work is grouped into plans and waves:
  - the Phase 3 gaps: backend first, then iOS and Android display;
  - the folded todos and the Android ports;
  - the backend deploy waves;
  - the build and submission.
- The exact regression-run checklist layout, and how the BACK-06, 07 and 19 steps slot into the sessions in D-04.
- The `event_data` rendering design for the chat reasons, within the existing chat event-row patterns. Label each reason by `reason_by`, and for request declines fall back to `reason_text ?? decline_reason_text`.

### Deferred Ideas (OUT OF SCOPE)
- **BACK-08 and BACK-13:** deferred past this release (D-07). `wave-3c` stays parked.
- **`G-03-1-ITEM1` (proposal push wording):** may be deferred under D-03 if it isn't shipped in a backend deploy.
- **`BOOKING_RESCHEDULED` `event_data`:** add the proposed time. Not requested.
- **Phased App Store release:** not used (D-21).
- Not folded (do not plan): `2026-11-13-flaky-make-a-booking-availability-test.md`, `2026-11-17-chat-booking-row-dual-role-route.md`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | Every phase's fixes pass a device UAT checklist on a real iPhone (amended by D-01) | §Carried-over device items (what D-01 does and does not cover), §Regression run layout, §Verification closeouts, §Validation Architecture |
| REL-02 | One new iOS build with all fixes is submitted to TestFlight and the App Store, backend changes deployed first (BACK-08 and BACK-13 deferred, D-07) | §Backend branch state, §Backend deploy waves, §Release mechanics (CI blockers, version bump, warnings baseline, submission), §Open Questions |
</phase_requirements>

## Summary

Phase 8 is not mostly coding. It is a gated sequence: close three backend gaps and ship them on an iOS-only backend line, render the chat reasons on iOS and Android, fold in the todos, then produce one signed build and run one real-money regression on it. The research found **seven findings that change or add to the plan**, in priority order:

1. **The CI build (D-19) cannot succeed today, for three independent reasons.** (a) `build.yml` line 22 sets `XCODE_PROJECT: ClickMe2026.xcodeproj`; the project on disk is `ClickMe.xcodeproj` (`test.yml:13` and `scripts/run-smoke-tests.sh:23` have the same stale name). (b) `ExportOptions.plist` has `<key>teamID</key><string>XXXXXXXXXX</string>`, a placeholder; the real team is `DEVELOPMENT_TEAM = V68J585TK5` in the project. (c) **A clean checkout does not compile.** `ClickMe2026/Debug/PreviewSecrets.swift` is gitignored, yet `#Preview` blocks in 38 Swift files reference `PreviewSecrets` (`grep -rl "PreviewSecrets\." ClickMe2026`). I ran `xcodebuild build -configuration Release -destination generic/platform=iOS CODE_SIGNING_ALLOWED=NO` on a `git archive HEAD` copy and it failed with `cannot find 'PreviewSecrets' in scope` in 37 distinct files (for example `ChattingView.swift:528`, `ChatConversationsView.swift:250`, `MyBookingsView.swift:454`). Also, GitHub `origin/main` is at `13b3d3a` (2026-11-07); local `main` is 780 commits ahead of it, so the first `release/1.1` push publishes the entire project history. The CI secrets (`BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`, `KEYCHAIN_PASSWORD`, `APP_STORE_CONNECT_API_KEY_*`) cannot be inspected from here. The plan needs a "make CI buildable and dry-run it" wave before D-19 can be trusted, plus a documented fallback (Xcode Organizer archive and upload, which is how build 6 shipped).
2. **The D-17 "expected conflicts" are stale; the merge is clean.** `git merge-tree --write-tree master origin/main` exits 0 with a merged tree and no conflict. Reason: 31-05 (`3149a6b`) is an ancestor of the merge base `32fa6ec`, and `master` has not touched the D-12 or CR-02 files since. Still run the three D-12/CR-02 describe blocks after the merge; a clean textual merge is not proof of passing tests.
3. **`94d659b` cherry-picks cleanly onto `origin/main`, and its suites pass there.** `git merge-tree --write-tree --merge-base=94d659b^ origin/main 94d659b` exits 0. I extracted the resulting tree and ran the whole backend suite: 3837 passed, 6 failed (the six `redis.test.js` tests that need `REDIS_URL`), 153 suites. The unmodified `origin/main` tip `28da165` gives 3803 passed and the same 6 Redis failures. A later merge of `origin/main` (plus the cherry-pick) into `master` is also clean (simulated). Do **not** cherry-pick `22b8967` (docs touching `.planning/` of the backend repo); it can stay on `master`.
4. **Migrations are not part of a Railway deploy; the "one-way" drop is already live.** The 31-12 summary records that the operator ran `supabase db push` and `expert_earnings` / `withdrawals` were dropped in production on 2026-11-12; the FAQ migration was "Applied to prod 2026-11-12". Railway only deploys code from a pushed `main`. So D-10's reason (deploying master would apply an irreversible migration) is moot for the database. The practical difference between `master` and `origin/main` at runtime is small: `94d659b`'s reason code (which ships anyway), the deleted `scripts/verify-legacy-drain.js`, test files and docs. D-10 stays locked, but the planner should know that **any future `supabase db push` must run from a checkout that contains the two already-applied migration files** (`20261113000100_*`, `20261113000200_*`), otherwise the CLI sees remote versions missing locally. After the D-17 merge, `master` is that checkout.
5. **D-06's "expert cancels a captured booking, must fully refund" cannot be exercised on a device.** The 01-19 checklist's own table says "A real refund of a captured booking: No (mocked tests only)", because neither client can force the captured branch and a booking whose call connected cannot be cancelled. The planner must either record BACK-19 as closing on hold-release only (like D-08 for BACK-15) or design a long-lead (T-24h charge) booking; this is a user decision (Open Question 2).
6. **Several "before Phase 8" device items are not covered by D-01.** D-01 names Phase 3 items 7-24 and Phase 4's skipped tests. Backlog 999.4 (Phase 6 Liquid Glass checks, items 13 and 16), Phase 5 deferred items 24 and 45, the Phase 2 overtime-with-Android-peer check, and Phase 6/7's "run before Phase 8" notes still say they run before release. The release record needs an explicit disposition for each (Open Question 3).

7. **The "no new warnings" gate is already failing by one.** Same-command Release builds of the shipped build 6 code (`a48c664`, 4 unique warnings) and HEAD (5) differ by `FavoritesViewModel.swift:282` "result of call to 'withAnimation' is unused" (fix: `_ = list.remove(...)`). The baseline is not zero, so the gate is a normalized diff, not "zero warnings".

Other facts the planner needs: production `/health` returned `{"status":"success","commit":"28da165"}` on 2026-11-19, equal to `origin/main`; the gap fixes for `G-03-1-ITEM1B/1C/1` are all in `src/services/events.js` plus two reschedule-decline call sites; iOS and Android chat-reason rendering are small additive changes; D-23's example wording trips the existing `AccountDeletionCopy` test for the word `removed`; and the iOS `PushRouter` maps `booking/declines` to the read-only booking summary, which is the wrong screen for a reschedule decline (the booking stays active).

**Primary recommendation:** Run the work in this order: (W0) make the release path buildable and dry-run it, (W1) backend gap fixes on the iOS-only line with one approved deploy each, (W2) iOS and Android display and the folded todos, (W3) closeout and verification regeneration, (W4) version bump, release branch, CI or Organizer build, internal TestFlight regression, then the human-only submission. Treat W0 as the critical path, because a failed CI at the end leaves no hotfix path.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Deciding reschedule-decline vs request-decline, push recipient and wording | API / Backend (`src/services/events.js`) | - | Only the backend knows who proposed; clients must not infer it |
| Reason text stored in chat event | API / Backend (`injectEventMessage`, `event_data`) | Database (`messages.event_data` JSONB) | Already shipped in `94d659b`; additive keys |
| Rendering reasons in chat rows | Client (iOS `ChatItemMapper` + `ChattingSystemEventRow`; Android `ChatMessageMapping` + `SystemEventRow`) | - | Display only; keys must be optional and ignorable |
| Currency symbol (`US$`, `CA$`) | Client (iOS `Money`, Android `Money.kt`) | API (server labels already `US$`) | Clients format minor units; backend doc §0 item 5 is the contract |
| Delete Account disclosure line | Client copy (iOS `AccountDeletionCopy`, Android `strings_delete_account.xml`) | - | No backend change (D-23) |
| Long-lead T-24h charge retry | API / Backend cron (`longLeadChargeSweep`) | Database (`bookings.off_session_attempted_at`) | Payments logic, runs server side only |
| Null topic currency, profile-name messages | API / Backend (serializers, zod schema) | OpenAPI doc | Contract hygiene, additive or message-only |
| Backend deploy | Release process (git fast-forward to `origin/main`, Railway auto-deploy) | Human (approval per D-14) | `/health` commit is the deploy oracle |
| iOS build, sign, upload | CI (GitHub Actions `macos-26`) or Xcode Organizer fallback | Human (App Store Connect) | Secrets and ASC state live outside the repo |
| Regression run | Human on real devices (iPhone build 7 + Android peer) | Backend queries, Stripe Dashboard | Money truth is the PaymentIntent, not the app |

## Standard Stack

This phase installs **no new packages**. The "stack" is the existing tools, with versions read from this machine.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Xcode / xcodebuild | 26.5 (17F42) [VERIFIED: `xcodebuild -version`] | iOS build, test, archive | Project is Xcode 26, iOS 18+ (CLAUDE.md) |
| Swift Testing (`import Testing`) | bundled | iOS unit tests | Existing convention (`ClickMe2026Tests/`) |
| jest via `npm test` | repo `package.json` script `node --experimental-vm-modules node_modules/.bin/jest` [VERIFIED: package.json] | Backend suite | Existing |
| Gradle wrapper + Android Studio JBR | `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"` exists [VERIFIED: `ls`] | Android tests/ktlint | Proven in plans 03-15, 06-09 |
| Railway (auto-deploy from `main`) | `railway.json`, healthcheck `/health` [VERIFIED: railway.json] | Backend hosting | `/health` returns the 7-char deployed commit |
| GitHub Actions `build.yml` | workflow "Deploy to TestFlight" [VERIFIED: .github/workflows/build.yml] | Signed TestFlight upload | D-19 (needs the fixes in Pitfall 1) |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `git merge-tree --write-tree` | git 2.50.1 [VERIFIED: `git --version`] | Conflict check without touching a worktree | Before D-11 cherry-pick and D-17 merge |
| `supabase` CLI | present (nvm node 24) [VERIFIED: `which`] | `supabase db push`, `migration list --linked` | Only if a gap fix needs a migration (D-15) |
| `railway` CLI | present [VERIFIED: `which`] | Optional deployment inspection | Rollback by redeploy (D-16) |
| `stripe` CLI, `redis-cli` | present [VERIFIED: `which`] | Optional | No Redis server is running, so the 6 Redis tests fail |
| `swiftformat` | present; `swiftlint` NOT installed locally [VERIFIED: `which`] | Style | CI lint runs swiftlint only in `test.yml` (PR to main), not `build.yml` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CI build via `release/1.1` (D-19) | Xcode Organizer: Archive, Validate, Distribute to TestFlight, from the Mac with signing already set up | The fallback if CI cannot be fixed in reasonable time. [ASSUMED] build 6 was archived locally this way: the repo shows no CI run for it, and `a48c664` is titled "Build 6 release config". Needs user approval to switch since D-19 is locked |
| Cherry-pick `94d659b` (D-11) | Rebuild the change on `origin/main` | Not needed: clean cherry-pick, tests green |

**Installation:** none. **Package Legitimacy:** see the audit below.

## Package Legitimacy Audit

No external packages are added, removed or upgraded in this phase (dependency versions stay as in `Package.resolved` and `package-lock.json`). Dependabot branches on GitHub (`stripe-ios-spm-26.4.1`, `agorainfra_ios-1.3.9`, `factory-3.3.2`, `actions/checkout-7`, `actions/cache-6`) exist but are **not** to be merged into the release (one build, no dependency churn).

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none installed) | - | - | - | - | n/a | n/a |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
                     BACKEND (iOS-only line, one approved deploy each, D-10/D-12/D-14)
 origin/main 28da165 ──▶ worktree "Backend D12" (branch from origin/main)
        │                  commit A: cherry-pick -x 94d659b            (chat reasons)
        │                  commit B: reschedule-decline marker + push  (ITEM1B/1C, ITEM1 wording)
        │                  commit C: long-lead sweep bounded retry     (needs decision, CP)
        │                  commit D: null topic currency / name msgs   (needs client tolerance gate)
        │                       │  npm test (3803 baseline + new; 6 Redis fails expected)
        │                       ▼
        │             record /health -> rollback branch -> USER APPROVES -> git push origin <sha>:main
        │                       ▼
        └────────────▶ Railway auto-deploy ──▶ poll /health commit == pushed SHA
                                │
                                ▼
              live smoke on build 6 + Android: login, bookings, chat, one touched path (D-13)

  master (local, 17 ahead / 2 behind) ◀── git merge origin/main (D-17, clean, no force) ── never deployed here

                     CLIENTS
 chat event row (messages.event_data) ──▶ iOS ChatItemMapper ─▶ BookingEvent(+reasonText, reasonBy)
                                                              └▶ ChattingSystemEventRow (reason line)
                                     ──▶ Android toThreadItem ─▶ ThreadItem.SystemEvent(+reason)
                                                              └▶ SystemEventRow (reason line)
 push (BOOKING_DECLINED, reschedule) ──▶ recipient = proposer (notify_user_id), not the decliner

                     RELEASE
 W3 closeouts ─▶ bump 1.1/7 ─▶ release/1.1 ─▶ CI (or Organizer) ─▶ TestFlight (internal, D-20)
                ─▶ HUMAN regression (D-04, D-06) ─▶ pass? ─┬─ yes ─▶ HUMAN submit (What's New, D-22) ─▶ release to all (D-21)
                                                            └─ no  ─▶ D-09 (backend fix + recheck, or new build + full rerun)
```

### Recommended Project Structure

No new source folders. Work lands in these existing places:

```
Backend (separate repo, commits there):
  src/services/events.js                       # dispatchPushForEvent, injectEventMessage
  src/controllers/{clientBooking,expertBooking}.controller.js   # two declineReschedule call sites
  src/cron/longLeadChargeSweep.js              # transient-error bounded retry
  src/controllers/expertTopics.controller.js   # serializeTopic currency
  src/schemas/userProfile.schema.js            # name messages
  tests/*.test.js, openapi/clickme-api.yaml, docs/ios/PUSH-ROUTING.md
iOS:
  ClickMe2026/Utils/ChatItemMapper.swift, Model/UIModels/ChatDisplayModels.swift,
  Views/Screens/Chat/Chatting/Subviews/ChattingSystemEventRow.swift
  ClickMe2026/Utils/Money.swift, AccountDeletionCopy.swift, tests under ClickMe2026Tests/
  ClickMe.xcodeproj/project.pbxproj (version), .github/workflows/build.yml, ExportOptions.plist
Android (separate repo):
  screens/chat/chatting/{ChatMessageMapping.kt,ThreadItem.kt,subviews/SystemEventRow.kt}, testing/ChatFixtures.kt
  util/Money.kt, res/values/strings_delete_account.xml, plus the parity todos
```

### Pattern 1: Cherry-pick onto the iOS-only line and deploy as a fast-forward
**What:** Work in the existing worktree `/Users/LeonChen/Documents/ClickMe2026 Backend D12` (clean, on `ios-p4-d12` = `origin/main`, with `node_modules`). Create a new branch from `origin/main`, commit there, push the branch tip to `main` by explicit refspec. Never touch `master`'s tip for a deploy.
**When to use:** Every backend deploy in this phase.
**Example:**
```bash
# Source: the way D-12 and CR-02 shipped (todo 2026-11-11, STATE.md 04-01/04-16)
cd "/Users/LeonChen/Documents/ClickMe2026 Backend D12"
curl -s https://clickme-backend-production.up.railway.app/health      # record: {"status":"success","commit":"28da165"}
git fetch origin && git status -sb                                    # expect clean, origin/main == 28da165...
git checkout -b ios-p8-wave1 origin/main
git branch ios-p8-wave1-rollback origin/main                          # D-16 rollback branch at the /health SHA
git cherry-pick -x 94d659b                                            # clean per merge-tree; keeps the trailer
npm test -- --silent                                                  # expect only the 6 redis.test.js failures
# --- human approval for THIS deploy (D-14) ---
git push origin ios-p8-wave1:main                                     # fast-forward only; never --force
until [ "$(curl -s https://clickme-backend-production.up.railway.app/health | grep -o '"commit":"[0-9a-f]*"' | cut -d'"' -f4)" = "$(git rev-parse --short=7 HEAD)" ]; do sleep 10; done
```
Run the suite from a path with **no dot-directory** in it: when I ran the cherry-picked tree under `$CLAUDE_JOB_DIR` (`~/.claude/jobs/...`), the three `tests/adminConsole.test.js` tests returned 404 instead of 200; the identical tree copied to `/tmp` passed them. The likely cause is Express static serving refusing dotfile path segments (not confirmed). The D12 worktree path has no dot directory and is safe.

### Pattern 2: Additive event_data marker for a reschedule decline
**What:** The two reschedule-decline call sites already pass `reason_text` and `reason_by` and no `notify_user_id`. Add `notify_user_id` (the proposer) and one new optional marker so events.js can route and word the push and so clients can tell a reschedule decline from a request decline even when no reason was given.
**Where (read this session):** `clientBooking.controller.js` declineReschedule dispatch at lines 774-781 (client declines the expert's proposal; proposer is `booking.expert_id`); `expertBooking.controller.js` at 1128-1135 (expert declines the client's proposal; proposer is `booking.client_id`). Request declines go through `bookingRequests.controller.js` 442-446 with `...booking` plus `decline_reason_code/text` and no `reason_by`.
**Example (shape, names are the planner's call):**
```javascript
// events.js, case 'BOOKING_DECLINED'. Today (lines 318-336) it always does sendPushToUser(client_id, ...).
const isRescheduleDecline = booking.reschedule_decline === true;           // new, set only by the two declineReschedule call sites
const recipient = isRescheduleDecline ? booking.notify_user_id : client_id;  // proposer, never the decliner
if (!recipient) { console.warn('[events] reschedule BOOKING_DECLINED: no notify_user_id; skipping push'); break; }
await sendPushToUser(recipient, {
  title: isRescheduleDecline ? 'Reschedule Declined' : 'Booking Declined',
  body:  isRescheduleDecline ? 'Your proposed new time was declined. The original time stands.'
                             : 'Your booking request was declined.',
  category: EVENT_CATEGORY[eventType],
  sub_category: isRescheduleDecline ? 'reschedules' : EVENT_SUBCATEGORY[eventType],  // see Pitfall 6
  target_role: targetRoleFor(booking, recipient),
  deep_link: `clickme://bookings/${booking.id}`,
  data: declinedData,                                  // no free text in data (BACK-02)
});
// injectEventMessage: when booking.reschedule_decline, add event_data.reschedule_decline = true (additive key)
```
Free text stays out of the push `data` map and `in_app_meta` for reschedule declines (the `94d659b` rule: reason travels in chat `event_data` only).

### Pattern 3: One additive chat-event field pair on each client
**What:** iOS `BookingEvent` is a struct with `let` fields and a memberwise init used by `ChatItemMapper`, `ChattingView` previews (lines 435, 457) and `ChatThreadReducerTests.swift:58`. Add the new fields as trailing `var ... = nil` properties (like `serverId`, `createdAt` already are) so no existing call site changes. Map in `ChatItemMapper.bookingEvent(...)` with the existing `extractString(from:key:)`.
**Rendering rule (CONTEXT discretion):** text = `reason_text ?? decline_reason_text` (trim, ignore blank); label by `reason_by` ("Client" / "Expert" wording or the peer's name; you are told which side wrote it, so "You" vs peer name needs the viewer's role, which the mapper does not have, so prefer neutral role labels). For a request decline also reuse `DeclineNote.reasonLine(for:)` for `decline_reason_code` (existing, tested labels). Render as a plain `String` `Text` (never `LocalizedStringKey`/Markdown, never `AttributedString(markdown:)`), `lineLimit` generous. Server caps read this session in `src/schemas/booking.schema.js`: cancel `reason` `.max(500)` (line 123), reschedule-decline `reason` `.max(500)` (line 219), reschedule proposal `note` `.max(500)` (line 104), request-decline `reason_text` `.max(1000)` (line 181); client text is trimmed before the cap on cancel. So a row can carry up to 1000 characters.
**Android equivalent:** `ChatMessageItem.eventData` is already `Map<String, Any?>` (`ChatPayloads.kt:73`), so read `data["reason_text"] as? String` in `ChatMessageMapping.toThreadItem`, add two nullable fields to `ThreadItem.SystemEvent` (constructor currently takes serverId, kind, bookingId, topic, startTime, content, createdAt, `ThreadItem.kt:88-96`; note its `toString` override at line 100 lists fields), render in `subviews/SystemEventRow.kt`, extend `chatEvent(...)` in `testing/ChatFixtures.kt:71-95` with optional `reasonText`, `reasonBy`, `declineReasonText`, and add rows to `ChatMessageMappingTest.kt`.

### Anti-Patterns to Avoid
- **Pushing `master` to `main`.** Even though the runtime delta is small (Summary item 4), D-10 locks it and `master` carries Phase 31/32 documentation and a deleted script. Always push an explicit `<branch>:main` refspec from a branch rooted at `origin/main`.
- **Putting reason text in push `data` or `in_app_meta` for reschedule declines.** `94d659b` and BACK-02 keep free text in chat `event_data` only.
- **Branching client UI on `message` text or on the absence of keys to detect a reschedule decline.** Use the explicit marker; absence is ambiguous (a request decline with no note and a reschedule decline with no note look identical today).
- **Moving a deploy forward on an unverified smoke.** The Stripe Dashboard PaymentIntent state is the money truth, not `payment_status` and not the app (01-17 lesson).
- **Editing `Environments.plist` `Current`.** Stays `Production` (D-19, roadmap note).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| "Will this cherry-pick or merge conflict?" | A scratch worktree or trial merge | `git merge-tree --write-tree --merge-base=<parent> <target> <commit>`; exit 0 = clean | Writes only objects, no refs, no worktree; used this session |
| Decline reason code labels | New strings for chat | `DeclineNote.reasonLine(for:)` (`ClickMe2026/Utils/DeclineNote.swift`) | Existing tested table (`UNAVAILABLE` -> "Not available at that time", etc.) |
| Currency formatting | A second formatter or `NumberFormatter` | `Money.format(minorUnits:currency:)`, `Money.prefix(for:)` | Phase 2 removed every `NumberFormatter` currency site (app-wide count 0); `TopicsSetupTopicCard.cardSymbol` and `TopicEditorViewModel.currencySymbol` are the two remaining parallel `US$` tables |
| Error text for a failed network call | New `errorMessage(for:)` | `Error.userMessage` | Project convention |
| Warning-baseline comparison | Eyeballing Xcode's issue navigator | The normalized `warning:` diff script below | Reproducible and attachable to the release record |
| Money-state verification | Trusting app toasts | Stripe Dashboard PaymentIntent state plus queries Q1/Q2 in `04-DEVICE-UAT-CHECKLIST.md` | Client cancel returns 200 even when the void failed |
| Waiting for a deploy | Fixed sleeps | Poll `/health` until the 7-char commit equals the pushed SHA | `/health` is the deploy oracle (`src/routes/health.js`) |

**Key insight:** every dangerous step in this phase (deploy, money, submission) already has a verification oracle that is independent of the code under test. Plan tasks should name the oracle, not just the action.

## Runtime State Inventory

This is not a rename phase, but two items change values clients already store or display, so the inventory is answered explicitly:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Existing `messages.event_data` rows written before `94d659b` have no `reason_text` / `reason_by` and no reschedule marker; request-decline rows have `decline_reason_*`. `bookings.decline_reason_text` is shared by request and reschedule declines. | None; clients must treat all new keys as optional. No backfill (an old reschedule-decline row stays ambiguous, accepted) |
| Live service config | Railway deploys `main` (evidence: `/health` moved to `ae3ec1a` and `28da165` after pushes). Stripe Dashboard webhook subscription to `payment_method.detached` is user-reported (04-01) | None new; re-confirm `/health` before each push |
| OS-registered state | None | None |
| Secrets / env vars | GitHub Actions secrets for signing and App Store Connect (names in `build.yml`); Environments.plist ships `pk_live` and Agora id | Human must confirm the secrets exist (Pitfall 1) |
| Build artifacts | `ClickMe.xcodeproj` version keys, gitignored `ClickMe2026/Debug/PreviewSecrets.swift`, Xcode-regenerated `Localizable.xcstrings` (uncommitted diff of 173/116 lines in the working tree today) | Commit or revert the catalog churn before cutting `release/1.1`; fix the PreviewSecrets tracking (Pitfall 1) |

## Common Pitfalls

### Pitfall 1: The release build path is untested and currently broken
**What goes wrong:** pushing `release/1.1` triggers `build.yml` and it fails, with no hotfix path and the schedule at risk.
**Why it happens:** (a) `XCODE_PROJECT: ClickMe2026.xcodeproj` points at a file that does not exist (project is `ClickMe.xcodeproj`); (b) `ExportOptions.plist` `teamID` is `XXXXXXXXXX`; (c) `PreviewSecrets.swift` is gitignored but required to compile (verified failure: `cannot find 'PreviewSecrets' in scope`); (d) `manageAppVersionAndBuildNumber` is `true` in `ExportOptions.plist`, so Xcode may rewrite the build number on export and the uploaded build may not be "7"; (e) nothing in the repo shows the workflow ever ran (GitHub `origin/main` is at `13b3d3a`, so it never received the 780 local commits; `gh` is not installed here to list runs); (f) signing and ASC secrets are unverifiable here.
**How to avoid:** Wave 0 tasks: fix the project name in `build.yml` (and `test.yml`, `scripts/run-smoke-tests.sh`), set the real team id, and make `PreviewSecrets` a tracked file whose committed form contains no token (Release already returns `nil`; keep DEBUG tokens out of git, for example read from environment variables in DEBUG only, matching the repo's "test credentials come from environment variables" convention). Re-run the clean-checkout Release build used in this research (command below) until it passes. Do a `workflow_dispatch` dry run on a throwaway branch name (`release/1.1-dryrun` also triggers the workflow, so use `workflow_dispatch` on a non-release branch), and decide with the user, in advance, on the Organizer fallback. Decide whether the build number is "7 as set" or "whatever ASC assigns" and record the actual uploaded number.
**Warning signs:** red run at "Install Swift packages" (wrong project), "No team found" at export, `cannot find 'PreviewSecrets'`, TestFlight showing a build number other than 7.

### Pitfall 2: Stale conflict expectations in the D-17 merge
**What goes wrong:** the executor hunts for conflicts that are not there, or resolves a non-conflict by hand and drops D-12.
**How to avoid:** run `git merge-tree --write-tree --name-only master origin/main` first (exit 0 today). After the real merge, run the three named describe blocks and the full suite before declaring done. Ancestry gates from the todo still apply: `git merge-base --is-ancestor ae3ec1abcd0bbe9a298ed9f2e2a4a3c2c9eaa45d <sha>` and `... 28da165ebe66a973008560f689c469389279c25f <sha>` must both exit 0 for any `master` push.

### Pitfall 3: A plan that deploys the whole of `master`
**What goes wrong:** `git push origin master:main` would be a non-fast-forward (git refuses; do not "fix" with force) and, even rebased, would carry Phase 31/32 docs and the removed script.
**How to avoid:** every deploy command in the plans is `git push origin <ios-line-branch>:main` from a branch created at `origin/main`.

### Pitfall 4: A new push marker that changes build 6 or Android behavior
**What goes wrong:** build 6 reads `data["category"]` first and `event_type` next (PUSH-ROUTING.md "Build 6 behavior"); Android routes on `category` / `sub_category`. A changed `sub_category` or a missing `deep_link` can send a tap to a different screen.
**How to avoid:** keep `data.booking_id` and `data.event_type: 'BOOKING_DECLINED'` unchanged; only recipient, title and body change. If `sub_category` is switched to `reschedules` (Pitfall 6), say so in `docs/ios/PUSH-ROUTING.md` and run the "build 6 + Android" live smoke with one reschedule decline. Never send `category` to iOS tokens (CR-01); `push.js` already enforces it, and its CR-01 test must keep passing.

### Pitfall 5: D-23 test conflict
**What goes wrong:** the example line `Saved cards are not removed by deleting your account.` fails `AccountDeletionCopyTests.noFalseClaims` twice: that test lowercases every string and expects none to contain `removed`, `saved card` or `payment details` (`AccountDeletionCopyTests.swift:46-52`).
**How to avoid:** either pick wording without those substrings, or rewrite the test to carve the new `savedCardsNote` out of exactly the `saved card` rule and keep `removed` and `payment details` forbidden elsewhere, plus add an exact-string assertion for the new line. Copy the final string word for word into Android's `strings_delete_account.xml` (Android's current `delete_account_body` still says "All your data, including ... payment details, will be permanently removed", the false claim iOS removed; the port todo replaces it).

### Pitfall 6: `booking/declines` routes to the read-only summary
**What goes wrong:** a reschedule decline leaves the booking active (status restored to `reschedule_prev_status`, default `confirmed`), but iOS `PushRouter.destination(category:subCategory:bookingId:threadId:)` sends `booking/declines` to `bookingSummary` (read-only; its doc table says "booking/declines, cancellations, expirations, refunds | bookingSummary" and the switch has `case "declines", "cancellations", "expirations", "refunds": return .bookingSummary(bookingId: bookingId)`), not `bookingDetail`.
**How to avoid:** for the reschedule-decline push use `sub_category: 'reschedules'` (routes to `bookingDetail`, and is a valid `EVENT_SUBCATEGORY` value used by `BOOKING_RESCHEDULED`), or keep `declines` and accept the summary screen; this is the planner's decision, but test the chosen route on device in the regression run. Note that the recipient's notification preference for that sub-category then governs the push.

### Pitfall 7: Money rendering drift between iOS and Android after D-24
**What goes wrong:** Android `Money.format` uses `NumberFormat.getCurrencyInstance(locale)`, so symbol placement, grouping (`$1,234,567,890.12` in `MoneyTest.kt:60`) and separators follow the device; iOS `Money` has a fixed prefix table and no grouping (`thousandsSeparator = nil`). D-24 only mandates the symbol table.
**How to avoid:** decide the Android scope up front (Open Question 4). Minimum: override the currency symbol for USD and CAD (and keep ISO-code fallback) while leaving locale placement; full parity would also drop grouping and force prefix placement and change `MoneyTest` rows. There is a second Android money path in `RequestEarnings.kt` (it calls `Money.formatMajor`, so it follows automatically) and the topic editor `TopicPrice.kt` (digits only).

### Pitfall 8: Real-money regression vs sessions that can't be cancelled
**What goes wrong:** the D-04 paid session is joined and captured (a real CAD charge by design), while BACK-07 and BACK-19 checks need bookings that are never joined and are cancelled while still held. Mixing them breaks the check or charges an unintended booking.
**How to avoid:** use separate bookings, following the 01-17/04-14 rules: held-booking checks start 2 to 5 days out, are never joined or rescheduled, and one hold at a time; the regression booking is the only one allowed to capture. The end-of-session query in `04-DEVICE-UAT-CHECKLIST.md` step h is the template.

### Pitfall 9: Warnings baseline is not zero
**What goes wrong:** "no new warnings" is checked against nothing.
**How to avoid:** build the pre-project baseline commit (`a48c664`, the shipped build 6 code, the last code commit before `docs: map existing codebase`) and the release candidate with the same command, normalize and diff. See Code Examples.

## Code Examples

### Clean-checkout Release build (what CI will do, minus signing)
```bash
# Source: run this session; it failed on HEAD with "cannot find 'PreviewSecrets' in scope"
J="$CLAUDE_JOB_DIR/tmp"; mkdir -p "$J/src" "$J/dd" "$J/spm"
git -C /Users/LeonChen/Documents/ClickMe2026 archive HEAD | tar -x -C "$J/src"
cd "$J/src" && xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 \
  -configuration Release -destination generic/platform=iOS CODE_SIGNING_ALLOWED=NO \
  -derivedDataPath "$J/dd" -clonedSourcePackagesDirPath "$J/spm" > "$J/build.log" 2>&1; echo "exit=$?"
# disk: DerivedData ~3.8 GB + packages ~1.5 GB; this Mac has under 8 GB free, clean up between runs
```

### Warnings diff (baseline vs candidate)
```bash
norm() { grep -E 'warning:' "$1" | grep -v 'appintentsmetadataprocessor' \
  | sed -E 's#^.*/(ClickMe2026[^:]*/)#\1#; s/:[0-9]+:[0-9]+:/:/' | sort -u; }
norm base.log > base.txt; norm cand.log > cand.txt
comm -13 base.txt cand.txt     # lines only in the candidate = NEW warnings; must be empty
```
Build `base.log` from `git archive a48c664` and `cand.log` from the release branch, both with the identical command (Release, `generic/platform=iOS`, `CODE_SIGNING_ALLOWED=NO`, a copy of the local `PreviewSecrets.swift` added to each tree if that fix has not landed). Release is the right configuration because it is the archived one; a Debug simulator build also works and is what the per-plan checks used.

### Version bump (D-18)
```bash
# App target only. Lines read this session in ClickMe.xcodeproj/project.pbxproj:
#   445: CURRENT_PROJECT_VERSION = 6;   464: MARKETING_VERSION = 1.0;     (Debug configuration, block starts at 439)
#   486: CURRENT_PROJECT_VERSION = 6;   505: MARKETING_VERSION = 1.0;     (Release configuration, block starts at 480)
# The test targets (1.2.3 / 1.0) at lines 525-579 are NOT changed.
# Verify the bundle id around each edit: PRODUCT_BUNDLE_IDENTIFIER = com.uptrendinvestments.clickmeapp;
```
Info.plist has no `CFBundleShortVersionString` / `CFBundleVersion` keys (grep returned none) and `GENERATE_INFOPLIST_FILE = YES`, so the two build settings are the only source of truth.

### iOS test and build commands (proven in Phase 7 plans)
```bash
# Full unit run (3 files don't compile: LoginTests, AuthSmokeTests, SignupSmokeTests, known blocker in STATE.md)
set -o pipefail; xcodebuild test -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  'EXCLUDED_SOURCE_FILE_NAMES=LoginTests.swift AuthSmokeTests.swift SignupSmokeTests.swift' \
  -only-testing:ClickMe2026Tests 2>&1 | tee /tmp/08-xx.log | tail -30
grep -Eq 'Test run with [1-9][0-9]* tests? in [0-9]+ suites? passed' /tmp/08-xx.log
# One suite: add -only-testing:ClickMe2026Tests/ChatItemMapperTests
# Debug build + warning grep: xcodebuild build -project ClickMe.xcodeproj -scheme ClickMe2026 -configuration Debug \
#   -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' | tee /tmp/08-build.log; grep -q 'BUILD SUCCEEDED' /tmp/08-build.log
# Known flake (not gated): MakeABookingAvailabilityTests "An older load that lands last writes nothing"; rerun once.
```

### Android test command (proven in plans 03-15, 06-09)
```bash
cd /Users/LeonChen/Documents/ClickMe_Android && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
  ./gradlew -Pkotlin.daemon.jvmargs=-Xmx3g :app:testDevDebugUnitTest \
  --tests 'com.uptrendinvestments.clickmeapp.screens.chat.chatting.ChatMessageMappingTest' ktlintCheck 2>&1 | tee /tmp/08-and.log | tail -20
grep -q 'BUILD SUCCESSFUL' /tmp/08-and.log
```
Android has `dev` and `prod` flavors; `prod` always uses the production backend (`app/build.gradle.kts` comment at line 32). The Android repo's local `main` is far ahead of its origin and is **not** pushed in this phase (the Android release is out of scope; one commit per change in that repo).

### Backend commands
```bash
npm test -- --silent                      # 153 suites; baseline on origin/main 28da165: 3809 tests, 3803 pass, 6 fail
npm test -- --silent tests/events.test.js tests/clientBooking.test.js tests/expertBooking.test.js
npm run check-docs && npm run check-openapi-coverage    # doc coverage gates (31-12 summary reports 126/126)
# The 6 failures are tests/services/redis.test.js ("REDIS_URL is not set"); no Redis server is running here.
```

## Phase 3 gaps: exact code and fix shape

### G-03-1-ITEM1C (major): reschedule-decline push goes to the decliner
- **Root cause (VERIFIED):** `events.js` `case 'BOOKING_DECLINED'` (lines 318-336) always calls `sendPushToUser(client_id, ...)` with title `'Booking Declined'` and body `'Your booking request was declined.'`. The two reschedule-decline call sites (`clientBooking.controller.js:774-781`, `expertBooking.controller.js:1128-1135`) pass `{ id, client_id, expert_id, reason_text, reason_by }` and **no `notify_user_id`**. So a client declining the expert's proposal gets the push themselves and the expert gets none; an expert declining a client's proposal sends the push to the client (the proposer), which happens to be the right person but with request-decline wording.
- **Pattern to reuse:** `BOOKING_CANCELLED` (`events.js:338-376`) and `BOOKING_RESCHEDULED` (412-431) route through `booking.notify_user_id`.
- **Fix:** in both call sites add `notify_user_id` (client call site: `booking.expert_id`; expert call site: `booking.client_id`) and a marker; in `dispatchPushForEvent` branch on the marker (Pattern 2). Request declines (`bookingRequests.controller.js`) stay unchanged and keep `decline_reason_code` in `data`.
- **Tests to add (`tests/events.test.js` near the existing `BOOKING_DECLINED decline note (BACK-02)` describe at line 807 and the `action reason` describe at 906; `tests/clientBooking.test.js`, `tests/expertBooking.test.js` for the call-site arguments):** client declines -> push to `expert_id` with `target_role` expert; expert declines -> push to `client_id` with `target_role` client; request decline unchanged (`client_id`, `data` equal to `{ booking_id, event_type }`); no reason text in `data`/`in_app_meta`; no `notify_user_id` -> warn and skip; marker absent from request-decline chat rows and present on reschedule-decline rows.
- **Contract docs:** `openapi/clickme-api.yaml` event_data description around lines 14895-14930 (add the new marker key) and the `docs/ios/PUSH-ROUTING.md` table row for `BOOKING_DECLINED` (currently `client` only).
- **Additivity:** build 6 and Android ignore unknown `event_data` keys; push `data` keeps `booking_id` and `event_type`.

### G-03-1-ITEM1B (major): reasons visible in chat
- **Backend:** done in `94d659b` (adds `reason_text` and `reason_by` `'client'|'expert'` to `BOOKING_CANCELLED`, `BOOKING_RESCHEDULED` and reschedule `BOOKING_DECLINED`). Request declines keep `decline_reason_code` and `decline_reason_text` and have no `reason_by` (always the expert). Existing rows never carry the keys. A reschedule decline with no reason is indistinguishable from a request decline today (the marker above fixes that).
- **iOS:** (1) `ChatItemMapper.bookingEvent(from:content:eventData:)` (lines 71-119) pulls `topic_title`, `start_time`, `duration_mins` and builds `BookingEvent` in each switch case, so extract `reasonText`, `reasonBy`, and the decline code once above the switch and pass into each case (or set after construction, as `chatItem` already does for `serverId` and `createdAt`). (2) `BookingEvent` in `ChatDisplayModels.swift:107-148` gets trailing optional vars. (3) `ChattingSystemEventRow.swift:43-60` renders title, then topic or subtitle; add one more caption line under it. (4) Tests: extend `ChatItemMapperTests.swift` (existing helper `mappedEvent(durationMins:)` builds a `ChatMessageItem`; add a sibling that takes an `eventData` object). Also make the title say "Reschedule Declined" when the marker is present (optional but cheap).
- **Android:** see Pattern 3; one commit in `../ClickMe_Android`.
- **Do not** show expert-private notes: `94d659b` never sends them; no client change is needed for that.

### G-03-1-ITEM1 (minor, ship if cheap): proposal push wording
- **VERIFIED:** `events.js:419-426` `case 'BOOKING_RESCHEDULED'` sends title `'Booking Rescheduled'`, body `'A booking has been rescheduled.'`. The event is dispatched only from the two propose call sites (`clientBooking.controller.js:413`, `expertBooking.controller.js:764`), so a wording change cannot mislabel another flow. Suggested text: title `'Reschedule Requested'`, body `'A new time has been proposed for a booking. Open it to respond.'`. No test or doc in the repo pins the old strings (grep of `tests`, `docs`, `openapi` found none), but the push tests may assert them indirectly; run `tests/events.test.js`. `EVENT_PREVIEW_TEXT.BOOKING_RESCHEDULED` ('Booking rescheduled', chat list preview) is a separate string; iOS/Android row titles also say "Booking Rescheduled" for the proposal. Changing those is optional polish, not required by D-03.

## Folded todos: current behavior, files, fix shape, tests

| Todo | Current behavior (verified) | Fix shape | Files and tests | Decision needed |
|------|-----------------------------|-----------|-----------------|-----------------|
| **merge D-12 into master** | master 17 ahead, 2 behind origin/main (D-12 `ae3ec1a`, CR-02 `28da165`); `git merge-tree` clean | `git merge origin/main` on master (merge commit, no rebase, no force); then run `describe('payment_method.detached (ios-p4 D-12)')` in `tests/webhooks.test.js`, `describe('platform card check (ios-p4 D-12)')` and `describe('transient platform-card error is retried on the next run (ios-p4 CR-02)')` in `tests/cron/longLeadChargeSweep.test.js`, then the full suite | Backend `master` worktree (the main checkout has uncommitted `.planning/STATE.md` and untracked `.planning` files; do the merge in a clean place or stash deliberately) | No. Do it after the iOS-line deploys so the merge includes the cherry-picks (simulated clean) |
| **long-lead sweep transient errors** | `chargeOne` stamps `off_session_attempted_at` (`stampAttempt`, line ~341) before `getOrCreateConnectedCustomer`/`getOrCreateClonedPaymentMethod`/`recheckStillChargeable`/`createManualPI`/`confirmPIOffSession`; non-card errors are re-thrown (comment lines 438-441) leaving a stamped `scheduled` row with no PaymentIntent; `scaRecoveryWindowSweep` cancels it at the 6 h mark | todo Option 1: on an error thrown strictly **before** `createManualPI`, do a guarded stamp reset (`UPDATE ... SET off_session_attempted_at = NULL WHERE id = $1 AND payment_status = 'scheduled' AND payment_intent_id IS NULL AND off_session_attempted_at = <this run's nowIso>`) so the next 5-minute run retries; leave errors after `createManualPI` as today; add a deadline (no reset once start_time is within a chosen margin) so retries can never let a session start uncharged | `src/cron/longLeadChargeSweep.js`, `tests/cron/longLeadChargeSweep.test.js`, `docs/ios/STRIPE-INTEGRATION.md` | **Yes, user decision first** (the todo says so): bounded-retry design and the deadline. Plan a `checkpoint:decision`, then a payment-change deploy checkpoint. Payments on live Stripe: highest-care item in the phase |
| **null topic currency** | `serializeTopic` sends `(topic.price_currency \|\| '').toUpperCase()` (`expertTopics.controller.js:95`), so `""` for no currency | send uppercase code or `null`; update OpenAPI `ExpertOwnedTopic.price.currency` to `[string, null]`, `USD-TOPIC-PRICING.md` §2, three rows in `tests/expertTopics.test.js` next to `describe('serializeTopic price shapes (TOPIC-02)')` | Value change on an existing field, so first re-run the client tolerance gate: iOS build 6 `ExpertTopicItem.Price.currency` is `String?` [VERIFIED: `git show a48c664:ClickMe2026/Model/Responses/Children/ExpertTopicItem.swift` lines 18-23]; current iOS has `TopicsSetupTopicCardLabelTests` and `TopicCurrencyTests` null rows; Android `TopicPriceDto.currency` nullable plus `ResponseDecodingTest.expertDetailsDecodesFreeAndPaidTopics` | Plan 06-17 recorded the user chose skip; CONTEXT now folds it. Treat as optional if the gate or time fails (record why) |
| **profile name validation** | `userProfile.schema.js:36-37` `first_name`/`last_name` are `z.string().min(1).max(100).optional()` with no custom message; signup stores `''` for both | Safe, message-only: hand-written messages (field paths and `VALIDATION_ERROR` unchanged); make OpenAPI match; tests in `errors.test.js` parity and a schema row | `src/schemas/userProfile.schema.js`, `openapi/clickme-api.yaml`, tests | **Yes** for the empty-last-name question (A: accept empty on PATCH). Recommend shipping only the message-only change and recording A/B as deferred, since the new iOS build does not depend on it |
| **D-23 saved cards disclosure** | `AccountDeletionCopy` has 8 strings; used in `DeleteAccountWarningHeader.swift:28-35`; test forbids `saved card` | Add `savedCardsNote` (4th group line on the confirmation step), update the test per Pitfall 5, port to Android | iOS `AccountDeletionCopy.swift`, `DeleteAccountWarningHeader.swift`, `AccountDeletionCopyTests.swift`; Android `strings_delete_account.xml`, `DeleteAccountComponents.kt` | Final wording (user approval) |
| **D-24 US$** | `Money.swift:39` `"USD": "$"`; `TopicsSetupTopicCard.swift:26` `currency == "USD" ? "US$" : Money.prefix(for: currency)`; `TopicEditorViewModel.swift:117-123` `currencySymbol` switch returns `US$`/`CA$` | Change the table to `"USD": "US$"`; delete `cardSymbol(for:)` (it becomes `Money.prefix`) and let `currencySymbol` call `Money.prefix(for:)` (note: for non-USD/CAD codes the editor shows the bare ISO code while `Money.prefix` appends U+00A0, keep the editor's existing `default: return currency`) | Pinned tests to update: `MoneyTests.swift` lines 30-52, 92-93, 101, 122, 133-136, 172-173; `MoneyCallSiteTests.swift` 24-25, 38-39, 46, 55; `ClientProfileBookingCardTests.swift:23`; `ClientProfileHistoryEarningsTests.swift:80`; `TopicsSetupTopicCardLabelTests.swift` (US$ rows already correct); check `grep -rn '"\$' ClickMe2026Tests` again after the change. Preview fixtures with `$250` strings in `TopicsSetupViewModel.swift:237,247`, `TopicEditorView.swift:559`, `ExploreClientView.swift:386-392`, `IncomingRequestsView.swift:182-204` are preview-only server labels, leave | Android scope (Open Question 4) |

### Android parity todos (all in `../ClickMe_Android`, one commit per change, nothing pushed)

| Todo | Files (from the todo, re-check before building) | Notes |
|------|-----------------------------------------------|-------|
| Chat reasons (new) | `ChatMessageMapping.kt`, `ThreadItem.kt`, `SystemEventRow.kt`, `ChatFixtures.kt`, `ChatMessageMappingTest.kt` | Pattern 3 |
| Delete Account copy and 409 blocker alert | `strings_delete_account.xml`, `DeleteAccountViewModel.kt`, `DeleteAccountComponents.kt`, `ErrorCode.kt` | Exact strings and the 5-row blocker table are in the todo; add the D-23 line. `delete_account_body` currently makes the false claim. Severity high in the todo |
| Money `US$`/`CA$` | `util/Money.kt`, `MoneyTest.kt` | D-24; Open Question 4 |
| Phase 6 follow-ups | `AvailabilityScheduleLogic.kt`, `TimeRangePickerSheet.kt`, `RequestDecisionViewModel.kt`, `ProfileHubComponents.kt` | Four compare-and-align items; nothing verified on a device |
| Phase 5 parity check | `screens/signup`, `screens/settings`, `screens/push` | A table of 12 questions, each "check, then align or record"; time-box it |
| Cancellation policy link | `ClientCancellationScreen.kt`, `strings_cancel_booking.xml` | Needs a policy screen (3 cards) if none exists; corrected copy given in the todo |
| Remember login email | branch `feature/remember-login-email` commit `0c9ecc55` | Port by hand onto current main, do not merge the old branch |
| Profile settings empty name | `ProfileSnapshot.kt`, `ClientProfileSettingsViewModel.kt`, `ExpertProfileSettingsViewModel.kt` | Port G-05-6 rules |
| Expert settings clear meeting link | `ExpertProfileSettingsViewModel.kt` (L326-336, L508), `ExpertProfileSettingsRepository.kt` | Send `meeting_url ""`; backend BACK-04 `df7fb18` is already in production |
| Android push prompt after reinstall | `PushPermissionRequester.kt` | A check on a device, "fix if real" |

The "Android release itself is not part of this phase" line in CONTEXT means these are local commits only. Suggest grouping them into 2-3 Android plans (display/copy/money; settings/auth ports; the check-only items) with `testDevDebugUnitTest` and `ktlintCheck` per commit.

## Backend branch state (re-derived 2026-11-19)

| Ref | SHA | Note |
|-----|-----|------|
| `origin/main` (GitHub, and production `/health`) | `28da165ebe66a973008560f689c469389279c25f` | `git ls-remote origin` and `curl /health` agree |
| local `master` | `22b89671efb73579e3133382cf8028d5d6328c9f` | 17 ahead, 2 behind origin/main |
| `origin/master` (remote branch) | `95b5d709dc5538bc1b1367bacc56179bb0e6cd9b` | stale, equals tag `v1.0`; irrelevant, never push to it |
| merge base | `32fa6ecd97a47409c5e7bf4f730b803f7b2fd7e5` | |
| `ios-p4-d12` worktree | `28da165` (= origin/main), clean | path `/Users/LeonChen/Documents/ClickMe2026 Backend D12`, has `node_modules` |
| rollback branches | `ios-p4-d12-rollback` = `32fa6ec`, `ios-p4-cr02-rollback` = `ae3ec1a` | stale for this phase; create new ones per D-16 |
| `wave-3c` | `8407402839945b1f30171687cc91d2c110db0847` | parked (BACK-08/13), do not touch |

**On origin/main, not on master (2):** `28da165` CR-02, `ae3ec1a` D-12. Both must be ancestors of any commit pushed to `main` (they are, trivially, for any branch rooted at `origin/main`).

**On master, not on origin/main (17), by ownership:**

| Commit | Subject | Owner | Deploy in Phase 8? |
|--------|---------|-------|--------------------|
| `94d659b` | feat(quick-261119-miw): carry booking action reasons and notes into the chat event | THIS project (iOS line) | **Yes**, cherry-pick `-x` (clean) |
| `22b8967` | docs(quick-261119-miw) | This project, `.planning/` only | No (docs; stays on master) |
| `35bc749` | fix(faq): align live Help FAQ with real charging, refunds and the Terms (adds `20261113000200_faq_content_match_terms.sql`) | Backend's own | No. Data already applied to production 2026-11-12 per its message |
| `c3c6ebc`, `00c3743`, `6bf45a8` | Phase 32 docs/state/pause | Backend's own | No |
| `d4b897f`, `39eff28`, `d65de73`, `24ff001`, `68d234e`, `c8c8c85` | Phase 31 docs/UAT/review/security | Backend's own | No |
| `4743550` | docs(31-12) | Backend's own | No |
| `61980a5` | chore(31-12): remove unrunnable drain script | Backend's own (deletes `scripts/verify-legacy-drain.js` and its test) | No |
| `d33c222` | feat(31-12): guarded one-way DROP migration for legacy ledger | Backend's own (the migration is **already applied** to prod by `supabase db push`) | **Must NOT deploy** as code from this phase (D-10); file stays off `main` |
| `1d1d8b0`, `50f760a` | docs(31-11) | Backend's own | No |

Cherry-pick verification: `git merge-tree --write-tree --merge-base=94d659b^ origin/main 94d659b` -> exit 0, tree `0cb169775cfbbacd80440e7c115874c05764f798`; 7 files changed (openapi, two controllers, `events.js`, three test files), +432/-13. Full suite on that tree (from a dot-free path): **153 suites, 3843 tests, 3837 passed, 6 failed (redis)**. Simulated later merge: `git merge-tree --write-tree master <commit-with-that-tree-on-origin/main>` -> exit 0.

**D-17 merge today:** `git merge-tree --write-tree --name-only master origin/main` -> exit 0, tree `2740df9afaf127f170f34b7b626166ad784ce2e4`, no conflicted files. The checkout at `/Users/LeonChen/Documents/ClickMe2026 Backend` is on `master` with an uncommitted `.planning/STATE.md` and several untracked `.planning` files, so do the merge deliberately (commit or stash first) and never use `git add -A` there.

## Backend deploy waves (recommended grouping; planner's discretion)

| Wave | Contents | Why separate | Approval |
|------|----------|--------------|----------|
| B1 | cherry-pick `94d659b` + ITEM1C marker/recipient + ITEM1 wording (all `events.js` and two call sites) | One surface, one test set, additive; satisfies D-03 | one D-14 approval |
| B2 | long-lead sweep bounded retry (after the decision checkpoint) | Money path on live Stripe; keep isolated for rollback clarity | one D-14 approval, extra care |
| B3 (optional) | null topic currency, profile-name messages | Contract hygiene; needs the client tolerance gate for the currency value change | one D-14 approval, or drop with a recorded reason |
| after B* | `git merge origin/main` into `master` (D-17), full suite, three describe blocks | Not a deploy | none (local) |

Each wave: record `/health`, create `ios-p8-<wave>-rollback` at that SHA, run the full suite, **stop for approval**, push `<branch>:main`, poll `/health`, run the D-13 smoke on build 6 and the current Android build (login, bookings, chat, plus the touched path: for B1 trigger one reschedule propose and one reschedule decline and confirm the recipient and the chat row on both apps), then freeze. The backend freezes after the last wave and before the TestFlight regression (D-12).

## Release mechanics

### Trigger and steps (VERIFIED: `.github/workflows/build.yml`)
`on: workflow_dispatch` and `push: branches: 'release/**'`; `concurrency` cancels in-progress runs for the same ref. Jobs on `macos-26`: checkout, `maxim-lobanov/setup-xcode@v1` Xcode 26, trust plugins, SPM cache and `xcodebuild ... -resolvePackageDependencies`, install signing certificate (`./.github/actions/code-signing-setup`, base64 p12 into a temporary keychain), write the App Store Connect API key from a secret, `xcodebuild clean archive` (`-destination generic/platform=iOS -allowProvisioningUpdates` with the API key), `xcodebuild -exportArchive` with `ExportOptions.plist` (`method app-store`, `destination upload`, `signingStyle automatic`, `uploadSymbols true`, `testFlightInternalTestingOnly false`, `manageAppVersionAndBuildNumber true`), then upload the archive as a build artifact. Secrets referenced: `BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`, `KEYCHAIN_PASSWORD`, `APP_STORE_CONNECT_API_KEY_BASE64`, `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_KEY_ISSUER_ID`. Whether they are set in GitHub cannot be checked here (`gh` is not installed, and `gh secret list` needs auth). `ci_scripts/ci_post_clone.sh` only writes two Xcode defaults and is unrelated to GitHub Actions.

### Version keys (D-18) and baseline commit
See Code Examples. Baseline commit for D-19 is `a48c664` (2026-11-07, "Build 6 release config"), the shipped App Store 1.0 (6) code. Version 1.0 build 6 is on the App Store, so 1.1 / 7 satisfies "higher than last upload".

### Warnings: measured state
Measured this session with the identical command on both trees (`xcodebuild build -configuration Release -destination generic/platform=iOS CODE_SIGNING_ALLOWED=NO`, local `PreviewSecrets.swift` copied into each `git archive`), warnings normalized as in Code Examples:

| Tree | Result | Unique app warnings |
|------|--------|---------------------|
| `a48c664` (shipped build 6 code) | BUILD SUCCEEDED | 4 |
| HEAD `bc42d01` | BUILD SUCCEEDED | 5 |

The 4 shared warnings: `NetworkService.swift:168` ("no 'async' operations occur within 'await' expression"); `MakeABookingStripePaymentSheet.swift:202` (deprecated `handleNextAction(forPayment:with:returnURL:completion:)`, renamed to `handleNextAction(paymentIntentClientSecret:...)`); `ProfileAvatarSection.swift:64-69` (main actor-isolated `brandGreen` and `onPrimary` referenced from a nonisolated context, 3 lines, 2 unique after normalization).

**One new warning since the baseline, which D-19 forbids shipping:** `ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift:282` "result of call to 'withAnimation' is unused". Cause (read): the preview-row branch of `removeFavorite` (lines 279-286) wraps `list.remove(key: expert.pagingKey)` in `withAnimation`, and `PagedList.remove(key:)` (`ClickMe2026/Utils/PagedList.swift:101`, `mutating func remove(key target: Key) -> (index: Int, item: Item)?`, no `@discardableResult`) now returns a value, so the closure result leaks out. One-line fix: `_ = list.remove(key: expert.pagingKey)` inside the closure. Which commit introduced it was not bisected (Phase 4 commits `753da57` WR-11, `151d8ab` WR-13 and `3f877d4` IN-15 touched `PagedList.swift` or this view model). The baseline is therefore **not** zero, and the plan should include this fix before the final comparison. Per-plan baselines in Phases 2 to 7 only covered touched files, which is how this slipped through. After D-24, Money and chat changes, re-run the full comparison once on the release candidate.

### Release branch hygiene
- `git status` today shows an uncommitted `ClickMe2026/Localizable.xcstrings` diff (Xcode regeneration) and `.planning` edits; commit or discard on purpose before branching. The release branch should be cut from committed `main`.
- Pushing `release/1.1` uploads 780 commits that GitHub has never seen (project history, `.planning/`, `GoogleService-Info.plist`, `Environments.plist` with the `pk_live` publishable key). `git grep` of HEAD for `sk_live|sk_test|whsec_` finds nothing; `eyJhbGciOi` appears only in `ClickMe2026Tests/Fixtures/Auth/login_success.json` and `ClickMe2026Tests/Network/Auth/LoginTests.swift` (test fixtures). Confirm the GitHub repo is private and that this is acceptable before the first push (Open Question 5).
- `.github/workflows/test.yml` runs on PRs to `main` only; it is not part of the release path.
- `config.json` has `git.create_tag: true`; the tag name and whether `main` is merged from `release/1.1` is the planner's call.

### Human-only steps (make each a `checkpoint:human-action` or `checkpoint:decision`)
1. **Backend deploy approvals** (D-14), one per wave. HUMAN approval, Claude pushes.
2. **GitHub Actions secrets exist and the repo is acceptable to publish** (before the first push).
3. **Run the TestFlight regression** (D-04) on a real iPhone with an Android peer; query results from Supabase and Stripe Dashboard readings are the user's (the 04-14 checklist says Claude does not run the SQL).
4. **App Store Connect**: select build 7 for version 1.1, paste "What's New" (Claude drafts, user approves, D-22), review the metadata checklist (`APP_STORE_REVIEW_CHECKLIST.md` sections 2, 3, 5, 6), confirm release option "Automatically release this version" vs manual (D-21 says release to everyone immediately), submit for review, then release. All of this is outside the repo.
5. **Export compliance / privacy**: `ITSAppUsesNonExemptEncryption = false` is already in Info.plist; if new data types are collected the ASC privacy questionnaire must match `PrivacyInfo.xcprivacy` (no new collection in this project, but confirm).
6. Reviewer notes in `APP_STORE_REVIEW_CHECKLIST.md` (last updated 2026-10-17) tell the reviewer to use Stripe test card `4242 4242 4242 4242`, while the app and backend run live Stripe since 2026-10-17. Version 1.0 passed review, so reuse its actual notes from App Store Connect rather than this stale text (Open Question 6).

## Verification closeouts

### D-05: Phase 3 and Phase 4 verification
- `03-VERIFICATION.md` frontmatter: `status: human_needed`, `verified: 2026-11-11T21:10:00Z`, `score: 7/18` and a `covered_digest` fingerprint of its covered source files; stale because source files changed afterwards (WR-01/WR-02 fixes, ITEM1B display, D-24 and D-23 will change more). Regenerate **after** the Phase 8 iOS code lands, not before, or it goes stale again: `/gsd-execute-phase 03` resumes at the verification gates; same for Phase 4 (`04-VERIFICATION.md`, `status: human_needed`, `score: 17/21`, `behavior_unverified: 2`, advisory WR-06/WR-07 and Explore WR-01..03). Under D-01 the 11 UI-SPEC backstop truths (Phase 3) and the `behavior_unverified_items` (Phase 4) become "not run on device; covered by unit tests plus regression".
- `03-UAT.md` frontmatter `status: partial`; tests 1 (issue), 2 (blocked), 5 (blocked, BACK-19 smoke) need resolution notes; gaps `G-03-1-ITEM1`, `ITEM1B`, `ITEM1C` get `status: resolved` with `resolved_by` plans. `04-UAT.md` is `status: partial` (3 passed, 20 skipped, 1 blocked: test 2 WR-01 3DS blocked by third-party; the `G-04-3` gap is resolved by 04-17).
- Review dispositions: Phase 3 has `open: 6` (all `severity: info`, ids starting at IN-01), Phase 6 has `open: 1` (IN-08), Phase 4 `open: 0`, Phase 7 `open: 0` (all read from the `*-REVIEW-DISPOSITION.md` frontmatter this session). None is major, so D-03 does not require them. Record them as deferred in the release record.

### REQUIREMENTS.md rows to change (VERIFIED by grep)
- **Checkbox `[ ]` today (25):** BOOK-01..05, BOOK-19, PAY-01..04, EXPL-01..07 (Phase 4 rows; trace table says "Gaps Found" except EXPL-03/07 "Pending"), BACK-06, BACK-07, BACK-08, BACK-13, BACK-15, BACK-19, REL-01, REL-02.
- BACK-06, BACK-07, BACK-19: tick and remove the "Pending on purpose" note only after the D-06 evidence (Open Question 2 for BACK-19's captured branch). BACK-15: tick on mock/unit evidence per D-08 with the reason. BACK-08 and BACK-13: leave unticked, add the deferral reason under REL-02 (D-07; the BACK-13 reason is already there). REL-01: reword per D-01/D-02 and tick after the regression. REL-02: tick after submission. Trace table rows 192-223 and 273-288 must change in step.
- ROADMAP.md Phase 8 success criterion 1 text is amended by D-01 (and the Phase 8 "Plans: TBD" line, the progress table row, and the unchecked backlog items 999.1-999.5 each get a disposition).

### Phase 1 smoke checklists (D-06 sources)
- Canonical live text: `.planning/phases/04-booking-payment-and-discovery/04-DEVICE-UAT-CHECKLIST.md` section "D-11 real-money session" (lines 335-552): setup, queries Q1/Q2, stop conditions S-A..S-E, steps a-h. Results so far: a, b, d, f, h PASS (2026-11-12); c, e SKIPPED; **g DEFERRED**: 01-17 steps 2, 5, 7, 9 (lone-card default, in-use block, Settings removal, default after removal) and 01-19 (expert accept and expert cancel releasing a live hold) have no live result.
- Original texts: `.planning/phases/01-backend-fixes/01-17-SUMMARY.md` (Task 2 part B, steps 1-9, S1-S5) and `01-19-SUMMARY.md` (Task 2 part B, level table, steps 1-5, S1-S5). Their rollback SHAs are stale (production is past `ddfe5bf` and `d356fdc`); the rule in 04-14 is "stop and tell Claude" instead of rolling back to an old SHA.

### Carried-over device items beyond D-01 (need a disposition in the release record)
| Item | Source | D-01/D-02 coverage |
|------|--------|--------------------|
| Phase 3 items 7-24, Phase 4 items 3-22 | 03/04 checklists | Covered by D-01 |
| VoiceOver steps (Phase 3 items 4, 11, 21; Phase 7 backlog 999.5) | D-02 | Dropped, record as untested |
| iOS 26 Liquid Glass readability checks (Phase 6 items 13 and 16) | ROADMAP backlog 999.4, 06-UAT.md, "before Phase 8" | **Not covered**: decide run, fold, or defer with reason |
| Phase 5 deferred items 24 (SIGN-02 resume keeps verified email) and 45 (U4 flash), need a fresh unpublished expert signup | STATE.md, 05-UAT.md "Deferred Follow-Ups" | **Not covered** |
| Phase 2: one full overtime call with an Android peer (does Android tear down on `call.ended` after an iPhone auto-end at end+60?) | STATE.md blocker, 02-UAT.md | Folds naturally into the D-04 "run past the scheduled end" step if the user waits to end+60; otherwise **not covered** |
| Phase 4 D-13 suspension alert on cold launch (needs a suspended account) | WINDOWS.md #28, 04-UAT test 17 | Covered by D-01 (skipped Phase 4 test) |
| Phase 4 item 20 Android push prompt after reinstall | 04-UAT test 23, todo | Android check, part of the Android todos |

## Regression run layout (Claude's discretion; recommended)

Use three sessions on build 7 (internal TestFlight), client **A** (iPhone) and expert **B** (Android peer), against production:
1. **S1 paid in-app voice (the real CAD charge):** pick B's cheapest paid CAD topic with cents and the shortest duration; book a slot that starts soon; pay with the saved card; expert accepts; both join; run past the scheduled end (CALL-01: end + 55 notice, auto-end at end + 60 on the iPhone); finish; then verify with Q1 and the Stripe Dashboard that exactly one capture happened and nothing is stranded. The 55-minute wait after end is optional; decide up front (Open Question 3).
2. **S2 free in-app voice:** same path, no money.
3. **S3 Skype/Zoom:** link provider label, "Open in {provider}", End Session tap, end + 55 banner on that layout.
4. **Side bookings for D-06 (held, never joined, 2 to 5 days out, one hold at a time, each cancelled and proven released in Stripe):** BACK-06 (remove all cards, add exactly one, it is the default: 01-17 steps), BACK-07 (read `connected_pm_clones` first, delete the card from Settings, confirm the clone is detached and not chargeable; the in-sheet removal path (D-12) already passed on 2026-11-12), BACK-19 hold-release (expert accepts then cancels a held booking: 01-19 steps 1-4). Captured-refund: Open Question 2.
5. **Chat reasons:** one cancel with a reason, one reschedule propose with a note, one reschedule decline with a reason, one request decline with a note: confirm each row on iPhone and Android, and the reschedule-decline push reaches the proposer.
6. End-state query and Dashboard check (step h template): no hold or charge remains except the S1 capture.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Pushing `master` to `main` | iOS-only fast-forward line from `origin/main` | D-12/CR-02 (2026-11-12) | All Phase 8 backend deploys follow it |
| Per-file empty warning baselines | Whole-build normalized diff vs shipped code | this phase | Required because HEAD has pre-existing warnings |
| `$` for USD in `Money` | `US$` (backend doc §0 item 5, topic editor, topic card) | D-24 | Removes the editor/card vs everywhere-else inconsistency |

**Deprecated/outdated:** `.github/workflows/*.yml` and `scripts/run-smoke-tests.sh` still say `ClickMe2026.xcodeproj` (renamed to `ClickMe.xcodeproj`); `ExportOptions.plist` placeholder team id; the backend todo's "expected conflicts" for D-17; `APP_STORE_REVIEW_CHECKLIST.md` test-card note.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Railway deploys on any push to `origin/main` and `/health` reports the new commit within a few minutes | Backend deploy waves | Poll loop never ends; add a timeout and check the Railway dashboard (evidence: prior pushes moved `/health`) |
| A2 | `supabase db push` from a checkout lacking `20261113000100_*` and `20261113000200_*` fails with "remote migration versions not found locally" | Summary item 4 | If wrong, no harm: the advice (push migrations from `master` after the merge) is merely conservative |
| A3 | `#Preview` bodies are compiled in Release (so the missing `PreviewSecrets` breaks the archive) | Pitfall 1 | Verified empirically by the failed Release build, so effectively confirmed for this repo/Xcode (26.5) |
| A4 | `manageAppVersionAndBuildNumber = true` can change the uploaded build number | Pitfall 1 | If Xcode keeps 7, harmless; record the actual number either way |
| A5 | GitHub secrets for signing and ASC API exist and the p12 is a valid Apple Distribution certificate | Release mechanics | CI fails at the signing step; mitigated by the dry run and Organizer fallback |
| A6 | The marker name `reschedule_decline` and the recipient wording are free design choices | Pattern 2 | None; any additive name works if documented in OpenAPI |
| A7 | Using `sub_category: 'reschedules'` for the reschedule-decline push is acceptable under users' notification preferences | Pitfall 6 | A user with reschedule pushes off won't be notified of a decline; planner may keep `declines` and accept the summary route |
| A8 | The 55 + 5 minute overtime wait is optional for the regression | Regression layout | If the user wants the Android `call.ended` observation (Phase 2 follow-up) the S1 session runs about 90 minutes |
| A9 | GitHub repo `mercforhire/ClickMe2026` is private | Release branch hygiene | If public, pushing 780 commits publishes planning docs and config; confirm before pushing |

## Open Questions (RESOLVED)

1. **Does the CI build get fixed, or does the build ship via Xcode Organizer?** What we know: three verified blockers (project name, team id, PreviewSecrets) plus unverifiable secrets and 780 unpublished commits. D-19 says CI. Recommendation: plan the fixes and a `workflow_dispatch` dry run as Wave 0; add a user checkpoint "CI green on the dry run, or approve the Organizer fallback" before the release branch is cut. **RESOLVED: D-25.**
2. **BACK-19's captured-refund branch.** What we know: 01-19 states a device cannot force it; D-06 asks for it. Recommendation: ask the user to accept hold-release evidence plus mocked captured-refund tests (as D-08 does for BACK-15), or define a T-24h charged booking that the expert cancels before start (possible only with a long-lead booking that has crossed T-24h, which the sweep must have charged). **RESOLVED: D-27.**
3. **Which carried-over device items are run, folded or deferred?** The Phase 6 glass checks, Phase 5 items 24/45, the Phase 2 Android overtime observation (see the table). Recommendation: a single `checkpoint:decision` listing them with a proposed disposition each, recorded in the release record. **RESOLVED: D-28.**
4. **Android `Money.kt` scope for D-24.** Symbol override only (keeps locale placement and grouping) or full iOS parity (prefix, no grouping). Recommendation: symbol override for USD and CAD via `DecimalFormatSymbols`, keep everything else, and update the six `Locale.US` rows in `MoneyTest.kt` (lines 15, 20, 40, 60, 67, 82); log full parity as a follow-up unless the user wants it. **RESOLVED: D-32.**
5. **Is publishing the repo history to GitHub acceptable?** Confirm visibility and secrets before the first push of `release/1.1`. **RESOLVED: D-26.**
6. **App Review notes** for 1.1: reuse the notes that passed for 1.0; the checklist's Stripe test-card instructions look stale. **RESOLVED: plan 08-23 (App Review notes at the submission checkpoint).**
7. **Long-lead sweep design and deadline** (needs the user before any code): bound and margin for the retry, and whether a persistent profiles/platform-card error needs the same deadline (todo Option 3). **RESOLVED: D-29.**
8. **Profile name rule:** message-only change now, or also accept an empty `last_name`. **RESOLVED: D-30.**
9. **Reschedule-decline push `sub_category`:** `declines` (summary) or `reschedules` (detail). **RESOLVED: D-31.**

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode 26 + iOS simulators | iOS build and tests | yes | Xcode 26.5; iPhone 17 simulator present (two `iPhone 17` entries across iOS 26.x runtimes) | - |
| Node and npm | backend tests | yes | node v26.8.1 on PATH (repo needs >=22) | - |
| Redis server | 6 `redis.test.js` tests | no | `redis-cli` only | Accept the 6 known failures (D-13) |
| Android Studio JBR + Gradle wrapper | Android tests | yes | JBR path exists | - |
| `supabase` CLI | migrations (if any, D-15) | yes | nvm node 24 | - |
| `railway` CLI | optional rollback aid | yes | - | Railway web dashboard |
| `gh` CLI | GitHub secret/run checks | no | - | GitHub web UI (human) |
| `swiftlint` | local lint | no | - | CI only; style by hand, `swiftformat` is present |
| Network to production `/health` | deploy oracle | yes | returned `28da165` | - |
| Disk space | iOS builds | tight | about 8 GB free of 460 GB; a Release build uses about 5 GB (DerivedData 3.8 GB + packages 1.5 GB) | Delete derived data between builds |
| GitHub Actions secrets, Apple team and ASC access | CI upload | unknown | - | Xcode Organizer from the user's Mac |

**Missing dependencies with no fallback:** none, but the unknown signing/ASC access is a blocker for any build path until the user confirms it.
**Missing dependencies with fallback:** Redis (accepted failures), `gh` (human checks), local swiftlint.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (iOS, `ClickMe2026Tests/`), jest (backend, `tests/`), JUnit/ktlint (Android) |
| Config file | `ClickMe2026/AllTests.xctestplan`; `jest.config.js`; Android Gradle |
| Quick run command | iOS: `... -only-testing:ClickMe2026Tests/<Suite>` (see Code Examples); backend: `npm test -- --silent tests/events.test.js tests/clientBooking.test.js tests/expertBooking.test.js`; Android: `:app:testDevDebugUnitTest --tests '<FQCN>' ktlintCheck` |
| Full suite command | iOS full command above; backend `npm test -- --silent` (expect only `redis.test.js` red); Android `:app:testDevDebugUnitTest ktlintCheck` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-02 / G-03-1-ITEM1C | reschedule decline pushes the proposer with correct role and wording; request decline unchanged | backend unit | `npm test -- --silent tests/events.test.js tests/clientBooking.test.js tests/expertBooking.test.js` | rows to add (files exist) |
| REL-02 / G-03-1-ITEM1B (backend) | `reason_text`/`reason_by` in chat event | backend unit | same | yes, from `94d659b` (+34 tests on the cherry-picked tree) |
| REL-02 / G-03-1-ITEM1B (iOS) | mapper reads `reason_text ?? decline_reason_text`, label by `reason_by`, blank ignored, marker | iOS unit | `-only-testing:ClickMe2026Tests/ChatItemMapperTests` | file exists; new rows |
| REL-02 / G-03-1-ITEM1B (Android) | `toThreadItem` carries the fields | Android unit | `--tests '...ChatMessageMappingTest'` | file exists; new rows |
| REL-02 / D-23 | Delete Account note exact string and test carve-out | iOS unit | `-only-testing:ClickMe2026Tests/AccountDeletionCopyTests` | exists; rewrite one test |
| REL-02 / D-24 | `US$` everywhere | iOS unit | `-only-testing:ClickMe2026Tests/MoneyTests` plus `MoneyCallSiteTests`, `ClientProfileBookingCardTests`, `ClientProfileHistoryEarningsTests`, `TopicsSetupTopicCardLabelTests`, `TopicCurrencyTests` | exist; pins change |
| REL-02 / long-lead retry | transient pre-PaymentIntent error leaves the row unstamped; post-PI errors unchanged; deadline honored | backend unit | `npm test -- --silent tests/cron/longLeadChargeSweep.test.js` | exists; new rows |
| REL-02 / D-17 | D-12 and CR-02 describe blocks pass on merged master | backend | full suite plus the three named describes | exist on `origin/main` |
| REL-02 / D-19 | clean checkout builds in Release, no new warnings | build | clean-checkout command + warnings diff | **Wave 0** (script not in repo) |
| REL-02 / D-18 | pbxproj app target is 1.1 / 7 | shell grep | `grep -c 'MARKETING_VERSION = 1.1;' ClickMe.xcodeproj/project.pbxproj` expect 2; `CURRENT_PROJECT_VERSION = 7;` expect 2 | n/a |
| REL-01 | regression run: book, pay, join, past end, finish; D-06 checks | manual device | checklist artifact, signed off by user | **Wave 0** (checklist file to write) |
| REL-01 | closeouts consistent | doc check | grep REQUIREMENTS/ROADMAP rows after edit; `03-VERIFICATION`/`04-VERIFICATION` status | n/a |

### Sampling Rate
- **Per task commit:** the quick command for the touched repo (suite named in the task).
- **Per wave merge:** full backend suite for B-waves; full iOS unit run plus Debug build and warnings grep for iOS waves; Android full unit + ktlint for Android waves.
- **Phase gate:** full iOS run green, clean-checkout Release build green with an empty new-warnings diff, backend suite at the 6-known-failures baseline, `/health` equals the last pushed SHA, regression checklist signed off, before submission.

### Wave 0 Gaps
- [ ] Fix `FavoritesViewModel.swift:282` (`_ = list.remove(key:)`) so the warnings diff is empty.
- [ ] Make the clean checkout compile (tracked `PreviewSecrets` without tokens) and fix `XCODE_PROJECT`, `teamID`; add `scripts/release-build-check.sh` (clean-checkout Release build + normalized warnings diff vs `a48c664`).
- [ ] `08-REGRESSION-CHECKLIST.md` combining S1-S3, the D-06 side checks, the chat-reason checks and the carried-over item dispositions.
- [ ] Release record `08-RELEASE-RECORD.md`: not-run-on-device list (D-01), VoiceOver removals (D-02), BACK-08/13 deferral (D-07), BACK-15 reason (D-08), deferred review infos, warnings diff, deploy SHAs and rollback branches.
- [ ] New test rows: `ChatItemMapperTests` (reasons), backend events/call-site rows, `ChatMessageMappingTest`, Money and AccountDeletionCopy rewrites.

## Security Domain

`security_enforcement` is enabled (ASVS level 1, block on high).

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no change | existing JWT/refresh; do not touch |
| V3 Session Management | no change | existing |
| V4 Access Control | yes | Reason text and the new push go only to the two booking parties: recipient chosen from booking ids on the server (`notify_user_id`), never from client input; `targetRoleFor` for the role hint |
| V5 Input Validation | yes | Reason and note text is user-supplied: backend already trims and caps; clients render as plain `String` text (no Markdown, no HTML, no deep-link parsing) |
| V6 Cryptography | no change | none hand-rolled; signing uses Apple tooling |
| V8 Data Protection | yes | Free text never in FCM/APNs `data` or `in_app_meta` for reschedule declines (BACK-02, `94d659b`); do not log reason text |
| V14 Configuration | yes | No secrets in the repo: the `PreviewSecrets` fix must not commit tokens; CI secrets stay in GitHub; `Environments.plist` publishable keys only; no `--force`; migrations additive only (D-15) |

### Known Threat Patterns for this stack
| Pattern | STRIPE category | Standard Mitigation |
|---------|-----------------|---------------------|
| Deploying the wrong commit (master with the Phase 31/32 delta) to production | Tampering / Elevation | Explicit `<branch>:main` refspec from `origin/main`; ancestry gates for `ae3ec1a` and `28da165`; user approval per push (D-14) |
| Force-push over production `main` | Tampering | Never `--force`; git rejects non-fast-forward by default |
| Committing the real preview JWTs while "fixing" the build | Information disclosure | Tracked file contains no tokens; real tokens stay local or in environment variables; re-run `git grep eyJhbGciOi` |
| Reason text injected into push payloads or rendered as Markdown/links | Spoofing / Tampering | Chat `event_data` only; plain-text render |
| Real-money regression leaving holds or charges | Repudiation / Denial | Stop conditions S-A..S-E, one hold at a time, Stripe Dashboard truth, end-state query |
| Signing material leaking in CI logs or artifacts | Information disclosure | The existing composite action writes the p12 to `$RUNNER_TEMP`; never echo secrets; artifact upload contains the archive only |
| Pushing 780 commits of project history to a public repo | Information disclosure | Confirm repo visibility first (Open Question 5) |

## Sources

### Primary (HIGH confidence, verified this session)
- Local repos read and executed: `/Users/LeonChen/Documents/ClickMe2026` (iOS), `/Users/LeonChen/Documents/ClickMe2026 Backend` (and the `Backend D12` worktree), `/Users/LeonChen/Documents/ClickMe_Android`.
- `git ls-remote origin` (backend) and `curl https://clickme-backend-production.up.railway.app/health` -> `{"status":"success","commit":"28da165"}`.
- `git merge-tree --write-tree` runs (cherry-pick and merge), full jest runs on `origin/main` and on the cherry-picked tree, `xcodebuild` Release run on a clean `git archive HEAD` (failed on `PreviewSecrets`).
- `.planning/` artifacts: 08-CONTEXT, STATE, REQUIREMENTS, ROADMAP, 03/04 UAT, VERIFICATION and checklists, 01-17/01-19 summaries, the 16 pending todos.

### Secondary (MEDIUM confidence)
- Supabase CLI behavior on missing local migration files (A2) from prior knowledge of the tool; not run.

### Tertiary (LOW confidence)
- None used as a basis for a recommendation beyond the Assumptions Log.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new dependencies; tools probed.
- Architecture / deploy flow: HIGH - branch state, merge simulations and test runs done this session.
- Pitfalls: HIGH for CI blockers (reproduced), MEDIUM for signing/secrets (not inspectable), MEDIUM for Android money scope (design choice).
- Requirements closeout: HIGH (read the rows), MEDIUM on what the user will accept for BACK-19.

**Research date:** 2026-11-19
**Valid until:** about 2026-11-26 for backend refs (`origin/main`, `master`, `/health` move); the release-tooling findings stay valid until the files change. Re-run `git ls-remote origin`, `git merge-tree` and `curl /health` immediately before each deploy.
