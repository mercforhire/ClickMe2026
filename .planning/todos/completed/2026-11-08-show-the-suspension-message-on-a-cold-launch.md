---
created: 2026-11-09T04:46:57.475Z
title: Show the suspension message on a cold launch
area: auth
severity: minor
files:
  - ClickMe2026/Managers/UserManager.swift:34
  - .planning/quick/261108-vrh-prompt-for-push-permission-on-every-sign/261108-vrh-SUMMARY.md:58
---

## Problem

On a cold launch, a suspended account appears to reach the dashboard with its session cleared, and never sees the suspension message. `tryAutoLogin` still returns `true` after a 403 `ACCOUNT_SUSPENDED`, and nothing outside `UserManager` reads `wasSuspended` (confirmed by search on 2026-11-08), although the comment in `UserManager` says the login or splash view shows it.

This comes from reading the code. It was not reproduced on a device. Found during quick task 261108-vrh.

## Solution

TBD. Reproduce first. Then make the splash or login route read `wasSuspended`, show the message, and stop routing to home. If behavior changes, check whether Android needs a matching change.

## Resolution

Done in plan 04-07 (D-13), commits 404f95c and a48c5a4: `tryAutoLogin` resolves a suspension to signed out through `AutoLoginOutcome`, and Login shows the alert once. Fixed from the code, with no device repro first. The device check on a real cold launch is in the Phase 8 release pass (UI-SPEC D4).
