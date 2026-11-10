---
phase: "02"
slug: "shared-ios-plumbing"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-11-10"
---

# Phase 02 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Register built from the `<threat_model>` blocks of plans 02-01 through 02-15 and the `## Threat Flags` sections of their SUMMARY files (all report no new flags). Verified at ASVS L1 depth (grep and read of the implementation and tests); no auditor run was needed because no threat was open after classification.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| app timer to call session | A local rule ends a paid session the user is in | Session lifetime (paid time) |
| app to POST /bookings/:id/end | The app reports the leg duration the server records | actual_duration, end_reason |
| expert-supplied meeting URL to client UI | An expert types the link; the client sees a provider label and opens it | Untrusted URL |
| Agora SDK worker thread to main actor | Connection state crosses into UI state | Call connection state |
| socket server to RealtimeService | Untrusted event payloads drive screen refreshes | booking.update payloads |
| socket server and REST responses to booking screens | Event-driven refetches can complete out of order | Booking data |
| app display gate to POST /bookings/:id/join | The Join button is a hint; the server authorizes | Join eligibility |
| server amounts to client display | Integer minor units and an ISO code become the price a client agrees to pay | Prices (financial) |
| server earnings fields to expert display | Some fields are minor units, some major | Earnings (financial) |
| expert bookings list to Client Profile history | Amount shown as what a booking with this client was worth | Earnings (financial) |
| app to POST /bookings/payment-intent and /bookings/confirm | Paid booking creation places a real hold on live Stripe | Payment intent, hold |
| app to PATCH /client/bookings/:id/reschedule | A paid reschedule can convert the payment model server-side | Reschedule slot, payment model |
| server error body to UI | Server message text is shown when no copy is mapped | Error strings |
| notification payload or row metadata to navigation | Category strings and ids from the server choose a screen | Untrusted category, ids |
| APNs/FCM payload to the app | Untrusted strings choose a mode and a screen | userInfo, target_role |
| app mode to server authorization | Mode and target_role are hints; the server authorizes every fetch | Role/mode |
| foreground push to presentation | The app decides whether a user is told about a message | Banner suppression |
| app to DELETE /notifications/tokens/:device_id | Needs the old account's live bearer | Bearer, device id |
| app to Firebase Messaging | deleteToken invalidates this install's FCM token | FCM token |
| shared device between accounts | One person's pushes must not reach the next person | Push content (PII) |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-02-01 | Denial of service | MeetingCallViewModel overtime cutoff | high | mitigate | `CallOvertimePolicy.cutoff = 60 * 60` (`ClickMe2026/Utils/CallOvertimePolicy.swift:34`), pinned by `CallOvertimePolicyTests.swift:31`; cutoff calls `CallCenter.shared.endCall()` (`MeetingCallViewModel.swift:542-544`); no temporary constant remains | closed |
| T-02-02 | Repudiation | /end actual_duration | low | mitigate | `endDuration` returns nil with no join start, else `max(1, …)` (`CallOvertimePolicy.swift:64-67`); used at `MeetingCallViewModel.swift:726` | closed |
| T-02-29 | Information disclosure | /end failure log in handleEndCall | low | mitigate | `#if DEBUG` print of booking id and `error.userMessage` only (`MeetingCallViewModel.swift:735-737`) | closed |
| T-02-03 | Spoofing | ExternalMeetingProvider.detect | medium | mitigate | Lowercased exact or dotted-suffix host match (`ExternalMeetingProvider.swift:30-60`); hostless strings are `.unknown`; lookalike matrix in `ClickMe2026Tests/Calls/ExternalMeetingProviderTests.swift:38` | closed |
| T-02-04 | Denial of service | call screen after a terminal Agora failure | low | mitigate | `.failed` maps to `.disconnected` (`AgoraManager.swift:44-50`), which runs `endAfterConnectionFailure()` (`MeetingCallViewModel.swift:269-273`) | closed |
| T-02-05 | Repudiation | end_reason on /end | low | mitigate | Agora `.disconnected` maps to nil (`AgoraManager.swift:38-49`); tested in `ClickMe2026Tests/Calls/AgoraConnectionMappingTests.swift` | closed |
| T-02-06 | Denial of service | RealtimeService booking.update decode | medium | mitigate | Tolerant decode to `.unknown` (`ClickMe2026/Model/Enums/BookingStatus.swift:38-40`); `ClickMe2026Tests/Model/BookingStatusDecodingTests.swift` | closed |
| T-02-07 | Tampering | status-driven UI (strips, lists, badges) | low | mitigate | `.rescheduled` and `.unknown` named explicitly in each switch (e.g. `ExpertDashboardViewModel.swift:378`, `UpcomingBookingsViewModel.swift:218,244`, `ClientProfileViewModel.swift:138`, `BookingSummaryViewModel.swift:358`, `ExploreClientViewModel.swift:165`) | closed |
| T-02-27 | Tampering | overlapping refetches on expert Upcoming Bookings | medium | mitigate | `ReloadGeneration` (`ClickMe2026/Utils/ReloadGeneration.swift`) guards at `UpcomingBookingsViewModel.swift:146,169,193`; `ClickMe2026Tests/Utils/ReloadGenerationTests.swift` | closed |
| T-02-08 | Elevation of privilege | JoinWindow treated as authorization | low | accept | Doc states display gate only (`ClickMe2026/Utils/JoinWindow.swift:25-26`); server keeps the gate (BACK-09). See AR-01 | closed |
| T-02-09 | Denial of service | Join hidden while the server would accept | medium | mitigate | Inclusive edges and `serverCanJoin` reconnect tier (`JoinWindow.swift:68-81`); `ClickMe2026Tests/Utils/JoinWindowTests.swift` | closed |
| T-02-10 | Repudiation (pricing) | client price display | medium | mitigate | Integer-only `Money.format(minorUnits:currency:)` (`ClickMe2026/Utils/Money.swift:102`); zero-decimal set matches backend `src/utils/earnings.js:25` (`Money.swift:34`); `MoneyTests.swift` | closed |
| T-02-11 | Spoofing (currency) | currency symbol | medium | mitigate | Fixed symbol table with `CA$` for CAD (`Money.swift:40,64`); no `Locale` or `NumberFormatter` in code (grep: comment mention only at line 20) | closed |
| T-02-12 | Repudiation (earnings) | expert money sites | medium | mitigate | Named entry points per unit; `MoneyCallSiteTests.swift:24,38,55` pin `1250` minor as `$12.50` and `75.0` major as `$75.00` | closed |
| T-02-30 | Tampering | TopicEditorViewModel price seed and validate() | high | mitigate | Lossless seed and stored minor/currency kept for untouched saves (`TopicEditorViewModel.swift:147-219`); seed currency from the topic's stored currency (`:159-172`); `MoneyCallSiteTests.swift:67-74` asserts 12550 USD round-trip | closed |
| T-02-13 | Tampering (financial) | long-lead fall-through to a confirm without a PaymentIntent | high | mitigate | No-PI confirm path removed; `completePaidBooking` requires `paymentIntentId` (`MakeABookingViewModel.swift:497-503`); long-lead codes terminal (`BookingErrorMapper.swift:64`); `BookingErrorCopyParityTests.swift:128-150` assert no `/bookings/confirm` | closed |
| T-02-14 | Tampering | server message shown in the alert | low | accept | Plain Text render; branching on `ErrorCode` only. See AR-02 | closed |
| T-02-15 | Tampering (financial) | paid reschedule beyond 6 days | low | mitigate | Local refusal before any request (`RescheduleViewModel.swift:301-307`); 422 `RESCHEDULE_TOO_FAR_AHEAD` mapped (`BookingErrorMapper.swift:26,66`; `ErrorCode.swift:138`) | closed |
| T-02-16 | Denial of service | unregistered HomeRoute on a tab stack (CR-01) | high | mitigate | Exactly one `navigationDestination(for: HomeRoute` and `homeStack(` used per tab in `HomeClientView.swift` and `HomeExpertView.swift` (grep counts 1 registration each); device check in `02-DEVICE-UAT-CHECKLIST.md` | closed |
| T-02-17 | Tampering | crafted category or id in a payload or row | low | mitigate | Destination table lowercases and returns nil for unknown categories or missing ids (`PushRouter.swift:250-300`); `ClickMe2026Tests/Push/PushDestinationTableTests.swift` | closed |
| T-02-18 | Tampering | PushEvent parse of untrusted userInfo | medium | mitigate | `target_role` only `client`/`expert` else nil (`PushEvent.swift:114-117`); ids via `UUID(uuidString:)` (`:136`) | closed |
| T-02-19 | Elevation of privilege | push-driven switch into expert mode | medium | mitigate | `canUseExpertMode` requires `.expert` role and `setupCompleted == true`; nil counts as no (`PushRouter.swift:101-104`) | closed |
| T-02-20 | Information disclosure | tap routed while signed out or into the next account | medium | mitigate | `handleTap` drops taps without a stored session (`PushRouter.swift:174-178`); queue cleared on logout (`UserManager.swift:418`) | closed |
| T-02-28 | Elevation of privilege | expert-mode decision made while roles are unknown | medium | mitigate | `planPending` loads roles and returns nil while they are unknown or the tap was superseded (`PushRouter.swift:202-218`) | closed |
| T-02-22 | Repudiation | suppressed banner for a chat that is not on screen | low | mitigate | Suppression only for `message` with exact thread match (`PushForegroundPolicy.swift`); presence clears only its own thread (`ChatPresence.swift:41-42`); `PushForegroundPolicyTests.swift`; tab-switch case is a device check | closed |
| T-02-23 | Information disclosure | old account's pushes after logout | high | mitigate | `signOut` order: bounded DELETE with live bearer, marker, clear session, bounded `deleteToken` (`PushTokenCleanup.swift:81-92`, 3 s default timeout); retry at launch and login (`UserManager.swift:185,224,266`); order, timeout and failure tests in `PushTokenCleanupTests.swift:65-222`. Offline residual window accepted (AR-03) | closed |
| T-02-24 | Spoofing | credential kept after logout for a retry | high | mitigate | Retry is `deleteToken` only, marker is a plain Bool (`PushTokenCleanup.swift`, test at `PushTokenCleanupTests.swift:138`); `clearLocalSession` clears bearer and refresh credentials (`UserManager.swift:401-420`) | closed |
| T-02-25 | Tampering | token re-registered to the old account during logout | high | mitigate | `isLoggingOut` guards in `registerPushToken` (`UserManager.swift:662`) and `fetchAndUploadFCMToken` (`:740`); login/signup await `retryPushCleanupIfNeeded().value` before registering (`:185,224`) | closed |
| T-02-26 | Information disclosure | tokens in logs | low | mitigate | New phase logging (`UserManager.swift:663-664,741-742`) is DEBUG-only with `push:` prefix and prints no token | closed |
| T-02-32 | Tampering | overlapping refetches on client booking screens | medium | mitigate | `ReloadGeneration` guards in `UpcomingBookingViewModel.swift:159,163`, `BookingSummaryViewModel.swift:185-204`, `MyBookingsViewModel.swift:119,156,171` | closed |
| T-02-31 | Denial of service | Join hidden on the Explore or dashboard strip | medium | mitigate | Both strips call `JoinWindow` inside a 60 s `TimelineView` (`ExploreTodaysSessionsSection.swift:88-89`, `ExpertDashboardView.swift:486-494` passing `actions.canJoin`); no symmetric-hour join rule found app-wide | closed |
| T-02-33 | Repudiation (earnings) | ClientProfileBookingCard amount label | low | mitigate | `Money.format(major:currency:)` with `"—"` for unknown (`ClientProfileBookingCard.swift:22-26`) | closed |
| T-02-SC-01 … T-02-SC-15 | Tampering | npm/pip/cargo installs (one per plan 02-01 … 02-15) | low | accept | No packages installed or upgraded in any plan. See AR-04 | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-02-08 | JoinWindow is a display gate only; POST /join keeps the two-tier gate and status check server-side (BACK-09) | Plan 02-04 threat model | 2026-11-10 |
| AR-02 | T-02-14 | Server-authored error strings are rendered as plain Text; branching is on `ErrorCode` only | Plan 02-07 threat model | 2026-11-10 |
| AR-03 | T-02-23 (residual) | After an offline logout where DELETE and every deleteToken attempt fail, the old account's pushes can reach the device until the next launch/login retry, FCM reports the token dead, or another login evicts the row | User decision D-17 (documented in `PushTokenCleanup.swift:36-42`) | 2026-11-10 |
| AR-04 | T-02-SC-01 … T-02-SC-15 | No dependency installs or upgrades in phase 02 | Plan threat models 02-01 … 02-15 | 2026-11-10 |

*Accepted risks do not resurface in future audit runs.*

### Informational (outside the register, non-blocking)

- `ClickMe2026/Managers/UserManager.swift:678` and `:769` print the first 24 characters of the FCM token inside `#if DEBUG`. These lines predate phase 02 (commit `06ae139`, 2026-10-15) and are DEBUG-only, so they are not a T-02-26 regression. Consider dropping the token prefix in a later phase to match the project logging rule.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-11-10 | 46 | 46 | 0 | gsd-secure-phase (orchestrator, ASVS L1 short-circuit) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-11-10
