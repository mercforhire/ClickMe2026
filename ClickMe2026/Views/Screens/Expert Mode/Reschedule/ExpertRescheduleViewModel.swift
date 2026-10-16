//
//  ExpertRescheduleViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// Expert-side counterpart to `RescheduleViewModel`. Loads booking detail
/// from `/expert/bookings/:id/details`, fetches the expert's own
/// availability slots via `/experts/:id/availability` (their own user id),
/// and submits via `PATCH /expert/bookings/:id/reschedule`.
///
/// Availability constraint mirrors the client flow — the expert can only
/// propose slots that already exist in their published schedule. If they
/// want a slot outside that grid they'd first add availability under
/// `AvailabilitySettingsView` and come back.
@MainActor
final class ExpertRescheduleViewModel: ObservableObject {

    // MARK: Identity
    let bookingId: UUID?

    // MARK: Content
    /// Reuses the client-side `RescheduleBooking` display value type — the
    /// component API is display-only, so its `expertName` field on the
    /// expert side actually carries the CLIENT's name (the counterparty
    /// on this booking).
    @Published var booking: RescheduleBooking
    @Published var loadState: LoadState

    /// The current expert's own user id — used as the "expert id" argument
    /// to `getExpertAvailability`. Sourced from `UserManager.shared.me?.id`
    /// at load time; nil until `/me` has resolved at least once.
    @Published var expertOwnId: UUID?

    // MARK: Selection state
    @Published var currentMonth: Date
    @Published var selectedDate: Date?
    @Published var selectedTime: BookingTimeSlot?
    @Published var message: String

    /// The booking's *current* scheduled start. Same purpose as its
    /// client-side twin: seed the calendar to the right day, and block
    /// picking the identical slot as the "new" time.
    @Published var currentSessionStart: Date?

    /// End of the Stripe authorization window on the client's live hold
    /// (`authorized_at + 6d`), or `nil` for free / long-lead / captured
    /// / terminal bookings.
    ///
    /// **Non-gating as of Phase 27.1** — the previous "reject slots
    /// whose session end exceeds this" rule was withdrawn. On the
    /// expert side there's currently no user-visible use for the
    /// field (the client is the one whose card is affected), but it's
    /// retained here mirroring the DTO in case an expert-facing
    /// advisory is added later.
    @Published var authorizationExpiresAt: Date?

    // MARK: Availability cache — keyed by "yyyy-MM-dd" in client's timezone
    @Published var availabilityByDate: [String: [BookingTimeSlot]]
    @Published var loadedMonths: Set<String>
    @Published var availabilityError: String?

    // MARK: Submission state
    @Published var isSubmitting: Bool
    @Published var submitError: String?

