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

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: Expert seed (required inputs)

    let expertId: UUID
    let expertName: String
    let expertTitle: String
    let expertImageURL: String

    // MARK: Loaded content

    /// Topics of discussion, populated from `GET /experts/:id/details`.
    @Published var topics: [BookingTopic] = []

    /// Available time slots grouped by `yyyy-MM-dd` key, populated from
    /// `GET /experts/:id/availability?month=yyyy-MM`.
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

    /// True when the user tapped Book Now on a paid topic — Stripe isn't
    /// wired yet, so the view shows an "Coming soon" alert.
    @Published var showPaidUnsupportedAlert: Bool = false

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
    func loadAvailability(for month: Date) async {
        availabilityState = .loading
        selectedTimeSlot = nil
        do {
            let monthString = Self.monthKey(month)
            let response = try await api.getExpertAvailability(id: expertId, month: monthString)
            self.expertTimezone = response.data.expertTimezone
            self.availabilityByDate = Self.groupSlots(response.data.days)
            self.availabilityState = .loaded
        } catch {
            self.availabilityState = .failed(Self.message(for: error))
        }
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

    /// Runs the booking flow for the current selection. Free topics fire
    /// `POST /bookings/request`. Paid topics surface a "coming soon" alert
    /// (Stripe integration is intentionally deferred).
    func book() {
        guard !isBooking else { return }
        guard let topic = selectedTopic, let slot = selectedTimeSlot else { return }

        if !topic.isFree {
            showPaidUnsupportedAlert = true
            return
        }

        isBooking = true
        Task {
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

    private static func groupSlots(_ days: [ExpertAvailabilityData.Day]) -> [String: [BookingTimeSlot]] {
        var result: [String: [BookingTimeSlot]] = [:]
        for day in days {
            guard let dateKey = day.date, let slots = day.slots else { continue }
            let mapped: [BookingTimeSlot] = slots.compactMap { slot in
                guard let start = slot.startTime else { return nil }
                let isAvailable = (slot.available ?? true) && !(slot.held ?? false)
                return BookingTimeSlot(
                    startTime: start,
                    endTime: slot.endTime,
                    isAvailable: isAvailable
                )
            }
            if !mapped.isEmpty {
                result[dateKey] = mapped
            }
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
