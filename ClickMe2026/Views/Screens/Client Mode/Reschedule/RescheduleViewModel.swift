//
//  RescheduleViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-30.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class RescheduleViewModel: ObservableObject {


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

    /// The booking's *current* scheduled start. Seeded from the detail
    /// fetch and used to (a) pre-select the current day on the calendar
    /// so the screen opens on the right month, and (b) block the user
    /// from picking the identical slot as their "new" time.
    @Published var currentSessionStart: Date?

    /// End of the Stripe authorization window for this booking
    /// (`authorized_at + 6d`), or `nil` for free / long-lead /
    /// captured / terminal bookings.
    ///
    /// **Non-gating as of Phase 27.1** — the previous "reject slots
    /// whose session end exceeds this" rule was withdrawn (following
    /// it produced a live bug where the picker showed zero slots for
    /// bookings past the boundary). The field is retained solely to
    /// drive the confirm-step disclosure: moving the session past this
    /// instant converts the booking to the charge-at-T-24h model
    /// rather than being refused.
    @Published var authorizationExpiresAt: Date?

    /// Duration of the current session, in seconds. Populated from the
    /// booking detail's `endTime - startTime`. Fallback for the
    /// disclosure computation when the picker slot omits its own
    /// `endTime`, so `slot.startTime + duration` still lands on a
    /// realistic session end.
    private var originalSessionDuration: TimeInterval?

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
        self.currentSessionStart = nil
        self.authorizationExpiresAt = nil
        self.originalSessionDuration = nil
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
        availabilityByDate: [String: [BookingTimeSlot]] = [:],
        currentSessionStart: Date? = nil
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
        self.currentSessionStart = currentSessionStart
        self.authorizationExpiresAt = nil
        self.originalSessionDuration = nil
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

            // Seed the calendar to the booking's current day so the
            // user lands on the month they're actually rescheduling
            // from. Time slot stays unselected — the current slot
            // itself is what we're moving away from.
            let startTime = response.data.startTime
            currentSessionStart = startTime
            originalSessionDuration = response.data.endTime.timeIntervalSince(startTime)
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
            availabilityError = error.userMessage
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
        // Guard against picking the same slot as the current session —
        // the UI already disables the "Current" chip, but this closes
        // the loop if a caller pushes selection programmatically.
        guard !isCurrentSlot(time) else { return }
        selectedTime = time
    }

    /// True when `slot` corresponds to the booking's *current* scheduled
    /// start. Compared to the second (slot start times are minute-aligned
    /// in practice, but sub-second tolerance guards against timezone
    /// round-tripping introducing microsecond drift).
    func isCurrentSlot(_ slot: BookingTimeSlot) -> Bool {
        guard let current = currentSessionStart else { return false }
        return abs(slot.startTime.timeIntervalSince(current)) < 1
    }

    /// Human-readable current-session label surfaced above the time-slot
    /// list — e.g. `"Wed, Jul 10 · 10:00 AM"`. Nil until the detail
    /// fetch resolves.
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

    /// Runs the real `PATCH /client/bookings/:id/reschedule`. On success
    /// invokes `onSuccess()` so the parent can pop the NavigationStack.
    ///
    /// **PAYMENT_METHOD_REQUIRED recovery (Phase 27.1):** the server's
    /// check for this code is DB-only — it does NOT mean the user has
    /// no saved cards. On this specific 422, fetch
    /// `GET /me/payment-methods`; if the caller has any saved card,
    /// resend the request with `stripe_payment_method_id` populated.
    /// Only fall through with an "add a card" prompt when the vault
    /// itself is empty. See `RESCHEDULE-PAYMENT-CONVERSION.md` §3.1.
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

        let proposedStart = Self.iso8601String(from: slot.startTime)
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = trimmed.isEmpty ? nil : trimmed
        let timezone = TimeZone.current.identifier

        do {
            _ = try await api.rescheduleClientBooking(
                id: bookingId,
                proposedStart: proposedStart,
                timezone: timezone,
                note: note
            )
            onSuccess()
            return
        } catch {
            guard Self.errorCode(for: error) == .paymentMethodRequired else {
                submitError = Self.rescheduleErrorMessage(for: error)
                return
            }
            // Fall through to the pm-recovery block below.
        }

        // PAYMENT_METHOD_REQUIRED — fetch the caller's vault and retry
        // with the preferred pm_ if one exists. An empty vault is the
        // only case where the app truly can't recover on its own.
        let vault: [PaymentMethodItem]
        do {
            vault = try await api.getPaymentMethods().data.paymentMethods
        } catch {
            submitError = "Couldn't check your saved payment methods. Please try again."
            return
        }

        let preferredId = vault.first(where: { $0.isDefault })?.id ?? vault.first?.id
        guard let pmId = preferredId else {
            submitError = "Please add a payment method in Settings > Payment before rescheduling this session."
            return
        }

        do {
            _ = try await api.rescheduleClientBooking(
                id: bookingId,
                proposedStart: proposedStart,
                timezone: timezone,
                note: note,
                stripePaymentMethodId: pmId
            )
        } catch {
            submitError = Self.rescheduleErrorMessage(for: error)
            return
        }

        onSuccess()
    }

    /// Maps reschedule submit failures to user-visible copy. Special
    /// cases:
    /// - `RESCHEDULE_OUTSIDE_AUTH_WINDOW` (Phase 27.1, now rare) — the
    ///   move is genuinely unconvertible (e.g. proposed <24h out); the
    ///   user must re-book.
    /// - `PAYMENT_METHOD_REQUIRED` on a retry — the picked card can't
    ///   be prepared for future billing (typically a one-off
    ///   PaymentSheet card); the user needs to add a reusable card.
    /// Everything else falls through to the server message.
    private static func rescheduleErrorMessage(for error: Error) -> String {
        switch errorCode(for: error) {
        case .rescheduleOutsideAuthWindow:
            return "This time is past the payment hold on your original booking. Please cancel and book again to authorize a new payment."
        case .paymentMethodRequired:
            return "The card on file can't be used for this reschedule. Please add a new payment method in Settings > Payment and try again."
        default:
            return error.userMessage
        }
    }

    private static func errorCode(for error: Error) -> ErrorCode? {
        guard case let NetworkError.httpError(_, data) = error,
              let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        else { return nil }
        return response.code
    }

    // MARK: - Derived

    /// Slots for `selectedDate` (client-local day). Empty when no day is
    /// picked or the day has no available slots.
    var slotsForSelectedDate: [BookingTimeSlot] {
        guard let selectedDate else { return [] }
        // Drop slots whose start time has already passed — if today is
        // the selected day, the morning grid should trim itself as the
        // day progresses so the user never sees a 9am chip at 11am.
        // Server should also reject these, but filtering here keeps the
        // grid honest without waiting for a submit round-trip.
        let now = Date()
        return (availabilityByDate[Self.dateKey(selectedDate, calendar: calendar)] ?? [])
            .filter { $0.startTime > now }
    }

    /// Whether a calendar day has at least one selectable slot. Used to
    /// gray out unbookable days in the grid. Also returns `false` for
    /// past days.
    func hasSlots(on day: Date) -> Bool {
        if calendar.startOfDay(for: day) < calendar.startOfDay(for: Date()) { return false }
        let slots = availabilityByDate[Self.dateKey(day, calendar: calendar)] ?? []
        return slots.contains { $0.isAvailable }
    }

    // MARK: - Payment-conversion disclosure (Phase 27.1)

    /// True when `slot`'s session END falls past the current booking's
    /// authorization window. In that case, submitting the reschedule
    /// converts the booking to the charge-at-T-24h model (server voids
    /// the live hold), so the view must present the disclosure copy
    /// before the user confirms. Free / long-lead / captured bookings
    /// have `authorizationExpiresAt == nil` and never trigger this.
    func requiresPaymentConversionDisclosure(for slot: BookingTimeSlot) -> Bool {
        guard let expiresAt = authorizationExpiresAt else { return false }
        return sessionEnd(for: slot) > expiresAt
    }

    /// True when the proposed slot lands close enough to now that the
    /// scheduled `new_session_start - 24h` charge will fire in under
    /// ~24 hours. Used to append the "your card may be charged sooner
    /// than 24 hours from now" caveat to the disclosure copy. `<24h`
    /// proposals are refused by the server up front, so this only
    /// covers the 24–48h band.
    func chargeWillFireSoon(for slot: BookingTimeSlot) -> Bool {
        slot.startTime.timeIntervalSinceNow < 48 * 3600
    }

    private func sessionEnd(for slot: BookingTimeSlot) -> Date {
        if let end = slot.endTime { return end }
        if let duration = originalSessionDuration {
            return slot.startTime.addingTimeInterval(duration)
        }
        return slot.startTime
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

    // MARK: - Error mapping


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
