//
//  ExpertDashboardViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ExpertDashboardViewModel: ObservableObject {


    // MARK: Data

    @Published var expertFirstName: String
    @Published var expertLastName: String
    @Published var pendingCount: Int
    /// All confirmed bookings whose `startTime` falls within today (client
    /// local timezone). Multiple cards render for accounts with multiple
    /// sessions in a day.
    @Published var todaysSessions: [ExpertBookingItem]

    // MARK: Financial

    /// `GET /expert/earnings/weekly` snapshot. Nil when the fetch fails
    /// or hasn't completed — soft dependency, hides the "This Week"
    /// figure without blocking the rest of the dashboard.
    @Published var weeklyEarnings: WeeklyEarningsData?

    /// `GET /expert/payouts/summary` snapshot. Nil when Stripe Connect
    /// isn't fully onboarded (see `payoutOnboardingRequired`) or the
    /// fetch failed.
    @Published var payoutSummary: PayoutSummaryData?

    /// True when `getPayoutSummary` returned 400 `NO_PAYOUT_METHOD` /
    /// `KYC_INCOMPLETE`. Drives a "Complete payout setup" CTA in place
    /// of the balance block.
    @Published var payoutOnboardingRequired: Bool

    /// Fresh Stripe Account Link URL — set by `startOnboarding()` for the
    /// view to open in a browser. Consumed immediately; the URL is
    /// single-use and expires in ~5 min.
    @Published var connectOnboardingURL: URL?

    /// Alert text for Stripe Connect onboarding failures.
    @Published var connectError: String?

    @Published var loadState: LoadState

    // MARK: Dependencies

    private let api: ClickMeAPI

    /// Client's local calendar — used for "is this booking today?" checks.
    private let calendar: Calendar = .current

    // MARK: Init

    /// Runtime init — hydrates expert name from the cached login snapshot
    /// and fetches today's bookings + pending count on `load()`.
    init(api: ClickMeAPI = .shared) {
        self.expertFirstName = ""
        self.expertLastName = ""
        self.pendingCount = 0
        self.todaysSessions = []
        self.weeklyEarnings = nil
        self.payoutSummary = nil
        self.payoutOnboardingRequired = false
        self.connectOnboardingURL = nil
        self.connectError = nil
        self.loadState = .idle
        self.api = api
    }

    /// Preview seam — installs canned data as if the fetch had succeeded.
    static func previewSeed(
        expertFirstName: String = "Ethan",
        expertLastName: String = "Carter",
        pendingCount: Int = 3,
        todaysSessions: [ExpertBookingItem] = [],
        weeklyEarnings: WeeklyEarningsData? = WeeklyEarningsData(
            weekStart: "2026-07-06",
            weekEnd: "2026-07-12",
            grossAmount: 142000,
            netAmount: 120000,
            currency: "USD",
            sessionCount: 8
        ),
        payoutSummary: PayoutSummaryData? = PayoutSummaryData(
            availableAmount: 385000,
            pendingAmount: 42000,
            currency: "USD",
            nextPayoutDate: "2026-07-15",
            payoutMethod: "bank_transfer"
        ),
        payoutOnboardingRequired: Bool = false
    ) -> ExpertDashboardViewModel {
        let vm = ExpertDashboardViewModel()
        vm.expertFirstName = expertFirstName
        vm.expertLastName = expertLastName
        vm.pendingCount = pendingCount
        vm.todaysSessions = todaysSessions
        vm.weeklyEarnings = weeklyEarnings
        vm.payoutSummary = payoutSummary
        vm.payoutOnboardingRequired = payoutOnboardingRequired
        vm.loadState = .loaded
        return vm
    }

    // MARK: - Load

    /// Fetches everything the dashboard needs:
    /// 1. Expert name from the cached auth snapshot (already in memory).
    /// 2. `GET /expert/bookings` → filter to today's confirmed bookings.
    /// 3. `GET /expert/booking-requests` → pending count.
    /// 4. `GET /expert/earnings/weekly` → weekly net earnings (soft).
    /// 5. `GET /expert/payouts/summary` → available balance + payout meta
    ///    (soft; 400 → sets `payoutOnboardingRequired`).
    /// Idempotent — skips when already loaded.
    func load() async {
        if case .loaded = loadState { return }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        loadState = .loading

        // Name — from the auth snapshot cached at login. Nil-safe fallback
        // to empty strings so the header renders even before login state
        // is fully hydrated.
        if let authUser = UserManager.shared.authUser {
            expertFirstName = authUser.firstName
            expertLastName = authUser.lastName
        }

        // Bookings + pending requests — hard dependencies; a failure here
        // blocks the whole dashboard.
        //
        // Sequential — parallel `async let` decoding trips Swift 6's
        // main-actor-isolated-Decodable check.
        do {
            let bookingResponse = try await api.getExpertBookings(page: 1, limit: 50)
            todaysSessions = bookingResponse.data.bookings
                .filter { isToday($0.session.startTime) && Self.isJoinable($0.status.code) }
                .sorted { $0.session.startTime < $1.session.startTime }

            let requestResponse = try await api.getBookingRequests(page: 1, limit: 20)
            pendingCount = requestResponse.data.pagination?.totalCount
                ?? requestResponse.data.requests.count
        } catch {
            loadState = .failed(error.userMessage)
            return
        }

        // Financial fetches — soft dependencies. A failure here dims the
        // Financial Summary but doesn't blank out the whole dashboard.
        await fetchWeeklyEarnings()
        await fetchPayoutSummary()

        loadState = .loaded
    }

    private func fetchWeeklyEarnings() async {
        do {
            let response = try await api.getWeeklyEarnings()
            weeklyEarnings = response.data
        } catch {
            // Silent — the section falls back to a placeholder.
            weeklyEarnings = nil
        }
    }

    /// Fetches the live payout balance. Server returns 400 with codes
    /// `NO_PAYOUT_METHOD` / `KYC_INCOMPLETE` when the expert hasn't
    /// completed Stripe Connect onboarding — the view swaps the balance
    /// block for a "Complete payout setup" CTA in that case.
    private func fetchPayoutSummary() async {
        do {
            let response = try await api.getPayoutSummary()
            payoutSummary = response.data
            payoutOnboardingRequired = false
        } catch {
            payoutSummary = nil
            if case let NetworkError.httpError(status, _) = error, status == 400 {
                payoutOnboardingRequired = true
            } else {
                payoutOnboardingRequired = false
            }
        }
    }

    // MARK: - Stripe Connect onboarding

    /// Fetches a fresh Stripe Account Link URL and hands it to the view
    /// via `connectOnboardingURL`. The URL is single-use with a ~5-minute
    /// expiry, so we never cache it.
    func startOnboarding() async {
        connectError = nil
        do {
            let response = try await api.startConnectOnboarding()
            connectOnboardingURL = URL(string: response.data.url)
        } catch {
            connectError = error.userMessage
        }
    }

    // MARK: - Derived helpers

    /// True when the booking's `startTime` falls within ±1 hour of now —
    /// same window as the client-side `UpcomingBooking.isWithinJoinWindow`
    /// convention. Drives the "STARTING NOW" pill on each session card.
    func isStartingNow(_ booking: ExpertBookingItem) -> Bool {
        let delta = booking.session.startTime.timeIntervalSinceNow
        return delta <= 3600 && delta >= -3600
    }

    /// `"10:00 AM — 11:00 AM"` formatted in the client's locale.
    func timeLabel(_ booking: ExpertBookingItem) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        let start = f.string(from: booking.session.startTime)
        let end = f.string(from: booking.session.endTime)
        return "\(start) — \(end)"
    }

    // MARK: - Currency formatting

    /// Formats `amount` in minor units to a localized currency string —
    /// e.g. `12000` + `"USD"` → `"$120.00"` (or `"$120"` when the amount
    /// has no cents). Falls back to `"USD 120"`-style on unknown codes.
    static func currencyLabel(minorUnits: Int, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        let value = Double(minorUnits) / 100.0
        formatter.maximumFractionDigits = Double(minorUnits).truncatingRemainder(dividingBy: 100) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: value))
            ?? "\(currency) \(String(format: "%.0f", value))"
    }

    /// Human-friendly form of `next_payout_date` (server sends
    /// `YYYY-MM-DD`) → e.g. `"May 15"`. Falls back to the raw string on
    /// parse failure.
    static func payoutDateLabel(_ isoDate: String) -> String {
        let inFormatter = DateFormatter()
        inFormatter.locale = Locale(identifier: "en_US_POSIX")
        inFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = inFormatter.date(from: isoDate) else { return isoDate }

        let outFormatter = DateFormatter()
        outFormatter.dateFormat = "MMM d"
        return outFormatter.string(from: date)
    }

    // MARK: - Private helpers

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    /// Statuses that qualify a booking to appear on the dashboard's
    /// "Today's Sessions" strip. `pendingApproval` is intentionally excluded
    /// — those show up separately in the "Pending Requests" banner, and
    /// they shouldn't render a Join button since the expert hasn't accepted
    /// the request yet.
    private static func isJoinable(_ status: BookingStatus) -> Bool {
        switch status {
        case .confirmed, .inProgress, .pendingReschedule:
            return true
        case .pendingApproval, .completed, .cancelled, .declined, .missed, .expired:
            return false
        }
    }

    // MARK: - Error mapping

}
