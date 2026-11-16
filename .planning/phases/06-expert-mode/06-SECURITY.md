---
phase: "06"
slug: "expert-mode"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-11-16"
---

# Phase 06 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Expert app → backend topic API | Topic create/PATCH/DELETE (price, currency, icon, description) | Money amounts and currency (high: wrong charge) |
| Expert app → backend booking-request API | Accept/decline with an optional message | Booking state, free-text message (medium) |
| Expert app → backend note API | Private booking note save (owner-scoped endpoint) | Private free text (medium) |
| Expert app → device calendar (EventKit editor) | Calendar event from a confirmed booking | Client name, topic, client message (low; expert's own device) |
| Android app → backend `/me` | `pricing_limits.allowed_currencies` read (additive) | Currency list (low) |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-06-01 | Denial of service | Topic price parse | medium | mitigate | `TopicPriceRules.filterInput` / `parseMinor` integer arithmetic, 7-digit cap; 20-digit test rows (`ClickMe2026/Utils/TopicPriceRules.swift`) | closed |
| T-06-02 | Tampering | Topic amount and currency on save | high | mitigate | One parser (`TopicPriceRules.parseMinor`) used by both the hint and Save in the topic editor; currency lock kept; server `PRICE_BELOW_MINIMUM` / `TOPIC_CURRENCY_LOCKED` authoritative | closed |
| T-06-03 | Tampering | `UpdateExpertTopicRequest` encoding | medium | mitigate | `NullableField` three-state encoding in `ClickMe2026/Model/Requests/ExpertTopicRequest.swift`; omit/set/null rows in `ExpertTopicRequestBodyTests` | closed |
| T-06-04 | Tampering | One-tap topic delete | low | mitigate | "Delete this topic?" confirmation alert; DELETE only from its destructive button; 0-DELETE rows in `TopicsSetupMutationTests` | closed |
| T-06-05 | Tampering | Availability schedule edits | low | mitigate | Draft copy committed only by Done; `AvailabilitySlotRules.addHours` clamps at 23:30; stored off-grid values inserted, never snapped | closed |
| T-06-06 | Information disclosure | Calendar event notes carry the client's message | low | accept | See Accepted Risks Log | closed |
| T-06-07 | Tampering | Double accept / replay | medium | mitigate | `isSubmitting` guard and `popsOnDismiss` on 409 in `RequestDecisionViewModel.swift`; one-POST concurrency row | closed |
| T-06-08 | Denial of service | Oversized accept message | low | mitigate | `cappedAcceptMessage` at 1,000 UTF-16 units, matching backend `acceptSchema` | closed |
| T-06-09 | Spoofing | Navigation driven by server message text | low | mitigate | Branches on `.alreadyProcessed` error code only; SLOT_UNAVAILABLE 409 row proves status alone does not pop | closed |
| T-06-10 | Repudiation | Always-online hub presence dot | low | mitigate | No `isOnline` state in `ExpertProfileHomeViewModel.swift` (grep: 0) | closed |
| T-06-11 | Information disclosure | Private note text in logs | medium | mitigate | No `print`/`Logger`/`os_log` in the Booking Note files (grep: 0) | closed |
| T-06-12 | Denial of service | Oversized note rejected after Save | low | mitigate | 5,000 UTF-16 cap via `UTF16Prefix` in `ExpertBookingNoteViewModel.swift`, matching `noteSchema` | closed |
| T-06-13 | Information disclosure | Short booking ID on the expert's Booking Summary | low | accept | See Accepted Risks Log | closed |
| T-06-14 | Tampering | Android topic currency on edit | high | mitigate | Paid-edit lock in Android `TopicEditorViewModel.kt` (`onCurrencyChange` ignored when locked; test row); picker disabled with caption; server `TOPIC_CURRENCY_LOCKED` authoritative (Android commit `da498620`) | closed |
| T-06-15 | Denial of service | Android `/me` decode on older server | low | mitigate | `allowedCurrencies: List<String>? = null` in Android `MeData.kt`; decode row in tests | closed |
| T-06-16 | Information disclosure | Credentials in the device UAT checklist | low | mitigate | Checklist Setup forbids tokens, passwords, card numbers and real emails; grep finds only that prohibition sentence | closed |
| T-06-SC | Tampering | Dependency installs (SPM / Gradle) | low | accept | See Accepted Risks Log | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-06-01 | T-06-06 | The client's message reaches only the system calendar editor on the expert's own device, which the expert reviews before saving; the app sends, logs and stores nothing; no location is written | plan 06-04 (planning) | 2026-11-16 |
| AR-06-02 | T-06-13 | Only the first 8 characters of an id the expert's own API responses already carry, shown to that booking's own expert | plan 06-08 (planning) | 2026-11-16 |
| AR-06-03 | T-06-SC | No package added or upgraded in Phase 6: `Package.resolved` unchanged; Android commit `da498620` touches no Gradle file | all plans (planning) | 2026-11-16 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-11-16 | 17 | 17 | 0 | secure-phase (L1 grep, orchestrator; auditor skipped per short-circuit: plan-time register, ASVS 1, 0 open) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-11-16
