//
//  MakeABookingViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class MakeABookingViewModel: ObservableObject {


    /// Sub-states of the paid booking flow. Free bookings never leave `.idle`
    /// — they use `isBooking` instead. Transitions:
    /// `idle → creatingIntent → awaitingPaymentSheet → confirming → idle`.
    enum PaidStep: Equatable {
        case idle
        case creatingIntent
        case awaitingPaymentSheet
        case confirming
    }

    /// Snapshot of the amounts returned by `POST /bookings/payment-intent`.
    /// Values are in **major units** (dollars for USD, yen for JPY, etc.),
    /// per the server contract. Formatting is a UI concern — this struct
    /// stores raw numbers plus the ISO-4217 currency code.
    struct PaymentSummary: Equatable {
        let subtotal: Double
        let discount: Double
        let total: Double
        let currency: String
    }

    // MARK: Expert seed (required inputs)

    let expertId: UUID
    let expertName: String
    let expertTitle: String
    let expertImageURL: String

    // MARK: Loaded content

    /// Topics of discussion, populated from `GET /experts/:id/details`.
    @Published var topics: [BookingTopic] = []

    /// Available time slots grouped by **client-local** `yyyy-MM-dd` key
    /// (derived from each slot's `startTime`), populated from
    /// `GET /experts/:id/availability?month=yyyy-MM`.
    ///
    /// The server buckets `day.date` in the expert's timezone, which drifts
    /// from the client's timezone at day boundaries — a slot the server
    /// files under "2026-07-15" (expert-local) may be "2026-07-16"
    /// client-local. We re-bucket on the client so lookups always agree
    /// with the calendar the user is looking at.
    @Published var availabilityByDate: [String: [BookingTimeSlot]] = [:]

    /// Expert's IANA timezone identifier (e.g. `America/Toronto`). Rendered
    /// under the calendar so the user knows what timezone the slots are in.
    @Published var expertTimezone: String?

    // MARK: Selections

    @Published var selectedTopic: BookingTopic?
    @Published var selectedDate: Date = .init()
    @Published var displayedMonth: Date = .init()
    @Published var selectedTimeSlot: BookingTimeSlot?
    @Published var meetingType: MeetingType = .inAppVoice
    @Published var clientNotes: String = ""
    @Published var showTopicPicker: Bool = false

    // MARK: Load / submission state

    @Published var topicsState: LoadState = .idle
    @Published var availabilityState: LoadState = .idle
    @Published var isBooking: Bool = false

    /// Surfaced to the view for an alert after the booking flow completes,
    /// whether success (server message) or failure (`bookingError`).
    @Published var bookingError: String?
    @Published var bookingSuccessMessage: String?

    // MARK: Paid flow state

    /// Where we are in the paid booking flow. Free bookings never move past
    /// `.idle` — they use `isBooking` instead.
    @Published var paidStep: PaidStep = .idle
    @Published var paymentIntentId: String?
    @Published var paymentIntentClientSecret: String?
    @Published var paymentSummary: PaymentSummary?
    /// Stripe Customer id + short-lived ephemeral key — fed into
    /// `PaymentSheet.Configuration.customer` so the sheet lists the
    /// caller's saved cards. Populated from the payment-intent
    /// response; nil until `beginPaidBooking` succeeds.
    @Published var stripeCustomerId: String?
    @Published var stripeEphemeralKey: String?

    /// True while either the free flow is submitting or the paid flow is
    /// in-flight. The book button binds to this.
    var isSubmitting: Bool { isBooking || paidStep != .idle }

    // MARK: Calendar constants

    let calendar = Calendar.current
    let dayHeaders = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Init

    init(
        expertId: UUID,
        expertName: String,
        expertTitle: String,
        expertImageURL: String,
        api: ClickMeAPI = .shared
    ) {
        self.expertId = expertId
        self.expertName = expertName
        self.expertTitle = expertTitle
        self.expertImageURL = expertImageURL
        self.api = api
    }

    /// Preview seam — seeds pre-loaded content so the canvas can render
    /// without hitting the network.
    init(
        expertId: UUID = UUID(),
        expertName: String,
        expertTitle: String,
        expertImageURL: String,
        topics: [BookingTopic],
        availabilityByDate: [String: [BookingTimeSlot]] = [:],
        expertTimezone: String? = nil,
        api: ClickMeAPI = .shared
    ) {
        self.expertId = expertId
        self.expertName = expertName
        self.expertTitle = expertTitle
        self.expertImageURL = expertImageURL
        self.api = api
        self.topics = topics
        self.availabilityByDate = availabilityByDate
        self.expertTimezone = expertTimezone
        self.topicsState = .loaded
        self.availabilityState = availabilityByDate.isEmpty ? .idle : .loaded
        self.selectedTopic = topics.first
    }

    // MARK: - Load

    func onAppear() async {
        async let t: Void = loadTopics()
        async let a: Void = loadAvailability(for: displayedMonth)
        _ = await (t, a)
    }

    func loadTopics() async {
        if case .loaded = topicsState { return }
        topicsState = .loading
        do {
            let response = try await api.getExpertDetails(id: expertId)
            let mapped = response.data.topicsOfDiscussion.map(Self.mapTopic)
            self.topics = mapped
            self.selectedTopic = mapped.first
            self.topicsState = .loaded
        } catch {
            self.topicsState = .failed(Self.message(for: error))
        }
    }

    /// Loads availability for the given calendar month (`yyyy-MM`). Cheap
    /// enough to re-fire each time the user paginates months.
    /// Loads the requested month plus its two neighbors and merges the
    /// result. Why: the server groups slots in the expert's timezone, but
    /// the client renders in its own timezone — a slot in expert-local
    /// month N can spill into client-local N±1. Neighbor fetches keep the
    /// visible client-local month fully populated at both edges.
    ///
    /// The center month's failure is user-visible; neighbor fetches are
    /// best-effort (silent on failure). Runs sequentially to avoid the
    /// Sendable-conformance pitfalls of parallel decoding across actor
    /// boundaries — acceptable since this only fires on month change.
    func loadAvailability(for month: Date) async {
        availabilityState = .loading
        selectedTimeSlot = nil

        // Center month — surfaces the error if this one fails.
        let center: SuccessDataResponse<ExpertAvailabilityData>
        do {
            center = try await api.getExpertAvailability(id: expertId, month: Self.monthKey(month))
        } catch {
            availabilityState = .failed(Self.message(for: error))
            return
        }

        // Neighbors — best-effort. `try?` swallows failures silently so a
        // flaky neighbor doesn't blank out the whole calendar.
        let prev = calendar.date(byAdding: .month, value: -1, to: month) ?? month
        let next = calendar.date(byAdding: .month, value: 1, to: month) ?? month
        let prevData = try? await api.getExpertAvailability(id: expertId, month: Self.monthKey(prev)).data
        let nextData = try? await api.getExpertAvailability(id: expertId, month: Self.monthKey(next)).data

        var merged: [String: [BookingTimeSlot]] = [:]
        for data in [prevData, center.data, nextData].compactMap({ $0 }) {
            let bucket = Self.groupSlots(data.days, calendar: calendar)
            for (k, slots) in bucket {
                merged[k, default: []].append(contentsOf: slots)
            }
        }
        // De-dup + resort per day — the same slot can appear in two adjacent
        // month responses if the server includes overlapping edges.
        for k in merged.keys {
            merged[k] = Array(Set(merged[k] ?? [])).sorted { $0.startTime < $1.startTime }
        }

        expertTimezone = center.data.expertTimezone
        availabilityByDate = merged
        availabilityState = .loaded
    }

    // MARK: - Month navigation

    func goToPreviousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        Task { await loadAvailability(for: displayedMonth) }
    }

    func goToNextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        Task { await loadAvailability(for: displayedMonth) }
    }

    // MARK: - Slots for the selected day

    /// Slots for `selectedDate`, in the order returned by the server.
    var slotsForSelectedDate: [BookingTimeSlot] {
        availabilityByDate[Self.dateKey(selectedDate, calendar: calendar)] ?? []
    }

    // MARK: - Book action

    /// Entry point for the "Book Now" button. Branches on `topic.isFree`:
    /// free → `POST /bookings/request` (single call), paid → begin the paid
    /// flow which fetches a PaymentIntent and hands the client secret over
    /// to the view for PaymentSheet presentation.
    func book() {
        guard !isSubmitting else { return }
        guard let topic = selectedTopic, let slot = selectedTimeSlot else { return }

        if topic.isFree {
            Task { await performFreeBooking(topic: topic, slot: slot) }
        } else {
            Task { await beginPaidBooking(topic: topic, slot: slot) }
        }
    }

    private func performFreeBooking(topic: BookingTopic, slot: BookingTimeSlot) async {
        isBooking = true
        defer { isBooking = false }
        do {
            let iso = Self.iso8601String(from: slot.startTime)
            let response = try await api.requestBooking(
                expertId: expertId,
                topicId: topic.id,
                scheduledStart: iso,
                durationMinutes: topic.durationMinutes,
                meetingType: meetingType,
                timezone: TimeZone.current.identifier,
                clientNotes: clientNotes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            )
            bookingSuccessMessage = response.data.message
        } catch {
            bookingError = Self.message(for: error)
        }
    }

    // MARK: - Paid flow

    /// Fetches a PaymentIntent from the server and moves the flow into
    /// `.awaitingPaymentSheet`. The view observes that state and presents
    /// Stripe's PaymentSheet with `paymentIntentClientSecret`.
    private func beginPaidBooking(topic: BookingTopic, slot: BookingTimeSlot) async {
        paidStep = .creatingIntent
        do {
            let selectedDateUTC = Self.utcDateString(from: slot.startTime)
            let timeSlotUTC = Self.utcTimeSlotString(from: slot.startTime)
            let response = try await api.createPaymentIntent(
                expertId: expertId,
                topicId: topic.id,
                selectedDate: selectedDateUTC,
                timeSlot: timeSlotUTC,
                durationMinutes: topic.durationMinutes,
                promoCode: nil
            )
            paymentIntentId = response.paymentIntentId
            paymentIntentClientSecret = response.clientSecret
            stripeCustomerId = response.customerId
            stripeEphemeralKey = response.ephemeralKey
            paymentSummary = PaymentSummary(
                subtotal: response.summary.subtotal,
                discount: response.summary.discount,
                total: response.summary.total,
                currency: response.currency
            )
            paidStep = .awaitingPaymentSheet
        } catch {
            bookingError = Self.message(for: error)
            resetPaidFlow()
        }
    }

    /// Called from the PaymentSheet completion handler after the user's
    /// card has been charged. Records the booking on our backend with the
    /// `paymentIntentId` + `stripePaymentMethodId` pair.
    func completePaidBooking(paymentMethodId: String) async {
        guard let topic = selectedTopic,
              let slot = selectedTimeSlot,
              let intentId = paymentIntentId
        else {
            resetPaidFlow()
            return
        }

        paidStep = .confirming
        do {
            let startTimeISO = Self.iso8601String(from: slot.startTime)
            let response = try await api.confirmBooking(
                paymentIntentId: intentId,
                expertId: expertId,
                topicId: topic.id,
                startTime: startTimeISO,
                meetingType: meetingType,
                stripePaymentMethodId: paymentMethodId,
                clientNotes: clientNotes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                promoCode: nil
            )
            bookingSuccessMessage = response.data.message
        } catch {
            // NOTE: money has been captured by Stripe at this point. Surface
            // the paymentIntentId with the error so support can reconcile.
            let base = Self.message(for: error)
            bookingError = "\(base)\n\nPayment reference: \(intentId)"
        }
        resetPaidFlow()
    }

    /// Called when the user dismisses the PaymentSheet without paying.
    func cancelPaidBooking() {
        resetPaidFlow()
    }

    private func resetPaidFlow() {
        paidStep = .idle
        paymentIntentId = nil
        paymentIntentClientSecret = nil
        stripeCustomerId = nil
        stripeEphemeralKey = nil
        paymentSummary = nil
    }

    // MARK: - Date helpers

    func isPastDate(_ date: Date) -> Bool {
        let today = calendar.startOfDay(for: Date())
        let day = calendar.startOfDay(for: date)
        return day < today
    }

    // MARK: - Calendar day generation

    struct CalendarDay {
        let label: String
        let date: Date?
        let isCurrentMonth: Bool
    }

    func generateDays(for month: Date) -> [CalendarDay] {
        let comps = calendar.dateComponents([.year, .month], from: month)
        guard let first = calendar.date(from: comps) else { return [] }

        let weekday = calendar.component(.weekday, from: first) - 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: first)?.count ?? 30

        var days: [CalendarDay] = []

        if let prevMonth = calendar.date(byAdding: .month, value: -1, to: first),
           let prevRange = calendar.range(of: .day, in: .month, for: prevMonth)
        {
            let prevCount = prevRange.count
            for i in stride(from: prevCount - weekday + 1, through: prevCount, by: 1) {
                days.append(CalendarDay(label: "\(i)", date: nil, isCurrentMonth: false))
            }
        }

        for day in 1 ... daysInMonth {
            var c = comps; c.day = day
            let date = calendar.date(from: c)
            days.append(CalendarDay(label: "\(day)", date: date, isCurrentMonth: true))
        }

        let total = days.count
        let trailing = (7 - total % 7) % 7
        for i in 1 ... max(1, trailing) {
            days.append(CalendarDay(label: "\(i)", date: nil, isCurrentMonth: false))
        }

        return days
    }

    // MARK: - Formatting

    func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    // MARK: - Static helpers

    private static func mapTopic(_ t: PublicProfileDetailsData.TopicOfDiscussion) -> BookingTopic {
        BookingTopic(
            id: t.id,
            title: t.title,
            durationMinutes: t.durationMins ?? 30,
            priceAmount: t.price.amount,
            currency: t.price.currency,
            isFree: t.price.isFree
        )
    }

    /// Flattens every slot the server returned and re-buckets them by the
    /// **client-local** ymd derived from each slot's UTC `startTime`. Server
    /// `day.date` is expert-local and is intentionally ignored — see the
    /// comment on `availabilityByDate` for the drift rationale.
    private static func groupSlots(
        _ days: [ExpertAvailabilityData.Day],
        calendar: Calendar
    ) -> [String: [BookingTimeSlot]] {
        var result: [String: [BookingTimeSlot]] = [:]
        for day in days {
            guard let slots = day.slots else { continue }
            for slot in slots {
                guard let start = slot.startUtc else { continue }
                let isAvailable = (slot.available ?? true) && !(slot.held ?? false)
                let booking = BookingTimeSlot(
                    startTime: start,
                    endTime: slot.endUtc,
                    isAvailable: isAvailable
                )
                let key = dateKey(start, calendar: calendar)
                result[key, default: []].append(booking)
            }
        }
        // Keep each day's slots chronological for stable UI ordering.
        for key in result.keys {
            result[key]?.sort { $0.startTime < $1.startTime }
        }
        return result
    }

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

    /// `yyyy-MM-dd` in UTC. Server (`booking.controller.js`) interprets
    /// `selected_date` as UTC, so we format in UTC to match.
    private static func utcDateString(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// `HH:mm` in UTC, 24-hour, zero-padded. Server schema validates against
    /// `/^\d{2}:\d{2}$/` and interprets it as UTC.
    private static func utcTimeSlotString(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    private static func message(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

// MARK: - Small helpers

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
