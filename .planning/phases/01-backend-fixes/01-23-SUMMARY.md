---
phase: 01-backend-fixes
plan: 23
subsystem: auth
tags: [deploy-handoff, wave-3c, smoke-checklist, expert-gate, BACK-13, BACK-08, BUG-03]

requires:
  - phase: 01-backend-fixes/01-19
    provides: "wave 3b live; production and origin/main at 3899d63, production smoke not run by user decision"
  - phase: 01-backend-fixes/01-20
    provides: "BACK-13 gate commits 2b5f9ea, f14f9d0, bdc580f"
  - phase: 01-backend-fixes/01-21
    provides: "BACK-08 seam commits de662e9, e1eb483 (option-a, decision record 01-21-D1)"
  - phase: 01-backend-fixes/01-22
    provides: "contract doc commits 730a1f0, 3f076e9, 8407402"
provides:
  - "Wave-3c push bundle and a no-money smoke checklist with minimum and full levels (below)"
  - "Setup-route promotion analysis against build 6 and current Android, with options for the user's decision before the push"
affects: [Phase 1 close, Phase 5 SIGN-06, Android EXPERT_SETUP_REQUIRED follow-up, BUG-03 in the Android bug log, Phase 4 payment UAT]

actuals:
  tokens: 8374
  tasks: 1
  # Measured at partial-SUMMARY write, before this file's own commit. Final count is set at resume.
  commits: 0

key-files:
  created:
    - ".planning/phases/01-backend-fixes/01-23-SUMMARY.md"
  modified:
    - ".planning/phases/01-backend-fixes/deferred-items.md"
    - ".planning/STATE.md"

key-decisions:
  - "The checklist needs no card: the plan's paid booking and hold are removed, because the wave changes no payment code (the only controller diff is the postOnboard role check)"
  - "One client-only test account covers both clients, because B5, which promotes it for good, now runs last. The plan needed a second account only because B5 came before B7"
  - "B5 cannot run on build 6: no screen there opens setup for a client-only account. Android runs setup, and the same account stays signed in on the iPhone to check the stale-token path on build 6"
  - "An expert role on account B does not by itself confirm silent promotion, because both apps sign up with the expert role. The summary gives a reading guide instead of the plan's rule"

requirements-completed: []
requirements-pending-checkpoint: [BACK-13, BACK-08]

coverage:
  - id: D1
    description: "Full gate at 8407402; push range is exactly the eight wave 3c commits; production and target SHAs recorded"
    requirement: BACK-13
    verification:
      - kind: other
        ref: "REDIS_URL=redis://localhost:6379 npm test (nine runs: seven passed 3099 of 3099, two failed one test each, each passing alone); check-openapi-coverage; check-doc-coverage; git log origin/main..master; git ls-remote origin main; GET /health"
        status: unknown
    human_judgment: true
    rationale: "Two of nine runs of the same commit failed one test each, in files this wave did not change, with no established cause. Whether that is acceptable for a push is the user's call."
  - id: D2
    description: "On production, a client-only account is not promoted by opening Expert mode, is refused on writes, and an existing expert keeps every feature, on build 6 and current Android"
    requirement: BACK-13
    verification: []
    human_judgment: true
    rationale: "Tests mock Supabase, and only the user can push and use the devices. Pending Task 2."
  - id: D3
    description: "A newly promoted account with a client-only token can write right away (stale-token path)"
    requirement: BACK-13
    verification: []
    human_judgment: true
    rationale: "Only mocks have exercised profiles.roles. B5 is the first real check. Pending Task 2."
  - id: D4
    description: "BACK-08 seams on production: no Stripe page and no payout_accounts row, and on build 6 an error view with no TIN field; Android blocks the account at the setup hub"
    requirement: BACK-08
    verification: []
    human_judgment: true
    rationale: "Neither client has run against these responses. B7 and B8 decide BACK-08. Pending Task 2."
  - id: D5
    description: "Account B background result recorded as the explanation of BUG-03"
    requirement: BACK-08
    verification: []
    human_judgment: true
    rationale: "Read-only production queries only the user runs. Informational; it does not decide BACK-08."

