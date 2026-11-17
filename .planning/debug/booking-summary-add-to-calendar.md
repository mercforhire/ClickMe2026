---
status: diagnosed
trigger: "UAT Phase 06 item 17: Add this \"Add to Calendar\" button on the booking summary screen for both client and expert, so this screen can be reached repeatedly."
created: 2026-11-16T00:00:00Z
updated: 2026-11-16T00:35:00Z
goal: find_root_cause_only
---

## Current Focus

bug_class: Bohrbug (deterministic missing capability; change request, not a crash)
hypothesis: CONFIRMED. Add to Calendar exists only on expert Booking Confirmed (reached once, on accept success). No summary screen has it because (a) Phase 6 scoped EXP-10 / D-13 to the Confirmed flow, and (b) the EventKit sheet's only input is the Confirmed display model `BookingConfirmation`, built only in RequestDecisionViewModel.confirmAccept.
test: done (code read on iOS, Android, backend; no runtime needed for an absent control)
expecting: n/a
next_action: Return ROOT CAUSE FOUND (goal: find_root_cause_only). Planner must confirm with the user that "client Booking Summary" means Upcoming Booking (UpcomingBookingView), not the past-only Session Summary.

reasoning_checkpoint:
  hypothesis: "The button is missing from both summary screens because Phase 6 wired Add to Calendar only into BookingConfirmedView, and CalendarEventEditorSheet takes a BookingConfirmation that only the accept-success path builds."
  confirming_evidence:
    - "grep EventKit/Add to Calendar finds only Expert Mode/Confirmed/* and Model/BookingCalendarPayload.swift"
    - "CalendarEventEditorSheet(booking: BookingConfirmation, onDismiss:); the only runtime BookingConfirmation is built in RequestDecisionViewModel.confirmAccept"
    - "06-CONTEXT scope: 'accept -> Confirmed flow and its calendar event'; 06-UI-SPEC lists Add to Calendar only under Booking Confirmed"
    - "ExpertBookingSummaryView / UpcomingBookingView action areas have Join, Message, Reschedule, Cancel and no calendar control"
  falsification_test: "Finding any other call site of CalendarEventEditorSheet or EKEventEditViewController, or a calendar control on a summary/upcoming screen, would disprove it. None found."
  fix_rationale: "Make the sheet take a neutral event value (title, notes, start, end), build it from data the summary screens already load, and add a status-gated button to ExpertBookingSummaryView and UpcomingBookingView (Android: UpcomingBookingScreen and ExpertBookingSummaryScreen). Reusing one builder keeps the title/notes identical to Confirmed."
  blind_spots: "Which client screen the user means (Upcoming Booking vs Session Summary); whether in_progress should show the button; whether the client's Skype/Zoom join link should go in the notes; an event added before a reschedule is accepted keeps the old time (EventKit gives no sync)."
  candidate_causes:
    - "code: no button on summary screens; sheet input coupled to the expert-only BookingConfirmation (confirmed)"
    - "config/spec: Phase 6 decision D-11/D-13 scoped the calendar to Confirmed only (confirmed)"
    - "data: backend detail payloads lack fields (eliminated: both detail endpoints return start, end, meeting type, topic, counterpart name, client notes)"
  and_gate: "yes: scope (spec) AND coupling (code). Adding a button alone fails because summary screens have no BookingConfirmation; refactoring the sheet alone adds nothing visible. Both must change."

## Symptoms

expected: Booking Summary has an "Add to Calendar" button for both client and expert, so the event can be added any time, not only once from Booking Confirmed. Android must mirror it.
actual: "Add this \"Add to Calendar\" button on the booking summary screen for both client and expert, so this screen can be reached repeatedly." (UAT Phase 06 checklist item 17)
errors: none (missing capability / change request)
reproduction: item 17 in .planning/phases/06-expert-mode/06-DEVICE-UAT-CHECKLIST.md
started: discovered during device UAT 2026-11-16; Add to Calendar was added only on expert Booking Confirmed in plans 06-04/06-05.

## Eliminated

