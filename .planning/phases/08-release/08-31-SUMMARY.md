---
phase: 08-release
plan: "31"
subsystem: android-parity
tags: [android, kotlin, compose, profile-hub, online-dot, parity, todo-close-out, tdd]

requires:
  - phase: 08
    provides: "Plan 08-26: the user's Android parity port request P2 (the client Profile hub online dot)"
  - phase: 06
    provides: "iOS 06-06 (U2): the client hub keeps its online dot, the expert hub loses its hard-coded one"
  - phase: 08
    provides: "Plans 08-27 to 08-30: the other five ports (P5, P6, P3/P4, P1) whose Android SHAs this plan cites"
provides:
  - "Android ProfileHubUserCard(showOnlineDot = false by default) and PROFILE_HUB_ONLINE_DOT_TAG; ClientProfileHomeContent turns it on, the expert hub passes nothing"
  - "Both Android parity todos closed in .planning/todos/completed/ with a Resolution and every requested port line reading ported (<Android SHAs>)"
  - "The consolidated (P1) to (P6) Android device-check list for plan 08-15"
affects: [08-15, 08-24, android-release]

# Actuals (#2632) - same estimateTokens scale (chars/4 over the realized diff)
actuals:
  tokens: 2324
  tasks: 2
  commits: 1

# commits is measured in the Android repo, where this plan's one code commit lives:
# git -C /Users/LeonChen/Documents/ClickMe_Android rev-list --count da7002ce..HEAD
# (the one iOS docs commit for the todos is a05d09f; nothing in the iOS repo is production code)
commits: 1
plan_head_before: da7002ce5e9ad4327950642cc292d7c69c2bbf83
plan_head_after: fa9057add36ba19ad5d773c6c8bf59bbb9840df8

tech-stack:
  added: []
  patterns:
    - "A decorative status mark on a shared card is an opt-in parameter (default off) so only the screen that needs it turns it on, and it carries no semantics so the card's merged spoken label is unchanged"

key-files:
  created: []
  modified:
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/clientmode/profile/subviews/ProfileHubComponents.kt"
    - "../ClickMe_Android/app/src/main/java/com/uptrendinvestments/clickmeapp/screens/clientmode/profile/ClientProfileHomeScreen.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/clientmode/profile/ClientProfileHomeScreenTest.kt"
    - "../ClickMe_Android/app/src/test/java/com/uptrendinvestments/clickmeapp/screens/expertmode/profile/ExpertProfileHomeScreenTest.kt"
    - ".planning/todos/completed/2026-11-16-android-phase-6-parity-follow-ups.md (moved from pending/)"
    - ".planning/todos/completed/2026-11-13-android-phase-5-parity-check.md (moved from pending/)"

key-decisions:
  - "The dot is static and unconditional, as on iOS (isOnline = true at init, never changed): no presence plumbing and no backend field"
  - "The dot is a sibling Box over the avatar, drawn with no semantics of its own, so the merged label stays {name}, {email}, Edit profile"
  - "The iOS avatar's own 2 pt green ring is not part of the P2 row and was not added (plan assumption)"

patterns-established:
  - "Close a parity todo by rewriting only its port decision lines to ported (<SHAs>), appending a Resolution, and proving with a script that no other line moved from the pre-port version"

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "The Android client Profile hub shows a green online dot at the avatar's bottom-right, also for the no-name fallback card, as the iOS client hub does"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../clientmode/profile/ClientProfileHomeScreenTest.kt#userCardShowsTheOnlineDot"
        status: pass
      - kind: unit
        ref: "app/src/test/.../clientmode/profile/ClientProfileHomeScreenTest.kt#userCardFallbackStillShowsTheOnlineDot"
        status: pass
    human_judgment: false
  - id: D2
    description: "The Android expert Profile hub shows no dot, and the card's merged spoken label is unchanged"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "app/src/test/.../expertmode/profile/ExpertProfileHomeScreenTest.kt#expertHubShowsNoOnlineDot"
        status: pass
      - kind: unit
        ref: "app/src/test/.../clientmode/profile/ClientProfileHomeScreenTest.kt#userCardWithEmailSpeaksNameEmailAndAction"
        status: pass
    human_judgment: false
  - id: D3
    description: "Both parity todos are in completed/ with a Resolution, every requested port line reads ported with an ancestor-of-main SHA, and no other line differs from the bf6aa99 version"
    requirement: REL-02
    verification:
      - kind: other
        ref: "bash /tmp/08-31-check.sh (the plan's Task 2 close-out verify split into steps) prints OK for both todos and ALL_OK"
        status: pass
    human_judgment: false
  - id: D4
    description: "On a real Android device the dot looks right (green, ringed, bottom-right of the avatar) and each of the six ports behaves as on iOS"
    verification: []
    human_judgment: true
    rationale: "Robolectric proves the dot exists and where it is turned on; only a device shows how it looks and, for P1 and P3 to P6, the behavior against the live backend. The six items in the device-check section below cover it."

