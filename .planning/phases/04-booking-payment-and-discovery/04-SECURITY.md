---
phase: "04"
slug: "booking-payment-and-discovery"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-11-12"
---

# Phase 04 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Stripe -> /webhooks/stripe | Internet-facing, unauthenticated except for the HMAC signature | Payment-method events (`pm_` ids) |
| cron -> Stripe (off-session charge) | Moves real money with no client present | PaymentIntents, card ids — high |
| cron -> bookings (cancel path) | A cancel releases the slot and notifies both parties | Booking status — high |
| app -> POST /bookings/confirm | Authorizes funds on the expert's connected account; the outcome can be lost in transit | PaymentIntent and `pm_` ids — high |
| backend replay (BACK-15) -> app | A replayed 201 for the same PaymentIntent, scoped to the caller | Booking record |
| backend -> build 6 and current Android | Shared live API; only server-side behavior may change | REST contract |

---

## Threat Register

53 distinct threats (T-04-SC appears in all 17 plans). Verified against current code: iOS `main`, backend `ios-p4-d12` at `28da165` (= production).

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-04-01 | Tampering | longLeadChargeSweep.chargeOne charging a card the client removed (T-01-32) | high | mitigate | Platform-card retrieve before any clone or PaymentIntent; detached, missing or foreign card takes cancelAndRelease; tests assert no createManualPI or confirmPIOffSession | closed |
| T-04-02 | Spoofing | Forged payment_method.detached event | medium | mitigate | Existing constructEvent HMAC-SHA256 check with 300 s tolerance runs before dispatch; the new case adds no unauthenticated path; a forged id could only evict clones of a pm_ that is already detached at Stripe | closed |
| T-04-03 | Repudiation | Replayed or duplicated webhook deliveries | low | mitigate | stripe_events primary-key claim and read cache absorb repeats; eviction of zero rows is a no-op that still stamps processed | closed |
| T-04-04 | Denial of service | Wrongful cancel of a paid booking on a transient Stripe error | high | mitigate | Only resource_missing counts as gone; every other retrieve error is re-thrown, the row stays scheduled and the 6 h window is the backstop; a test row asserts no cancel — superseded by T-04-42 (CR-02, 04-16): errors now re-throw before the stamp | closed |
| T-04-05 | Denial of service | Deploy breaking App Store build 6 or current Android | high | mitigate | Server-only change; no response, route, code or push change; full backend suite in the D-12 worktree before the push; the user pushes one gated SHA after seeing the commit and its files; rollback base recorded as `ios-p4-d12-rollback` | closed |
| T-04-06 | Information disclosure | PaymentMethod ids in logs | low | mitigate | Webhook log records a count only; the sweep logs the booking id only | closed |
| T-04-07 | Denial of service | A persistent eviction error retried forever by the drain cron | low | accept | The drain warns past its attempt threshold (ops-visible); eviction errors are rare and the sweep guard still protects charges | closed |
| T-04-36 | Tampering | The D-12 deploy shipping unreviewed backend Phase 31 code (pushing master) to the production backend build 6 depends on | high | mitigate | D-12 is built on `ios-p4-d12` from origin/main in its own worktree, never on master; Task 3's pre-push gate (`git log origin/main..ios-p4-d12 --name-only` and `git diff --name-only origin/main ios-p4-d12`: one commit, six files) and the user's one-line command, which re-checks the rollback base, the ancestry, the one-commit count and the exact sorted six-file list before it pushes, refuse anything else; the push names the D-12 SHA as a fast-forward of main, never --force; the post-deploy check proves `ios-p4-d12-rollback..origin/main` is exactly that commit and those files; the route (a or b) is the user's choice before any push | closed |
| T-04-37 | Denial of service | A later backend deploy from master dropping D-12 and reopening T-01-32 | medium | mitigate | Git refuses a non-fast-forward push of master; the pending todo says master must merge origin/main (never rebase or force-push) and keep both `ios-p4 D-12` describes passing, and that `/health` must contain the D-12 commit before the D-11 session and the Phase 8 release | closed |
| T-04-SC | Tampering | npm/pip/cargo installs (all 16 plans) | low | accept | No package added or upgraded (RESEARCH Package Legitimacy Audit: none); `npm ci` in the worktree reinstalls origin/main's committed lockfile, the packages production runs (identical to master's lockfile at revision time) | closed |
| T-04-08 | Tampering | presentSheet completion confirming after a close (an unintended real hold) | high | mitigate | didCancel overload plus PaymentSheetOutcome.proceeds; truth-table tests; the D-11 session checks the Dashboard for no requires_capture PaymentIntent | closed |
| T-04-09 | Denial of service | Stripe Link dismissing the sheet without a usable result (stuck spinner or dropped card) | low | mitigate | config.link.display = .never (D-16) | closed |
| T-04-10 | Tampering | Resubmitting the booking form after Request Sent (duplicate request or a second hold attempt) | medium | mitigate | Back hidden, both pop recognizers locked, exits reset the source stack; the backend's DUPLICATE_BOOKING and confirm replay remain the server-side backstop | closed |
| T-04-11 | Denial of service | A Request Sent state with no exit (client trapped) | medium | mitigate | Exits pinned in loading and error states; source assertion counts three action placements | closed |
| T-04-12 | Tampering | Stale month response overwriting the displayed month (client books a slot that is not offered for that month) | low | mitigate | ReloadGeneration token and month check before every write; the server still rejects an unavailable slot with SLOT_UNAVAILABLE | closed |
| T-04-13 | Spoofing | Zone label naming a different zone than the chip or Today's Sessions times (client books or joins at the wrong hour) | medium | mitigate | Both labels are the device zone from DateUtil.zoneName(), the zone DateFormatter formats in; IANA id and expert zone never shown; unit tests with explicit locales; grep gate on the Today's Sessions label (D-18) | closed |
| T-04-14 | Information disclosure | Distinguishing a suspended from a deleted expert | low | accept | The server returns the same 404 NOT_FOUND for both and the app shows the same copy; no new disclosure | closed |
| T-04-15 | Tampering | A late details response overwriting the client's in-flight favorite toggle | low | mitigate | The heart is written only when no toggle is in flight and only by the current ReloadGeneration token | closed |
| T-04-16 | Denial of service | Repeated Retry taps flooding /details | low | mitigate | retry() ignores taps while isRetrying; one request per tap | closed |
| T-04-17 | Denial of service | Unbounded or looping page requests | low | mitigate | One request at a time (isLoadingMore), stop on has_more false, a 500 on a later page ends the list | closed |
| T-04-18 | Tampering | Duplicated or skipped rows after an offset shift | low | mitigate | Dedupe by expertId; reload from page 1 after an unfavorite while more pages remain | closed |
| T-04-19 | Elevation of privilege | A suspended account shown a home shell on cold launch | medium | mitigate | AutoLoginOutcome maps a suspension to signedOut; tryAutoLogin returns false; the token was already cleared by the suspension handler (ASVS V3) | closed |
| T-04-20 | Information disclosure | Suspension alert content | low | accept | Copy names only the public support address; no account detail is shown | closed |
| T-04-21 | Tampering | A second PaymentIntent or second hold from a retry after an unknown outcome | high | mitigate | Same PI, same pm_ and same booking_attempt_id on every retry; resetPaidFlow and newBookingAttempt never run on the unknown path; tests assert the request bodies and the unchanged attempt id | closed |
| T-04-22 | Repudiation | Client cannot reconcile a charge after a lost confirm | low | mitigate | The alert shows "Payment reference: {pi_id}" (pi_ only, never pm_, client secret or ephemeral key) | closed |
| T-04-23 | Denial of service | Retry loop holding the screen for minutes on a black-holed network | low | accept | Bounded to 3 attempts; 120 s per-request timeout unchanged and recorded as a known limit; airplane mode fails fast | closed |
| T-04-24 | Tampering | Double submit from the alert and Book Now | medium | mitigate | paidStep stays .confirming while the alert is up; retryConfirm guards on a stored pm_ and .confirming; test row | closed |
| T-04-35 | Tampering | A 409 PAYMENT_IN_PROGRESS on confirm dropping the PaymentIntent, so the next Book Now creates a second PaymentIntent while the first may still settle into a hold (D-17) | high | mitigate | ErrorCode.paymentInProgress is in ConfirmOutcome.outcomeUnknownCodes: same PI, pm_ and booking_attempt_id, bounded retries, then the confirm-unknown alert; test rows assert the request bodies and the unchanged attempt id | closed |
| T-04-25 | Repudiation | Telling the client a hold or charge happened, or is coming, when it did not or will not (or the reverse) | medium | mitigate | Pure chooser over booking status, payment_status and authorization_expires_at, with the CancelRefundPreview live-hold rule. Charged copy only for captured. Charge-scheduled copy only for none on a pending_approval, pending_reschedule or confirmed booking. Held without a live expiry, none on any other status, and unknown values hide the card. Table tests and stubbed view-model tests both include the held-with-null-expiry and cancelled-none rows | closed |
| T-04-26 | Denial of service | A tab left holding a stale Favorites stack after an exit | low | mitigate | HomeShellExit resets the source tab; invariant test row | closed |
| T-04-27 | Denial of service | Unbounded or looping review page requests | low | mitigate | PagedList one-at-a-time guard, has_more stop, 500-as-end | closed |
| T-04-28 | Repudiation | A seeded heart that disagrees with the server | low | mitigate | The seed is used only from Favorites; plan 04-05's details load replaces it with is_favorite | closed |
| T-04-29 | Information disclosure | IDOR through detail.booking_id | low | mitigate | The server returns the id only for the caller's own active booking (T-01-28); the app parses it as a UUID and Request Sent loads it through GET /client/bookings/:id, which re-checks ownership (ASVS V4) | closed |
| T-04-30 | Repudiation | "Slot taken" shown for the client's own unconfirmed booking | medium | mitigate | Ledger-backed D-04 copy and the D-15 route; the record survives SLOT_UNAVAILABLE and 409 PAYMENT_IN_PROGRESS (keepsRecord, D-17); test rows for matching and non-matching cases and for PAYMENT_IN_PROGRESS | closed |
| T-04-31 | Information disclosure | Session ledger seen by another account on the same device | low | accept | Only hedged copy or a server-scoped id can result; the ledger holds expert id and start time, no payment data | closed |
| T-04-32 | Tampering | A real hold or charge left in place after the session | high | mitigate | Ordered session with the 01-17 booking rule (2 to 5 days out, never joined or rescheduled) and an end-state table that must show every PaymentIntent released or refunded | closed |
| T-04-33 | Elevation of privilege | Claude touching production during the gate | medium | mitigate | Claude runs only local tests and builds; the migration check, deploys and holds are the user's steps (Phase 1 D-11) | closed |
| T-04-34 | Repudiation | Requirements marked done without a device check | low | mitigate | REQUIREMENTS.md checkboxes for EXPL-03, EXPL-07 and BACK-06/07/15/19 asserted unchecked | closed |
| T-04-38 | Tampering | completePaidBooking sending a changed topic or start time with the original PaymentIntent (CR-01) | medium | mitigate | PaidAttempt captured at PaymentIntent creation; every confirm reads only it; rows bookCreatesPaidAttempt, retryKeepsOriginalSelection, scaRetryKeepsOriginalSelection, formEditWhileConfirmRunsKeepsRequest; isConfirmRunning keeps one confirm at a time (secondConfirmWhileRunningIsRejected); the server's PI_CONTEXT_MISMATCH stays the backstop | closed |
| T-04-39 | Denial of service | A silent resetPaidFlow dropping the PaymentIntent and pm_ ids while a hold may exist, after a reload cleared the slot (CR-01) | high | mitigate | completePaidBooking guards only on paidAttempt; loadAvailability keeps the slot while isSubmitting; rows reloadDuringConfirmKeepsSlot and confirmWithoutAttemptMakesNoRequest | closed |
| T-04-40 | Repudiation | The D-04 record keyed on a changed slot, so a later DUPLICATE_BOOKING or SLOT_UNAVAILABLE misses it and the client books a second slot while the first hold exists | high | mitigate | Ledger record, clear and checks use paidAttempt.slot.startTime; row ledgerKeysOnPaidAttempt | closed |
| T-04-41 | Tampering | Form edits during Confirming making the screen disagree with the confirm and regenerating bookingAttemptId | medium | mitigate | .disabled(viewModel.isSubmitting) on the five input cards; row everyResetUnlocksTheForm proves the lock always lifts; device step d | closed |
| T-04-42 | Denial of service | A transient retrieve or profiles read error at the T-24h card check becoming a wrongful cancellation 6 h later (CR-02) | high | mitigate | Profiles read and card check moved above stampAttempt; either error is re-thrown and leaves off_session_attempted_at NULL (the profiles error no longer degrades to a null customer, see T-04-49); the two-run tests show the next run charges an attached card and scaRecoveryWindowSweep cannot select the row | closed |
| T-04-43 | Tampering | The reorder weakening stamp-before-charge, so two overlapping runs both cancel or both charge one booking | high | mitigate | One status- and NULL-guarded stampAttempt still precedes every Stripe write and the cancel; only read-only calls move above it; call-order and lost-claim rows | closed |
| T-04-44 | Denial of service | A persistent profiles read or card-check error retried every 5 minutes with no deadline, leaving a due booking neither charged nor cancelled; past the session start nothing cancels it (scaRecoveryWindowSweep needs a stamp), joining is gated on booking status only, and once the call connects or the session completes the long-lead sweep stops and the completion capture takes only requires_capture rows, so the session is delivered uncharged and the expert unpaid (a missed session settles with no charge) | medium | accept | Needs a Stripe outage or account fault on a valid saved pm_, or a profiles read fault while the bookings select and stamp still work, lasting from charge_due_at to the session; logged each run with the booking id (ops-visible); no client is charged wrongly or cut off; the outcome is re-checked against the shipped code and stated in full at Task 3 step 6, and the user must accept it ("limits accepted") before pushing; bounding it is recorded in the follow-up todo | closed |
| T-04-45 | Denial of service | Transient errors after the stamp still cancelling about 6 h later | medium | accept | Predates D-12 (Phase 26, backend D-08 single window); a safe fix needs a bounded design because a stamp reset after a Stripe write can strand an authorized PaymentIntent; tracked in .planning/todos/pending/2026-11-12-long-lead-sweep-transient-errors-after-stamp.md; comments and STRIPE-INTEGRATION.md now say so | closed |
| T-04-46 | Denial of service | The deploy breaking App Store build 6 or the current Android build | high | mitigate | Cron-only change in three files; no route, response, error code or push change; full backend suite and check-docs before the push; the user pushes one gated commit; rollback base `ios-p4-cr02-rollback` recorded | closed |
| T-04-47 | Tampering | The deploy shipping unreviewed backend master code | high | mitigate | Commit built on ios-p4-d12 from origin/main in the D12 worktree; Task 3's pre-push gate and the user's one-line command refuse anything but one commit with exactly the three files; master never pushed; never --force; post-deploy check of `ios-p4-cr02-rollback..origin/main` | closed |
| T-04-48 | Information disclosure | PaymentMethod ids in the moved log lines | low | mitigate | The moved warn line logs the booking id only (unchanged); the existing D-12 row asserting no pm_ id in that output keeps passing | closed |
| T-04-49 | Elevation of privilege | A profiles read fault, or a profile with no stripe_customer_id, skipping the D-12 ownership comparison so a card attached to another customer is cloned and charged off-session (checker iteration 2) | high | mitigate | The profiles read error is re-thrown before retrievePaymentMethod and stampAttempt with no null fallback; with a good read a missing stripe_customer_id counts as a mismatch, the same rule confirmLongLead applies at insert (booking.controller.js L1297); the profiles-error two-run it.each (attached, foreign, detached) and the no-stripe_customer_id row; Task 1's third gate checks the throw and the removed null skip | closed |
| T-04-50 | Denial of service | Explore stranded on skeletons after a cancelled fetch (G-04-3), blocking discovery and booking from Explore | medium | mitigate | `load()` awaits an unstructured `Task` running `fetchHome` (`ExploreClientViewModel.swift:82`), so the caller's cancellation never reaches URLSession; loaded sections are not swapped during a refresh; a cancelled fetch settles every section through `stateAfterCancelledFetch(current:before:)` (L125-129, L340), never `.idle`; `ClientHomeFeedTests` G-04-3 rows | closed |
| T-04-51 | Information disclosure | A raw system error ("cancelled") as section text, or stale Featured Topics beside section errors (EXPL-07) | low | mitigate | A cancelled first load shows `interruptedLoadMessage` = `NetworkError.invalidResponse.userMessage` (L327, L346); a test asserts no "cancel" text (`ClientHomeFeedTests.swift:536`); the failure branch still clears `featuredTopics` (L134) | closed |
| T-04-52 | Denial of service | Shielded fetches outliving the screen or overlapping (last to finish wins) | low | accept | One read-only GET per appear, pull or Retry, written only to the view model's published state; the completion-order race predates 04-17 and is recorded out of scope in 04-17-SUMMARY | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

