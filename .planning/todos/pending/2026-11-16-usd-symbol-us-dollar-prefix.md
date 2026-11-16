---
created: 2026-11-16T00:00:00.000Z
title: "Decide how USD renders: `$` (shipped Money table) or `US$` (backend doc and topic editor label)"
area: ui
severity: low
files:
  - ClickMe2026/Utils/Money.swift
  - ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorView.swift
---

## Problem

Phase 6 research Open Question 3, left out of Phase 6 on purpose (no code change was made).

The backend doc `docs/ios/USD-TOPIC-PRICING.md` section 0 item 5 says USD renders as `US$` (CAD as `CA$`), and the server's own labels already do (`US$75.00 / session`). The shipped iOS `Money` symbol table (Phase 2 D-10, `ClickMe2026/Utils/Money.swift`, `"USD": "$"`) renders USD as `$`. The result is an inconsistency inside the iOS app:

- the topic editor's price label follows the selected currency and reads `Price per Session (US$)` for USD;
- the same topic's card, the Client Profile history rows and every other `Money.format` call read `$12.50`, with no `US$`.

An expert who creates a USD topic therefore sees `US$` while typing and `$12.50` afterwards. Android has not been compared.

## What to do

Ask the user to decide before Phase 8 (the release pass), or sooner as a follow-up:

- Keep `$` for USD everywhere and change the topic editor label to match, or
- change the `Money` table to `US$` for USD on iOS (and check what Android renders), so a CAD user sees `CA$` and `US$` side by side as the backend doc specifies.

Whichever is chosen applies to both apps. `Money` tests (`MoneyCallSiteTests`, `ClientProfileHistoryEarningsTests`, which pin `$42.50` for USD) change with it. No backend change is needed.
