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

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: Identity
    let bookingId: UUID?

    // MARK: Content
    @Published var booking: RescheduleBooking
    @Published var loadState: LoadState

    /// Server UUID for the session's expert. Needed to fetch availability
    /// and stays nil until `getClientBookingDetail` settles.
    @Published var expertId: UUID?

    // MARK: Selection state
    @Published var currentMonth: Date
    @Published var selectedDate: Date?
    @Published var selectedTime: BookingTimeSlot?
    @Published var message: String

    // MARK: Availability cache — keyed by "yyyy-MM-dd" in client's timezone
    @Published var availabilityByDate: [String: [BookingTimeSlot]]
    /// Set of month keys ("yyyy-MM") whose availability has already been
    /// fetched. Used to skip re-fetching when the user paginates months.
    @Published var loadedMonths: Set<String>
    /// Non-fatal availability fetch failure (per-month). Surfaced as an
    /// inline label under the calendar without blocking the whole screen.
    @Published var availabilityError: String?

    // MARK: Submission state
    @Published var isSubmitting: Bool
    /// Alert text for reschedule-request failures.
    @Published var submitError: String?

    let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 1 // Sunday
        return c
    }()

    // MARK: Dependencies

    private let api: ClickMeAPI

    /// Runtime init — hydrates from `GET /client/bookings/:id` then fetches
    /// availability for the current month. `PATCH /client/bookings/:id/reschedule`
    /// fires on submit.
    init(
        bookingId: UUID,
        api: ClickMeAPI = .shared
    ) {
        self.bookingId = bookingId
        self.booking = RescheduleViewModel.placeholderBooking
        self.loadState = .idle
        self.expertId = nil
        self.currentMonth = Calendar.current.startOfMonth(for: Date()) ?? Date()
        self.selectedDate = nil
        self.selectedTime = nil
        self.message = ""
        self.availabilityByDate = [:]
        self.loadedMonths = []
        self.availabilityError = nil
        self.isSubmitting = false
        self.submitError = nil
        self.api = api
    }

    /// Preview seam — pre-populates the booking + availability as if the
    /// fetch had already succeeded. Availability is optional; empty means
    /// the calendar renders with no bookable days.
    init(
        booking: RescheduleBooking = .sample,
        currentMonth: Date = RescheduleViewModel.defaultMonth,
        selectedDate: Date? = RescheduleViewModel.defaultSelectedDate,
        selectedTime: BookingTimeSlot? = nil,
        message: String = "",
        availabilityByDate: [String: [BookingTimeSlot]] = [:]
    ) {
        self.bookingId = nil
        self.booking = booking
        self.loadState = .loaded
        self.expertId = nil
        self.currentMonth = currentMonth
        self.selectedDate = selectedDate
        self.selectedTime = selectedTime
        self.message = message
        self.availabilityByDate = availabilityByDate
        self.loadedMonths = availabilityByDate.isEmpty ? [] : [Self.monthKey(currentMonth)]
        self.availabilityError = nil
        self.isSubmitting = false
        self.submitError = nil
        self.api = .shared
    }

    // MARK: - Load

    /// Loads booking display fields + availability for the current month.
    /// Idempotent — skips when there's no `bookingId` (preview seed) or
    /// when the load already succeeded.
    func load() async {
        guard let bookingId else { return }
        if case .loaded = loadState { return }
        await forceLoad(bookingId: bookingId)
    }

    func reload() async {
        guard let bookingId else { return }
        await forceLoad(bookingId: bookingId)
    }

    private func forceLoad(bookingId: UUID) async {
        loadState = .loading

        let expertId: UUID
        do {
            let response = try await api.getClientBookingDetail(id: bookingId)
            booking = Self.map(detail: response.data)
            expertId = response.data.expert.id
            self.expertId = expertId
        } catch {
            loadState = .failed(Self.errorMessage(for: error))
            return
        }

        await fetchAvailability(for: currentMonth, expertId: expertId)
        loadState = .loaded
    }

    // MARK: - Availability

    /// Lazy per-month availability fetch. Skips already-loaded months so
    /// paginating back and forth is cheap. On failure sets `availabilityError`
    /// but doesn't clear the loaded map — previously-loaded months stay
    /// visible.
    func fetchAvailability(for month: Date) async {
        guard let expertId else { return }
        await fetchAvailability(for: month, expertId: expertId)
    }

    private func fetchAvailability(for month: Date, expertId: UUID) async {
        let key = Self.monthKey(month)
        if loadedMonths.contains(key) { return }

        availabilityError = nil
        do {
            let response = try await api.getExpertAvailability(id: expertId, month: key)
            let grouped = Self.groupSlots(response.data.days, calendar: calendar)
            for (dateKey, slots) in grouped {
                let combined = (availabilityByDate[dateKey] ?? []) + slots
                let deduped = Array(Set(combined)).sorted { $0.startTime < $1.startTime }
                availabilityByDate[dateKey] = deduped
            }
            loadedMonths.insert(key)
        } catch {
            availabilityError = Self.errorMessage(for: error)
        }
    }

    // MARK: - Actions

    func select(date: Date) {
        selectedDate = date
        // Reset the picked time whenever the day changes so we never carry
        // a stale slot from a different day into `submit`.
        selectedTime = nil
    }

    func select(time: BookingTimeSlot) {
        selectedTime = time
    }

    func shiftMonth(_ delta: Int) {
        guard let next = calendar.date(byAdding: .month, value: delta, to: currentMonth) else { return }
        withAnimation(.easeInOut(duration: 0.18)) { currentMonth = next }
        Task { await fetchAvailability(for: next) }
    }

    /// Runs the real `PATCH /client/bookings/:id/reschedule`. On success
    /// invokes `onSuccess()` so the parent can pop the NavigationStack.
    func submit(onSuccess: @escaping () -> Void) async {
        guard !isSubmitting else { return }
        guard let bookingId, let slot = selectedTime else {
            submitError = "Please choose a new time before rescheduling."
            return
        }

        submitError = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let proposedStart = Self.iso8601String(from: slot.startTime)
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = try await api.rescheduleClientBooking(
                id: bookingId,
                proposedStart: proposedStart,
                timezone: TimeZone.current.identifier,
                note: trimmed.isEmpty ? nil : trimmed
            )
        } catch {
            submitError = Self.errorMessage(for: error)
            return
        }

        onSuccess()
    }

    // MARK: - Derived

    /// Slots for `selectedDate` (client-local day). Empty when no day is
    /// picked or the day has no available slots.
    var slotsForSelectedDate: [BookingTimeSlot] {
        guard let selectedDate else { return [] }
        return availabilityByDate[Self.dateKey(selectedDate, calendar: calendar)] ?? []
    }

    /// Whether a calendar day has at least one selectable slot. Used to
    /// gray out unbookable days in the grid. Also returns `false` for
    /// past days.
    func hasSlots(on day: Date) -> Bool {
        if calendar.startOfDay(for: day) < calendar.startOfDay(for: Date()) { return false }
        let slots = availabilityByDate[Self.dateKey(day, calendar: calendar)] ?? []
        return slots.contains(where: { $0.isAvailable })
    }

    // MARK: - Calendar derivation

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

    // MARK: - Mapping

    private static func map(detail: ClientBookingDetail) -> RescheduleBooking {
        RescheduleBooking(
            expertName: detail.expert.fullName ?? "",
            role: detail.expert.title ?? detail.topic.title,
            currentDateLabel: formatDateTime(start: detail.startTime, end: detail.endTime),
            imageURL: detail.expert.avatarUrl ?? ""
        )
    }

    private static func formatDateTime(start: Date, end: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return "\(dateFormatter.string(from: start)) • \(timeFormatter.string(from: start)) - \(timeFormatter.string(from: end))"
    }

    /// Buckets server slots by client-local calendar day. Server groups in
    /// the expert's timezone, so slots near midnight can shift day when
    /// re-rendered in the client's timezone.
    private static func groupSlots(
        _ days: [ExpertAvailabilityData.Day],
        calendar: Calendar
    ) -> [String: [BookingTimeSlot]] {
        var result: [String: [BookingTimeSlot]] = [:]
        for day in days {
            guard let slots = day.slots else { continue }
            for slot in slots {
                guard let start = slot.startTime else { continue }
                let ts = BookingTimeSlot(
                    startTime: start,
                    endTime: slot.endTime,
                    isAvailable: (slot.available ?? false) && !(slot.held ?? false)
                )
                let key = dateKey(start, calendar: calendar)
                result[key, default: []].append(ts)
            }
        }
        for key in result.keys {
            result[key]?.sort { $0.startTime < $1.startTime }
        }
        return result
    }

    // MARK: - Format helpers

    private static func dateKey(_ date: Date, calendar: Calendar) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = calendar.timeZone
        return f.string(from: date)
    }

    private static func monthKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM"
        return f.string(from: date)
    }

    private static func iso8601String(from date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: date)
    }

    // MARK: - Error mapping

    private static func errorMessage(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    // MARK: - Defaults

    static let defaultMonth: Date = Calendar.current.startOfMonth(for: Date()) ?? Date()
    static let defaultSelectedDate: Date? = nil

    /// Empty stub while the runtime `getClientBookingDetail` fetch is in
    /// flight. Never shown to the user — the view routes loading state
    /// to a spinner instead.
    private static let placeholderBooking = RescheduleBooking(
        expertName: "",
        role: "",
        currentDateLabel: "",
        imageURL: ""
    )
}

// MARK: - Calendar helpers

private extension Calendar {
    /// First moment of the month containing `date`.
    func startOfMonth(for date: Date) -> Date? {
        self.date(from: dateComponents([.year, .month], from: date))
    }
}
