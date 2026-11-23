---
created: 2026-11-23T23:30:00.000Z
title: "Android: CAD price shows no CA$ prefix (D-24 regression on the dev build)"
area: android
severity: minor
files:
  - ClickMe_Android app/src/main/java/com/uptrendinvestments/clickmeapp/util/Money.kt:62-79 (pinnedSymbol)
  - ClickMe_Android app/src/main/java/com/uptrendinvestments/clickmeapp/util/PriceDisplay.kt
  - ClickMe_Android commit 50626142 fix(ios-p8): show US$ and CA$ regardless of locale (D-24, D-32)
---

## Problem

Found in the 08-22 TestFlight regression, R8 step 2 (2026-11-23), on the Android dev build at `e311a74c`. On the page where A sees B's USD and CAD topics (an expert profile or Explore), Android shows `US$` for the USD price, but the CAD price has **no `CA$` prefix**. iOS 1.1 (7) shows both correctly. The Android phone's region is **Canada** (user, 2026-11-23), so CAD is the local currency there; this points at cause 3 below.

`Money.format` is meant to pin `USD -> US$` and `CAD -> CA$` by overwriting `DecimalFormatSymbols.currencySymbol` on the `NumberFormat.getCurrencyInstance(locale)` result.

## Solution

Not diagnosed. Possible causes to check:

1. **The CAD row skips `Money.format`.** It may go through `PriceDisplay.kt` or another formatter instead. Find which code that screen calls.
2. **The topic's currency is null or empty, so it falls back to a bare `$`.** Backend `412f1aa` sends null for a topic stored with no currency; check B's CAD topic row.
3. **Android ICU differs from the JVM.** On a device in en_CA, where CAD is the local currency, the `currencySymbol` override may be ignored or reset, while JVM unit tests pass.

Reproduce on the device first. Add a test that reproduces the cause (a Robolectric or instrumented test if it's ICU). Android only, local commits. It doesn't affect the iOS 1.1 build.