duration: 6min
completed: 2026-11-20
status: complete
---

# Phase 8 Plan 31: Android Client Hub Online Dot (P2), Then Close Both Parity Todos Summary

**The Android client Profile hub now shows the iOS-style green online dot (14 dp primary circle, 2 dp card-coloured ring, bottom-right of the avatar) while the expert hub shows none, and with all six ports landed (P1 to P6) both Android parity todos are closed with their Android SHAs.**

## Performance

- **Duration:** about 6 min (start 2026-11-20T06:39:14Z)
- **Completed:** 2026-11-20T06:45Z
- **Tasks:** 2 (tracer: dot on the client hub; full Android run plus todo close-out)
- **Files modified:** 4 Android source/test files, 2 todo files moved and edited in the iOS repo. No iOS code, no backend change, nothing pushed.

## Accomplishments

- Closed port request P2 (iOS 06-06, U2). `ProfileHubUserCard` gained a trailing `showOnlineDot: Boolean = false`; the avatar sits in a `Box` and, when the flag is on, a 14 dp `primary` circle ringed 2 dp in the card colour (`surfaceContainerLow`) is drawn at `BottomEnd`, tagged `PROFILE_HUB_ONLINE_DOT_TAG` ("profile_hub_online_dot"). It has no content description or semantics, so the merged label stays "{name}, {email}, Edit profile". `ClientProfileHomeContent` passes `showOnlineDot = true`; `ExpertProfileHomeScreen.kt` is untouched. The card preview shows the dot.
- No presence plumbing or backend field was needed: the iOS client hub sets `isOnline = true` at init and never changes it, so the Android dot is equally static (T-08-61 accepted as planned).
- All six requested ports have landed. Both parity todos moved to `.planning/todos/completed/` with a `## Resolution`, and each requested line now reads `ported (<SHAs>)`: Phase 6 todo, `item 2 Off-grid stored time` (`96933b85`, `da7002ce`) and `item 4 Client hub online dot` (`fa9057ad`); Phase 5 todo, `Photo required to publish` (`3634f415`, `4ca8326b`), `Feedback minimum` (`68509208`), `Settings language save` (`4bd04caa`, `b1e37ca2`), `Resume keeps the verified email` (`1b536ef2`, `5a044d0a`). The `Expert-mode gate and Not now` closed line (P7) is unchanged. Plan 08-24's folded-todo gate (in completed/, absent from pending/, has `## Resolution`) now passes for both.
- Full Android unit suite plus ktlint green: 400 test classes, 5423 tests, 0 failures, 0 errors, 0 skipped (up from 5420; +3 rows).

## Task Commits

All Android commits are local on `main`; nothing was pushed (Android `origin/main` is still `27e024bf`).

1. **Task 1: Tracer, the client Profile hub shows the online dot; the expert hub does not** - `fa9057ad` (feat; exactly the four planned paths, Android repo)
2. **Task 2: Full Android run, then close both parity todos** - iOS repo `a05d09f` (docs; the two renames from pending/ to completed/ with their edits, no other file). Task 2 changes no Android code, so its Android contribution is the full verification run.

`git -C /Users/LeonChen/Documents/ClickMe_Android rev-list --count da7002ce..HEAD` prints 1 for this plan (08-30's last commit is `da7002ce`). The Android total across 08-27 to 08-31 is 10 (`rev-list --count 2d75fb974d39..HEAD`, 08-27's plan head before): 2 + 2 + 3 + 2 + 1. `.idea/*` and the untracked `.planning/` files in the Android repo were never staged.

**Plan metadata:** the iOS repo docs commit that holds this SUMMARY with STATE.md and ROADMAP.md (docs: complete plan).

## TDD evidence (RED)

RED was run first and is recorded here, not committed separately (the plan calls for one commit for Task 1). The repo's classifier (`gsd_run check tdd-red-evidence`) has no adapter for Gradle console output, so the semantic assessment below is the evidence.

```
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew -Pkotlin.daemon.jvmargs=-Xmx3g :app:testDevDebugUnitTest \
  --tests 'com.uptrendinvestments.clickmeapp.screens.clientmode.profile.ClientProfileHomeScreenTest' \
  --tests 'com.uptrendinvestments.clickmeapp.screens.expertmode.profile.ExpertProfileHomeScreenTest'
ClientProfileHomeScreenTest > userCardShowsTheOnlineDot FAILED               AssertionError at ClientProfileHomeScreenTest.kt:218
ClientProfileHomeScreenTest > userCardFallbackStillShowsTheOnlineDot FAILED  AssertionError at ClientProfileHomeScreenTest.kt:225
21 tests completed, 2 failed
BUILD FAILED
```

