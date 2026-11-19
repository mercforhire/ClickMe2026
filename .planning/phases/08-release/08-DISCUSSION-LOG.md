# Phase 8: Release - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-19
**Phase:** 8-Release
**Areas discussed:** Release-ready bar, Unverified backend items, Backend deploy order, Build and submission (plus the todo fold)

---

## Release-ready bar

| Option | Description | Selected |
|--------|-------------|----------|
| Run all or record a skip | Every remaining Phase 3 and 4 item either passes on a device or gets a recorded skip reason | |
| Money and call items only | Only call, booking and payment items must run; the rest are deferred with a reason | |
| Regression run replaces them | Skip the remaining checklist items and rely on the final regression run | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Skip with reason | Mark VoiceOver items skipped and list them as known untested | |
| Test before release | Someone runs the VoiceOver items | |
| Drop them from checklists | Remove the VoiceOver steps entirely | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Major and above | Fix blocker and major gaps; minor or cosmetic gaps may be deferred with a reason | ✓ |
| All gaps | Every open gap is fixed | |
| Blockers only | Fix blockers; defer the rest | |

| Option | Description | Selected |
|--------|-------------|----------|
| TestFlight, full mix | The TestFlight RC with a small real CAD charge: paid and free in-app voice plus one Skype/Zoom session, with an Android peer | ✓ |
| TestFlight, paid voice only | One paid in-app voice session | |
| Xcode build first | An Xcode Release build first, then a light TestFlight check | |

**Follow-up:** Claude flagged that this amends REL-01 and roadmap criterion 1. The user chose "Amend, next area".

---

## Unverified backend items

| Question | Options | Selected |
|----------|---------|----------|
| BACK-06/07/19 smokes | Fold into regression / Separate smoke first / Defer with reason | Fold into regression |
| BACK-08 | Defer like BACK-13 / Ship it alone / Ship after the new build | Defer like BACK-13 |
| BACK-15 | Close on mocks / Production API test / Leave pending | Close on mocks |
| A real-money check fails | Stop, fix, re-run / Submit if backend-only / Decide case by case | Stop, fix, re-run |

---

## Backend deploy order

| Question | Options | Selected |
|----------|---------|----------|
| Deploy from | iOS-only line / Full master / Review then decide | iOS-only line |
| Timing | As fixes land, then freeze / One final deploy / Before any iOS work | As fixes land, then freeze |
| Safety check | Tests plus a live smoke / Tests and contract diff / Tests only | Tests plus a live smoke |
| Who deploys | You push, I prepare / Claude pushes on approval | Claude pushes on approval |
| Cherry-pick of 94d659b conflicts | Rebuild on main / Stop and ask | Rebuild on main (asked a second time: the first prompt was answered "More questions" without a choice) |
| Migrations | Schema first / Same deploy / No migrations | Schema first |
| Master merge (D-12 todo) | After App Store approval / During Phase 8 / Not this project | During Phase 8 |
| Rollback | Previous /health commit / Revert commits | Previous /health commit |

**Context given:** production `/health` = `28da165` (`origin/main`). Backend `master` is 2 commits behind and 17 ahead, including the non-iOS Phase 31 and 32 work and the one-way legacy-ledger drop migration.

---

## Build and submission

| Question | Options | Selected |
|----------|---------|----------|
| Version | 1.1 (build 7) / 1.0.1 (build 7) | 1.1 (build 7) |
| Build path | CI release branch / Xcode Organizer | CI release branch |
| TestFlight | Internal testers only / Internal, then external | Internal testers only |
| Rollout | Phased over 7 days (recommended) / Manual, then immediate / Immediate on approval | Immediate on approval (chose against the recommendation) |
| What's New text | Claude drafts, you edit / You write it | Claude drafts, you edit |

---

## Todo fold

First answer: "Backend release gates, Backend data/contract fixes, Android parity follow-ups, None", which contradicted itself. Asked again: "Backend release gates, Backend data/contract fixes, Android parity follow-ups". All three groups are folded.

## Claude's Discretion

- How the work is grouped into plans and waves; the layout of the regression checklist; the chat-reason rendering design within the existing patterns.

## Deferred Ideas

- BACK-08 and BACK-13 past this release; the proposal push wording (minor) may be deferred; the proposed time in the `BOOKING_RESCHEDULED` event; phased release not used.
