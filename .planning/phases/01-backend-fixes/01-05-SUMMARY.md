---
phase: 01-backend-fixes
plan: 05
subsystem: api
tags: [express, jest, supertest, openapi, reviews, currency, expert-bookings]

requires:
  - phase: 01-backend-fixes/01-01
    provides: "tests/contract.responseShapes.test.js (D-12 additive-only key-set lock) and the table-keyed supabase mock pattern"
provides:
  - "has_review (boolean, never null) on GET /expert/bookings items, /expert/bookings/:id/details and /:id/summary (BACK-03)"
  - "pricing.currencySymbolFor(code): shared symbol lookup over MIN_PRICE_CURRENCY_SYMBOLS (BACK-05)"
  - "consultation_fee.label on expert reads shows the currencies-table symbol and the currency's minor-unit digits, e.g. CA$12.50 / session (BACK-05)"
  - "GET /expert/booking-requests/:id economics.potential_earnings uses the booking currency's minor-unit digits (BACK-05)"
affects: [iOS Phase 3 BOOK-17 (Leave a Review), iOS Phase 6 EXP-14, 01-10 (wave-1 smoke checklist)]

actuals:
  tokens: 5800
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "One batched reviews read per request, skipped when the page is empty (no N+1, no query on an empty feed)"
    - "Tests that add a new table read use a table-name switch on supabaseAdmin.from (restored in afterEach) instead of extending mockReturnValueOnce chains"
    - "Mock reviews chain applies the recorded .eq() filters to its rows, so the reviewer_role = 'client' filter is exercised for real"

key-files:
  created: []
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/expertBooking.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/expertBooking.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/utils/pricing.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/utils/pricing.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/bookingRequests.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/bookingRequests.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml"

key-decisions:
  - "A reviews read error fails the request through dbError rather than reporting has_review false, so the app never shows a wrong review state (plan assumption)"
  - "Reused MIN_PRICE_CURRENCY_SYMBOLS via a new exported currencySymbolFor; no new currency.js and no fourth zero-decimal set"
  - "The reviews read runs after the payout-fallback read in the feed and details, so existing order-dependent test mocks (bookings, then payout_accounts) keep working"
  - "CHF stays 'CHF' with no trailing space in the table, so a CHF label reads 'CHF12.50 / session'. This matches the existing minimumPriceLabel behavior and the pinned table, and was not changed"

requirements-completed: [BACK-03, BACK-05]

coverage:
  - id: D1
    description: "Expert feed, details and summary report has_review: true only when a client review exists; expert-only review is false; no review is false (never null); an empty feed page issues no reviews query; item order is unchanged"
    requirement: BACK-03
    verification:
      - kind: integration
        ref: "tests/expertBooking.test.js#has_review on expert booking reads (BACK-03)"
        status: pass
      - kind: integration
        ref: "tests/contract.responseShapes.test.js (additive-only key-set lock, still green)"
        status: pass
    human_judgment: false
  - id: D2
    description: "consultation_fee.label reads CA$12.50 / session for 1250 CAD, the yen sign 1200 / session for 1200 JPY, XYZ 12.50 / session for an unknown code, CA$0.00 / session for a null amount; null booking currency falls back to topic currency then CAD"
    requirement: BACK-05
    verification:
      - kind: unit
        ref: "tests/utils/pricing.test.js#currencySymbolFor (BACK-05)"
        status: pass
      - kind: integration
        ref: "tests/expertBooking.test.js#consultation_fee.label currency symbol and digits (BACK-05)"
        status: pass
    human_judgment: false
  - id: D3
    description: "economics.potential_earnings on GET /expert/booking-requests/:id is 12.5 for 1250 CAD, 1200 for 1200 JPY and null for a null amount"
    requirement: BACK-05
    verification:
      - kind: integration
        ref: "tests/bookingRequests.test.js#potential_earnings currency digits (BACK-05)"
        status: pass
    human_judgment: false
  - id: D4
    description: "OpenAPI documents has_review on the three expert booking schemas, the new consultation_fee.label wording and the potential_earnings digit rule; route and doc coverage checks still pass"
    requirement: BACK-03
    verification:
      - kind: other
        ref: "grep -c has_review openapi/clickme-api.yaml (4); npm run check-openapi-coverage; npm run check-doc-coverage (OK: all 128 endpoints)"
        status: pass
    human_judgment: false

# plan_head_before / plan_head_after below are the iOS repo (planning docs only, no code in this plan).
# Backend (the repo with this plan's code) heads are listed separately.
plan_head_before: f39cf45cb8f7a2b32185716418e7bad0473f798f
plan_head_after: PENDING_SUMMARY_COMMIT
backend_head_before: 70c7ed6ee2ffdd12649f43e267ad93f4a6c43391
backend_head_after: 365e091ca3fbe98073c11dae0eb77e6335ed9579
commits: 3

duration: ~12min (approximate; start time was not captured, derived from first and last commit timestamps)
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 05: has_review and currency-correct expert fee labels and earnings Summary

**The expert booking feed, detail and summary now say whether the client left a review (`has_review`), and the expert-side fee label and request earnings are correct for any currency (`CA$12.50 / session`, JPY with no decimals).**

## Performance

- **Duration:** ~12 min (approximate)
- **Completed:** 2026-11-08
- **Tasks:** 3 of 3
- **Files:** 7 backend, 0 iOS code (planning docs only)

## Accomplishments

