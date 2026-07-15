//
//  BookingCalendarPayload.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Raw session window handed to the EventKit sheet for "Add to Calendar".
/// Kept separate from `BookingConfirmation` so the display model stays
/// display-only (formatted strings) and this data model owns the real dates.
struct BookingCalendarPayload {
    let startDate: Date
    let endDate: Date
}
