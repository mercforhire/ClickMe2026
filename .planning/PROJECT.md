# ClickMe iOS — Android-Parity Bug Fixes

## What This Is

A bug-fix project for the live ClickMe iOS app (SwiftUI), a marketplace where clients book paid or free voice and video sessions with experts. While porting the app to Android, the team found that many of its behaviors were wrong in iOS: some were fixed on Android, some avoided, some flagged. This project fixes every confirmed and likely iOS bug from that work, plus the backend issues behind them, and ships one new iOS build at the end.

## Core Value

Live iOS users can book, pay for, join and finish a session without the app cutting them off, charging them wrongly, or silently dropping their actions. Calls, bookings and payments come first when there's a tradeoff.

## Business Context

- **Customer**: Clients who book sessions and experts who sell them, on the App Store build (currently build 6)
- **Revenue model**: Paid sessions through Stripe (holds and captures on connected accounts)
- **Success metric**: No user-visible regressions against the inventory; every inventory item closed or explicitly deferred
- **Strategy notes**: Android launch on Google Play is targeted for ~2026-12-13 (`ClickMe_Android/.planning/STATE.md`); this iOS release has no fixed date

## Requirements

### Validated

<!-- Shipped and relied on in production — inferred from the codebase map. -->

- ✓ Email-only signup and login, with expert onboarding (photo, tags, languages, topics) — existing
- ✓ Client explore, search, favorites and public expert profiles — existing
- ✓ Booking requests, expert accept/decline, reschedule and cancel flows — existing
- ✓ Stripe PaymentSheet payments with holds, saved cards and payouts — existing
- ✓ In-app Agora voice calls, plus Skype/Zoom external meetings, with minimize-to-pill — existing
- ✓ Socket.IO chat with block, unblock and report — existing (unblock added `c8b2f62`)
- ✓ Report/block from expert profile and global account-suspension handling — existing (`097db7a`)
- ✓ Offline-tolerant auto-login — existing (`f43f38d`)
- ✓ FCM push for chat and booking requests — existing (other categories broken, see N1)
- ✓ Backend fixes K1–K5, K9–K12, K14, K16, plus the backend halves of H7 and N1 — Phase 1 (deployed to production at `d86bf97`)

### Active

<!-- Full detail, evidence and fix notes per ID live in .planning/IOS-BUG-INVENTORY.md. -->

- [ ] Calls: C1–C10 (incl. critical C1 5-minute overtime cutoff, likely C5)
- [ ] Client bookings: B1–B19 (incl. critical B6 reschedule response)
- [ ] Payments: P1, P2, P3, P5, P6
- [ ] Explore / profile / favorites / reviews: X1–X6 (likely X2)
- [ ] Signup and mode switch: S1, S3–S7
- [ ] Expert mode: E1–E8, E11–E18 (likely E14)
- [ ] Chat: H1–H9 (H7 needs backend, H8 needs re-test)
- [ ] Push: N1–N4 (N1 needs backend)
- [ ] Settings / profile / account: T1–T7
- [ ] Backend fixes still open: K6, K7, K15 and Q2 refund retry (BACK-19) are deployed but await real-money checks in Phase 4; K8 and K13 are not delivered (wave 3c parked until SIGN-06)
- [ ] Backend: handle card removal made inside Stripe's PaymentSheet (T-01-32 accepted risk; must ship before the iOS release)
- [ ] EXPL-07: Explore loads when a featured topic has no currency (fix built; device check in Phase 4)

### Out of Scope

- Deliberate Android deviations D1–D9 (loading standard, optimistic favorites, booking IDs on rows, private note on details, etc.) — product choices, not iOS bugs; port later only if wanted
- Already-fixed items P7, E9, E10, T9 and the by-design P8/P9 config — nothing to do (rotate the preview JWT separately if it was ever shared)
- Android code changes — Android is a separate project; this project keeps backend changes compatible with the current Android build and logs any Android follow-ups instead
- P4 (3DS cancel toast), S2 (optional province), S8 (password digit rule), T8 (remember-login-email) — by-design differences, unless the related decision (Q1/Q5) moves them in

## Context