    let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 1 // Sunday
        return c
    }()

    // MARK: Dependencies

    private let api: ClickMeAPI
    private let userManager: UserManager

    /// Runtime init — hydrates from `GET /expert/bookings/:id/details`
    /// then fetches availability for the current month via
    /// `GET /experts/:id/availability` using the expert's own id.
    init(
        bookingId: UUID,
        api: ClickMeAPI = .shared,
        userManager: UserManager = .shared
    ) {
        self.bookingId = bookingId
        self.booking = ExpertRescheduleViewModel.placeholderBooking
        self.loadState = .idle
        self.expertOwnId = nil
        self.currentMonth = Calendar.current.startOfExpertMonth(for: Date()) ?? Date()
        self.selectedDate = nil
        self.selectedTime = nil
        self.message = ""
        self.availabilityByDate = [:]
        self.loadedMonths = []
        self.availabilityError = nil
        self.isSubmitting = false
        self.submitError = nil
        self.currentSessionStart = nil
        self.authorizationExpiresAt = nil
        self.api = api
        self.userManager = userManager
    }

    /// Preview seam — pre-populates the booking + optional availability so
    /// the canvas can render without hitting the network.
    init(
        booking: RescheduleBooking = .sample,
        currentMonth: Date = ExpertRescheduleViewModel.defaultMonth,
        selectedDate: Date? = nil,
        selectedTime: BookingTimeSlot? = nil,
        message: String = "",
        availabilityByDate: [String: [BookingTimeSlot]] = [:],
        currentSessionStart: Date? = nil
    ) {
        self.bookingId = nil
        self.booking = booking
        self.loadState = .loaded
        self.expertOwnId = nil
        self.currentMonth = currentMonth
        self.selectedDate = selectedDate
        self.selectedTime = selectedTime
        self.message = message
        self.availabilityByDate = availabilityByDate
        self.loadedMonths = availabilityByDate.isEmpty ? [] : [Self.monthKey(currentMonth)]
        self.availabilityError = nil
        self.isSubmitting = false
        self.submitError = nil
        self.currentSessionStart = currentSessionStart
        self.authorizationExpiresAt = nil
        self.api = .shared
        self.userManager = .shared
    }

    // MARK: - Load

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

        // Resolve the expert's own id via /me if it isn't cached yet.
        // Without it we can't query availability, so this is a hard-fail.
        if expertOwnId == nil {
            if let cached = userManager.me?.id {
                expertOwnId = cached
            } else {
                do {
                    try await userManager.refreshMe()
                    expertOwnId = userManager.me?.id
                } catch {
                    loadState = .failed(error.userMessage)
                    return
                }
            }
        }

        do {
            let response = try await api.getExpertBookingDetails(id: bookingId)
            booking = Self.map(detail: response.data)

            // Land the calendar on the booking's current day so the
            // expert opens the screen already looking at the month
            // they're rescheduling from. Time slot stays empty — the
            // current slot is what we're moving away from.
            let schedule = response.data.session.schedule
            let startTime = schedule.startTime
            currentSessionStart = startTime
            authorizationExpiresAt = response.data.authorizationExpiresAt
            if let monthStart = calendar.date(
                from: calendar.dateComponents([.year, .month], from: startTime)
            ) {
                currentMonth = monthStart
            }
            selectedDate = startTime
        } catch {
            loadState = .failed(error.userMessage)
            return
        }

        if let expertOwnId {
            await fetchAvailability(for: currentMonth, expertId: expertOwnId)
        }
        loadState = .loaded
    }

    // MARK: - Availability

    func fetchAvailability(for month: Date) async {
        guard let expertOwnId else { return }
        await fetchAvailability(for: month, expertId: expertOwnId)
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
            availabilityError = error.userMessage
        }
    }

    // MARK: - Actions

    func select(date: Date) {
        selectedDate = date
        selectedTime = nil
    }

    func select(time: BookingTimeSlot) {
        guard !isCurrentSlot(time) else { return }
        selectedTime = time
    }

    func isCurrentSlot(_ slot: BookingTimeSlot) -> Bool {
        guard let current = currentSessionStart else { return false }
        return abs(slot.startTime.timeIntervalSince(current)) < 1
    }

    var currentSessionLabel: String? {
        guard let start = currentSessionStart else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, MMM d · h:mm a"
        return f.string(from: start)
    }

    func shiftMonth(_ delta: Int) {
        guard let next = calendar.date(byAdding: .month, value: delta, to: currentMonth) else { return }
        withAnimation(.easeInOut(duration: 0.18)) { currentMonth = next }
        Task { await fetchAvailability(for: next) }
    }

    /// Runs `PATCH /expert/bookings/:id/reschedule`. On success invokes
    /// `onSuccess()` so the parent can pop the NavigationStack.
    func submit(onSuccess: @escaping () -> Void) async {
        guard !isSubmitting else { return }
        guard let bookingId, let slot = selectedTime else {
            submitError = "Please choose a new time before rescheduling."
            return
        }

        if isCurrentSlot(slot) {
            submitError = "Please choose a different time than the current session."
            return
        }

        submitError = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let proposedStart = Self.iso8601String(from: slot.startTime)
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = try await api.rescheduleExpertBooking(
                id: bookingId,
                proposedStart: proposedStart,
                timezone: TimeZone.current.identifier,
                note: trimmed.isEmpty ? nil : trimmed
            )
        } catch {
            submitError = Self.rescheduleErrorMessage(for: error)
            return
        }

        onSuccess()
    }

    /// Maps reschedule submit failures to user-visible copy. Special-cases
    /// `RESCHEDULE_OUTSIDE_AUTH_WINDOW` (Phase 27): the client's Stripe
    /// authorization can no longer cover a slot past its ~6-day window,
    /// so the counterparty must re-book. Expert-side surface tells the
    /// expert to ask the client to re-book (the expert can't do it for
    /// them). Everything else falls through to the server message.
    private static func rescheduleErrorMessage(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data),
           response.code == .rescheduleOutsideAuthWindow
        {
            return "This time is past the payment hold on the original booking. Please cancel and ask the client to book a new session."
        }
        return error.userMessage
    }

    // MARK: - Derived

    var slotsForSelectedDate: [BookingTimeSlot] {
        guard let selectedDate else { return [] }
        // Drop slots that have already started. Keeps today's grid
        // honest as the day rolls forward — server rejects past-time
        // proposals anyway, so trimming client-side avoids a confusing
        // submit failure.
        let now = Date()
        return (availabilityByDate[Self.dateKey(selectedDate, calendar: calendar)] ?? [])
            .filter { $0.startTime > now }
    }

    func hasSlots(on day: Date) -> Bool {
        if calendar.startOfDay(for: day) < calendar.startOfDay(for: Date()) { return false }
        let slots = availabilityByDate[Self.dateKey(day, calendar: calendar)] ?? []
        return slots.contains { $0.isAvailable }
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

    private static func map(detail: ExpertBookingDetail) -> RescheduleBooking {
        RescheduleBooking(
            expertName: detail.client.name ?? "Client",
            role: detail.session.topicTitle ?? "Session",
            currentDateLabel: formatDateTime(
                start: detail.session.schedule.startTime,
                end: detail.session.schedule.endTime
            ),
            imageURL: detail.client.avatarUrl ?? ""
        )
    }

    private static func formatDateTime(start: Date, end: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return "\(dateFormatter.string(from: start)) • \(timeFormatter.string(from: start)) - \(timeFormatter.string(from: end))"
    }

    private static func groupSlots(
        _ days: [ExpertAvailabilityData.Day],
        calendar: Calendar
    ) -> [String: [BookingTimeSlot]] {
        var result: [String: [BookingTimeSlot]] = [:]
        for day in days {
            guard let slots = day.slots else { continue }
            for slot in slots {
                guard let start = slot.startUtc else { continue }
                let ts = BookingTimeSlot(
                    startTime: start,
                    endTime: slot.endUtc,
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

    // MARK: - Defaults

    static let defaultMonth: Date = Calendar.current.startOfExpertMonth(for: Date()) ?? Date()

    private static let placeholderBooking = RescheduleBooking(
        expertName: "",
        role: "",
        currentDateLabel: "",
        imageURL: ""
    )
}

// MARK: - Calendar helpers

private extension Calendar {
    /// Namespaced to avoid symbol collision with the identically-named
    /// extension in the client-side reschedule module — Swift allows
    /// multiple file-private extensions with the same method name only
    /// when they're actually private/fileprivate as here.
    func startOfExpertMonth(for date: Date) -> Date? {
        self.date(from: dateComponents([.year, .month], from: date))
    }
}
