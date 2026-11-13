---
phase: 05-signup-mode-switch-and-account
plan: 01
subsystem: auth
tags: [swiftui, valet, keychain, login, account-deletion, swift-testing]

requires:
  - phase: 04-auth-session-and-push
    provides: clearLocalSession() sign-out funnel, AutoLoginOutcome, SuspensionNotice
provides:
  - UserManager.lastLoginEmail with rememberLoginEmail(_:) and forgetLastLoginEmail(), stored in the Keychain only
  - Login pre-fill from the remembered email (explicit email still wins, password always empty)
  - DeleteAccountViewModel userManager seam and forget-on-success
  - RememberedLoginEmailTests suite (8 tests)
affects: [05-08 delete-account 409 handling, 05-13 Android follow-up for 0c9ecc55, 05-15 delete-account copy]

actuals:
  tokens: 3036
  tasks: 2
  commits: 2
plan_head_before: cbf397486f9d223c96965eb9c7d9bb41a40fc84d
plan_head_after: 9d19efce2c7e217d8da040cb47765d8a55797afb

tech-stack:
  added: []
  patterns:
    - "Remembered-email Keychain writes use do/catch with a documented ignore; only the init read uses try? (root CLAUDE.md Error Handling)"
    - "Tests never call UserManager.logout() on the shared singleton"

key-files:
  created:
    - ClickMe2026Tests/Auth/RememberedLoginEmailTests.swift
  modified:
    - ClickMe2026/Managers/UserManager.swift
    - ClickMe2026/Views/Screens/Login Flow/Login/LoginViewModel.swift
    - ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountViewModel.swift

key-decisions:
  - "Ported feature/remember-login-email (b0629d9) by hand onto current main instead of merging (407 commits behind, conflicts in UserManager)"
  - "The two Keychain writes (remember, forget) use do/catch with a comment-only catch instead of the branch's try?, per root CLAUDE.md; nothing is logged because the value is PII"
  - "rememberLoginEmail is called after apply(...) and after the awaited push-cleanup retry in login and signup"
  - "Branch test prefillsAfterLogout and deletionForgetsEmail ported without the shared-manager logout() call"

patterns-established:
  - "LoginViewModel email: String? = nil: nil pre-fills from the remembered email, an explicit value wins"

requirements-completed: [T8, D-14]

coverage:
  - id: D1
    description: "After any sign-out, Login opens with the last signed-in email filled in and an empty password; an explicit email wins and the field stays editable"
    requirement: "D-14"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Auth/RememberedLoginEmailTests.swift#prefillsAfterSignOut, emptyWhenNothingRemembered, prefilledEmailIsEditable, explicitEmailWins"
        status: pass
    human_judgment: false
  - id: D2
    description: "rememberLoginEmail trims whitespace and newlines and ignores an empty value"
    requirement: "T8"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Auth/RememberedLoginEmailTests.swift#remembersTrimmedEmail, ignoresWhitespaceOnlyEmail"
        status: pass
    human_judgment: false
  - id: D3
    description: "A successful account deletion forgets the remembered email before the farewell step; a failed deletion (401) keeps it"
    requirement: "T8"
    verification:
      - kind: unit
        ref: "ClickMe2026Tests/Auth/RememberedLoginEmailTests.swift#deletionForgetsEmail, failedDeletionKeepsEmail"
        status: pass
    human_judgment: false
  - id: D4
    description: "login() and signup() remember the email only after apply(...) succeeds, through the real login/signup flow on a device"
    requirement: "D-14"
    verification: []
    human_judgment: true
    rationale: "The unit suite cannot call login()/signup() or sign out the shared UserManager (Firebase and Keychain side effects race the singleton), so the end-to-end sign-out then Login pre-fill is covered by grep gates and the device UAT checklist, not a test"

duration: 8min
completed: 2026-11-13
status: complete
---

# Phase 5 Plan 01: Remembered Login Email Summary

