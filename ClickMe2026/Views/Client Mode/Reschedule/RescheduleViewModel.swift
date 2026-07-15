//
//  RescheduleViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-30.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class RescheduleViewModel: ObservableObject {

    // MARK: Content
    @Published var booking: RescheduleBooking

    // MARK: Selection state
    @Published var currentMonth: Date
    @Published var selectedDate: Date?
    @Published var selectedTime: String?
    @Published var message: String

    let timeSlots: [String]

    let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 1 // Sunday
        return c
    }()

    init(
        booking: RescheduleBooking = .sample,
        currentMonth: Date = RescheduleViewModel.defaultMonth,
        selectedDate: Date? = RescheduleViewModel.defaultSelectedDate,
        selectedTime: String? = "11:00 AM",
        message: String = "",
        timeSlots: [String] = RescheduleViewModel.defaultTimeSlots
    ) {
        self.booking = booking
        self.currentMonth = currentMonth
        self.selectedDate = selectedDate
        self.selectedTime = selectedTime
        self.message = message
        self.timeSlots = timeSlots
    }

    // MARK: Actions

    func select(date: Date) {
        selectedDate = date
    }

    func select(time: String) {
        selectedTime = time
    }

    func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: currentMonth) {
            withAnimation(.easeInOut(duration: 0.18)) { currentMonth = next }
        }
    }

    // MARK: Calendar derivation

    func monthYearLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: date)
    }

    func isSelected(_ day: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return calendar.isDate(selected, inSameDayAs: day)
    }

    /// Returns a 7-column grid of optional Date cells covering the current
    /// month, with `nil` for leading/trailing pad cells.
    func monthCells() -> [Date?] {
        guard
            let firstOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: currentMonth)
            )
        else { return [] }

        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30
        let leadingPad = calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday
        let normalizedLeading = (leadingPad + 7) % 7

        var cells: [Date?] = Array(repeating: nil, count: normalizedLeading)
        for offset in 0 ..< daysInMonth {
            if let day = calendar.date(byAdding: .day, value: offset, to: firstOfMonth) {
                cells.append(day)
            }
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    // MARK: Defaults

    static let defaultMonth: Date = {
        Calendar.current.date(from: DateComponents(year: 2024, month: 7, day: 1)) ?? Date()
    }()

    static let defaultSelectedDate: Date? = {
        Calendar.current.date(from: DateComponents(year: 2024, month: 7, day: 15))
    }()

    static let defaultTimeSlots: [String] = [
        "9:00 AM", "10:00 AM", "11:00 AM", "12:00 PM",
        "1:00 PM", "2:00 PM", "3:00 PM", "4:00 PM",
        "5:00 PM", "6:00 PM", "7:00 PM", "8:00 PM",
    ]
}