- hypothesis: The backend summary/detail responses lack a field the event needs, so a backend change is required.
  evidence: GET /client/bookings/:id (clientBooking.controller.js getDetail) returns start_time, end_time, meeting_type, topic.title, expert.full_name, join_link, client_notes, status. GET /expert/bookings/:id/details returns session.topic_title, session.schedule.start_time/end_time, session.meeting_type, client.name, preparation_notes.text, status.code. iOS already decodes all of them (ClientBookingDetail, ExpertBookingDetail) and both screens render them.
  timestamp: 2026-11-16T00:30:00Z

- hypothesis: The client already has Add to Calendar somewhere (client Booking Confirmed / Request Sent / payment success).
  evidence: No EventKit or "Add to Calendar" under Views/Screens/Client Mode; the client flow ends at BookingRequestSentView ("Booking Request"), which has no calendar action. Android likewise has calendar only in expertmode/confirmed.
  timestamp: 2026-11-16T00:06:00Z

## Evidence

- timestamp: 2026-11-16T00:05:00Z
  checked: .planning/debug/knowledge-base.md (Phase 0)
  found: No knowledge-base.md exists; no prior pattern to test.
  implication: Proceed with open investigation.

- timestamp: 2026-11-16T00:06:00Z
  checked: grep EventKit / EKEvent / "Add to Calendar" across ClickMe2026 + ClickMe2026Tests
  found: Only 5 app files: Model/BookingCalendarPayload.swift, Views/Screens/Expert Mode/Confirmed/BookingConfirmedView.swift, Confirmed/Subviews/BookingConfirmedActionButtons.swift, Confirmed/Subviews/CalendarEventEditorSheet.swift, Localizable.xcstrings; tests in ClickMe2026Tests/Utils/ExpertBookingConfirmationContentTests.swift. Nothing under Client Mode, Booking Summary, or Upcoming Booking Details.
  implication: Add to Calendar exists only on the expert Booking Confirmed screen. The client side has no Add to Calendar anywhere (Request Sent / payment / Upcoming / Session Summary all checked by grep).

- timestamp: 2026-11-16T00:08:00Z
  checked: CalendarEventEditorSheet.swift, BookingCalendarPayload.swift, ExpertBookingConfirmationContent.swift, BookingConfirmedView.swift
  found: CalendarEventEditorSheet is a UIViewControllerRepresentable over EKEventEditViewController with inputs `booking: BookingConfirmation` + `onDismiss`. makeEvent reads only booking.calendarTitle, booking.calendarPayload.startDate/endDate, booking.calendarNotes, and adds EKAlarm(-15 min); no location. BookingConfirmation is the expert-Confirmed display model (clientName, clientImageURL, topic, date, time, duration, meetingTypeLabel/Icon, calendarTitle, calendarNotes, calendarPayload). Title/notes are built by ExpertBookingConfirmationContent.calendarTitle(topic:clientName:) -> "ClickMe \u{00B7} {topic} with {client}" (fallbacks "Session"/"Client") and calendarNotes(meetingType:clientMessage:) -> label + "\n" + trimmed message. BookingConfirmedView presents it via `.sheet(isPresented:)` + `.ignoresSafeArea()`. Info.plist key in pbxproj: INFOPLIST_KEY_NSCalendarsFullAccessUsageDescription.
  implication: The reusable piece is the EventKit sheet, but its input type is coupled to the expert Confirmed display model; reuse on summary screens needs the sheet to accept a small value (title, notes, start, end) rather than BookingConfirmation.

- timestamp: 2026-11-16T00:10:00Z
  checked: RequestDecisionViewModel.confirmAccept (lines 192-221)
  found: The only producer of BookingConfirmation at runtime is the accept-success path: ExpertBookingConfirmationContent.confirmation(clientName: detail.client.name, clientImageURL:, topic: detail.session.topic, start: detail.session.startTime, end: detail.session.endTime, meetingType:, clientMessage: detail.session.clientMessage).
  implication: The event is reachable exactly once (right after accepting a request). After leaving Booking Confirmed it cannot be reached again — this is the UAT complaint.

- timestamp: 2026-11-16T00:12:00Z
  checked: Phase 06 CONTEXT D-11/D-13 and UI-SPEC copy table
  found: Scope explicitly said "accept -> Confirmed flow and its calendar event"; UI-SPEC lists Add to Calendar only under Booking Confirmed. Copy contract: title "ClickMe · {topic} with {client name}", notes = meeting type + client message, no location, 15-min alarm kept.
  implication: Absence on summary screens is a scoping decision, not a regression. Summary screens were never in the 06-04/06-05 file list.