- **BACK-03:** `fetchClientReviewedBookingIds(bookingIds)` is one `reviews` read (`booking_id IN (...)` and `reviewer_role = 'client'`) returning a Set; it issues no query for an empty list. `getFeed` calls it once per page and adds `has_review` to each item without reordering; `getDetails` and `getSummary` call it for their single booking. The query returns only booking ids, never rating or comment text (T-01-06).
- **BACK-05 label:** `currencySymbolFor` is exported from `src/utils/pricing.js` (own-property lookup, so `'constructor'` is not a symbol; unknown code gives `'XYZ '`); `minimumPriceLabel` now calls it with identical output. `buildSessionMoney` builds the label as symbol + `toFixed(digits)` + ` / session`. `amount` and `currency` are unchanged.
- **BACK-05 earnings:** `getDetail` divides by `10 ** minorUnitDigitsFor(currency)` (the list endpoint already did).
- **OpenAPI:** `has_review` added to `ExpertBookingItem`, `ExpertBookingDetail` and `ExpertBookingSummary`; `consultation_fee.label` and `potential_earnings` descriptions updated.

## Commits

| Repo | SHA | Message |
|------|-----|---------|
| backend (master) | `ec02fde` | fix(ios-p1/BACK-03): expose has_review on expert booking feed, detail and summary |
| backend (master) | `f5bc8b0` | fix(ios-p1/BACK-05): consultation_fee.label uses the booking currency symbol and digits |
| backend (master) | `365e091` | fix(ios-p1/BACK-05): potential_earnings uses currency digits; document has_review and labels |

Backend `git status -sb` shows `master...origin/main [ahead 11]`. Nothing was pushed or deployed (D-11).

## TDD

Each task ran RED first and was committed once with its tests (the plan specifies one commit per task): Task 1 had 6 of 7 new tests failing before the change (the empty-page case passed trivially), Task 2 had 12 failing, Task 3 had 1 failing (the JPY case). All green after the change.

## Verification

- Targeted: `tests/expertBooking.test.js` + `tests/contract.responseShapes.test.js` 120/120; `tests/utils/pricing.test.js` + `tests/expertBooking.test.js` 148/148; `tests/bookingRequests.test.js` 62/62.
- Full gate (`npm test -- --testPathIgnorePatterns=tests/services/redis.test.js`): 125/125 suites, 2732/2732 tests on three of four runs. See Issues Encountered for the one run with 2 failures. `check-openapi-coverage` and `check-doc-coverage` both print `OK: all 128 endpoints`.
- Acceptance criteria: `grep -c "currencySymbolFor(" expertBooking.controller.js` is 1 (baseline 0); `grep -c has_review openapi/clickme-api.yaml` is 4 (baseline 0, needs 3); the contract suite stays green (has_review is additive).

## Deviations from Plan

### Auto-fixed Issues

None needed for correctness. Notes:

**1. [Interpretation] Existing JPY label assertion updated**
- **Found during:** Task 2
- **Issue:** `tests/expertBooking.test.js` "Test E" asserted `'$5000 / session'` for JPY, the old wrong label.
- **Fix:** Changed to `'¥5000 / session'`, which is the intended BACK-05 result.
- **Commit:** `f5bc8b0`

**2. [Interpretation] Acceptance grep for `CA\$12.50` needs `grep -F` on macOS**
- **Issue:** The plan's command `grep -n "CA\$12.50"` (double-quoted) hands grep the pattern `CA$12.50`, where BSD grep treats `$` as an anchor and finds nothing, although the text is present twice (`openapi/clickme-api.yaml` lines 14830 and 14904).
- **Fix:** Verified with `grep -nF 'CA$12.50'`; both lines match. No spec change needed.

**Total deviations:** 0 auto-fixed, 2 interpretation notes. **Impact:** none on scope or behavior.

## Issues Encountered

- **Intermittent failure, not reproduced:** the first full-suite run reported `tests/expertBooking.test.js` with 2 failed tests (2730 passed of 2732). The file passes alone (118/118) and the full suite then passed three further times (2732/2732). The failing test names were not captured. The file contains older real-time `Date.now()` based tests and the new tests restore `supabaseAdmin.from` in `afterEach`, so a leak from the new describe is unlikely but not ruled out. Worth watching if it recurs.

## Authentication Gates

None.

## Known Stubs

None. No stub, skipped test or unrun verify was introduced, so nothing was appended to `.planning/WINDOWS.md`.

## Threat Flags

None. T-01-06 is mitigated: the `reviews` query receives only booking ids already scoped to the caller's `expert_id` and returns only `booking_id`. T-01-07 accepted: symbols come from a static server-side map. T-01-SC: no packages installed or upgraded.

## Notes for later plans

- Build 6 may display `consultation_fee.label`; after deploy it reads `CA$12.50 / session` (accepted by the user, Open Q4). Android shares this field.
- Wave-1 smoke checklist (01-10) can assert: an expert feed item for a reviewed booking shows `has_review: true`, and a JPY booking label has no decimals.
- The backend changes are committed locally only; the user pushes and deploys.

## Next

Ready for plan 01-06.

## Self-Check: PASSED

- FOUND files: `src/utils/pricing.js` (exports `currencySymbolFor`), the controllers, tests and `openapi/clickme-api.yaml` in the backend repo
- FOUND backend commits on master: `ec02fde`, `f5bc8b0`, `365e091`; backend `rev-list --count 70c7ed6..HEAD` is 3
