# Phase 2: Shared iOS Plumbing - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-09
**Phase:** 02-shared-ios-plumbing
**Areas discussed:** Q3: long-lead SCA recovery, Push tap and mode switch, Join button and overtime end, Money display format

---

## Pending todos

| Option | Description | Selected |
|--------|-------------|----------|
| Fold neither | Neither is push routing; both stay pending | ✓ |
| Fold suspension message | Add the cold-launch suspension fix | |
| Fold Android push prompt | Add the Android device check | |

## Q3: long-lead SCA recovery

| Option | Description | Selected |
|--------|-------------|----------|
| Route only | Open booking detail, as Android does; no recovery flow | ✓ |
| Route + build recovery | Confirm payment via recover-payment with 3D Secure | |
| Route + explain only | Static notice, no recover-payment call | |

**User's choice:** Route only

## Push tap and mode switch

| Question | Options | Selected |
|----------|---------|----------|
| target_role differs from the current mode | Switch silently / Ask first | Switch silently |
| target_role expert but the account can't use expert mode | Stay, open notifications / Switch anyway | Stay, open notifications |
| Where the destination opens | Owning tab's stack / Sheet over current tab | Owning tab's stack |
| Logout unregister fails | Log out anyway, retry later / Log out anyway, no retry / Block logout on failure | Log out anyway, retry later |

## Join button and overtime end

| Question | Options | Selected |
|----------|---------|----------|
| What decides Join visibility | Local CALL-02 rule + reconnect via can_join / Local rule only / Server can_join only | Local CALL-02 rule + reconnect via can_join |
| Cutoff at end + 60 | Warn 5 min before, then end / Just end | Warn 5 min before, then end |

## Money display format

| Question | Options | Selected |
|----------|---------|----------|
| Whole amounts | Always show cents ($12.00) / Drop .00 ($12) | Always show cents |
| Currency symbol | Disambiguated (CA$12.50) / Device locale / Plain $ for both | Disambiguated |
| Scope | Formatter + every call site / Formatter + client sites only | Formatter + every call site |

## Claude's Discretion

- Unknown booking status: refetch the booking and show a neutral label
- One shared booking error mapper, with the paid path's copy as the base
- 6-day cap: hide the slots beyond it, rather than showing them disabled
- Cold-launch push taps, the full destination table, CHAT-09 suppression by thread_id
- CALL-04, CALL-05 and CALL-09 implementation details; where the helpers live

## Deferred Ideas

- Long-lead SCA recovery UI (Q3 = route only)
- Topic price input decimals and currency (Phase 6)
- Expert-mode setup gate (Phase 5)
