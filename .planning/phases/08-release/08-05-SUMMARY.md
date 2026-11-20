---
phase: 08-release
plan: "05"
subsystem: backend-api
tags: [zod, validation, openapi, topics, currency, jest, tolerance-gate]

requires:
  - phase: 08-release
    provides: "Plan 08-02 backend branch ios-p8-x1 (D12 worktree) with the chat-reason and reschedule-decline commits"
provides:
  - "PATCH /user/profile: hand-written 422 messages for an empty first or last name, same code, paths and acceptance"
  - "serializeTopic sends price.currency null (not an empty string) for a topic stored with no currency, built only after the client tolerance gate passed"
  - "Backend branch ios-p8-x1 now four commits ahead of origin/main (28da165), nothing pushed"
  - "Both folded todos moved to .planning/todos/completed/ with a Resolution"
affects: [08-08, 08-21, android-profile-settings-empty-name-save]

actuals:
  tokens: 3500
  tasks: 3
  commits: 2

plan_head_before: 162f1d7c8f7f16044c7044ecdd30fd604e767b06
plan_head_after: 412f1aa649f5aa72fb853e40e87ab5e0998eb926
commits: 2

tech-stack:
  added: []
  patterns:
    - "Message-only validation change: hand-written zod min(1) message, rule and path untouched, pinned by exact errors[] equality in the test"
    - "Value-change on a live field goes behind a client tolerance gate (build 6 decoder read + iOS tests + Android tests) run before any code is written"

key-files:
  created: []
  modified:
    - "../ClickMe2026 Backend D12/src/schemas/userProfile.schema.js"
    - "../ClickMe2026 Backend D12/tests/userProfile.test.js"
    - "../ClickMe2026 Backend D12/src/controllers/expertTopics.controller.js"
    - "../ClickMe2026 Backend D12/tests/expertTopics.test.js"
    - "../ClickMe2026 Backend D12/openapi/clickme-api.yaml"
    - "../ClickMe2026 Backend D12/docs/ios/USD-TOPIC-PRICING.md"
    - ".planning/todos/completed/2026-11-14-backend-profile-name-validation.md"
    - ".planning/todos/completed/2026-11-16-backend-null-topic-currency.md"

key-decisions:
  - "The currency change was built: all three parts of the tolerance gate passed, so T-08-13 is mitigated by evidence rather than by reading the debug notes"
  - "The new test rows assert exact errors[] equality for the name 422, so any change to field path or message text fails the suite (T-08-14)"
  - "Co-Authored-By trailer is the orchestrator-specified 'Claude Opus 5.5' text on both backend commits and the iOS docs commit"

patterns-established:
  - "A `null` currency key is present in the JSON (toHaveProperty('currency', null)), never omitted, because ExpertOwnedTopic keeps price.currency in required"

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "PATCH /user/profile with an empty first_name or last_name returns 422 VALIDATION_ERROR at basic.first_name / basic.last_name with the hand-written message, which is also the top-level message; both empty returns both entries"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "tests/userProfile.test.js#empty first_name -> 422 VALIDATION_ERROR at basic.first_name"
        status: pass
      - kind: unit
        ref: "tests/userProfile.test.js#empty last_name -> 422 VALIDATION_ERROR at basic.last_name"
        status: pass
      - kind: unit
        ref: "tests/userProfile.test.js#both names empty -> 422 with both field paths, each with its own message"
        status: pass
    human_judgment: false
  - id: D2
    description: "Acceptance is unchanged: a 101-character first_name is still refused at basic.first_name, a 100-character last_name is still accepted (200), 'Ada' still accepted"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "tests/userProfile.test.js#a 101-character first_name is still refused at basic.first_name (max(100) unchanged)"
        status: pass
      - kind: unit
        ref: "tests/userProfile.test.js#a 100-character last_name is still accepted (200)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Client tolerance gate for the null currency: build 6 (a48c664) Price.currency is String? with no custom decoder; iOS TopicsSetupTopicCardLabelTests + TopicCurrencyTests; Android ResponseDecodingTest + ExpertTopicDtoTest"
    requirement: REL-02
    verification:
      - kind: other
        ref: "git show a48c664:ClickMe2026/Model/Responses/Children/ExpertTopicItem.swift (struct Price: currency String?, no init(from, no CodingKeys)"
        status: pass
      - kind: unit
        ref: "xcodebuild test -only-testing:ClickMe2026Tests/TopicsSetupTopicCardLabelTests -only-testing:ClickMe2026Tests/TopicCurrencyTests (44 tests in 2 suites passed)"
        status: pass
      - kind: unit
        ref: "gradlew :app:testDevDebugUnitTest --tests ResponseDecodingTest --tests ExpertTopicDtoTest (65 + 3 tests, 0 failures, BUILD SUCCESSFUL)"
        status: pass
    human_judgment: false
  - id: D4
    description: "serializeTopic sends price.currency null for a topic with no stored currency (list and POST echo); a paid topic stored as 'usd' still returns 'USD'; is_free, amount 0 and the Free label unchanged"
    requirement: REL-02
    verification:
      - kind: unit
        ref: "tests/expertTopics.test.js#G-06-1-currency: free row with price_currency null sends price.currency null"
        status: pass
      - kind: unit
        ref: "tests/expertTopics.test.js#G-06-1-currency: paid row stored as \"usd\" still sends \"USD\""
        status: pass
      - kind: unit
        ref: "tests/expertTopics.test.js#G-06-1-currency: POST of a free topic with no hourly_rate stores null and echoes price.currency null"
        status: pass
    human_judgment: false
  - id: D5
    description: "Full backend suite at the Redis baseline, doc gates green, four commits ahead of origin/main, no migration, nothing pushed"
    requirement: REL-02
    verification:
      - kind: other
        ref: "npm test (full): Tests 6 failed, 3858 passed; the only FAIL suite is tests/services/redis.test.js"
        status: pass
      - kind: other
        ref: "npm run check-docs and npm run check-openapi-coverage: both OK, 126 endpoints"
        status: pass
      - kind: other
        ref: "git rev-list --count origin/main..ios-p8-x1 = 4; git diff origin/main..HEAD -- supabase/migrations empty; ls-remote origin main = 28da165"
        status: pass
    human_judgment: false
  - id: D6
    description: "On a real iPhone with build 6 or the new build, an expert with a free topic stored with no currency still sees the topic list and editor render correctly after the deploy"
    requirement: REL-02
    verification: []
    human_judgment: true
    rationale: "Needs the deployed backend (plan 08-08) and a production-shaped row; the automated gate covers decoding, not what the device shows."

