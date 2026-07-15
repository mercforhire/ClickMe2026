//
//  AvailiabilitySettingsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import Observation
import SwiftUI

@Observable
final class AvailiabilitySettingsViewModel {
    // MARK: Calendar

    var selectedDate: Date
    var displayedMonth: Date

    // MARK: Timezone

    var selectedTimezone: String
    var showTimezonePicker: Bool = false

    // MARK: Save state

    var isSaving: Bool = false
    var didSave: Bool = false

    // MARK: Time picker sheet

    var editingDayIndex: Int?
    var editingSlotIndex: Int?
    var showTimePicker: Bool = false

    // MARK: Schedule

    var schedule: [DaySchedule]

    // MARK: Init

    init(
        selectedDate: Date = Date(),
        displayedMonth: Date = Date(),
        selectedTimezone: String = "(GMT-07:00) Pacific Time",
        schedule: [DaySchedule] = [
            DaySchedule(day: "Monday", shortDay: "Mon", isEnabled: true, slots: [AvailabilityTimeSlot(start: 9 * 60, end: 12 * 60 + 30), AvailabilityTimeSlot(start: 14 * 60, end: 17 * 60)]),
            DaySchedule(day: "Tuesday", shortDay: "Tue", isEnabled: true, slots: [AvailabilityTimeSlot(start: 9 * 60, end: 17 * 60)]),
            DaySchedule(day: "Wednesday", shortDay: "Wed", isEnabled: true, slots: [AvailabilityTimeSlot(start: 9 * 60, end: 12 * 60 + 30), AvailabilityTimeSlot(start: 15 * 60, end: 18 * 60)]),
            DaySchedule(day: "Thursday", shortDay: "Thu", isEnabled: false, slots: []),
            DaySchedule(day: "Friday", shortDay: "Fri", isEnabled: true, slots: [AvailabilityTimeSlot(start: 10 * 60, end: 16 * 60)]),
            DaySchedule(day: "Saturday", shortDay: "Sat", isEnabled: false, slots: []),
            DaySchedule(day: "Sunday", shortDay: "Sun", isEnabled: false, slots: []),
        ]
    ) {
        self.selectedDate = selectedDate
        self.displayedMonth = displayedMonth
        self.selectedTimezone = selectedTimezone
        self.schedule = schedule
    }

    // MARK: Intents

    func beginEditingSlot(dayIndex: Int, slotIndex: Int) {
        editingDayIndex = dayIndex
        editingSlotIndex = slotIndex
        showTimePicker = true
    }

    func dismissTimePicker() {
        showTimePicker = false
    }

    func save() {
        guard !isSaving, !didSave else { return }
        withAnimation { isSaving = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self.isSaving = false
                self.didSave = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                withAnimation { self?.didSave = false }
            }
        }
    }
}