Semantic assessment: with only the `PROFILE_HUB_ONLINE_DOT_TAG` constant added so the rows compile, the two client rows executed and failed on the planned assertion (`assertCountEquals(1)` found no node tagged `profile_hub_online_dot` in the unmerged tree), which is the missing-dot behavior. The expert row (`expertHubShowsNoOnlineDot`) passed by construction, as the plan states, and is a guard against the flag leaking to the expert hub. The other 18 tests, including `userCardFallbacks` and `userCardWithEmailSpeaksNameEmailAndAction`, passed, so nothing failed for an unrelated reason (not a compile, setup or discovery failure).

GREEN: the same two classes plus `ktlintCheck` returned BUILD SUCCESSFUL (21 tests, 0 failures). Tracer gate: Task 1's verify was green on the exact tree that was committed, so the tracer was treated as verified end to end before Task 2.

## Verification

- Task 1 verify (filtered classes plus ktlint, then the greps), run as separate commands: BUILD SUCCESSFUL; the tag constant line, `showOnlineDot = true` in `ClientProfileHomeScreen.kt`, no `showOnlineDot` in `ExpertProfileHomeScreen.kt`, and `fun userCardShowsTheOnlineDot` all present. `git show --stat HEAD` in the Android repo lists exactly the four paths.
- Task 2 verify: the full `:app:testDevDebugUnitTest ktlintCheck` run is BUILD SUCCESSFUL in 1m 23s (400 classes, 5423 tests, 0 failures, 0 errors, 0 skipped, counted from the Gradle XML results). The todo close-out check, written to `/tmp/08-31-check.sh` as the plan's one-line chain split into the same steps, prints `OK` for both todos and `ALL_OK`: each todo is in completed/ with no pending copy and a `## Resolution`; no `port requested` text remains; each requested row reads `ported (<SHAs>)` exactly once and the ported count is 2 (Phase 6) and 4 (Phase 5); every cited SHA is an ancestor of Android `main`; every other line equals the `bf6aa99` version (blank lines aside, Resolution excluded); the `Expert-mode gate and Not now` closed line is present verbatim; Android `origin/main` is `27e024bf`.
- Each of the nine earlier Android SHAs (`4bd04caa`, `b1e37ca2`, `1b536ef2`, `5a044d0a`, `3634f415`, `4ca8326b`, `68509208`, `96933b85`, `da7002ce`) was confirmed against the 08-27 to 08-30 SUMMARYs (all `status: complete`) and with `git merge-base --is-ancestor <sha> main`; so is `fa9057ad`.
- Nothing pushed in either repo; the iOS repo's `.DS_Store`, `config.json`, `Localizable.xcstrings`, `state.json` and `milestone.lock` changes were never staged.

## Files Created/Modified

- `ProfileHubComponents.kt` - `PROFILE_HUB_ONLINE_DOT_TAG`, `OnlineDotSize` and `OnlineDotRingWidth`, `showOnlineDot` on `ProfileHubUserCard` with the dot over the avatar, KDoc, preview shows the dot
- `ClientProfileHomeScreen.kt` - passes `showOnlineDot = true` (the only caller that does)
- `ClientProfileHomeScreenTest.kt` - `userCardShowsTheOnlineDot`, `userCardFallbackStillShowsTheOnlineDot`
- `ExpertProfileHomeScreenTest.kt` - `expertHubShowsNoOnlineDot`
- `.planning/todos/completed/2026-11-16-android-phase-6-parity-follow-ups.md` and `.planning/todos/completed/2026-11-13-android-phase-5-parity-check.md` - moved from pending/, six port lines rewritten, `## Resolution` appended

## Decisions Made

See `key-decisions` above. In short: a static decorative dot with no presence data (iOS has none), opt-in on the shared card so the expert hub is untouched, and no added avatar ring.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0
**Impact on plan:** none.

## Issues Encountered

- The plan's one-line verify chains (nested command substitution, `tee`, long `&&` chains) were not run as written; as the run instructions allow, each Gradle run and each grep or `git rev-parse` check ran as a separate equivalent command, and the Task 2 todo check ran as `/tmp/08-31-check.sh`, the same steps in the same order.
- My first docs commit for the todos recorded only the pending-to-completed renames, because the content edits were still unstaged. I staged both files and amended that local, unpushed commit before anything else was committed; the final commit `a05d09f` holds the two renames with their edits and nothing else.
- Disk free stayed between 6.9 and 7.0 GiB across all Gradle runs; nothing was deleted.

## Known Stubs

None.

## Threat Flags

