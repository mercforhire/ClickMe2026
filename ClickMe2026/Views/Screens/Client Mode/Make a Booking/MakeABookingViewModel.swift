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
            guard oldValue?.id != selectedTopic?.id else { return }
            newBookingAttempt()
            // Free to paid: a slot picked under no limit may now be past
            // the 6-day limit.
            if let slot = selectedTimeSlot, !isBookableStart(slot.startTime) {
                selectedTimeSlot = nil
            }
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

    /// BOOK-02: month changes start overlapping availability loads, and their
    /// responses can land out of order. Only the newest load may write the
    /// calendar; an older one finishes its call and writes nothing.
    private var availabilityGate = ReloadGeneration()

    /// The load started by the latest month change, cancelled when the next
    /// month change starts so a superseded request stops early.
    private var availabilityTask: Task<Void, Never>?

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
    /// in sync with `paymentMethodsAvailability`. The PaymentSheet flow
    /// does not read this and relies on PaymentSheet's own saved-card
    /// list.
    @Published var savedPaymentMethods: [PaymentMethodItem] = []

    /// True when the selected topic is paid and the client has no
    /// saved cards on file. Drives the CTA to route to Payment Methods
    /// instead of starting the paid booking flow.
    var requiresPaymentMethodSetup: Bool {
        guard let topic = selectedTopic, !topic.isFree else { return false }
        return paymentMethodsAvailability == .none
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
    /// Raised when the automatic confirm retries run out with the outcome still
    /// unknown (D-03). The paid flow stays on `.confirming` while it is set.
    /// Declared here because a stored property cannot live in an extension; the
    /// type and its actions are in `MakeABookingViewModel+PaidFlow.swift`.
    @Published var paidFlowAlert: PaidFlowAlert?
    /// The paid attempt in flight: topic, slot, PaymentIntent, meeting type and
    /// notes as they were when Book Now created the PaymentIntent (CR-01). Set
    /// only by `beginPaidBooking` and cleared only by `resetPaidFlow()`. Internal
    /// so tests can install one (a test seam, like `confirmRetryPolicy`); not
    /// published because no view renders it.
    var paidAttempt: PaidAttempt?
    /// The PaymentIntent of the current paid attempt.
    var paymentIntentId: String? { paidAttempt?.paymentIntentId }
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
    /// The 402 `detail` carries both `client_secret` and `stripe_account`
    /// (backend WR-02 exception).
    @Published var pendingSCAChallenge: SCAChallenge?

    /// Carries the `client_secret` and the `stripe_account` the SDK needs to
    /// complete 3DS.
    struct SCAChallenge: Equatable {
        let clientSecret: String
        /// Connected account id for the PI, from `detail.stripe_account` of the
        /// 402. A missing value fails closed: the sheet treats nil as a
        /// hard fail rather than guessing an account.
        let stripeAccount: String?
    }

    /// How a paid confirm is retried when its outcome is unknown (D-03).
    /// A test seam: tests inject zero delays so retries do not wait.
    var confirmRetryPolicy: ConfirmRetryPolicy = .standard

    /// The `pm_…` id of the confirm in flight, kept until the user leaves an
    /// unknown outcome so Try again can send the same confirm. Internal so
    /// `MakeABookingViewModel+PaidFlow.swift` can read and clear it.
    var confirmPaymentMethodId: String?

    /// True while a `POST /bookings/confirm` run (first attempt and automatic
    /// retries) is in progress. Guards against a second confirm for the same
    /// attempt (Pitfall 11).
    private(set) var isConfirmRunning = false

    /// True while either the free flow is submitting or the paid flow is
    /// in-flight. The book button binds to this.
    var isSubmitting: Bool { isBooking || paidStep != .idle }

    // MARK: Calendar constants

    let calendar = Calendar.current
    let dayHeaders = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    // MARK: Dependencies

    private let api: ClickMeAPI

    /// Confirms whose booking may exist without the app knowing (PAY-02, D-04).
    /// Internal so `MakeABookingViewModel+PaidFlow.swift` can read it. Tests pass
    /// their own instance and never write to `.shared`.
    let ledger: UnconfirmedBookingLedger

    // MARK: Init

    init(
        expertId: UUID,
        expertName: String,
        expertTitle: String,
        expertImageURL: String,
        ledger: UnconfirmedBookingLedger = .shared,
        api: ClickMeAPI = .shared
    ) {
        self.expertId = expertId
        self.expertName = expertName
        self.expertTitle = expertTitle
        self.expertImageURL = expertImageURL
        self.ledger = ledger
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
        ledger: UnconfirmedBookingLedger = .shared,
        api: ClickMeAPI = .shared
    ) {
        self.expertId = expertId
        self.expertName = expertName
        self.expertTitle = expertTitle
        self.expertImageURL = expertImageURL
        self.ledger = ledger
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
            self.topicsState = .failed(error.userMessage)
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
    ///
    /// BOOK-02: the load takes a `ReloadGeneration` token first and checks it
    /// after every `await`. It writes `availabilityByDate`, `expertTimezone`
    /// and `availabilityState` only while it is the newest load and `month`
    /// is still the displayed month, so a slower older month never lands on
    /// top of a newer one. A cancelled or superseded request is not a
    /// failure and never sets `.failed`; the newest load owns the state.
    func loadAvailability(for month: Date) async {
        let token = availabilityGate.begin()
        availabilityState = .loading
        // A paid attempt in flight keeps its slot (CR-01): the confirm reads
        // `paidAttempt`, and clearing would also regenerate `bookingAttemptId`.
        if !isSubmitting { selectedTimeSlot = nil }

        // Center month — surfaces the error if this one fails.
        let center: SuccessDataResponse<ExpertAvailabilityData>
        do {
            center = try await api.getExpertAvailability(id: expertId, month: Self.monthKey(month))
        } catch {
            guard availabilityGate.isCurrent(token), !Self.isCancellation(error) else { return }
            availabilityState = .failed(error.userMessage)
            return
        }
        guard availabilityGate.isCurrent(token) else { return }

        // Neighbors — best-effort. `try?` swallows failures silently so a
        // flaky neighbor doesn't blank out the whole calendar.
        let prev = calendar.date(byAdding: .month, value: -1, to: month) ?? month
        let next = calendar.date(byAdding: .month, value: 1, to: month) ?? month
        let prevData = try? await api.getExpertAvailability(id: expertId, month: Self.monthKey(prev)).data
        guard availabilityGate.isCurrent(token) else { return }
        let nextData = try? await api.getExpertAvailability(id: expertId, month: Self.monthKey(next)).data
        guard availabilityGate.isCurrent(token),
              calendar.isDate(month, equalTo: displayedMonth, toGranularity: .month)
        else { return }

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
        availabilityTask?.cancel()
        availabilityTask = Task { await loadAvailability(for: displayedMonth) }
    }

    func goToNextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        availabilityTask?.cancel()
        availabilityTask = Task { await loadAvailability(for: displayedMonth) }
    }

    /// A cancelled request is not a failure (same rule as
    /// `ExploreClientViewModel.isCancellation`).
    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        return false
    }

    // MARK: - Slots for the selected day

    /// Slots for `selectedDate`, in the order returned by the server. Nothing
    /// is dropped: a slot a paid topic cannot book (more than 6 days ahead,
    /// BOOK-14) stays in the list and renders dimmed, as on Android. See
    /// `isSelectableSlot(_:)`.
    var slotsForSelectedDate: [BookingTimeSlot] {
        availabilityByDate[Self.dateKey(selectedDate, calendar: calendar)] ?? []
    }

    // MARK: - Paid booking window (BOOK-14)

    /// The latest start the selected topic can book, or nil for no limit.
    /// Read from the clock on every call so a screen left open never keeps a
    /// stale limit. Non-nil also means the slots card shows the paid window
    /// note (Android `latestSelectableStart`).
    var latestBookableStart: Date? {
        PaidBookingWindow.latestStart(isPaid: !(selectedTopic?.isFree ?? true), now: Date())
    }

    /// Whether the server would accept a session starting at `start` for the
    /// selected topic.
    func isBookableStart(_ start: Date) -> Bool {
        PaidBookingWindow.allows(start, latestStart: latestBookableStart)
    }

    /// Whether a chip can be tapped: the slot is available, has not started,
    /// and is inside the paid limit. Mirrors Android
    /// `BookingTimeSlot.isSelectable(now, latestStart)`. A slot that fails
    /// this is shown dimmed, never hidden.
    func isSelectableSlot(_ slot: BookingTimeSlot) -> Bool {
        slot.isAvailable && slot.startTime > Date() && isBookableStart(slot.startTime)
    }

    // MARK: - Book action

    /// Entry point for the "Book Now" button. Branches on `topic.isFree`:
    /// free → `POST /bookings/request` (single call), paid → begin the paid
    /// flow which fetches a PaymentIntent and hands the client secret over
    /// to the view for PaymentSheet presentation.
    func book() {
        guard !isSubmitting else { return }
        guard let topic = selectedTopic, let slot = selectedTimeSlot else { return }

        // The picker dims these; this catches a slot that drifted past the
        // limit while the screen was open. No request is made.
        guard isBookableStart(slot.startTime) else {
            selectedTimeSlot = nil
            bookingError = BookingErrorMapper.longLeadMessage
            return
        }

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
            let code = BookingErrorMapper.code(for: error)
            if code == .slotUnavailable {
                // Same side effect as the paid path: send the user back to
                // the slot picker, the slot they chose is gone.
                selectedTimeSlot = nil
            }
            bookingError = BookingErrorMapper.message(for: code, fallback: error.userMessage)
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

            // CR-01: snapshot the Book Now values; the confirm reads only this.
            paidAttempt = PaidAttempt(
                topic: topic,
                slot: slot,
                paymentIntentId: intent.paymentIntentId,
                meetingType: meetingType,
                clientNotes: clientNotes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            )
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
            handlePaidFlowError(error, phase: .createIntent, topic: topic, slot: slot)
        }
    }

    /// Called from the PaymentSheet completion handler after the user
    /// has selected/entered a card. Server confirms the PI on the
    /// connected account, authorizes funds (not captured yet — capture
    /// runs post-session, ~15 min after the end time, per Phase 27),
    /// and creates the booking.
    ///
    /// PAY-02 (D-03): a confirm whose outcome is unknown (transport failure,
    /// unmapped 5xx) keeps the PaymentIntent, the `pm_…` id and
    /// `bookingAttemptId`, and is sent again with the same arguments. The
    /// server replays the booking it already made (BACK-15), so a retry cannot
    /// create a second hold. Server-coded errors keep the existing mapping.
    /// The attempt's topic, slot, meeting type and notes come from `paidAttempt`
    /// (CR-01), so a change on the form never reaches the request.
    func completePaidBooking(paymentMethodId: String) async {
        // One confirm at a time: a second call while one runs would start a
        // second request for an attempt whose first outcome is still unknown.
        guard !isConfirmRunning else { return }
        guard let attempt = paidAttempt else {
            resetPaidFlow()
            return
        }

        confirmPaymentMethodId = paymentMethodId
        paidStep = .confirming
        isConfirmRunning = true
        defer { isConfirmRunning = false }

        // D-04: from here a booking may exist that the app never hears about.
        ledger.record(expertId: expertId, start: attempt.slot.startTime)

        let result = await confirmRetryPolicy.run {
            try await self.api.confirmBooking(
                paymentIntentId: attempt.paymentIntentId,
                expertId: self.expertId,
                topicId: attempt.topic.id,
                startTime: Self.iso8601String(from: attempt.slot.startTime),
                meetingType: attempt.meetingType,
                stripePaymentMethodId: paymentMethodId,
                clientNotes: attempt.clientNotes,
                promoCode: nil
            )
        }

        switch result {
        case let .succeeded(response):
            // Funds are AUTHORIZED, not captured. Capture runs post-session
            // (~15 min after end time, per Phase 27). Success routes the
            // user to `BookingRequestSentView` where the payment
            // lifecycle is explained inline; the raw server message is
            // no longer surfaced. A replayed 201 (BACK-15) lands here too.
            completedBookingId = response.data.bookingId
            ledger.clear(expertId: expertId, start: attempt.slot.startTime)
            confirmPaymentMethodId = nil
            resetPaidFlow()
        case let .serverCoded(error):
            // D-04, D-17: the record stays for SLOT_UNAVAILABLE (the slot may be
            // the client's own) and PAYMENT_IN_PROGRESS (it may still settle).
            if !UnconfirmedBookingLedger.keepsRecord(afterServerCode: BookingErrorMapper.code(for: error)) {
                ledger.clear(expertId: expertId, start: attempt.slot.startTime)
            }
            confirmPaymentMethodId = nil
            handlePaidFlowError(error, phase: .confirm, topic: attempt.topic, slot: attempt.slot)
        case .outcomeUnknown:
            // D-03: keep every id and stay on `.confirming`. The hold may
            // exist, so the flow must not reset and the attempt id must not
            // change. The alert offers Try again, Check My Bookings or Not now.
            // D-04: the ledger record stays, also after Not now or leaving the screen.
            paidFlowAlert = .confirmUnknown(paymentReference: attempt.paymentIntentId)
        }
    }

    /// Clears every paid-flow field. Internal so `MakeABookingViewModel+PaidFlow.swift`
    /// can reset the flow when the client leaves an unknown confirm outcome.
    func resetPaidFlow() {
        confirmPaymentMethodId = nil
        paidFlowAlert = nil
        paidStep = .idle
        paidAttempt = nil
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
        let code = BookingErrorMapper.code(for: error)
        let message = error.userMessage

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
            bookingError = BookingErrorMapper.message(for: code, fallback: message)
            resetPaidFlow()

        case .intentExpired, .piContextMismatch, .piAmountMismatch:
            // PI is unusable. Regenerate attempt id and reset so the
            // user can retry cleanly.
            newBookingAttempt()
            bookingError = message
            resetPaidFlow()

        case .expertNotBookable:
            bookingError = BookingErrorMapper.message(for: code, fallback: message)
            resetPaidFlow()

        case .longLeadRequiresSavedCard, .longLeadNotAvailable:
            // Terminal. The server refuses a paid start more than 6 days
            // ahead; the app never confirms without a PaymentIntent.
            selectedTimeSlot = nil
            newBookingAttempt()
            bookingError = BookingErrorMapper.message(for: code, fallback: message)
            resetPaidFlow()

        case .slotUnavailable:
            // Kick the user back to the slot picker — the slot they had
            // just got taken.
            selectedTimeSlot = nil
            newBookingAttempt()
            resetPaidFlow()
            // D-04: when a confirm of ours for this expert and slot may have
            // succeeded, "taken" could be the client's own booking, so say so
            // and point to My Bookings. The record stays. The alert is set after
            // the reset because resetPaidFlow() clears paidFlowAlert.
            if ledger.contains(expertId: expertId, start: slot.startTime) {
                paidFlowAlert = .mayAlreadyBeBooked
            } else {
                bookingError = BookingErrorMapper.message(for: code, fallback: message)
            }

        case .invalidPaymentMethod:
            bookingError = BookingErrorMapper.message(for: code, fallback: message)
            resetPaidFlow()

        case .meetingLinkUnavailable:
            bookingError = BookingErrorMapper.message(for: code, fallback: message)
            resetPaidFlow()

        case .directChargeDisabled:
            bookingError = BookingErrorMapper.message(for: code, fallback: message)
            resetPaidFlow()

        case .paymentFailed:
            bookingError = BookingErrorMapper.message(for: code, fallback: message)
            resetPaidFlow()

        case .duplicateBooking:
            // D-15: the server answers the caller's own identical active booking
            // with `detail.booking_id` (backend docs/ios/STRIPE-INTEGRATION.md,
            // BACK-15). When a lost confirm of ours left a record for this expert
            // and slot, open that booking. The id is used only when it parses as a
            // UUID; Request Sent loads it through GET /client/bookings/:id, which
            // re-checks ownership.
            if let idText = Self.errorDetail(for: error)?["booking_id"] as? String,
               let bookingId = UUID(uuidString: idText),
               ledger.contains(expertId: expertId, start: slot.startTime) {
                ledger.clear(expertId: expertId, start: slot.startTime)
                resetPaidFlow()
                completedBookingId = bookingId
                return
            }
            // D-04: no record, or no usable id. The server says the caller already
            // has this booking, so point to My Bookings. The slot is cleared so the
            // same booking cannot be resubmitted (K4).
            selectedTimeSlot = nil
            newBookingAttempt()
            resetPaidFlow()
            paidFlowAlert = .mayAlreadyBeBooked

        case .amountBelowMinimum:
            bookingError = BookingErrorMapper.message(for: code, fallback: message)
            resetPaidFlow()

        case .invalidPromo:
            bookingError = BookingErrorMapper.message(for: code, fallback: message)
            resetPaidFlow()

        case .cannotBookSelf:
            bookingError = BookingErrorMapper.message(for: code, fallback: message)
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

        /// True for a cell that only pads the grid with a day number from the
        /// previous or next month. Such a cell is never tappable, and the
        /// calendar card hides it from VoiceOver (02-UI-SPEC A1), like the
        /// Reschedule calendar's empty cells and Android's empty `Box`.
        var isFiller: Bool { date == nil }
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
