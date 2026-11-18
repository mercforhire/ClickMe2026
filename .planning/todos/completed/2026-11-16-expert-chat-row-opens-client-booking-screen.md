---
created: 2026-11-16T00:00:00.000Z
title: Expert-mode chat row opens the client booking screen and fails to load
area: chat
severity: major
files:
  - .planning/debug/booking-summary-add-to-calendar.md:110
  - ClickMe2026/Views/Screens/Chat/
  - ClickMe2026/Views/Screens/Expert Mode/Booking Summary/ExpertBookingSummaryView.swift
---

## Problem

Found by the Phase 06 UAT diagnosis (debug session `booking-summary-add-to-calendar`), not seen on a device yet. In the expert shell, iOS chat rows open the client booking screens: `upcomingBooking` for a booking that hasn't finished and `bookingSummary` for one that has. Both load `GET /client/bookings/:id`, which is scoped to `client_id`, so for an expert it returns 404 and the screen shows its error state. Android sends expert mode to `ExpertBookingSummaryKey` instead.

## Solution

TBD. Confirm on a device first: as an expert, open a chat with a booking and tap its booking row. If it reproduces, route expert-mode chat rows to `ExpertBookingSummaryView`, matching Android. This is an iOS-only change; the backend and Android need none.

## Resolution

The device check (D-18) was run on 2026-11-18 on App Store build 6 as the test expert and the user reported "reproduced". Fixed by plan 07-09 in commit `491b600`: `ChatBookingRowRoute.route(isTerminal:bookingId:hostsClientBookingFlows:)` sends the expert shell (`hostsClientBookingFlows` false) to `HomeRoute.expertBookingSummary` for active and finished bookings, and `ChattingView.openBookingDetail(for:)` pushes that route. The client shell keeps `bookingSummary` (finished) and `upcomingBooking` (active). The after-fix device check is item 14 (C10) in `.planning/phases/07-chat/07-DEVICE-UAT-CHECKLIST.md`. A user who is the client on a booking but opens its row in the expert shell is not covered; see `2026-11-17-chat-booking-row-dual-role-route.md`.
