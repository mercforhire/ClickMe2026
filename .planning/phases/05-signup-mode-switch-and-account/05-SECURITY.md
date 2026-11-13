---
phase: "05"
slug: "signup-mode-switch-and-account"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-11-13"
---

# Phase 05 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| App process -> device Keychain | Remembered login email written and read via Valet | PII (email) |
| API DELETE /user/account -> client state | Successful deletion must clear local PII tied to the account | PII, session state |
| Photo library -> app -> POST /user/profile/avatar | User-picked image re-rendered and uploaded as the public avatar | Image bytes, EXIF metadata |
| client -> PATCH /expert/profile/setup | Profile fields, tag/language ids, publish flag; server validates | Profile data |
| client -> PATCH /notifications/preferences | Preference rows for the signed-in user | User settings |
| client -> POST /feedback/submit | Free text from the user | User content |
| app -> mail client | mailto URL leaves the app | Support address |
| app copy -> user consent | Deletion and refund policy copy is a disclosure the user acts on | Policy claims |
| iOS mode gate -> /expert/* routes | iOS gate is UX only; server `ensureExpert` authorizes | Role / mode |
| push / foreground -> mode switch and setup hub | Background triggers must not promote accounts or interrupt a live call | Mode, navigation |
| leaf screen -> shell navigation | Environment action resets stacks and selects a tab | Navigation only |
| device storage -> next session | Setup deferral flag in UserDefaults across launches | Per-account flag |
| planning docs -> other teams | UAT checklist and todos shared with the Android port | Copy, codes, paths |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-05-01 | Information disclosure | Remembered email after account deletion | medium | mitigate | `DeleteAccountViewModel.swift:131` forgets email only after DELETE succeeds; `RememberedLoginEmailTests.swift:89-134` | closed |
| T-05-02 | Information disclosure | Email written to UserDefaults or logs | medium | mitigate | Valet `.whenUnlocked` (`UserManager.swift:65-68`); key used only with Valet (`:156,:503,:515`); no UserDefaults/print use | closed |
| T-05-03 | Information disclosure | Next person on shared device sees previous email | low | accept | See Accepted Risks AR-05-01 | closed |
| T-05-04 | Tampering | Client-chosen tag order decides primary tag | low | accept | See AR-05-02 | closed |
| T-05-05 | Information disclosure | EXIF GPS in uploaded signup avatar | medium | mitigate | `ProfilePhotoCropper.swift:46-56,74-83` re-renders via `UIGraphicsImageRenderer`; non-vacuous GPS test `ProfilePhotoCropperTests.swift:188-217` | closed |
| T-05-06 | Denial of service | Very large picked image | low | mitigate | `ProfilePhotoCropper.swift:25,28,73,83` (1024 px, JPEG 0.85); test `:117-123` | closed |
| T-05-07 | Tampering | Client publish pre-check bypassed | low | accept | See AR-05-03 | closed |
| T-05-08 | Tampering | Malformed country code reaching server | low | mitigate | `SignupAccumulator.swift:111,234,241` (`Countries.normalize`); tests `SignupAccumulatorTests.swift:137,145` | closed |
| T-05-09 | Tampering | Notification prefs written without a user change | medium | mitigate | `NotificationSettingsViewModel.swift:115,127,148` snapshot guard; `NotificationSettingsAutoSaveTests.swift:69,98,112` | closed |
| T-05-10 | Tampering | Feedback length check bypassed on client | low | accept | See AR-05-04 | closed |
| T-05-11 | Spoofing | Support mail to wrong/lookalike address | low | mitigate | `SupportContact.swift:17,21`; exact-value test `SupportContactTests.swift:19`; no other Swift file spells it | closed |
| T-05-12 | Repudiation | Policy copy promising refunds/timing backend does not give | medium | mitigate | `CancellationConfirmCard.swift:34`; client copy matches backend `refund.js:39-47` and FAQ migration; expert-cancel wording deferred (see Notes) | closed |
| T-05-13 | Tampering | Dead code paths with stale call logic | low | accept | See AR-05-05 | closed |
| T-05-14 | Elevation of privilege | Treating iOS gate as authorization | medium | transfer | Backend `src/middleware/ensureExpert.js:63-116` on all 37 `/expert/*` routes, mounted after `authenticate` (`src/routes/index.js:75`) | closed |
| T-05-15 | Information disclosure | Setup deferral leaking to next account | medium | mitigate | `UserManager.swift:484` `setupDeferral.clear()` in `clearLocalSession()`; reached by `logout()` and `forceLogout()` | closed |
| T-05-16 | Elevation of privilege | Client-only account promoted to expert without asking | high | mitigate | `UserManager.swift:722-730` lookup only behind `target == .expert`; callers `ModeSwitchGate.swift:34` and role-gated push handlers (`PushRouter.swift:101-104,127-131,211`) | closed |
| T-05-17 | Repudiation | Deletion copy claiming removal the backend does not do | high | mitigate | `AccountDeletionCopy.swift:26-36` checked against backend `accountCascade.js` and `account.controller.js`; `AccountDeletionCopyTests.swift:30-52` | closed |
| T-05-18 | Spoofing | Deletion without re-authentication | high | mitigate | `DeleteAccountViewModel.swift:107-127` fresh token per attempt, never cached; retry test `DeleteAccountViewModelTests.swift:158-175` | closed |
| T-05-19 | Information disclosure | Blocker alert revealing booking details | low | accept | See AR-05-06 | closed |
| T-05-20 | Tampering | Full-replace PATCH deleting custom languages | medium | mitigate | `ClientProfileSettingsViewModel.swift:327-328`, `ExpertProfileSettingsViewModel.swift:333-334`; `ProfileLanguagesSaveTests.swift` | closed |
| T-05-21 | Tampering | Unknown language id rejected (422) | low | accept | See AR-05-07 | closed |
| T-05-22 | Elevation of privilege | View bypassing gate to enter Expert mode | medium | mitigate | `UserManager.swift:584` `private func setMode`, `:49` `private(set) currentMode`; no external callers | closed |
| T-05-23 | Denial of service | Mode switch during a call | medium | mitigate | `ModeSwitchGate.swift:33` on all four Mode Switch mounts; backstop `UserManager.swift:719` | closed |
| T-05-24 | Elevation of privilege | Launch/login lookup promoting client-only account | high | mitigate | `UserManager.swift:823-838` behind `ExpertModeGate.swift:111-113,123-125`; `ExpertModeGateTests.swift:221-226,272-278` | closed |
| T-05-25 | Spoofing | Client-side verified flag | low | accept | See AR-05-08 | closed |
| T-05-26 | Elevation of privilege | Foreground re-check promoting client-only account | high | mitigate | `UserManager.swift:678-690`, `ExpertModeGate.swift:179`; test `ExpertModeGateTests.swift:313-318` | closed |
| T-05-27 | Denial of service | Lookup on every foreground | low | mitigate | `UserManager.swift:675-677,694`, `ExpertModeGate.swift:176`, `ClickMe2026App.swift:59-63` | closed |
| T-05-28 | Information disclosure | Secrets/PII in checklist or todos | low | mitigate | Ban stated at `05-DEVICE-UAT-CHECKLIST.md:18`; scan found no tokens, keys, card numbers or personal emails | closed |
| T-05-29 | Information disclosure | Expert-shell bookings action | low | accept | See AR-05-09 | closed |
| T-05-30 | Denial of service | Mode switch applied during a live call | medium | mitigate | `UserManager.swift:719` first statement, `:734` re-check; `ExpertModeGate.swift:87`; tests `ExpertModeGateTests.swift:123-149` | closed |
| T-05-31 | Denial of service | Push tap switching mode mid-call or lost when refused | medium | mitigate | `.blockedByCall` keeps tap queued (`HomeClientView.swift:195`, `HomeExpertView.swift:145`); replay on call end (`:167-169`, `:116-118`) | closed |
| T-05-32 | Denial of service | Foreground re-check opening setup hub over a live call | medium | mitigate | `UserManager.swift:693` call guard after lookup, before flag clear (`:694`) and hub request (`:697`) | closed |
| T-05-SC | Tampering | npm/pip/cargo/SPM installs | low | accept | See AR-05-10 | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-05-01 | T-05-03 | Remembered email on a shared device is by design (D-14); password is never stored or prefilled | plan 05-01 threat model | 2026-11-13 |
| AR-05-02 | T-05-04 | Tag order is the user's own intent; server validates every tag id and caps the list (BACK-11) | plan 05-02 threat model | 2026-11-13 |
| AR-05-03 | T-05-07 | Publish pre-check is UX only; server 422 `missing_fields` remains the enforcer | plan 05-04 threat model | 2026-11-13 |
| AR-05-04 | T-05-10 | Server `details: z.string().min(10)` and feedback rate limit (BACK-16) stay authoritative | plan 05-05 threat model | 2026-11-13 |
| AR-05-05 | T-05-13 | Unreachable screen deleted; recoverable from git. Spot check: `Call/Ready/` gone, no `ReadyToStart` references | plan 05-17 threat model | 2026-11-13 |
| AR-05-06 | T-05-19 | Blocker copy names no booking, person or amount (`AccountDeletionBlocker.swift:59-67`) | plan 05-08 threat model | 2026-11-13 |
| AR-05-07 | T-05-21 | Language ids come only from `GET /meta/languages`; server validates | plan 05-09 threat model | 2026-11-13 |
| AR-05-08 | T-05-25 | Verified flag is display only and set true only from a server response | plan 05-11 threat model | 2026-11-13 |
| AR-05-09 | T-05-29 | Action only resets navigation and selects a tab in the signed-in expert shell; no data carried | plan 05-14 threat model | 2026-11-13 |
| AR-05-10 | T-05-SC | No packages installed or upgraded; `Package.resolved` unchanged across phase 5 commits | plans 05-01..05-17 | 2026-11-13 |

*Accepted risks do not resurface in future audit runs.*

---

## Out-of-Scope Notes (not counted)

The auditor reported these. They are outside the declared threat scopes and do not block this phase:

1. Settings avatar uploads (`ClientProfileSettingsViewModel.swift:242`, `ExpertProfileSettingsViewModel.swift:196`) skip `ProfilePhotoCropper`. If `jpegData` fails, the raw picked bytes are uploaded and could carry GPS. This predates the phase and is excluded by `05-03-PLAN.md`.
2. The expert cancel screen still says "within 3–5 business days" (`ExpertCancellationMainCard.swift:38`). T-05-12 defers this to Phase 6, but no Phase 6 item in ROADMAP.md or REQUIREMENTS.md tracks it. Add a todo.
3. The account email is in the UserDefaults cached profile while signed in (`UserManager.swift:562`). It is cleared on sign-out. This predates the phase.
4. In debug builds, `#if DEBUG` request-body logging prints the login and delete-request passwords (`NetworkService.swift:250-254`). This predates the phase.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-11-13 | 33 | 33 | 0 | gsd-security-auditor (via /gsd-secure-phase, verify:post hook) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-11-13
