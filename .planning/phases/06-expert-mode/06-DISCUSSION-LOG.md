# Phase 6: Expert Mode - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-16
**Phase:** 06-expert-mode
**Areas discussed:** Topic currency picker, Midnight end time, Hub online dot, Accept → Confirmed flow

---

## Topic currency picker

| Option | Description | Selected |
|--------|-------------|----------|
| Segmented control | CAD / USD toggle by the price field; Android gets a SegmentedButton | ✓ |
| Menu on the price prefix | Tap 'CA$' to choose | |
| Separate 'Currency' row | Row that opens a picker sheet | |

| Option | Description | Selected |
|--------|-------------|----------|
| Paid locked, free selectable | Matches backend TOPIC_CURRENCY_LOCKED | ✓ |
| Always read-only on edit | Picker only on create | |

| Option | Description | Selected |
|--------|-------------|----------|
| Keep the number, revalidate | No conversion; floor and hint update | ✓ |
| Clear the price | Forces re-entry | |

| Option | Description | Selected |
|--------|-------------|----------|
| pricing_limits default, else CAD | Android D-10 | ✓ |
| Always CAD | Ignore server default | |
| Last currency used | Needs local storage | |

**User's choice:** all recommended options.

---

## Midnight end time

| Option | Description | Selected |
|--------|-------------|----------|
| Keep 23:30 cap | Matches Android, no backend risk | ✓ |
| Allow 24:00 as '12:00 AM' | Needs backend proof and an Android change | |

| Option | Description | Selected |
|--------|-------------|----------|
| Clamp to 23:30 | Disabled when start is 23:00 or later | ✓ |
| Disable when it won't fit | Only enabled when the full block fits | |

| Option | Description | Selected |
|--------|-------------|----------|
| Insert it as a selected row | Exact stored value shown checked; nothing changes | ✓ |
| Snap to the nearest grid time | Next save silently changes the schedule | |

**User's choice:** all recommended options.

---

## Hub online dot

| Option | Description | Selected |
|--------|-------------|----------|
| Remove it | Android D-06 never ported it | ✓ |
| Bind to socket connection | Connectivity indicator; new behavior | |

---

## Accept → Confirmed flow

| Option | Description | Selected |
|--------|-------------|----------|
| Copy Android | Confirmed replaces Request Decision; Back to Home → refreshed Dashboard | ✓ |
| Confirmed as a sheet | Modal over Request Decision | |

| Option | Description | Selected |
|--------|-------------|----------|
| Alert, then refreshed list | Android D-07 | ✓ |
| Inline error, stay on screen | | |

| Option | Description | Selected |
|--------|-------------|----------|
| '{Topic} with {Client name}' | | ✓ (then refined) |
| 'Session with {Client name}' | | |
| Match Android exactly | | |

Follow-up: Android's title is "ClickMe · {topic} with {client name}".

| Option | Description | Selected |
|--------|-------------|----------|
| Match Android exactly | Same string both platforms, no Android change | ✓ |
| No prefix, change Android | | |

---

## Todo cross-reference

Folded: "Availability settings: pin the nav bar dark so the Save button stays legible" (same screen as EXP-05/06/07).

## Claude's Discretion

- Segmented control and read-only note placement and styling.
- Wording of the "Add hours" disabled state.
- Ordering of an inserted off-grid row.

## Deferred Ideas

- More currencies than CAD and USD.
- A 24:00 end time, only if a backend test proves slot generation handles it.