duration: 4min
completed: 2026-11-19
status: complete
---

# Phase 08 Plan 05: Profile name messages and null topic currency Summary

**Empty first or last names on PATCH /user/profile now return "First name can't be empty." / "Last name can't be empty." under the same VALIDATION_ERROR code and field paths, and a topic stored with no currency sends price.currency null instead of "", built only after build 6, iOS and Android all passed the tolerance gate; both are local commits on backend branch ios-p8-x1, four ahead of origin/main, nothing pushed.**

## Performance

- **Duration:** 4 min by the system clock (the clock was started at the first command of this run)
- **Started:** 2026-11-20T04:27:50Z
- **Completed:** 2026-11-20T04:32:39Z
- **Tasks:** 3 (Task 1 tracer, Task 2 auto/tdd, Task 3 auto)
- **Files modified:** 6 backend files in the D12 worktree (a separate git repo), plus 2 todo files moved in this iOS repo

## Accomplishments

- **D-30 names.** `basic.first_name` and `basic.last_name` keep `min(1).max(100).optional()`; the `min(1)` rule carries the hand-written message. Because `validationSummaryMessage` promotes the first non-raw-zod message, the top-level 422 `message` is now the hand-written sentence instead of "Please check the information you entered and try again." The code, the `errors[]` shape and the field paths are unchanged, and empty strings are still refused. OpenAPI documents `minLength: 1` and `maxLength: 100` and says accepting an empty last name is deferred.
- **Tolerance gate first, then currency.** All three parts passed before any currency code was written (results below). `serializeTopic` now returns the stored code uppercased or `null`; the key stays present and stays in OpenAPI `required`, with type `["string","null"]`. `docs/ios/USD-TOPIC-PRICING.md` §2 notes the null and that older servers sent `""`.
- Both todos are closed in `.planning/todos/completed/` with a Resolution (commit SHAs, gate results, what stays deferred).

## Tolerance gate results (Task 2, 2026-11-19)

| Part | Result |
| ---- | ------ |
| Build 6 `a48c664` `ExpertTopicItem.Price` | `currency: String?`, no `init(from`, no `CodingKeys` (extracted with `git show`, grep PASS) |
| iOS `TopicsSetupTopicCardLabelTests` + `TopicCurrencyTests` | `** TEST SUCCEEDED **`, "Test run with 44 tests in 2 suites passed" |
| Android `ResponseDecodingTest` + `ExpertTopicDtoTest` | BUILD SUCCESSFUL; test-result XML shows 65 tests and 3 tests, 0 failures, 0 errors, 0 skipped; `expertDetailsDecodesFreeAndPaidTopics` present |

## RED / GREEN evidence

- **Task 1 RED:** `tests/userProfile.test.js` + `tests/utils/errors.test.js`, 130 tests, 3 failed, all on the planned assertion: `errors[].message` was the raw `"Too small: expected string to have >=1 characters"` where the hand-written text was expected (first name, last name, both). The 101-character and 100-character regression rows passed on the old code by design. **GREEN:** 130 passed.
- **Task 2 RED:** `tests/expertTopics.test.js`, 119 tests, 2 failed: `Expected path: "currency", Expected value: null, Received value: ""` (list row and POST row). The `usd` -> `USD` row passed on the old code by design. **GREEN:** 119 passed.
- **Full suite:** 153 suites, 3864 tests: 3858 passed, 6 failed, all six in `tests/services/redis.test.js` (no Redis server). Previous baseline (08-02) was 3850 passed; the 8 extra passes are this plan's new rows (5 profile, 3 currency).