None. T-08-61 is accepted as planned (a static dot with no presence data, on the user's own hub only). T-08-62 is mitigated: the todos were closed only after every gap SUMMARY existed with `status: complete` and the full run passed, every cited SHA was checked as an ancestor of Android `main`, only the six port lines changed, and the P7 closed line is still verbatim.

## Device checks for 08-15 (Android section)

Use an Android dev build from `ClickMe_Android` `main` (at or after `fa9057ad`; all ten 08-27 to 08-31 commits are local, nothing pushed). Items (P1), (P3), (P4), (P5) and (P6) are copied from the 08-30, 08-29, 08-29, 08-27 and 08-28 SUMMARYs; (P5) and (P6) keep their numbered steps as indented lines under the item. Claude does not run these: several write to the live production backend.

- (P1) Sign in as a dedicated test expert account (never a real expert's account). Before starting, note that account's current weekly availability. The user sets that account's Monday slot to 09:15 to 24:00 through the API (Claude never writes production data). Open the slot: 9:15 AM and 12:00 AM are selected. Tap 10:00 AM: the 9:15 AM row is still listed. Tap 11:30 PM as the end: the 12:00 AM row is still listed. Cancel leaves the slot unchanged. Afterwards restore the noted availability on that account and confirm the Availability screen shows it again. (Dev build at or after `da7002ce`.)
- (P2) Open the client Profile hub: a green dot with a card-coloured ring shows at the bottom-right of the avatar on the user card, and the card still reads "{name}, {email}, Edit profile" to TalkBack with no extra announcement for the dot. Switch to expert mode and open the expert Profile hub: no dot shows on the avatar. Read-only, any test or real account.
- (P3) Use a dedicated, unpublished test expert signup with every step done except the photo (if the refusal failed, the profile would be published on production). On Profile Review the Publish Profile button is usable and no "Still needed" line shows; tap it: "Couldn't publish profile" with "Finish these first: Add profile picture."; OK stays on Review and nothing is published (the expert is not live, the setup hub still shows the photo step open).
- (P4) Help, Feedback: type fewer than 10 characters and send: "Please enter at least 10 characters." shows and the typed text is kept.
- (P5) Zero-language Done on Android client and expert Profile Settings. Run on a dedicated test account with a throwaway profile, not a real user: if the guard failed, these steps would delete that account's languages on the live production backend. Use an Android dev build from `ClickMe_Android` `main` (at or after `b1e37ca2`).
    1. Client mode: open Profile Settings, then Spoken Languages. Deselect every language in the sheet (including any custom ones that appear as chips, if the screen offers removal; otherwise a profile with only catalogue languages) and tap Done.
    2. Expect: the sheet closes, a dialog titled "Couldn't save changes" shows "Keep at least one language.", and the Spoken Languages list is unchanged. The auto-save status icon shows no failure and no save runs.
    3. Dismiss the dialog with "Got it", leave Profile Settings, and reopen it: the languages are still there. Force-quit the app and reopen to confirm the server still returns them.
    4. Repeat steps 1 to 3 on expert Profile Settings (switch to expert mode with the same test account).
    5. Restore note: no cleanup is needed if the guard works. If the languages were wiped, re-add them in the sheet and record the failure.
- (P6) Verified email survives resume on Android. Run on a dedicated test account with a fresh unpublished expert signup, on an Android dev build from `ClickMe_Android` `main` (at or after `5a044d0a`).
    1. Sign up as a new expert, open Verify email from the setup hub and verify the code. Expect the Verify email row ticked on the hub.
    2. Pull to refresh on the hub. Expect Verify email stays ticked.
    3. Open and leave two other steps (for example Personal details and Timezone). Expect Verify email stays ticked each time the hub reappears.
    4. Force-quit the app, relaunch and log in mid-setup. Expect the hub loads with Verify email still ticked.
    5. Failure handling: if the row ever unticks after a successful verify, record which step preceded it (reappearance, pull to refresh, other step, or relaunch).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The Android parity lane is complete: P1 to P6 landed, P7 closed, both todos in completed/. Plan 08-15 can copy the six items above into the regression checklist's Android section; plan 08-24's folded-todo gate can record both todos as completed.
- Nothing pushed: Android `origin/main` is still `27e024bf`, with all ten 08-27 to 08-31 commits local on `main`. Pushing and the Android release are separate decisions.

---
*Phase: 08-release*
*Completed: 2026-11-20*

## Self-Check: PASSED

- Modified files exist: the three Android source/test files and the expert test checked, plus both completed todos, all FOUND; neither todo remains in pending/.
- Commits are ancestors of Android `main`: `fa9057ad` FOUND, and the nine earlier SHAs FOUND; `rev-list --count da7002ce..HEAD` is 1. iOS commit `a05d09f` is on iOS `main`.
- Nothing staged beyond the planned paths in either repo; Android `.idea/*` still modified and unstaged; Android `origin/main` is `27e024bf`.
