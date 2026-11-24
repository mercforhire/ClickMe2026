---
phase: 08-release
review: 08-REVIEW.md
created: 2026-11-23
open: 15
---

# Phase 8 code review disposition

Build 1.1 (7) was submitted from 1fdcc26 before this review, so no finding can change the shipped build. Every row starts open until the user rules.

| Finding | Severity | Title | Disposition |
|---|---|---|---|
| CR-01 | critical | `run-smoke-tests.sh` exits 0 when the smoke tests fail | open |
| WR-01 | warning | A failed review-context fetch on first load offers "Leave a Review" for an already-reviewed booking | open |
| WR-02 | warning | "Message Expert" runs in an unstructured `Task` that is never cancelled, so it can open a chat after the user has left | open |
| WR-03 | warning | An untouched price is sent back as stored minor units even after the currency picker changed | open |
| WR-04 | warning | Workflows run with default token permissions, and secrets-bearing jobs use mutable third-party action tags | open |
| WR-05 | warning | A manual run uploads to TestFlight by default from any ref, and a newer push can cancel an upload in progress | open |
| WR-06 | warning | Secrets are inlined into shell scripts, and signing material is never cleaned up | open |
| WR-07 | warning | The "no new warnings" gate has false negatives and breaks on a relative `WORK` | open |
| IN-01 | info | Redundant prefix/digits round trip in the topic card price label | open |
| IN-02 | info | `.gitignore` does not cover `.DS_Store` or build and signing artifacts, and four `.DS_Store` files are tracked | open |
| IN-03 | info | The chat event time formatter comment promises a "·" that the template drops | open |
| IN-04 | info | Booking Summary builds two `DateFormatter`s per call and uses fixed patterns | open |
| IN-05 | info | `ChatItemMapper` repeats the same constructor seven times and can render an event row as a blank bubble | open |
| IN-06 | info | Smaller CI and script hygiene items | open |
| IN-07 | info | `startChat` treats any HTTP 404 as "expert unavailable", and the second branch is largely redundant | open |
