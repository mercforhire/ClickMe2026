# Phase 1: Backend Fixes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-07
**Phase:** 01-backend-fixes
**Areas discussed:** Push routing (Q6), Join window & rejoin, Expert promotion (BACK-13), Deploy & rollout, BACK-01 accept message, BACK-16 mark-read, Q2 refund policy

---

## Push routing (Q6)

| Option | Description | Selected |
|--------|-------------|----------|
| Backend category | BACK-17: send category/sub_category to iOS too; safe for build 6 | ✓ |
| Widen iOS parser only | Close BACK-17; cron pushes go to the notifications list | |
| Both | Backend category plus an iOS event_type fallback | |

| Option | Description | Selected |
|--------|-------------|----------|
| Add target role | `target_role: client\|expert` per recipient, both platforms | ✓ |
| iOS infers it | No new field; iOS derives the mode | |
| You decide | Researcher picks | |

**Notes:** All push senders already pass category/sub_category; only the Android-only branch in push.js blocks iOS.

---

## Join window & rejoin

| Option | Description | Selected |
|--------|-------------|----------|
| Two-tier | First join per CALL-02; reconnect (joined_at set) until end+60 | ✓ |
| Loose outer bound | Server allows [start-60, end+60] for everyone | |
| Exact CALL-02 | No reconnect after the scheduled end | |

| Option | Description | Selected |
|--------|-------------|----------|
| confirmed/in_progress/completed | Matches JOINABLE_STATUSES | ✓ |
| confirmed/in_progress only | Blocks reconnect after the end+15 cron | |

| Option | Description | Selected |
|--------|-------------|----------|
| Leave cron as is | Fixed price, so capture at end+15 is fine | ✓ |
| Defer while in a call | Sweep B skips live in_progress rows | |
| Extend grace to end+60 | Delays every capture by 45 min | |

---

## Expert promotion (BACK-13)

| Option | Description | Selected |
|--------|-------------|----------|
| PATCH /expert/profile/setup | Existing onboarding setup call promotes | ✓ |
| New POST /expert/activate | Dedicated endpoint; breaks shipped clients' onboarding | |

| Option | Description | Selected |
|--------|-------------|----------|
| Empty reads, 403 writes | Build 6 expert home shows empty; writes get EXPERT_SETUP_REQUIRED | ✓ |
| 403 on everything | Cleanest contract; build 6 shows errors | |
| You decide | Per-route choice by the researcher | |

| Option | Description | Selected |
|--------|-------------|----------|
| Leave them | No migration | ✓ |
| Demote via migration | One-off script on live auth metadata | |

---

## Deploy & rollout

| Option | Description | Selected |
|--------|-------------|----------|
| Risk-grouped batches | Additive → behavior → money/BACK-13 separately | ✓ |
| Deploy each fix as done | Every item live on merge | |
| One deploy at phase end | Single deploy | |

| Option | Description | Selected |
|--------|-------------|----------|
| I push it myself | Claude commits locally; the user pushes each wave | ✓ |
| Claude pushes after I approve | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Tests + device smoke list | Backend tests, contract tests, manual smoke on build 6 and Android | ✓ |
| Tests only | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Mocked tests + local test-mode run | | ✓ |
| Mocked tests only | | |

---

## Second round

| Question | Options | Selected |
|----------|---------|----------|
| BACK-01 accept message | Post as chat message / Show on booking / Drop it | Post as chat message |
| BACK-16 mark-read vs NOTIF-07 | Keep NOTIF-07, drop sub-item / Re-add read state | Keep NOTIF-07, drop sub-item |
| Q2 expert-cancel refund | Always full refund / Keep 24 h rule / Decide in Phase 3 | Always full refund (pulled into Phase 1) |

---

## Claude's Discretion

- Error code names/statuses for new 4xx responses; BACK-15 replay mechanism; BACK-05 currency mapping; shape of non-expert empty GET responses.

## Deferred Ideas

- Accidental-expert demotion / downgrade path (T-19-01)
- Notification read state
- Deferring the end+15 cron during overtime calls
- Android copy follow-up for the expert-cancel full refund