**Login pre-fills the last signed-in email from the Keychain after any sign-out (password always empty), and a successful account deletion forgets it, ported by hand from `feature/remember-login-email` onto current main.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-11-13T17:21:52Z
- **Completed:** 2026-11-13T17:29:19Z
- **Tasks:** 2
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- `UserManager` gains `lastLoginEmail` (`@ObservationIgnored private(set)`), the Valet key `lastLoginEmail`, `rememberLoginEmail(_:)` and `forgetLastLoginEmail()`. `login(email:password:)` and `signup(email:password:role:)` call `rememberLoginEmail(email)` after `apply(...)`. `clearLocalSession()` is untouched, so every sign-out path (Log Out, forced logout, suspension, rejected refresh) keeps the email.
- `LoginViewModel.init` takes `email: String? = nil` and sets `email ?? userManager.lastLoginEmail ?? ""`; previews and the password-reset flow that pass an explicit email are unchanged.
- `DeleteAccountViewModel` takes a `userManager: UserManager = .shared` seam and calls `forgetLastLoginEmail()` after `DELETE /user/account` succeeds, immediately before `step = .deleted`. Nothing else in the file changed, so plan 05-08 (409 handling) and 05-15 (copy) apply cleanly after it.
- `RememberedLoginEmailTests` (8 tests, serialized, `@MainActor`) ported without any `logout()` call.

## Task Commits

1. **Task 1 (tracer): Login opens with the last email filled in** - `c1e96d1` (feat)
2. **Task 2: Deleting the account forgets the email** - `9d19efc` (feat)

## Verification

- `RememberedLoginEmailTests`: 6 tests passed after Task 1, 8 tests in 1 suite passed after Task 2 (both deletion tests present in `/tmp/05-01-t2.log`).
- Task 1 grep gate and acceptance criteria: pass (key used 3+ times, login and signup both remember, `clearLocalSession()` never references the email, no `UserDefaults` use, the only `try?` on the key is the init read, both writes have `catch`, the test file has no `logout()`).
- Task 2 acceptance criteria: `forgetLastLoginEmail()` 1 hit and `userManager: UserManager = .shared` 1 hit in `DeleteAccountViewModel.swift` (baseline 0 and 0).
- Build gate: `BUILD SUCCEEDED`. Warning comparison for the three app files against the pre-edit baseline: no new warnings (the single baseline warning, `call to main actor-isolated static method 'describe'` in `UserManager.swift`, is pre-existing and was not touched).
- Phase 4 regression: `AutoLoginOutcomeTests` passed (5 tests), `SuspensionNoticeTests` passed (4 tests). `AutoLoginOutcome`, `SuspensionNotice` and the suspension message text were not edited.
- Tracer gate: `human_verify_mode` is `end-of-phase` and auto mode is off; the tracer's `<verify>` is automated-only, so it was re-run against the committed tree, passed, and expansion continued.

## Files Created/Modified

- `ClickMe2026/Managers/UserManager.swift` - remembered-email state, key, init read, remember/forget methods, login and signup hooks
- `ClickMe2026/Views/Screens/Login Flow/Login/LoginViewModel.swift` - prefill from the remembered email
- `ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountViewModel.swift` - `userManager` seam and forget on success
- `ClickMe2026Tests/Auth/RememberedLoginEmailTests.swift` - new suite (new `Auth/` folder, picked up by the file-system synchronized test group, no `project.pbxproj` edit)

## Decisions Made

See `key-decisions` in the frontmatter. In short: hand port instead of merge; `do/catch` writes instead of the branch's `try?`; remember after `apply(...)`; no singleton `logout()` in tests.

## Deviations from Plan

None - plan executed exactly as written.

Note on TDD flow: the plan prescribes one `feat` commit per task, so the test file was written before the implementation but there was no separate `test(...)` RED commit and no RED run (the tests reference symbols that did not exist yet, which is a build failure, not a valid RED under the TDD reference). Both tasks were verified GREEN.

## Issues Encountered

None. One Xcode warning in `UserManager.swift` (main actor-isolated `describe`) predates this plan and is unchanged.

## Known Stubs

None.

## Threat Flags

None. The remembered email is Keychain-only (Valet, `.whenUnlocked`), is never written to `UserDefaults` or logged, and is forgotten on a successful deletion (T-05-01, T-05-02 mitigated; T-05-03 accepted by design).

## Working tree note

The working tree carried uncommitted edits before this run (`.DS_Store`, `.planning/STATE.md`, `.planning/config.json`, `ClickMe2026/Localizable.xcstrings`, untracked `.planning/state.json`, `.planning/milestone.lock`, `.DS_Store` files). This plan did not edit `Localizable.xcstrings` and did not stage any of those files.

## Next Phase Readiness

Ready for 05-02. Plan 05-08 can add the 409 handling to `DeleteAccountViewModel` on top of the new `userManager` init parameter.

## Self-Check: PASSED

- FOUND: `ClickMe2026Tests/Auth/RememberedLoginEmailTests.swift`, `ClickMe2026/Managers/UserManager.swift`
- FOUND: `c1e96d1`, `9d19efc` (both ancestors of HEAD)
- `check evaluation-scope --plan 05-01 --commits-only` returns both commits.