plan_head_before: 958ab2ebccc449ad1a59f2b456375ccd6ef8034e
# plan_head_after and the final commits count: set when the plan completes after the checkpoint resumes.
# plan_head_before is an iOS repo SHA. This plan makes no backend commits; backend master stays at 8407402.

status: in-progress
---

# Phase 1 Plan 23: Wave 3c close-out Summary (PARTIAL, awaiting Task 2)

**Wave 3c (the expert promotion gate and the tax-ID seams) is packaged for your push at `8407402`, with no migration. One decision is yours before the push. The smoke needs no card and creates no hold or charge.**

Status: Task 1 done. Task 2 (`checkpoint:human-action`, `gate="blocking"`) is waiting on you. Claude pushed and deployed nothing (D-11), and no backend code changed in this plan. No requirement is marked complete.

## Read this before pushing

**Sources.** Everything about client behavior below comes from reading code, not from running it:

- **Build 6:** iOS `main`. Its last app-code commit is `a48c664`, "Build 6 release config". There is no release tag, so that this is the shipped code is an inference.
- **Android:** HEAD `2d04c4ce`, whose build number is vc 6. Which build your Samsung runs is not known here.

### 1. DECISION NEEDED: what the setup route accepts as a promotion

**What happens today, in plain terms.** `PATCH /expert/profile/setup` promotes any request that passes validation, and every field is optional:

| Request from a client-only account | Result |
|---|---|
| `{}` | Becomes an expert, permanently. Returns 200 with `setup_completed: false` |
| `{ "setup_completed": true }` on an incomplete record | Becomes an expert, permanently, then gets a 422 listing the missing fields |
| Unknown key or wrong type | 422, nothing changes |

This matches the plan's wording (validate, then promote). It is looser than "only a valid setup promotes".

**Who could trigger these two bodies.** Only someone signed in, making a hand-written API call, and only on their own account. Roles are never read from the body, and no one can promote another account.

**Do shipped clients send them? No, from their code:**

| Client | `{}` | The flag alone | Other notes |
|---|---|---|---|
| Build 6 | Never | Never. Publish sends the full payload, after a local completeness check | A client-only account cannot reach setup on build 6 at all (note 2) |
| Android | Never. `patch()` returns early when the body has no fields | Never. Publish sends the full payload | The only shipped client where a client-only account reaches setup |

**Consequence if someone does it.**

- The account passes all 20 refused routes, including Connect onboarding and the tax form, with no way back (D-09).
- Nothing in `src` outside setup and `GET /expert/profile` reads `setup_completed`, and migration `20260726120000` removed the home feed's filter on it, so nothing hides an unfinished expert for that reason. I did not trace whether one with no topics appears in search.
- This grants nothing new: `POST /auth/signup` with `role: expert` already gives any new account the same role, and both apps sign up that way.

**The case a real user can hit is a different one.** On Android, the first saved step in the setup hub promotes. A client-only user who saves one step and taps "Not now" is an expert for good, with setup unfinished. Rejecting `{}` does not change this. Only option C does.

**Options:**

| Option | What changes | Effect on build 6 and Android, from their code | Size |
|---|---|---|---|
| **A. Push as is (my recommendation)** | Nothing | None | None |
| B. Reject empty bodies | For a client-only account, a body with no profile field (`{}`, the flag alone, `{"location":{}}`) gets a 422 and no promotion. Experts are unchanged | None: neither client sends these as a client-only account | About 10 lines, 4 to 6 tests, two doc sections. A new commit, so the gate and this bundle are redone. Under an hour |
| C. Only a complete publish promotes | Partial saves work but do not promote. Promotion happens once the record is complete and `setup_completed: true` is sent | Build 6: none, because its setup callers already hold the role. Android: looks safe, since tag rows reference `profiles` and the avatar route is not gated, but its behavior changes and only a device check can confirm it | One small plan, about the size of 01-20's Task 2 plus docs and tests |

