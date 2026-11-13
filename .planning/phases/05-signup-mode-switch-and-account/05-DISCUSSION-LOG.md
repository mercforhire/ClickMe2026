# Phase 5: Signup, Mode Switch and Account - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-13
**Phase:** 05-signup-mode-switch-and-account
**Areas discussed:** Expert-mode gate + BACK-13, Optional province, Delete Account wording, Dead screens + remember-email

---

## Pending todos (cross-reference)

| Option | Description | Selected |
|--------|-------------|----------|
| Fold none | Keep all three keyword-only matches as separate todos | ✓ |
| Fold some | Pick which to fold | |

---

## Expert-mode gate + BACK-13

**Switch to Expert with setup incomplete**

| Option | Description | Selected |
|--------|-------------|----------|
| Setup hub + Not now | Android D-17/D-27; Not now returns to Client, deferral remembered for the login | ✓ |
| Setup hub, no way out | No Not now | |
| Stay in Client + prompt | Alert with Continue setup | |

**Setup-status lookup fails**

| Option | Description | Selected |
|--------|-------------|----------|
| Let them into Expert | Fail open like Splash and Android | ✓ |
| Stay in Client + error | Block with Retry | |
| You decide | | |

**BACK-13**

| Option | Description | Selected |
|--------|-------------|----------|
| Defer past this release | Keep on wave-3c; iOS gate covers SIGN-06; record in REL-02 | ✓ |
| Ship it in a build-6-safe form | Additive backend change this phase | |
| Drop it permanently | Close as won't-fix | |

**Gate scope**

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, one shared check | Mode Switch, push switchToMode and Splash all gated | ✓ |
| Only the Mode Switch screen | | |
| You decide | | |

---

## Optional province

| Question | Options | Selected |
|----------|---------|----------|
| Province at signup | Make it optional / Keep it required | Make it optional |
| Display when empty | City, Country / City only / You decide | City, Country |
| Clearing a saved province | Yes, like Android / No, only change it | Yes, like Android |

---

## Delete Account wording

Context shown: self-delete is refused (409) with upcoming bookings or a session in progress; iOS lacks `CLIENT_HAS_UPCOMING_BOOKINGS`; the cascade tombstones the profile as "Deleted user", scrubs booking PII and keeps messages, reviews, reports and the payment audit.

| Question | Options | Selected |
|----------|---------|----------|
| Detail level | Short summary + 3 groups / One honest paragraph / Detailed + privacy link | Short summary + 3 groups |
| Upcoming-booking blockers | Yes, plus handle all three codes / Only handle the errors / Copy only | Yes, plus handle all three codes |
| Messages and reviews | Say it plainly / Fold into kept for records | Say it plainly |
| Android copy | Log a follow-up with final copy / Change Android in this phase | Log a follow-up with final copy |

---

## Dead screens + remember-email

| Question | Options | Selected |
|----------|---------|----------|
| CancellationPoliciesView | Wire into the cancel flow / Delete it / Link from Help only | Wire into the cancel flow |
| ReadyToStartCallView | Delete it / Keep and wire it in | Delete it |
| Q1 remember-login-email | Keep it out (recommended) / Merge it in this phase | **Merge it in this phase** (user overrode the recommendation) |
| More on Delete Account | No, it's covered / Yes, one more thing | No, it's covered |

**Notes:** after the Q1 choice, a check showed the branch is 405 commits behind main and conflicts in `UserManager.swift`, so CONTEXT D-14 says to port it rather than merge.

---

## Claude's Discretion

- Swift structure of the shared gate (single entry point required)
- Exact Delete Account wording within the agreed three-group structure
- Placement of the Cancellation policy link in the cancel confirmation

## Deferred Ideas

- BACK-13 backend change (after build 6 and current Android stop relying on implicit promotion)
- Android follow-ups: Delete Account copy, 409 codes, remember-login-email, cancellation-policy link
