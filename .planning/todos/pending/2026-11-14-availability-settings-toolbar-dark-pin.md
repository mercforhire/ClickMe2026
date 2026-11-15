---
created: 2026-11-15T04:50:00.000Z
title: "Availability settings: pin the nav bar dark so the Save button stays legible"
area: ui
severity: low
files:
  - ClickMe2026/Views/Screens/Expert Mode/Availability/AvailabilitySettingsView.swift
---

## Problem

This is the latent version of G-05-1 (the setup hub's illegible `Not now`), found by code read only. It has not been seen on a device.

- The trailing toolbar Save button (L61-65, and the `saveToolbarButton` builder around L244-266) uses `Brand.primary`, or `Brand.onSurfaceVariant` at 0.55 opacity when disabled. Both are dark-theme colours.
- The screen pins no bar colour scheme: `AvailabilitySettingsView.swift` has no `toolbarColorScheme` (0 at HEAD).
- It is pushed from `Expert Mode/Profile/ExpertProfileHomeScreen.swift` (L235) and `Expert Mode/Expert Dashboard/ExpertDashboardView.swift` (L237).

So on a phone in Light appearance with Reduce Transparency or Liquid Glass Tinted, the iOS 26 toolbar capsule behind Save likely turns light grey, the same way it did behind `Not now`.

## What to do

Apply the sibling pins used by plan 05-18 on the screen body: `toolbarBackground(Brand.surface, for: .navigationBar)`, `toolbarBackground(.visible, for: .navigationBar)` and `toolbarColorScheme(.dark, for: .navigationBar)`. Then check on a device in Light appearance with Reduce Transparency on, and again with Liquid Glass set to Tinted.

References: `.planning/debug/not-now-button-low-contrast.md` (root cause and the pixel evidence) and plan 05-18 (the fix on the setup hub).
