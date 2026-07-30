//
//  AvailabilitySettingsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class AvailabilitySettingsViewModel {


    // MARK: Timezone

    /// IANA identifier (e.g. `"America/Los_Angeles"`) — source of truth
    /// for the PUT payload.
    var selectedTimezoneId: String
    /// Human-readable label shown in the picker row.
    var selectedTimezone: String
    var showTimezonePicker: Bool = false

    // MARK: Load / Save state

    var loadState: LoadState = .idle
    var isSaving: Bool = false
    var didSave: Bool = false
    var saveError: String?

    // MARK: Time picker sheet

    var editingDayIndex: Int?
    var editingSlotIndex: Int?
    var showTimePicker: Bool = false

    // MARK: Schedule

    var schedule: [DaySchedule]

    // MARK: Dependencies

    @ObservationIgnored
    private let api: ClickMeAPI

    // MARK: Init

    init(
        selectedTimezoneId: String = Timezones.detected().id,
        selectedTimezone: String = Timezones.detected().label,
        schedule: [DaySchedule] = AvailabilitySettingsViewModel.defaultSchedule(),
        api: ClickMeAPI = .shared
    ) {
        self.selectedTimezoneId = selectedTimezoneId
        self.selectedTimezone = selectedTimezone
        self.schedule = schedule
        self.api = api
    }

    /// Preview seam — installs canned schedule + timezone as if the fetch
    /// had succeeded.
    static func previewSeed(
        selectedTimezoneId: String = Timezones.detected().id,
        selectedTimezone: String = Timezones.detected().label,
        schedule: [DaySchedule] = AvailabilitySettingsViewModel.defaultSchedule()
    ) -> AvailabilitySettingsViewModel {
        let vm = AvailabilitySettingsViewModel(
            selectedTimezoneId: selectedTimezoneId,
            selectedTimezone: selectedTimezone,
            schedule: schedule
        )
        vm.loadState = .loaded
        return vm
    }

    /// Every day of the week enabled, 5 PM – 9 PM by default (assumes
    /// most experts have a day job and take bookings in the evening).
    /// Experts who can't take bookings for a given week just reject
    /// incoming requests rather than editing this schedule.
    private static func defaultSchedule() -> [DaySchedule] {
        let defaultSlot = AvailabilityTimeSlot(start: 17 * 60, end: 21 * 60)
        return [
            DaySchedule(day: "Monday",    shortDay: "Mon", isEnabled: true, slots: [defaultSlot]),
            DaySchedule(day: "Tuesday",   shortDay: "Tue", isEnabled: true, slots: [defaultSlot]),
            DaySchedule(day: "Wednesday", shortDay: "Wed", isEnabled: true, slots: [defaultSlot]),
            DaySchedule(day: "Thursday",  shortDay: "Thu", isEnabled: true, slots: [defaultSlot]),
            DaySchedule(day: "Friday",    shortDay: "Fri", isEnabled: true, slots: [defaultSlot]),
            DaySchedule(day: "Saturday",  shortDay: "Sat", isEnabled: true, slots: [defaultSlot]),
            DaySchedule(day: "Sunday",    shortDay: "Sun", isEnabled: true, slots: [defaultSlot]),
        ]
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

    /// Snap `selectedTimezone` to whatever `TimeZone.current` maps to.
    /// Called from the "Auto-detect" affordance.
    func autoDetectTimezone() {
        let entry = Timezones.detected()
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTimezoneId = entry.id
            selectedTimezone = entry.label
        }
    }

    /// Called when the user picks a timezone from the confirmation dialog.
    func selectTimezone(_ entry: Timezones.Entry) {
        selectedTimezoneId = entry.id
        selectedTimezone = entry.label
    }

    // MARK: - Load

    /// Fetches `GET /expert/availability` and hydrates schedule + timezone.
    /// Idempotent — skips when already loaded so preview seeds aren't
    /// clobbered.
    func load() async {
        if case .loaded = loadState { return }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        loadState = .loading
        do {
            let response = try await api.getMyAvailability()
            hydrate(from: response.data)
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }
    }

    private func hydrate(from data: AvailabilityScheduleData) {
        // Prefer a bundled entry (its label matches the picker), fall
        // back to the server-provided display name for zones we don't
        // list.
        if let entry = Timezones.entry(forId: data.timezone.id) {
            selectedTimezoneId = entry.id
            selectedTimezone = entry.label
        } else {
            selectedTimezoneId = data.timezone.id
            selectedTimezone = data.timezone.displayName
        }

        let recurring = data.recurringSchedule
        let dayLists: [[TimeSlot]] = [
            recurring.monday, recurring.tuesday, recurring.wednesday,
            recurring.thursday, recurring.friday, recurring.saturday,
            recurring.sunday,
        ]

        for i in schedule.indices where i < dayLists.count {
            let apiSlots = dayLists[i]
            let mapped = apiSlots.compactMap(Self.mapSlot(from:))
            schedule[i].slots = mapped
            schedule[i].isEnabled = !mapped.isEmpty
        }
    }

    /// Parse `"HH:mm"` → minutes-from-midnight. Nil for malformed strings.
    private static func mapSlot(from api: TimeSlot) -> AvailabilityTimeSlot? {
        guard let start = parseHHMM(api.startTime),
              let end = parseHHMM(api.endTime),
              end > start else { return nil }
        return AvailabilityTimeSlot(start: start, end: end)
    }

    private static func parseHHMM(_ s: String) -> Int? {
        let parts = s.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]),
              let m = Int(parts[1]) else { return nil }
        return h * 60 + m
    }

    // MARK: - Validation

    /// Day names whose enabled slots overlap. Empty when the schedule
    /// is valid. Used to disable Save and to build the error banner.
    ///
    /// Overlap = any two slots on the same day with `a.start < b.end`
    /// and `a.end > b.start`. Order-insensitive — we sort a copy first
    /// so `[13:00-14:00, 09:00-10:00]` isn't mistaken for overlap.
    var overlappingDayNames: [String] {
        schedule.compactMap { day in
            guard day.isEnabled, day.slots.count > 1 else { return nil }
            let sorted = day.slots.sorted { $0.start < $1.start }
            for i in 1..<sorted.count where sorted[i].start < sorted[i - 1].end {
                return day.day
            }
            return nil
        }
    }

    var hasOverlaps: Bool { !overlappingDayNames.isEmpty }

    // MARK: - Save

    /// Persist the current schedule + timezone via `PUT /expert/availability`.
    /// Shows a spinner in the nav bar while in-flight and briefly flashes
    /// a checkmark on success.
    func save() {
        Task { await performSave() }
    }

    private func performSave() async {
        guard !isSaving else { return }
        saveError = nil

        // Pre-flight: the server hard-rejects any day with overlapping
        // slots with a per-day 422. Catch it locally so the user sees a
        // targeted "Monday has overlaps" message instead of a generic
        // network error, and so the write is never even attempted.
        let overlaps = overlappingDayNames
        if !overlaps.isEmpty {
            saveError = Self.overlapMessage(for: overlaps)
            return
        }

        isSaving = true
        defer { isSaving = false }

        let body = buildRequest()
        do {
            _ = try await api.updateMyAvailability(body)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                didSave = true
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation { didSave = false }
        } catch {
            saveError = error.userMessage
        }
    }

    private static func overlapMessage(for days: [String]) -> String {
        if days.count == 1 {
            return "Time slots on \(days[0]) overlap. Please adjust them before saving."
        }
        let joined = ListFormatter.localizedString(byJoining: days)
        return "Time slots on \(joined) overlap. Please adjust them before saving."
    }

    private func buildRequest() -> UpdateMyAvailabilityRequest {
        let dayLists = schedule.map { day -> [TimeSlot] in
            guard day.isEnabled else { return [] }
            // Sort by start so out-of-order edits still hit the server
            // in ascending order — cosmetic on the server side but
            // matches what the day rows display.
            return day.slots
                .sorted { $0.start < $1.start }
                .map { slot in
                    TimeSlot(
                        startTime: Self.formatHHMM(slot.start),
                        endTime: Self.formatHHMM(slot.end)
                    )
                }
        }
        // Guard against a schedule that isn't exactly 7 days.
        let padded = dayLists + Array(repeating: [TimeSlot](), count: max(0, 7 - dayLists.count))
        return UpdateMyAvailabilityRequest(
            timezoneId: selectedTimezoneId,
            schedule: .init(
                monday:    padded[0],
                tuesday:   padded[1],
                wednesday: padded[2],
                thursday:  padded[3],
                friday:    padded[4],
                saturday:  padded[5],
                sunday:    padded[6]
            )
        )
    }

    /// Minutes-from-midnight → `"HH:mm"`.
    private static func formatHHMM(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%02d:%02d", h, m)
    }

    // MARK: - Error mapping

}