**Why A:** no shipped client can reach B's case, and an attacker gains nothing that signup does not already give. B only closes a hypothetical. If you want the rule to mean what it says, C is the real fix. It fits best with SIGN-06 in Phase 5, when iOS gets the same hub path. It needs no migration, and it can be added later. The cost of waiting is that accounts promoted in the meantime stay promoted.

Nothing is implemented. Say A, B or C when you reply. B or C means no push yet.

### 2. Promotion is one-way, and the gate reaches every shipped app

- **No downgrade (D-09).** Anything promoted stays promoted, so use only a test account below.
- **Build 6 opens the expert home for any role.** A client-only user sees empty states, and 403 messages on writes.
- **`GET /expert/tax-profile` now returns 403 for client-only accounts.** Neither client has run against that, so the smoke checks how each error state looks.
- **A client-only account on build 6 can no longer become an expert.** Splash and login open setup only when the account already holds the expert role, and the old first-touch promotion is what used to give it that. Build 6 has no other way in, so the setup message on build 6 points at something the user cannot do. This lasts until SIGN-06 ships. Android does open its hub.
- **How many accounts this touches is unknown.** Both apps sign up with the expert role, so client-only accounts come from the API, seeds or older builds. Q0 below counts them.

### 3. A freshly promoted user keeps a client-only token for up to 7 days

So both gates consult `profiles.roles`. Tests mock this. B5 is the first real check, and it runs on both clients.

### 4. Tests do not prove client behavior, and the suite is flaky

Every test mocks Supabase and Stripe. None shows what a client does. A green suite here says nothing about how a screen looks.

**This plan, nine full runs of `8407402`: seven passed 3099 of 3099. Two failed one test each.**

| Where | Test | Failure | Alone |
|---|---|---|---|
| 01-23 | `tests/moderationGates.test.js`, `reportLimiter › counts reports (10/hour) but never action != report` | Expected 429, received 401 | 14 of 14 passed |
| 01-23 | `tests/connectWebhooks.test.js`, `payout.paid › updates withdrawals.status to "paid" when payout.paid fires` | 5 s timeout, then Jest's forced worker exit warning | 107 of 107 passed |
| 01-21 | `connectWebhooks`, 15 tests | One 5 s timeout, plus others | Passed |
| 01-22 | `clientBooking`, 40 tests in one run | For example, 401 under a mocked `authenticate` | 143 of 143 passed |
| 01-21 | `expertBooking`, 1 test | Likely a `Date.now()` fixture bug. Read from the code, not reproduced | Passed |

Earlier waves also had varying failures.

**The cause is unknown, and I will not call it harmless.** Stripe Connect webhooks are real-money code, and that file has now failed in two separate plans. What can be said is limited: these failures appear only in parallel full runs, each file passes alone, and this wave did not change any of them. The unexpected 401 appears in two different files, which is a clue and not a finding. A real production bug hidden behind these failures is not ruled out. No test infrastructure was changed to hide this.

### 5. Do not use `scripts/uat-convert-expert.js` to judge the gate

It asserts the old first-touch behavior, so it would fail after this deploy even when the gate is right. It was not run, since it calls production. From 01-22's code read:

- `uat-topic-tags.js` and `uat-topic-owned-tags.js` should pass if their default accounts hold the expert role (not checked).
- `uat-seed-notifications.js` would not fail.

### 6. Rollback, and what is already live without a real check

- **Rollback target is `3899d63`.** It contains waves 3a and 3b, and neither has had a real-Stripe check. Going back is code-only, since this wave has no migration. Accounts promoted while 3c is live stay promoted, and first-touch promotion returns.
- **BACK-06, BACK-07 and BACK-19 stay Pending,** with skipped smokes. This smoke does not cover them.

### 7. Still open, none of it touched here

