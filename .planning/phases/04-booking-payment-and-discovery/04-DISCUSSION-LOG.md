# Phase 4: Booking, Payment and Discovery - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-11
**Phase:** 04-booking-payment-and-discovery
**Areas discussed:** Q4: dismissed card sheet, Timeout retry landing, Request Sent and Back, Favorites and dead profiles (plus folded todos)

---

## Todo folding

| Option | Description | Selected |
|--------|-------------|----------|
| Card removal (backend) | T-01-32 backend fix, own plan and deploy | ✓ |
| Android push prompt | Android-only reinstall check | ✓ |
| Suspension on cold launch | Auth fix, `wasSuspended` unread | ✓ |

**User's choice:** fold all three.

---

## Q4: dismissed card sheet

| Option | Description | Selected |
|--------|-------------|----------|
| Cancel, no hold | Android parity; only Continue confirms; SDK `didCancel` | ✓ |
| Add our own Pay step | In-app summary plus Pay button after the sheet | |
| Keep confirming | Today's iOS behavior | |

| Option | Description | Selected |
|--------|-------------|----------|
| Silent reset | Stay on form, slot kept, no message | ✓ |
| Short toast | "Payment wasn't completed. No charge was made." | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| One combined session | PAY-01/02 plus 01-17 and 01-19 real-card checks; release every hold | ✓ |
| Phase 4 items only | Leave BACK-06/07/15/19 pending | |
| Mocks only for now | No real holds until release | |

| Option | Description | Selected |
|--------|-------------|----------|
| Own plan, deploy first | Backend fix deployed before the device session, which also tests it | ✓ |
| Own plan, test later | Real-card check in the release pass | |
| Investigate only | Confirm the route, fix later | |

---

## Timeout retry landing

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-retry, then Request Sent | Same PI, 1–2 retries, then error with Try again | ✓ |
| Error with Try again | No auto retry | |
| Send to My Bookings | Skip retrying | |

| Option | Description | Selected |
|--------|-------------|----------|
| Point to My Bookings | Only after a timed-out or abandoned confirm for the same expert and slot | ✓ |
| Always mention My Bookings | Every paid SLOT_UNAVAILABLE | |
| You decide | | |

---

## Request Sent and Back

| Option | Description | Selected |
|--------|-------------|----------|
| No Back; buttons only | Hide Back, disable swipe | ✓ |
| Replace the form | Back returns to the expert profile | |
| Back to tab root | Pop the whole flow | |

| Option | Description | Selected |
|--------|-------------|----------|
| Reset all stacks, go to Explore | Reset source tab; Home → Explore, My Bookings → Bookings | ✓ |
| Return to the source tab | Stay on Search or Profile | |
| You decide | | |

---

## Favorites and dead profiles

| Option | Description | Selected |
|--------|-------------|----------|
| Infinite scroll | Pages of 20; same pattern for Reviews | ✓ |
| Raise limit to 100 | One call | |
| You decide | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Message + Back only | No retry on 404; network error gets Retry | ✓ |
| Also offer Remove from Favorites | | |
| Auto-remove from Favorites | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Bookings tab, past list | Explore Experts → Explore; View My History → past bookings | ✓ |
| Bookings tab, default view | | |
| Drop View My History | | |

---

## Folded todo handling

| Option | Description | Selected |
|--------|-------------|----------|
| Suspension: repro, then fix | | |
| Suspension: fix from code, no repro | Unit test; device check at release | ✓ |
| Android push: device check, Android commit | | |
| Android push: check only, fix later | Record the result; any fix becomes a todo | ✓ |

## Claude's Discretion

- PAY-02 transport-failure detection, retry count and spacing; whether the D-04 record survives a relaunch.
- Undiscussed clear-cut items: BOOK-02..05, EXPL-04, PAY-03 copy, PAY-04.
- Pro Tip copy says "heart" (matches the profile icon); not asked.

## Deferred Ideas

- Android parity follow-ups for the behavior changes; any Android push-prompt fix becomes a new todo.