Per-threat file:line evidence is in the gsd-security-auditor verdict of 2026-11-12; key points: card check and profiles read precede `stampAttempt` (`longLeadChargeSweep.js:301-342`); confirm retries read only the `PaidAttempt` snapshot (`MakeABookingViewModel.swift:542-609`); webhook HMAC precedes dispatch (`webhooks.controller.js:425-440`).

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-04-01 | T-04-07 | Stuck stripe_events rows only warn at 10 attempts (`stripeEventsDrain.js:179-183`) | Plan 04-01 | 2026-11-11 |
| AR-04-02 | T-04-14 | 404 reveals only that an expert id does not exist | Plan 04-05 | 2026-11-11 |
| AR-04-03 | T-04-20 | Suspension copy names only the support address | Plan 04-07 | 2026-11-11 |
| AR-04-04 | T-04-23 | Confirm retries bounded to 3 attempts at the 120 s timeout | Plan 04-08 | 2026-11-11 |
| AR-04-05 | T-04-31 | Ledger stores only expertId and start second | Plan 04-13 | 2026-11-11 |
| AR-04-06 | T-04-44 | Limits (a)/(b): a persistent profiles or card-check error retries every 5 min with no bound; past the start it can be delivered uncharged; no client charged wrongly | User (04-16 checkpoint) | 2026-11-12 |
| AR-04-07 | T-04-45 | Limit (c): errors after the stamp still cancel at ~6 h; tracked in todo 2026-11-12-long-lead-sweep-transient-errors-after-stamp | User (04-16 checkpoint) | 2026-11-12 |
| AR-04-08 | T-04-SC | No dependency changes in this phase (Package.resolved last changed before Phase 4; no backend lockfile change) | Plans 04-01..04-17 | 2026-11-11 |
| AR-04-09 | T-04-52 | Overlapping or post-dismiss Explore GETs are read-only and only write the screen's own view-model state; the completion-order race predates 04-17 | Plan 04-17 | 2026-11-12 |

---

## Audit Notes (do not reopen a threat)

1. `04-DEVICE-UAT-CHECKLIST.md` (lines 10, 20, 25, 335) still names `ae3ec1a` as production and `32fa6ec` as the rollback base; update to `28da165` / `ae3ec1a` before the D-11 session.
2. T-04-10 (gesture lock), T-04-32 and T-04-33 are closed on code or procedure; real-world proof is the device UAT and D-11 session.
3. WR-01 (3DS retry sending the clone `pm_`) is outside this register and still untriaged in `04-REVIEW-DISPOSITION.md`.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-11-12 | 50 | 50 | 0 | gsd-security-auditor (ASVS 1, block_on high) |
| 2026-11-12 | 53 | 53 | 0 | secure-phase L1 short-circuit after 04-17 (T-04-50..52 grep-verified; ASVS 1, block_on high) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-11-12
