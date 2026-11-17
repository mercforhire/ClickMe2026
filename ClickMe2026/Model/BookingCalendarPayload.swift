//
//  BookingCalendarPayload.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The plain event the EventKit sheet adds: title, notes, start and end. No
/// location; the sheet adds the 15-minute alert itself. Built by the content
/// builders (`ExpertBookingConfirmationContent` today) so any screen can
/// present `CalendarEventEditorSheet` without knowing the display model of
/// the screen that built the event (G-06-1-summary-calendar).
struct BookingCalendarPayload: Equatable {
    let title: String
    let notes: String
    let startDate: Date
    let endDate: Date
}
