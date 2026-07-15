//
//  IncomingRequestsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class IncomingRequestsViewModel: ObservableObject {


    // MARK: State
    @Published var requests: [BookingRequest]
    @Published var loadState: LoadState

    // MARK: Dependencies
    private let api: ClickMeAPI

    /// Client's calendar / current time — injected here so tests can freeze
    /// "now" when they need deterministic `expiresInHours` values.
    private let now: () -> Date

    // MARK: Init

    init(api: ClickMeAPI = .shared, now: @escaping () -> Date = Date.init) {
        self.requests = []
        self.loadState = .idle
        self.api = api
        self.now = now
    }

    /// Preview seam — installs canned data as if the fetch had succeeded.
    static func previewSeed(requests: [BookingRequest] = BookingRequest.samples) -> IncomingRequestsViewModel {
        let vm = IncomingRequestsViewModel()
        vm.requests = requests
        vm.loadState = .loaded
        return vm
    }

    // MARK: - Load

    /// Fetches `GET /expert/booking-requests` (page 1) and maps every row
    /// to the local display model. Idempotent — skips when already loaded
    /// so preview seeds aren't clobbered.
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
            let response = try await api.getBookingRequests(page: 1, limit: 50)
            requests = response.data.requests
                .map { Self.mapRequest(from: $0, now: now()) }
                .sorted { Self.sortKey(for: $0) < Self.sortKey(for: $1) }
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }
    }

    /// Pending first (soonest expiry earliest), expired last.
    private static func sortKey(for request: BookingRequest) -> (Int, Int) {
        // (isExpired ? 1 : 0, expiresInHours) — pending sort ascending by
        // hours-to-expiry, expired sink to the bottom in insertion order.
        (request.isExpired ? 1 : 0, request.expiresInHours)
    }

    // MARK: - Mapping

    static func mapRequest(from item: BookingRequestItem, now: Date) -> BookingRequest {
        let expiresAt = item.expiresAt ?? now
        let secondsLeft = max(0, Int(expiresAt.timeIntervalSince(now)))
        let hoursLeft = secondsLeft / 3600
        let isExpired = item.status == "expired" || expiresAt <= now

        return BookingRequest(
            id: item.requestId,
            clientName: item.client.fullName ?? "Client",
            clientImageURL: item.client.avatarUrl ?? "",
            topic: item.topic ?? "",
            dateTime: formatDateTime(start: item.timeSlot.startTime, end: item.timeSlot.endTime),
            earnings: formatEarnings(amountMajor: item.earnings, currency: item.currency),
            expiresInHours: hoursLeft,
            // < 6 h to expiry rings amber; ≥ 6 h stays green. Time-based
            // priority replaces the old server-driven `is_high_priority`
            // flag (which never existed on the wire).
            isHighPriority: !isExpired && hoursLeft < 6,
            isExpired: isExpired
        )
    }

    private static func formatDateTime(start: Date, end: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm a"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return "\(dateFormatter.string(from: start)) - \(timeFormatter.string(from: end))"
    }

    /// Server sends earnings in **major currency units** already
    /// (`amount_paid_minor_units / 100`), unlike prices in `topic.price`
    /// which are minor units. NumberFormatter handles the cent
    /// suffix — `75.0` → `"$75"`, `75.5` → `"$75.50"`.
    private static func formatEarnings(amountMajor: Double?, currency: String?) -> String {
        guard let amount = amountMajor, let currency = currency else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = amount.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: amount))
            ?? "\(currency) \(String(format: "%.0f", amount))"
    }

    // MARK: - Error mapping

}
