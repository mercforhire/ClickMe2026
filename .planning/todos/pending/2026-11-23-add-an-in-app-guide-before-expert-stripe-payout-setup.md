---
created: 2026-11-23T18:30:25.111Z
title: Add an in-app guide before expert Stripe payout setup
area: expert-payouts
severity: minor
files:
  - ClickMe2026/Views/Screens/Expert Mode/Payouts/PayoutsView.swift:493
  - ClickMe2026/Views/Screens/Expert Mode/Payouts/Subviews/ConnectOnboardingSession.swift
  - ClickMe2026/Views/Screens/Expert Mode/Expert Dashboard/ExpertDashboardView.swift:99
  - ClickMe2026/Views/Screens/Expert Mode/Expert Dashboard/ExpertDashboardView.swift:547
  - ../ClickMe2026 Backend/docs/ios/STRIPE-INTEGRATION.md (§3, Phase 24 Connect onboarding)
---

## Problem

The user (2026-11-23) finds the Stripe Connect payout setup for experts long, and worries it scares experts off. Today the expert sees only `PayoutsView.onboardCard`: "Complete payout setup" / "Verify your identity and connect a bank account to start receiving your earnings." and a **Continue** button. Continue opens Stripe's hosted Canada Express onboarding in an `ASWebAuthenticationSession` (`ConnectOnboardingSession`) with no explanation of what is coming. The Expert Dashboard's payout CTA (`payoutOnboardingRequired`, "Couldn't open payout setup") leads into the same flow. An expert who drops out cannot take paid bookings (paid topics 422 `EXPERT_NOT_BOOKABLE`; free topics still work).

**Timing (user choice 2026-11-23: "In-app, next release"):** not in 1.1. Build 1.1 (7) is frozen in the TestFlight regression; any iOS change there means build 8 and a full rerun (D-09). Build this after 1.1 ships.

## Solution

Not built. A short step-by-step guide shown before Continue (both entry points), iOS first, then Android parity (`ClickMe_Android` mirrors the folder tree):

- What Stripe will ask for: identity document, personal details and address, bank account for payouts.
- Roughly how long it takes, and that it can be left and resumed (expired link: refresh endpoint in STRIPE-INTEGRATION.md §3).
- Why ClickMe uses Stripe, and that ClickMe never sees the ID or bank details.
- What happens after: `currently_due` non-empty shows a "finish verification" CTA that reopens onboarding; done shows "You're ready to receive payouts".
- Optionally a "don't show again" or a compact version on re-entry.

Before writing copy, check Stripe's current Canada Express onboarding requirements (they change), and the onboarding states in backend `docs/ios/STRIPE-INTEGRATION.md` §3. No backend change expected. Unit-test any state logic that picks guide vs. direct Continue; device-check both entry points.