- **Refund retry fix (you chose option A).** It needs its own plan before Phase 4 payment UAT. No plan exists yet.
- **The `pending_approval` hold after `end_time`.** It stays until `expireBookings` voids it, up to about 12 hours after the request. You have not explicitly confirmed this.
- **The confirm orphaned hold.** This needs your decision before Phase 4 payment UAT.
- **The client-cancel `retrievePI` failure.** It can leave a hold with no flag and no retry until the authorization lapses.

### 8. Correction: the Redis test exclusion was needless

Earlier waves excluded `tests/services/redis.test.js` with the reason "no local Redis". The local Redis was running all along; the test only needs `REDIS_URL` set.

- Without `REDIS_URL` it fails 6 of 6. With it, it passes 6 of 6, and `redis-cli ping` answers `PONG`.
- `git log 2ec82af..master -- src/services/redis.js tests/services/redis.test.js` is empty, so neither file changed since `2ec82af`.
- So this says the test passes today. It does not retroactively run it against those waves, though neither file changed.
- The `WINDOWS.md` entries stay open until phase close.

## Task 1: Gate and push bundle (done)

### Full gate (at `8407402`)

| Check | Result |
|---|---|
| `REDIS_URL=redis://localhost:6379 npm test`, nine runs | Seven: `130 passed, 130 total`, `3099 passed, 3099 total`. Two: 1 suite and 1 test failed, see note 4 |
| Redis suite | Included. `jest --listTests` lists it among the 130 |
| `npm run check-openapi-coverage` | `OK: all 128 endpoints present in spec (routes === spec paths).` |
| `npm run check-doc-coverage` | `OK: all 128 endpoints covered 1:1 (routes === doc headings).` |

The first run was clean. The extra runs were added to measure the flake rate, because one clean run does not rule it out.

`git status --porcelain -- src tests openapi docs supabase scripts` prints one line: `?? scripts/uat-seed-profile.js`, the same pre-existing untracked file. It is not part of the push. No tracked file is modified.

### Push bundle

- **Production SHA now** (`GET /health`): `3899d63`. `git ls-remote origin main` shows the same full SHA, `3899d63ca7…`.
- **Target SHA:** `8407402`
- **`git status -sb`:** `## master...origin/main [ahead 8]`. `master..origin/main` is 0, so the push is a fast-forward. The range is exactly the expected eight; no other session has added to it.
- **Diff:** 28 files, 1470 insertions, 315 deletions.
- **Runtime change:** `src/middleware/ensureExpert.js`, `src/routes/onboarding.js`, the mount on `src/routes/expertTaxProfile.js`, and the role check in `src/controllers/connect.controller.js`. The other route files changed in comments only.
- **No migration or dependency change:** `git diff --name-status 3899d63 master -- supabase package.json package-lock.json railway.json` prints nothing.
- **No money path changed:** `git diff --stat 3899d63 master -- src/controllers src/services src/cron src/utils src/schemas` shows only `connect.controller.js`, 10 added lines, 3 of them code. Expert money actions such as accept and cancel do pass through the gate, but a token with the expert role takes the fast path with no database read.
- **Push command (you only):** `git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" push origin master:main`

