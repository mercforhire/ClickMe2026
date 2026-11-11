---
phase: "03"
slug: "booked-sessions-and-joining"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-11-11"
---

# Phase 03: Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> The register was written when the 15 plans were authored (`register_authored_at_plan_time: true`). The gsd-security-auditor checked every mitigation on 2026-11-11 at ASVS L1, with `block_on: high`.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| iOS app → ClickMe backend REST | Client and expert actions: accept or decline a reschedule, cancel, reschedule, join, expert booking details | Booking ids, reasons and comments (user text), refund and payment state (money-affecting) |
| Backend → Stripe | Holds, captures and refunds behind cancel and reschedule (no change in this phase) | Payment state; only derived booleans reach the app |
| Expert- or server-authored text → client UI | Reschedule note, decline note and status strings rendered on the client | Untrusted text, rendered verbatim |
| App → external meeting URLs | Skype, Zoom, Meet and Teams links handed to the call path | URL host decides the provider label |
| Push or chat deep link → booking screens | Push-opened Upcoming details and Booking Summary actions | Booking id from the payload; the server checks ownership |
| Backend deploy → live App Store build 6 and Android | Additive change `65bb2ed` to GET /expert/bookings/:id/details | New optional JSON keys |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-03-01 | Tampering | RescheduleResponder accept/decline double-submit | medium | mitigate | `guard !isSubmitting` plus `defer` reset in `RescheduleResponder.swift`, and `.disabled(isSubmitting)` on the card. Test `concurrentAcceptSendsOnce` | closed |
| T-03-02 | Tampering | Expert note formatting injection | low | mitigate | `Text(verbatim: note)` in `RescheduleResponseCard.swift` | closed |
| T-03-03 | Information Disclosure | Decline reason and note logging | low | mitigate | No print, NSLog or Logger in the responder, card or booking view models (grep) | closed |
| T-03-04 | Spoofing | Refund preview on a skewed clock | medium | mitigate | `CancelRefundPreview` with strict 24 h, a 60 s TimelineView recompute and a recompute at the tap that blocks once. Tests `changedCaseBlocksOnce` and the 24 h boundary | closed |
| T-03-05 | Tampering | Double submit of Confirm Cancellation | low | mitigate | Submitting guard in `ClientCancellationViewModel` and a disabled button | closed |
| T-03-06 | Repudiation | Skype/Zoom copy implying an automatic end | low | mitigate | `skypeStatusText` ("Tap End Session"), the end+55 banner and an unchanged 60 min cutoff. `SkypeStatusTextTests` | closed |
| T-03-07 | Denial of Service | Expert Join hidden while the server would accept | medium | mitigate | `ExpertJoinVisibility` forwards to `JoinWindow.isOpen`, with a 60 s re-evaluation. Status matrix in `ExpertJoinVisibilityTests` | closed |
| T-03-08 | Elevation of Privilege | Join offered on cancelled, declined, missed or expired bookings | low | mitigate | `alwaysShownStatuses` and `joinableStatuses` allow-lists, covered by tests | closed |
| T-03-25 | Tampering | Expert proposes a paid slot more than 6 days ahead | low | mitigate | `PaidBookingWindow`, plus the select guard, submit refusal and dimming in `ExpertRescheduleViewModel`. `ExpertRescheduleWindowTests` | closed |
| T-03-09 | Information Disclosure | Raw payment columns in expert details | low | mitigate | The backend selects them as inputs only and returns only the derived keys. A test asserts the raw keys are absent (`tests/expertBooking.test.js`) | closed |
| T-03-10 | Denial of Service | Backend deploy breaking App Store build 6 or Android | high | mitigate | `65bb2ed` is additive only (0 deletions), and iOS decodes the keys as optional. 153 `expertBooking` tests pass. Deployed on the user's decision, and `/health` = `65bb2ed` | closed |
| T-03-26 | Repudiation | `payment_not_charged` false with no money held | medium | mitigate | Allow-list `MONEY_HELD_OR_TAKEN_PAYMENT_STATUSES`, false only with a PaymentIntent. Tests cover SCA pending, hold, captured, converted long-lead, free and failed | closed |
| T-03-11 | Spoofing | Success toast after a failed action | medium | mitigate | `toasts.show` runs only after an awaited 2xx in the responder, reschedule and cancel. Tests assert no toast on failure | closed |
| T-03-13 | Tampering | Decline note rendered as Markdown or links | low | mitigate | `Text(verbatim:)`. The raw code maps to a label and is never shown. Test `markupIsLiteral` | closed |
| T-03-15 | Repudiation | Expert told a refund happens when it does not | medium | mitigate | `ExpertCancelRefundLine` shows a money line only when both keys are present and false, and fails closed otherwise. `ExpertCancelRefundLineTests` | closed |
| T-03-27 | Repudiation | Default refund line reaching a screen no rule fed | low | mitigate | No default `refundLine` in any initializer (grep). The bootstrap passes `.none` | closed |
| T-03-16 | Spoofing | Lookalike meeting URL labelled as a trusted provider | medium | mitigate | `ExternalMeetingProvider` matches the exact host or a dotted subdomain, and a lookalike reads "Open Meeting". The card has no URL opener and goes through `CallCenter.startCall`. `ExternalMeetingProviderTests` | closed |
| T-03-17 | Denial of Service | Client Join disabled while the server would accept | medium | mitigate | `JoinWindow.isOpen` together with `canJoin`, with a 60 s TimelineView. `UpcomingBookingViewModelTests` | closed |
| T-03-18 | Tampering | Cancel reason over the server limit | low | mitigate | `CancelReasonComposer` caps the comment at 450 and the reason at 500. `UTF16Prefix` cuts on grapheme boundaries. `CancelReasonComposerTests` | closed |
| T-03-22 | Tampering | Booking Summary duplicate or divergent money action | medium | mitigate | Accept and decline API calls happen only in `RescheduleResponder`, which Booking Summary uses | closed |
| T-03-23 | Spoofing | Pill shows Confirmed for an unknown or other status | medium | mitigate | `BookingStatusPill` uses an exhaustive switch with no default, and `.unknown` is neutral. `BookingStatusPillTests` | closed |
| T-03-24 | Information Disclosure | Android short ID; unrelated files in the commit | low | mitigate | Android `0f2e8cd` touches exactly 2 files and uses `shortBookingId` | closed |
| T-03-12 | Information Disclosure | Toast read aloud by VoiceOver | low | accept | See the Accepted Risks Log | closed |
| T-03-14 | Information Disclosure | Booking ID shown and selectable | low | accept | See the Accepted Risks Log | closed |
| T-03-19 | Information Disclosure | Cancel comment visible to the expert | low | accept | See the Accepted Risks Log | closed |
| T-03-20 | Tampering | `exclude_booking_id` unblocking a slot | low | accept | See the Accepted Risks Log | closed |
| T-03-21 | Elevation of Privilege | Cancel or reschedule from a push for a booking the user does not own | low | accept | See the Accepted Risks Log | closed |
| T-03-SC-01 … SC-15 | Tampering | Package installs (one row per plan) | low | accept | No dependency manifest changed in iOS, backend `65bb2ed` or Android `0f2e8cd` | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low. Only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-03-01 | T-03-12 | The toast text is fixed status copy plus the user's own refund amount, with no third-party data | Plan-time threat model; auditor confirmed | 2026-11-11 |
| AR-03-02 | T-03-14 | The short booking ID grants no access, because the server checks ownership | Plan-time threat model; auditor confirmed | 2026-11-11 |
| AR-03-03 | T-03-19 | The cancel comment is stored (BACK-14) and shown to the expert, and the app never logs it. The field does not tell the client the expert sees it, which is flagged in `03-DEVICE-UAT-CHECKLIST.md` | Plan-time threat model; auditor confirmed | 2026-11-11 |
| AR-03-04 | T-03-20 | The app sends `exclude_booking_id` only for the booking being moved. The backend ignores a non-UUID value, and the id only filters the caller's month view. **Caveat:** the auditor found no slot-conflict hold (`holdSlotMulti` or a unique index) on the client reschedule or accept-reschedule paths, so expert approval is the visible gate. Do not rely on a server-side conflict check here | Plan-time threat model; auditor confirmed with caveat | 2026-11-11 |
| AR-03-05 | T-03-21 | The new push routes add no endpoint or id source. The client endpoints scope by `client_id` and return 404 when the booking is not the caller's | Plan-time threat model; auditor confirmed | 2026-11-11 |
| AR-03-06 | T-03-SC-01 … SC-15 | No packages were installed or upgraded in any plan | Plan-time threat model; auditor confirmed | 2026-11-11 |

*Accepted risks do not resurface in future audit runs.*

Notes (non-blocking):
- T-03-10 evidence covers `tests/expertBooking.test.js`, with 153 tests passing. The full backend suite was not run for this audit.
- Deploy evidence is `origin/main` containing `65bb2ed` and `/health` returning `{"status":"success","commit":"65bb2ed"}` on 2026-11-10.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-11-11 | 42 | 42 | 0 | gsd-security-auditor (ASVS L1, block_on high) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-11-11
