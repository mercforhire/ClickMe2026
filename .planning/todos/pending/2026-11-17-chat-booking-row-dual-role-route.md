---
created: 2026-11-17T00:00:00.000Z
title: Chat booking row routes by shell, not by the viewer's role on the booking (dual-role users)
area: chat
severity: minor
files:
  - ClickMe2026/Utils/ChatBookingRowRoute.swift
  - ClickMe2026/Views/Screens/Chat/Chatting/ChattingView.swift
  - ClickMe2026/Views/Extensions/HomeNavigationPath.swift
---

## Problem

Plan 07-09 (D-18) picks the destination of a tapped booking row in a chat from the shell: the expert shell opens `HomeRoute.expertBookingSummary`, the client shell opens `bookingSummary` or `upcomingBooking`. A user who has both roles can be on the other side of a booking from the shell they are in: an expert-shell user who is the client on that booking, or a client-shell user who is its expert. The row then opens the screen for the wrong side, and its endpoint (`GET /client/bookings/:id` is behind `roleCheck('client')` and scoped to `client_id`) refuses them, so they see a load error. Not seen on a device; found from the 07-RESEARCH Open Question 2 reading. The shell rule was kept for Phase 7 on the research recommendation.

## Solution

Not built. A per-viewer route could compare the booking event's `event_data.expert_id` with the signed-in user's id: equal means the viewer is the expert and gets the expert summary, otherwise the client screens. The client shell would then need a case that renders `ExpertBookingSummaryView`, which it stubs as `EmptyView()` today (`HomeClientView`, `.expertBookingSummary`), and `ChatBookingRowRoute` would take the viewer id and the event's expert id instead of the shell flag. Check first that `event_data.expert_id` is present on every booking event the chat endpoint returns (backend `src/` and the `BookingEvent` mapping in `ChatItemMapper.swift`), and whether Android needs the same.
