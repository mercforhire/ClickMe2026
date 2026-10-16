//
//  MakeABookingViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class MakeABookingViewModel: ObservableObject {


    /// Sub-states of the paid booking flow. Free bookings never leave `.idle`
    /// — they use `isBooking` instead. Transitions:
    /// `idle → creatingIntent → collectingPaymentMethod → confirming → idle`.
    ///
    /// **Path A flow (server-side confirm):** the PaymentSheet only
    /// collects a `pm_…` — it does NOT confirm the PI itself, because
    /// the PI lives on the expert's connected Stripe account and the
    /// client SDK doesn't have that account id. Server-side
    /// `/bookings/confirm` runs the actual confirm.
    enum PaidStep: Equatable {
        case idle
        case creatingIntent
        case collectingPaymentMethod
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

    /// Regenerates `bookingAttemptId` on change — a genuinely-new attempt
    /// gets a fresh idempotency seed so the server doesn't 409 with
    /// `BOOKING_ATTEMPT_CONFLICT`. Network retries within the same attempt
    /// reuse the id.
    @Published var selectedTopic: BookingTopic? {
        didSet {
            if oldValue?.id != selectedTopic?.id { newBookingAttempt() }
        }
    }
    @Published var selectedDate: Date = .init()
    @Published var displayedMonth: Date = .init()
    @Published var selectedTimeSlot: BookingTimeSlot? {
        didSet {
            if oldValue?.startTime != selectedTimeSlot?.startTime { newBookingAttempt() }
        }
    }
    @Published var meetingType: MeetingType = .inAppVoice
    @Published var clientNotes: String = ""
    @Published var showTopicPicker: Bool = false

    // MARK: Load / submission state

    @Published var topicsState: LoadState = .idle
    @Published var availabilityState: LoadState = .idle
    @Published var isBooking: Bool = false

    // MARK: Payment-methods gating

    /// Whether the client has a saved card. Paid bookings require this
    /// to be `.available` before the CTA does the actual booking —
    /// otherwise the CTA routes to the Payment Methods screen so the
    /// user saves a card first. Loaded from `GET /me/payment-methods`
    /// on appear and refreshed whenever the user returns from
    /// `PaymentMethodsView`.
    enum PaymentMethodsAvailability: Equatable {
        case unknown
        case none
        case available
    }

    @Published var paymentMethodsAvailability: PaymentMethodsAvailability = .unknown

    /// The client's saved cards, in the order the server returned. Kept
    /// in sync with `paymentMethodsAvailability`. Populated so the
    /// long-lead branch (session start > 6 days out, see Phase 27.1)
    /// can pick a card and skip PI creation entirely — the short-lead
    /// PaymentSheet flow never reads this and continues to rely on
    /// PaymentSheet's own saved-card list.
    @Published var savedPaymentMethods: [PaymentMethodItem] = []

    /// True when the selected topic is paid and the client has no
    /// saved cards on file. Drives the CTA to route to Payment Methods
    /// instead of starting the paid booking flow.
    var requiresPaymentMethodSetup: Bool {
        guard let topic = selectedTopic, !topic.isFree else { return false }
        return paymentMethodsAvailability == .none
    }

    /// Payment method id used by the long-lead branch. Prefers the
    /// user's default; falls back to the first saved card so a user
    /// with a single card (and no default flag set) still books.
    private var preferredPaymentMethodId: String? {
        if let defaultPM = savedPaymentMethods.first(where: { $0.isDefault }) {
            return defaultPM.id
        }
        return savedPaymentMethods.first?.id
    }

    /// Surfaced to the view for an alert on booking failure.
    @Published var bookingError: String?
    /// Set to the newly-created booking's id after a successful booking
    /// flow (free or paid). Drives a `navigationDestination` push to
    /// `BookingRequestSentView` — replaces the earlier "success alert"
    /// pattern so the client lands on a proper confirmation screen that
    /// can explain the Phase 27 payment lifecycle.
    @Published var completedBookingId: UUID?

    // MARK: Paid flow state

    /// Where we are in the paid booking flow. Free bookings never move past
    /// `.idle` — they use `isBooking` instead.
    @Published var paidStep: PaidStep = .idle
    @Published var paymentIntentId: String?
    @Published var paymentSummary: PaymentSummary?
    /// SetupIntent client secret returned by
    /// `POST /me/payment-methods/setup-intent`. Path A confirmation model:
    /// PaymentSheet runs in **setup mode** against THIS secret so it only
    /// attaches a card to the platform customer without touching the
    /// booking PI (which lives on the expert's connected account and the
    /// client SDK can't confirm). Side benefit: 3DS runs up-front at
    /// SetupIntent confirm, so the resulting `pm_…` is pre-authenticated
    /// and off-session confirm on the connected-account PI won't bounce
    /// on fresh-card SCA.
    @Published var setupIntentClientSecret: String?
    /// Stripe Customer id + short-lived ephemeral key — fed into
    /// `PaymentSheet.Configuration.customer` so the sheet lists the
    /// caller's saved cards. Populated from the setup-intent response;
    /// nil until `beginPaidBooking` succeeds.
    @Published var stripeCustomerId: String?
    @Published var stripeEphemeralKey: String?

    /// Idempotency seed for the current booking attempt — sent as
    /// `booking_attempt_id` on every `POST /bookings/payment-intent`
    /// call. Regenerated only when the user meaningfully changes the
    /// attempt (slot / topic swap); a network retry after failure
    /// deliberately reuses the same id so Stripe treats it as one
    /// idempotent operation.
    private(set) var bookingAttemptId: UUID = UUID()

    /// Set to true when the last confirm call landed on
    /// `PAYMENT_REQUIRES_ACTION` — the view presents a 3DS/SCA sheet,
    /// and after completion we retry `/bookings/confirm`.
    ///
    /// TODO(backend): the `stripeAccount` needed to complete 3DS on the
    /// connected-account PI is expected in `detail.stripe_account` of
    /// the 402 error. Wire the full retry once that ships.
    @Published var pendingSCAChallenge: SCAChallenge?

    /// Carries the `client_secret` (and, when the backend ships it,
    /// the `stripe_account`) the SDK needs to complete 3DS.
    struct SCAChallenge: Equatable {
        let clientSecret: String
        /// Connected account id for the PI. Nil until backend adds it
        /// to `detail.stripe_account`; the sheet handles nil as a
        /// hard-fail.
        let stripeAccount: String?
    }

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
        paymentMethodsAvailability: PaymentMethodsAvailability = .available,
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
        self.paymentMethodsAvailability = paymentMethodsAvailability
        self.topicsState = .loaded
        self.availabilityState = availabilityByDate.isEmpty ? .idle : .loaded
        self.selectedTopic = topics.first
    }

    // MARK: - Load

    func onAppear() async {
        async let t: Void = loadTopics()
        async let a: Void = loadAvailability(for: displayedMonth)
        async let p: Void = loadPaymentMethods()
        _ = await (t, a, p)
    }

    /// Fetches the client's saved cards to gate the paid-booking CTA.
    /// A load failure is treated as "no cards" — the CTA routes to
    /// Payment Methods, which surfaces its own retry, rather than
    /// silently permitting a booking that would then need a card to
    /// be added mid-checkout.
    func loadPaymentMethods() async {
        do {
            let response = try await api.getPaymentMethods()
            savedPaymentMethods = response.data.paymentMethods
            paymentMethodsAvailability = response.data.paymentMethods.isEmpty ? .none : .available
        } catch {
            savedPaymentMethods = []
            paymentMethodsAvailability = .none
        }
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
            completedBookingId = response.data.bookingId
        } catch {
            bookingError = Self.message(for: error)
        }
    }

    // MARK: - Paid flow (Path A — server-side confirm)

    /// Two-endpoint kick-off:
    /// 1. `POST /bookings/payment-intent` — creates the PI on the expert's
    ///    connected account (server-only concern; the client just needs the
    ///    `pi_…` id to hand back at `/bookings/confirm`).
    /// 2. `POST /me/payment-methods/setup-intent` — mints a SetupIntent on
    ///    the platform customer so PaymentSheet can collect a card
    ///    **without** confirming the connected-account PI. The resulting
    ///    `pm_…` is what we hand to `/bookings/confirm` for the server to
    ///    confirm off-session on the connected account.
    ///
    /// Runs the two calls sequentially. `async let` was rejected by Swift 6
    /// strict concurrency — the child task ends up nonisolated and Swift's
    /// synthesized main-actor `Decodable` conformance on the response types
    /// can't be used from there. The serial cost (~two RTTs on tap) is
    /// imperceptible and only paid once per booking attempt. On any
    /// failure the flow resets — `bookingAttemptId` is preserved so a
    /// user-triggered retry lands on the same idempotency key.
    private func beginPaidBooking(topic: BookingTopic, slot: BookingTimeSlot) async {
        paidStep = .creatingIntent

        let selectedDateUTC = Self.utcDateString(from: slot.startTime)
        let timeSlotUTC = Self.utcTimeSlotString(from: slot.startTime)

        do {
            let intent = try await api.createPaymentIntent(
                expertId: expertId,
                topicId: topic.id,
                selectedDate: selectedDateUTC,
                timeSlot: timeSlotUTC,
                durationMinutes: topic.durationMinutes,
                bookingAttemptId: bookingAttemptId,
                promoCode: nil
            )
            let setup = try await api.createPaymentMethodSetupIntent().data

            paymentIntentId = intent.paymentIntentId
            setupIntentClientSecret = setup.clientSecret
            // Customer + ephemeral come from the SetupIntent so PaymentSheet
            // lists the platform customer's saved cards. The PI response
            // returns the same platform customer's ids too — either source
            // works; picking one keeps the field origin unambiguous.
            stripeCustomerId = setup.customerId
            stripeEphemeralKey = setup.ephemeralKey
            paymentSummary = PaymentSummary(
                subtotal: intent.summary.subtotal,
                discount: intent.summary.discount,
                total: intent.summary.total,
                currency: intent.currency
            )
            paidStep = .collectingPaymentMethod
        } catch {
            // Long-lead branch — server refused PI creation because the
            // slot is > 6 days out. Skip the payment-intent step
            // entirely and confirm against a saved card; the server
            // schedules the actual charge ~24h before the session.
            // See Phase 27.1 / `RESCHEDULE-PAYMENT-CONVERSION.md`.
            if Self.errorCode(for: error) == .longLeadRequiresSavedCard {
                await performLongLeadBooking(topic: topic, slot: slot)
                return
            }
            handlePaidFlowError(error, phase: .createIntent, topic: topic, slot: slot)
        }
    }

    /// Long-lead paid booking (session > 6 days out). Skips
    /// `/bookings/payment-intent` and calls `/bookings/confirm`
    /// **without** a `payment_intent_id`, routing the server to the
    /// save-card-first / charge-at-T-24h branch (Phase 27.1). Requires
    /// a saved card; the CTA gate already ensures this, so the missing
    /// -pm guard here is a belt-and-suspenders backstop rather than a
    /// user-visible state.
    private func performLongLeadBooking(topic: BookingTopic, slot: BookingTimeSlot) async {
        guard let pmId = preferredPaymentMethodId else {
            paidStep = .idle
            bookingError = "Please add a payment method before booking."
            return
        }

        paidStep = .confirming
        do {
            let startTimeISO = Self.iso8601String(from: slot.startTime)
            let response = try await api.confirmBooking(
                paymentIntentId: nil,
                expertId: expertId,
                topicId: topic.id,
                startTime: startTimeISO,
                meetingType: meetingType,
                stripePaymentMethodId: pmId,
                clientNotes: clientNotes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                promoCode: nil
            )
            completedBookingId = response.data.bookingId
            resetPaidFlow()
        } catch {
            handlePaidFlowError(error, phase: .confirm, topic: topic, slot: slot)
        }
    }

    /// Called from the PaymentSheet completion handler after the user
    /// has selected/entered a card. Server confirms the PI on the
    /// connected account, authorizes funds (not captured yet — capture
    /// runs post-session, ~15 min after the end time, per Phase 27),
    /// and creates the booking.
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
            // Funds are AUTHORIZED, not captured. Capture runs post-session
            // (~15 min after end time, per Phase 27). Success routes the
            // user to `BookingRequestSentView` where the payment
            // lifecycle is explained inline; the raw server message is
            // no longer surfaced.
            completedBookingId = response.data.bookingId
            resetPaidFlow()
        } catch {
            handlePaidFlowError(error, phase: .confirm, topic: topic, slot: slot)
        }
    }

    /// Called when the user dismisses the PaymentSheet without paying.
    func cancelPaidBooking() {
        resetPaidFlow()
    }

    private func resetPaidFlow() {
        paidStep = .idle
        paymentIntentId = nil
        setupIntentClientSecret = nil
        stripeCustomerId = nil
        stripeEphemeralKey = nil
        paymentSummary = nil
        pendingSCAChallenge = nil
    }

    /// Regenerate `bookingAttemptId` when the user meaningfully changes
    /// the attempt (slot / topic / expert swap). Called by setters below
    /// via `didSet`.
    private func newBookingAttempt() {
        bookingAttemptId = UUID()
    }

    // MARK: - Paid flow error handling

    private enum PaidPhase { case createIntent, confirm }

    /// Maps `ErrorCode` → user-visible message + side effects, per the
    /// backend Stripe integration doc. Codes without a specific action
    /// fall back to the server's `message`.
    private func handlePaidFlowError(_ error: Error, phase: PaidPhase, topic: BookingTopic, slot: BookingTimeSlot) {
        let code = Self.errorCode(for: error)
        let message = Self.message(for: error)

        switch code {
        case .paymentRequiresAction:
            // Server confirmed the PI but it needs SCA/3DS. The client
            // completes the challenge, then re-hits `/bookings/confirm`
            // (server re-detects `requires_capture` and skips confirm).
            if let detail = Self.errorDetail(for: error),
               let clientSecret = detail["client_secret"] as? String {
                let stripeAccount = detail["stripe_account"] as? String
                pendingSCAChallenge = SCAChallenge(
                    clientSecret: clientSecret,
                    stripeAccount: stripeAccount
                )
                // Stay in `.confirming` — the SCA challenge sheet is
                // presented by the view; on completion we retry confirm.
                return
            }
            bookingError = message
            resetPaidFlow()

        case .bookingAttemptConflict:
            // Same `booking_attempt_id`, different details — regenerate
            // and start over from the intent-create step.
            newBookingAttempt()
            bookingError = "Please try booking again."
            resetPaidFlow()

        case .intentExpired, .piContextMismatch, .piAmountMismatch:
            // PI is unusable. Regenerate attempt id and reset so the
            // user can retry cleanly.
            newBookingAttempt()
            bookingError = message
            resetPaidFlow()

        case .expertNotBookable:
            bookingError = "This expert isn't accepting bookings right now."
            resetPaidFlow()

        case .slotUnavailable:
            // Kick the user back to the slot picker — the slot they had
            // just got taken.
            selectedTimeSlot = nil
            newBookingAttempt()
            bookingError = "That time slot was just taken. Please pick another."
            resetPaidFlow()

        case .invalidPaymentMethod:
            bookingError = "This payment method can't be used for this booking. Please choose another card."
            resetPaidFlow()

        case .meetingLinkUnavailable:
            bookingError = "The expert hasn't set up their Skype/Zoom link yet. Please choose in-app voice instead."
            resetPaidFlow()

        case .directChargeDisabled:
            bookingError = "Payments are temporarily unavailable. Please try again in a few minutes."
            resetPaidFlow()

        case .paymentFailed:
            bookingError = "Your card was declined. Please try another card."
            resetPaidFlow()

        case .duplicateBooking:
            bookingError = "A booking for this session already exists."
            resetPaidFlow()

        case .amountBelowMinimum:
            bookingError = "The session total is below the minimum charge amount."
            resetPaidFlow()

        case .invalidPromo:
            bookingError = "That promo code isn't valid."
            resetPaidFlow()

        case .cannotBookSelf:
            bookingError = "You can't book yourself."
            resetPaidFlow()

        default:
            // On confirm-phase failure include the PI reference so
            // support can reconcile if funds were charged.
            if phase == .confirm, let intentId = paymentIntentId {
                bookingError = "\(message)\n\nPayment reference: \(intentId)"
            } else {
                bookingError = message
            }
            resetPaidFlow()
        }
        _ = topic; _ = slot // reserved for future retry recovery
    }

    /// Called by the SCA challenge sheet after 3DS finishes. Re-hits
    /// `/bookings/confirm` with the SAME `pm_…` — server sees the PI is
    /// now `requires_capture` and skips its own confirm, just creating
    /// the booking.
    func retryConfirmAfterSCA(paymentMethodId: String) async {
        pendingSCAChallenge = nil
        await completePaidBooking(paymentMethodId: paymentMethodId)
    }

    /// Called if the SCA challenge failed or the user cancelled it.
    func cancelSCA(withMessage message: String? = nil) {
        pendingSCAChallenge = nil
        if let message { bookingError = message }
        resetPaidFlow()
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
            description: t.description,
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

    private static func errorCode(for error: Error) -> ErrorCode? {
        guard case let NetworkError.httpError(_, data) = error,
              let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        else { return nil }
        return response.code
    }

    /// Parses `detail` from the raw JSON error body via `JSONSerialization`
    /// so `.convertFromSnakeCase` doesn't rewrite keys — the doc-defined
    /// keys (`client_secret`, `stripe_account`) are snake_case and must
    /// stay that way for lookup.
    private static func errorDetail(for error: Error) -> [String: Any]? {
        guard case let NetworkError.httpError(_, data) = error,
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return root["detail"] as? [String: Any]
    }
}

// MARK: - Small helpers

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