| Commit | Plan | Subject |
|---|---|---|
| 2b5f9ea | 01-20 | fix(ios-p1/BACK-13): split ensureExpert into read/write gates; promotion only via provisionExpert (D-07/D-08) |
| f14f9d0 | 01-20 | fix(ios-p1/BACK-13): only PATCH /expert/profile/setup promotes, after validation (D-07) |
| bdc580f | 01-20 | test(ios-p1/BACK-13): client-only reads pass through, writes get EXPERT_SETUP_REQUIRED |
| de662e9 | 01-21 | fix(ios-p1/BACK-08): never create a Connect account for a non-expert; lock the /expert/* classification |
| e1eb483 | 01-21 | fix(ios-p1/BACK-08): refuse GET /expert/tax-profile for client-only accounts (option-a, D-08 amendment) |
| 730a1f0 | 01-22 | docs(ios-p1/BACK-13): document EXPERT_SETUP_REQUIRED, the expert gate and the BACK-08 seams |
| 3f076e9 | 01-22 | docs(ios-p1/BACK-13): refresh expert route headers for the BACK-13 gate |
| 8407402 | 01-22 | docs(ios-p1/BACK-13): correct remaining first-touch wording in middleware and docs |

## Task 2: Checkpoint (PENDING, user action)

**This smoke needs no real card and can create no hold or charge.** I checked the diff (above) and removed the plan's paid booking from B1, because this wave changes no payment code. Use free topics only. If a payment sheet ever appears, back out; see S6.

### Accounts

| Account | What it is | Notes |
|---|---|---|
| **A** | Your real expert account, the pre-existing expert | Shows a working expert is not locked out |
| **T** | A test client-only account, from Q0 | **B5 makes it an expert for good.** Never use a real customer or account B |
| **B** | Android test "client account B" | **Read-only query only. Background for BUG-03, not a pass or fail for BACK-08.** Do not sign in with it for this smoke |
| Throwaways | Two new emails you control, such as plus aliases | Full level only, for B6 |

**Finding T.** A `seed-client-00N@clickme.test` account from `docs/UAT-ACCOUNTS.md` (backend repo), if Q0 lists it. That doc has the login. Skip these:

- `seed-client-001`: a UAT script changes its password.
- `seed-client-010`: the default target of the account-deletion script.
- `uat.client@clickme.test`: despite the name, it already holds the expert role.

**The plan's "fresh signup as client" is not possible in either app**, because both sign up as experts. If Q0 lists no usable account, run this yourself. It only creates an account:

`curl -X POST https://clickme-backend-production.up.railway.app/api/v1/auth/signup -H 'Content-Type: application/json' -d '{"email":"<alias you control>","password":"<new password>","role":"client"}'`

**Do not sign T in, or open Expert mode with it, until `/health` shows `8407402`.** Production still promotes on first touch until then, which would spoil T.

### Read-only queries (Supabase SQL editor)

**Q0, before the push. Sizes note 2 and finds T:**
```sql
select count(*) filter (where 'expert' = any(roles)) as with_expert_role,
       count(*) filter (where not ('expert' = any(roles))) as client_only
from profiles where deleted_at is null;

select u.email, p.id, p.roles, u.email_confirmed_at is not null as email_confirmed, ep.id is not null as has_expert_row
from profiles p
join auth.users u on u.id = p.id
left join expert_profiles ep on ep.id = p.id
where p.deleted_at is null and not ('expert' = any(p.roles)) and u.email like '%@clickme.test'
order by u.email;
```

**Q1, T's state:**
```sql
select roles, role from profiles where id = '<T id>';
select id, setup_completed from expert_profiles where id = '<T id>';
```

**Q2, T's Connect state:**
```sql
select expert_id from payout_accounts where expert_id = '<T id>';
```

**QB, account B, informational:**
```sql
select id from auth.users where email = '<B email>';
select roles, role from profiles where id = '<B id>';
select id, setup_completed from expert_profiles where id = '<B id>';
select expert_id, kyc_status from payout_accounts where expert_id = '<B id>';
```

### What to run

| Level | Steps | Devices | What it proves |
|---|---|---|---|
| **Minimum** | Prep, B2-min, B3, B4, B7, B8, B3-Android, B5, QB | iPhone and Samsung | **The gate and the BACK-08 seams: nobody promoted by reading, writes refused, no tax-ID surface, a working expert not locked out, and setup still works.** BACK-13 and BACK-08 can be recorded from this |
| Full D-12 | Minimum, plus B1, the rest of B2, B3-walk and B6 | iPhone and Samsung | Also the base app checks, the other refused screens, and new signups on both clients |

The steps marked **[M]** are the minimum. **B7 and B8 decide BACK-08.** The base checks in B1 are marked as full level only, which is a judgment call of mine against D-12: the wave touches no booking, call or chat code.

Run the steps in the order below. **B5 goes last because it cannot be undone.**

### Prep [M]

1. Run Q0. Choose T. Note the two counts for me.
2. Decide note 1.
3. Push: `git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" push origin master:main`. Wait for Railway to report the deploy healthy.
4. Open https://clickme-backend-production.up.railway.app/health. It must show `"commit":"8407402"` before you go on.

### Existing expert

**B2-min [M], build 6, account A:**
1. Open Expert mode.
2. Edit a topic's description, save, then restore it.
3. Open Payouts & Earnings. **Do not tap Continue or Finish verification.**
4. Open Tax & Payout Info. The form shows. **Do not save it.**

Expected: everything works, and "Finish setting up your expert profile to use this feature." never appears. If it does, see S1.

### Client-only account T, before promotion

Sign T in on the iPhone (build 6) and leave it signed in for the rest of the smoke.

**B3 [M], build 6:**
1. Profile, then Switch to Expert Mode, then Expert Mode.
2. The expert home shows empty states, with no crash and no sign-out.
3. Profile, then Expertise & Topics, then add a topic and save.

Expected: "Finish setting up your expert profile to use this feature." Nothing is saved. Note how it looks.

**B4 [M]:** Q1. `roles` is only client and `expert_profiles` returns no row. If not, see S3.

**B7 [M], BACK-08 Stripe seam, build 6:** Profile, then Payouts & Earnings. The "Complete payout setup" card shows. Tap Continue.

Expected: an alert titled "Couldn't open payout setup" with the setup message, and **no Stripe page opens.** Then Q2 returns no row. If a page opens, see S2.

**B8 [M], BACK-08 tax form, build 6:** Profile, then Tax & Payout Info.

Expected (plan 01-21 option-a, your 2026-11-07 decision, record 01-21-D1): an error view with "Finish setting up your expert profile to use this feature." and Retry, with **no TIN field and no form to save.** `GET /expert/tax-profile` returns 403 `EXPERT_SETUP_REQUIRED`. Account A in B2-min still opened the form. If a TIN field shows, see S4.

**B3-walk, full level only, build 6.** Still as T, note how each looks:
- Availability: change something and save (should show the setup message).
- Edit profile: save (should show the setup message).
- Earnings and analytics on the home screen (should show zeros or empty).
- View My Public Profile. This route filters by role, so expect a not-found state. It was not traced on build 6, so report what you see.

**B3-Android [M]; also the Android half of B7 and B8.** Sign T in on the Samsung.
1. Profile, then switch to Expert. It opens the **setup hub**.
2. **Save nothing here: any saved step promotes T.**
3. Tap "Not now". It returns to client home.
4. T has reached no expert screen, so Payouts, the Stripe page and Tax & Payout Info are all out of reach. That is the Android result for B7 and B8.
5. Q1 again: still client only, no row.

### Base checks and new signups, full level only

**B1, free booking only, each client:** Sign in, make a free booking with T on a free topic of A, join a call from both sides, and chat both ways. If A has no free topic, make one and delete it afterwards. Cancel the booking at the end.

**B2-rest:** Run B2-min on Android as A. On either client, accept a free request. Accepting a free one has no payment step, because a free booking has no payment intent.

**B6:** A brand-new expert signup completes on each client, with a throwaway email. You can delete these accounts in the app afterwards. These do not touch T.

### Promotion and the stale-token path

**B5 [M]. This makes T an expert for good. Run it last.**
1. Keep T signed in on the iPhone. **Do not sign out on either device.**
2. On the Samsung, as T: switch to Expert, complete every step in the hub, and publish. It lands in client mode.
3. Q1: `roles` now has expert, and `setup_completed` is true.
4. Still on the Samsung, with no sign-out: switch to Expert and create a **free** topic. Expected: it saves.
5. On the iPhone, still signed in from before the promotion: Profile, then Expertise & Topics, then create a **free** topic. Expected: it saves, with no setup message.
6. **Delete both topics right away.** T is now on live production, and a real client could otherwise find and book them.

**Why build 6 runs only half of this.** The plan asks for setup on both clients, but no screen on build 6 opens setup for a client-only account (note 2). The iPhone keeps a token issued before the promotion, so step 5 still tests the stale-token path on build 6.

### Account B background check [M]

Run QB. **Nothing identifying account B is written down.** The Android docs name it only by role: "the user's second real account", signed in on the Samsung in client mode, seen on vc 1 on 2026-10-30. So use the email you know. Your bug log notes that the A and B labels were unclear, so check you have the right one.

**How to read the results.** This corrects the plan, which treats any expert role or row as confirming silent promotion. Both apps sign up with the expert role, so that does not follow:

| Result | Reading |
|---|---|
| Client only, no rows | BUG-03's origin is unexplained. The traced seams are closed either way |
| Expert role, no `expert_profiles` row | The role came from signup, not first touch |
| Expert role, row, `setup_completed` false | First touch is likely. A profile edit can also create the row |
| Expert role, row, `setup_completed` true | It went through setup |
| Any `payout_accounts` row | Connect onboarding started on this account, so Stripe's own prompt is a likely source of the TIN request |

**If B holds the expert role from signup, BACK-08 does not change what B sees.** The gate lets it through, so a person who thinks of it as a client account can still open the tax form. That would be a product question for you, and it is logged. D-09 leaves the account as it is.

### Stop conditions

- **S1, account A is refused anywhere, or gets the setup message.** Stop and tell me at once, with the screen and the time. A working expert is locked out, which is the worst case for this wave. The likely step is going back to `3899d63` (note 6).
- **S2, B7 opens a Stripe page.** **Enter nothing.** Close it, run Q2 and tell me. A row would mean a live Connect account now exists for T.
- **S3, B4 shows expert before B5.** First check `/health` showed `8407402` before T signed in. If it did, tell me the time and which screen you were on. Do not continue to B5.
- **S4, B8 shows a TIN field.** **Enter no real number and do not save.** Tell me.
- **S5, a crash, a blank screen or a sign-out on T.** Note the client, the screen and the time, and tell me. Continue only with the steps that do not depend on that screen.
- **S6, a payment sheet appears.** Back out and do not pay. That topic is not free. Nothing in this smoke needs a card.

### What this smoke cannot show

| Check | Can it? | Note |
|---|---|---|
| Client-only reads do not promote; writes are refused | Yes | B3, B4 |
| A working expert is not locked out | Yes, for A | One account; other existing experts are not sampled |
| Stale-token path against real Supabase | Yes, for one account | Not the full 7-day life of a token |
| BACK-08 seams for a client-only account | Yes | B7, B8 |
| The `{}` and flag-only bodies of note 1 | **No** | Neither app can send them. Tests only |
| An account that already holds the expert role but thinks of itself as a client | **No** | The gate lets these through by design. See QB and the reading guide |
| Accounts already promoted with setup unfinished | **No** | D-09 leaves them. SIGN-06 handles the routing |
| Stripe's follow-up requests on an existing Connect account | **No** | They need a `payout_accounts` row, which T must not have |
| Any money path, including BACK-06, BACK-07 and BACK-19 | **No** | Those smokes stay outstanding |
| Whether the flaky tests hide a real bug | **No** | Note 4 |
| The exact shipped binaries | **Partly** | Your devices are the shipped builds, but my expectations come from code. Tell me if a screen differs |

### Required end state

- T holds the expert role permanently, with no topics left. That is expected.
- Q2 returns no row for T.
- No test topic or free booking is left active. Throwaway accounts, if you made them, are deleted or noted.
- No card was used. Nothing moved on Stripe, so there is no Dashboard check to do.

**After you reply, Claude runs (read-only):** `git -C "/Users/LeonChen/Documents/ClickMe2026 Backend" rev-list --count origin/main..master` must print 0, and `curl -fsS https://clickme-backend-production.up.railway.app/health` must contain `"commit":"8407402"`. Claude then records your results here. BACK-08 is recorded as delivered only if B7 and B8 pass on both clients.

**Resume signal:** reply "wave 3c deployed" with:
- your choice on note 1;
- which level you ran;
- the results of B7 and B8;
- the two Q0 counts and the QB results;
- any step that failed, or "all passed".

If you choose B or C, reply with that instead and do not push.

## Deviations from Plan

- **[Dispatch] Paid booking and hold removed from B1.** The plan asked for a real hold. The diff confirms no money path changed, so a hold would add cost and prove nothing about this wave. This departs from D-12's "book (free and paid), pay".
- **[Rule 1 - Plan correction] B5 cannot run on build 6.** No screen there opens setup for a client-only account. Replaced by the stale-token check in B5 step 5. The plan's truth that a client-only account completes setup holds on Android only.
- **[Rule 1 - Plan correction] "A fresh signup as client" is not possible in either app.** T comes from Q0, or from the curl fallback, which you would run.
- **[Rule 1 - Plan correction] The reading of account B.** The plan treats an expert role or a row as confirming silent promotion. Both apps sign up with that role, so a reading guide replaces it.
- **[Rule 2 - Missing critical] Order and accounts.** B5 moved last, so one test account covers B3, B7 and B8 on both clients, instead of the plan's second account. A warning not to touch T before the deploy is live is added, because old production would promote it on the first read.
- **[Rule 2 - Missing critical] Added:** Q0, B3-walk for the other error states, two levels, stop conditions, topic deletion after B5, and instructions not to tap Continue or save the form as A.
- **Account B has no identifying detail on record.** The plan asks to copy one from the Android bug log, which has none. The docs name accounts by role only (D-03), so the checklist describes the account instead.
- **The gate was not clean on every run.** Two of nine runs failed one test each (note 4). The plan's prohibition says not to hand off on a red gate. I am handing off because the dispatch says to capture and rerun, each file passes alone, and the wave did not change those files. **The call on whether that is acceptable is yours.**
- **[Rule 3 - Out of scope, logged] New deferred items:** build 6 client-only accounts cannot reach setup, the expert-role limit on BACK-08, and the flakes above. Added to `deferred-items.md`.
- **`01-USER-SETUP.md` not generated,** even though the plan has `user_setup`. The push and queries are fully written in Task 2, as in 01-17 and 01-19.
- **Commits on `main`:** same as earlier plans. `branching_strategy` is `none` and the dispatch named this branch. Only planning docs were committed.

## Threat Coverage

- **T-01-44 (wave-3c deploy):** the isolated push range is done. The gate is green in seven of nine runs (note 4). The `/health` check and the two-client smoke are Task 2.
- **T-01-45 (information disclosure):** the checklist's queries are read-only `SELECT`s. It names accounts by email pattern or role, and points to the backend doc for test logins instead of copying any credential.
- No new security surface: this plan changes no code.

## Next Phase Readiness

Blocked on Task 2 and on your choice in note 1. BACK-13 and BACK-08 stay Pending until the push and the results are recorded here. BACK-06, BACK-07 and BACK-19 stay Pending. This is the last plan in Phase 1.

## Self-Check: PASSED (record checks only; Task 2 not run)

- This SUMMARY contains `BACK-08`, the production and target SHAs, every commit in `origin/main..master` with its plan id, how to identify account B, and the B8 option-a expected result.
- `git log origin/main..master` holds exactly the eight expected commits. `git rev-list --count master..origin/main` = 0, and `git ls-remote origin main` = `3899d63`; nothing pushed by Claude.
- No backend file changed in this plan: `git status --porcelain` in the backend shows no tracked change.
- The tables and columns in Q0, Q1, Q2 and QB match the migrations and the code that uses them. None of the queries were run; only you can run them.
- Task 2 is not done, so `status: in-progress`, `requirements-completed: []`, and no requirement is marked complete.