## Task Commits

All backend commits are in `/Users/LeonChen/Documents/ClickMe2026 Backend D12`, branch `ios-p8-x1`:

1. **Task 1 (tracer): empty-name messages** - `0767cf4` (fix): `userProfile.schema.js`, `userProfile.test.js`, `clickme-api.yaml`
2. **Task 2: null currency behind the gate** - `412f1aa` (fix): `expertTopics.controller.js`, `expertTopics.test.js`, `clickme-api.yaml`, `USD-TOPIC-PRICING.md`
3. **Task 3: close the todos** - `2d10b7a` (docs, iOS repo): the two todo files moved to `completed/` with a Resolution

Branch now holds `5da3976`, `162f1d7` (plan 08-02) and `0767cf4`, `412f1aa`: `git rev-list --count origin/main..ios-p8-x1` is 4.

**Plan metadata:** committed in the iOS repo after this file (docs: complete plan).

## Files Created/Modified

- `src/schemas/userProfile.schema.js` - hand-written `min(1)` messages for both names, with a comment naming D-30 and the deferred empty-last-name decision
- `tests/userProfile.test.js` - five rows: empty first, empty last, both empty, 101-char first still refused, 100-char last still accepted
- `src/controllers/expertTopics.controller.js` - `serializeTopic` currency is `topic.price_currency ? toUpperCase() : null`; comment above the function updated
- `tests/expertTopics.test.js` - three rows named G-06-1-currency
- `openapi/clickme-api.yaml` - names get `minLength`/`maxLength` and descriptions; `ExpertOwnedTopic.price.currency` is string or null
- `docs/ios/USD-TOPIC-PRICING.md` - §2 sentence about null
- Two todo files moved to `.planning/todos/completed/` in this repo

## Decisions Made

- The gate passed, so the currency change was built rather than deferred; the todo is closed, not left pending.
- The name tests assert exact `errors[]` equality (field plus message) and the top-level message, so a changed path, extra entry or different text fails the suite. This is what pins "build 6 and Android parse the same 422".
- The Co-Authored-By trailer is the text the orchestrator specified (`Claude Opus 5.5`) on `0767cf4`, `412f1aa` and `2d10b7a`.

## Deviations from Plan

None under Rules 1 to 4. Process notes:

**1. [Process] RED observed, not committed separately.** The plan fixes the commit count (one commit per change, branch four ahead), so tests and code for each change were written test-first, run RED, then committed together. The RED output is recorded above only. `tdd_mode` is not enabled and the plan type is `execute`, so no TDD gate applies.

**2. [Process] Disk was tight for the iOS gate.** `df` showed 6.7 GiB free (99% used), which met the plan's 6 GB check, so no DerivedData was deleted. The existing DerivedData was warm and the test run completed in about 2 minutes; free space was not re-measured afterward.

**3. [Process] Compound `<automated>` commands run as separate simple commands.** The gate pipeline and the Task 3 pipeline were executed step by step (bash 3.2) with the same checks, results recorded above. The Android run used the plan's exact Gradle command.

**Total deviations:** 0 auto-fixed, 3 process notes
**Impact on plan:** None on scope or behavior.

## Issues Encountered

- `git add` on the two old `pending/` paths failed after `git mv` (the rename was already staged); the failed `&&` chain stopped before the commit, so nothing was half-committed. The second attempt staged only the `completed/` files. 
- The Android checkout shows unstaged `.idea/*` changes (`Project.xml`, `gradle.xml`, `vcs.xml`). They are outside `app/`, were not touched by this plan, and were not staged anywhere.

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or trust-boundary file access. T-08-13 (topic decode on build 6 and Android) is mitigated by the passed gate; T-08-14 (validation contract) is mitigated by the exact-equality test rows; no package was added (T-08-SC).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 08-08 deploys `ios-p8-x1` (four commits) and needs the per-deploy user approval (D-14). Production `/health` is still 28da165 and `origin/main` was not touched.
- Backend master gets these commits through the 08-21 merge of origin/main (plus the cherry-pick of `94d659b` already on master).
- Still open as user decisions, not built: accepting an empty `last_name` on PATCH (would unblock build 6 and Android profile-settings saves for accounts signup created with `''`), collecting a last name at signup, backfilling NULL `price_currency` rows, and whether a free create must require a currency.
- Device check after deploy (coverage D6): open an expert's topic list on a real iPhone with a free topic that has no stored currency.

## Self-Check: PASSED

- Commits exist on the branch: `0767cf4`, `412f1aa` (`git rev-list --count origin/main..ios-p8-x1` = 4); iOS repo commit `2d10b7a`.
- `git ls-remote origin main` in the backend still prints `28da165`; no migration file changed; the D12 worktree is clean.
- Both todos exist under `.planning/todos/completed/` with a `## Resolution`, and neither remains under `pending/`.

---
*Phase: 08-release*
*Completed: 2026-11-19*