- **Source inventory:** `.planning/IOS-BUG-INVENTORY.md` (117 rows: 76 BUG, 4 LIKELY, 5 FIXED, 14 BY-DESIGN, 18 BACKEND), built 2026-11-07 from `ClickMe_Android/.planning/STATE.md`, the Android phase files and `16-BUG-LOG.md`, and checked against iOS `main` and the backend. Originating todo: `ClickMe_Android/.planning/todos/pending/2026-11-02-sync-android-bug-fixes-to-ios.md`.
- **Codebase map:** `.planning/codebase/` (architecture, stack, conventions, testing, concerns), mapped 2026-11-07.
- **C1 was confirmed on a production iPhone on 2026-11-02.** Most other items come from code reading during the port and still need device confirmation.
- **Decline-reason 422 (from the todo) is already fixed server-side** (backend `075fe81`, `784aa07`).
- **Three repos:** iOS (`ClickMe2026`, this repo), backend (`../ClickMe2026 Backend`, Node/Express/Supabase, owns the API contract), Android (`../ClickMe_Android`). The backend owns the contract: check `openapi/clickme-api.yaml`, `docs/SOCKET-CONTRACT.md`, `src/routes` and `src/schemas` before changing `Network/` or `Model/`.
- **Testing today:** unit tests cover only auth endpoints; UI-test page objects reference accessibility IDs that don't exist yet (`.planning/codebase/TESTING.md`).
- **Release config:** `Environments.plist` is set to Production on `main`, and all environments point at the production Railway backend.

## Constraints

- **Tech stack**: SwiftUI, Swift 6 strict concurrency, iOS 18+, Xcode 26 — the existing app, no rewrites
- **Backend compatibility**: Backend changes must be additive or otherwise safe for the current Android build — both clients share the REST contract
- **Cross-repo commits**: Backend fixes are committed in the backend repo, one commit per repo per change; never assume the other repo already has it
- **Release**: One iOS release at the end of the project; no hotfix build in between (user decision 2026-11-07), no fixed date
- **Definition of done**: Unit tests where the logic is testable, a clean `xcodebuild` with no new warnings, a device check on a real iPhone via a UAT checklist, and backend tests for backend changes
- **Production data**: The backend is the live production one; payment and refund changes need care (real holds and charges)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Fix every BUG and LIKELY item, not just critical/major | Minor items are mostly small and group with the majors in the same area | — Pending |
| Ship one iOS release at the end, not a hotfix first | User choice 2026-11-07, even though C1 is live in production | — Pending |
| All 18 backend items in scope | User choice; several iOS fixes (N1, H7, B7) depend on them | — Pending |
| Backend changes stay compatible with current Android | Android launches ~2026-12-13 on the same API | — Pending |
| Settle open product questions (inventory Q1–Q8) in each phase's discuss step | Decide with the code in front of the user, not up front | — Pending |

| Drop deploy wave 3c (BACK-08, BACK-13) | It would stop client-only accounts on App Store build 6 from becoming experts; no backend change may break the live build | ✓ Good — revisit with SIGN-06 |
| Defer real-money smoke checks to Phase 4 payment UAT | Avoid real holds now; mocked tests cover the logic | — Pending (backlog 999.1, 999.2) |
| Backend guard for the Explore free-topic decode failure | Build 6 can't get an iOS fix until release | ✓ Good — migration applied 2026-11-09 |

### Open product questions (settle in the affected phase's discuss step)

- Q1 Merge `feature/remember-login-email` (iOS `b0629d9`)?
- Q2 Expert cancel: always a full refund, or the backend's 24 h rule? (E13, B8)
- Q3 Long-lead SCA recovery on iOS, or just route the push as Android does? (B15)
- Q4 Dismissed payment sheet with a preselected card: cancel or confirm? (P1)
- Q5 Optional province and a gated Expert-mode switch? (S2, S7)
- Q6 Fix dead iOS pushes via backend `category` for iOS or by extending the iOS parser? (N1)
- Q7 Delete or wire in `CancellationPoliciesView` and `ReadyToStartCallView`? (T7)
- Q8 Re-test H8 ("Read" label) on a device before planning it

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-11-09 after Phase 1*