- timestamp: 2026-11-16T00:15:00Z
  checked: Expert Mode/Booking Summary/ExpertBookingSummaryView.swift + ExpertBookingSummaryViewModel.swift
  found: Title "Booking Summary". One screen for upcoming AND past expert bookings (UpcomingBookingsView.handleCardTap and handlePastCardTap both push HomeRoute.expertBookingSummary; push routes .bookingDetail/.bookingSummary/.leaveReview also land here). Data: GET /expert/bookings/:id/details -> ExpertBookingDetail with client.name, client.avatarUrl, session.topicTitle, session.schedule.startTime/endTime, session.meetingType, preparationNotes.text (client_notes = client's message), status (BookingStatusMeta .code/.label), actions.canJoin/canReschedule/canCancel/canMessage. VM already exposes dateLabel, timeRangeLabel, durationLabel, meetingTypeLabel/Icon. Actions area = joinAndMessageSection then Reschedule/Cancel row; no calendar button.
  implication: Every input the expert event needs is already loaded on the expert Booking Summary; no new fetch needed. Because past bookings use the same screen, the button must be gated by status.

- timestamp: 2026-11-16T00:18:00Z
  checked: Client Mode/Booking Summary/BookingSummaryView(+Model).swift, Client Mode/Upcoming Booking Details/UpcomingBookingView(+Model).swift, MyBookingsView routes, HomeClientView push handling, ChattingView.openBookingDetail, PushRouter
  found: Client has TWO per-booking screens. (a) BookingSummaryView, title "Session Summary", is pushed only for terminal bookings (MyBookings .past, chat isTerminal, pushes declines/cancellations/expirations/refunds, leaveReview); its mapStatus returns nil for pending_approval/confirmed/pending_reschedule/in_progress and the VM comment says "the summary screen is only ever pushed for terminal bookings". (b) UpcomingBookingView, title "Upcoming Booking", is pushed for non-terminal bookings (MyBookings .upcoming, push .bookingDetail, chat non-terminal, Explore today card, ClientTransactionsView). UpcomingBookingViewModel already holds expertName, topic, startTime, endTime, meetingType, joinLink, preparationNote (= ClientBookingDetail.clientNotes), bookingStatus (BookingStatus), date, timeRange.
  implication: The client screen that is "reached repeatedly" for a future session is UpcomingBookingView, not BookingSummaryView. A calendar button on Session Summary would only ever show for completed/cancelled/missed sessions, which is useless. The client-side change belongs on UpcomingBookingView (confirm wording with user).

- timestamp: 2026-11-16T00:22:00Z
  checked: BookingStatus.swift, UpcomingActionPolicy.swift, JoinWindow.showsJoinButton, ExpertJoinVisibility.alwaysShownStatuses, BookingStatusMeta
  found: BookingStatus UPCOMING = pendingApproval, confirmed, pendingReschedule, inProgress; PAST = completed, cancelled, declined, missed, expired; socket-only rescheduled; fallback unknown. ExpertJoinVisibility.alwaysShownStatuses = [.confirmed, .inProgress, .pendingReschedule] (the "booked, not over" set). JoinWindow hides Join for pendingApproval ("The Join Call option unlocks then"). UpcomingActionPolicy.canShowCancel adds an `end > now` time gate evaluated in a 60 s TimelineView. ExpertBookingDetail.status.code is a decoded BookingStatus.
  implication: Convention-derived gate for the calendar button: status in [.confirmed, .pendingReschedule, .inProgress] AND now < end, ticking via the existing TimelineView pattern. Hide for pendingApproval (not booked yet, may be declined/expire), every terminal status, rescheduled and unknown.

- timestamp: 2026-11-16T00:25:00Z
  checked: Android repo (HEAD da498620): grep CalendarContract / add_to_calendar
  found: Only screens/expertmode/confirmed/CalendarIntent.kt (+ BookingConfirmedScreen.kt, subviews/ConfirmedDetailsCard.kt, res/values/strings_booking_confirmed.xml, tests CalendarIntentTest.kt/BookingConfirmedScreenTest.kt). CalendarIntent.kt has data class CalendarEventSpec(title, beginMillis, endMillis, description), calendarEventSpec(key: BookingConfirmedKey, title, meetingTypeLabel) (coupled to the Confirmed nav key), buildCalendarInsertIntent(spec) (ACTION_INSERT on CalendarContract.Events.CONTENT_URI, no permission, no reminder), Context.launchCalendarInsert(intent, onNoHandler) (catches ActivityNotFoundException -> "No calendar app found" snackbar). BookingConfirmedScreen has a `launching` double-tap guard reset in LifecycleResumeEffect. Strings: booking_confirmed_calendar_title "ClickMe · %1$s with %2$s", booking_confirmed_add_to_calendar, booking_confirmed_no_calendar, booking_confirmed_topic_fallback.
  implication: Android has the same single-site gap and the same coupling (spec builder takes BookingConfirmedKey). buildCalendarInsertIntent + launchCalendarInsert are already generic and reusable.

- timestamp: 2026-11-16T00:27:00Z
  checked: Android summary screens and routing (ChatEntries.kt, PushDestinationResolver.kt, ClientBookingManagementEntries.kt, ExpertBookingsRoute.kt, ExpertDashboardRoute.kt)
  found: Same structure as iOS. Client: screens/clientmode/upcomingbooking/UpcomingBookingScreen.kt (+ViewModel, UiState: UpcomingBookingDetails has expertName, topicTitle, start, end, meetingType, joinLink, clientNotes, status) for non-terminal; screens/clientmode/bookingsummary/BookingSummaryScreen.kt titled "Session Summary" (booking_summary_title) for past. Expert: screens/expertmode/bookingsummary/ExpertBookingSummaryScreen.kt titled "Booking Summary" (expert_summary_title), used for upcoming and past; ExpertSummaryDetails has clientName, topic, start, end, durationMinutes, meetingType, preparationNotes, statusCode. Helpers clientDisplayName / meetingTypeLabel in screens/expertmode/ExpertDisplay.kt.
  implication: Android needs the same two insertion points (UpcomingBookingScreen + ExpertBookingSummaryScreen); every input is already in the loaded UI state.

- timestamp: 2026-11-16T00:30:00Z
  checked: Backend clientBooking.controller.js getDetail (lines 1040-1125), expertBooking controller detail (lines ~371-440), bookingRequests.controller.js:197
  found: GET /client/bookings/:id returns start_time, end_time, meeting_type, topic.title, expert.full_name, join_link, client_notes, status (scoped .eq('client_id', ...)). GET /expert/bookings/:id/details returns session.topic_title, session.schedule.start_time/end_time, session.meeting_type, client.name, preparation_notes.text (= client_notes), status.code. Request detail's client_message is also data.client_notes.
  implication: No backend change needed. The expert summary's preparationNotes.text is the same text the Confirmed event uses as the client's message, so summary and Confirmed events will be identical.

- timestamp: 2026-11-16T00:32:00Z
  checked: ChattingView.openBookingDetail (iOS) vs Android ChatEntries.kt
  found: iOS chat rows push the client screens (upcomingBooking / bookingSummary) even in the expert shell; for an expert, GET /client/bookings/:id 404s (client_id scope) so the screen shows its error state. Android routes Expert mode to ExpertBookingSummaryKey.
  implication: Pre-existing divergence, out of scope. It does not cause a wrong calendar event (the client screen never loads for an expert), so it does not block this change.

## Resolution

root_cause: "Two causes together (AND-gate). (1) Scope: Phase 6 (EXP-10, D-11/D-13, plans 06-04/06-05) wired Add to Calendar only into the expert BookingConfirmedView, which shows once, on accept success. Neither ExpertBookingSummaryView nor the client screens were in scope. The client has no Add to Calendar anywhere. (2) Coupling: CalendarEventEditorSheet takes only `booking: BookingConfirmation`, the Confirmed display model, and the only runtime producer of that model is RequestDecisionViewModel.confirmAccept. Summary screens have no way to feed the sheet without a refactor. Android has the same gap: calendarEventSpec(key: BookingConfirmedKey, ...) is used only by BookingConfirmedScreen. No backend change is needed."
fix: "(not applied: find_root_cause_only)"
verification: "(not applied)"
files_changed: []
