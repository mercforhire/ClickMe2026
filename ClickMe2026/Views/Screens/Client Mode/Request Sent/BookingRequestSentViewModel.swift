//
//  BookingRequestSentViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-29.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class BookingRequestSentViewModel: ObservableObject {


    // MARK: Identity

    let bookingId: UUID

    // MARK: Content (hydrated from GET /client/bookings/:id)

    @Published var expertName: String
    @Published var topic: String
    @Published var dateTime: String

    // MARK: Load state

    @Published var state: LoadState

    // MARK: Entry animation state
    @Published var iconScale: CGFloat = 0.50
    @Published var iconOpacity: Double = 0
    @Published var bodyOpacity: Double = 0
    @Published var bodyOffset: CGFloat = 22
    @Published var cardOpacity: Double = 0
    @Published var cardOffset: CGFloat = 18
    @Published var btnsOpacity: Double = 0
    @Published var btnsOffset: CGFloat = 16
    @Published var glowPulse: Bool = false

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Inits

    /// Runtime init — starts empty; `.task { load() }` hydrates from
    /// `GET /client/bookings/:id` and then runs the entry animation.
    init(bookingId: UUID, api: ClickMeAPI = .shared) {
        self.bookingId = bookingId
        self.expertName = ""
        self.topic = ""
        self.dateTime = ""
        self.state = .idle
        self.api = api
    }

    /// Preview seam — pre-installs display strings and marks state as
    /// `.loaded` so the canvas can render without hitting the network.
    static func previewSeed(
        bookingId: UUID = UUID(),
        expertName: String = "Sarah Jenkins",
        topic: String = "Advanced UI Architecture",
        dateTime: String = "Oct 24, 2023 | 2:00 PM - 3:00 PM"
    ) -> BookingRequestSentViewModel {
        let vm = BookingRequestSentViewModel(bookingId: bookingId)
        vm.expertName = expertName
        vm.topic = topic
        vm.dateTime = dateTime
        vm.state = .loaded
        return vm
    }

    // MARK: - Load

    /// Idempotent — skips when already loaded so it doesn't clobber the
    /// preview seed.
    func load() async {
        if case .loaded = state { return }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        state = .loading
        do {
            let response = try await api.getClientBookingDetail(id: bookingId)
            apply(response.data)
            state = .loaded
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    // MARK: - Mapping

    private func apply(_ data: ClientBookingDetail) {
        expertName = data.expert.fullName ?? "Expert"
        topic = data.topic.title
        dateTime = Self.dateTimeString(from: data.startTime, to: data.endTime)
    }

    // MARK: - Formatting

    /// Renders "Oct 24, 2023 | 2:00 PM - 3:00 PM" from two `Date` moments in
    /// the client's local timezone. Same shape as the sample copy.
    private static func dateTimeString(from start: Date, to end: Date) -> String {
        let dateF = DateFormatter()
        dateF.locale = Locale(identifier: "en_US_POSIX")
        dateF.dateFormat = "MMM d, yyyy"
        let timeF = DateFormatter()
        timeF.locale = Locale(identifier: "en_US_POSIX")
        timeF.dateFormat = "h:mm a"
        return "\(dateF.string(from: start)) | \(timeF.string(from: start)) - \(timeF.string(from: end))"
    }

    private static func message(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    // MARK: - Actions

    /// Staggered entry animation: glow pulse → icon spring → headline → card → buttons.
    func runEntryAnimation() {
        glowPulse = true

        withAnimation(.spring(response: 0.55, dampingFraction: 0.60).delay(0.10)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.42).delay(0.35)) {
            bodyOpacity = 1
            bodyOffset = 0
        }
        withAnimation(.easeOut(duration: 0.40).delay(0.50)) {
            cardOpacity = 1
            cardOffset = 0
        }
        withAnimation(.easeOut(duration: 0.38).delay(0.64)) {
            btnsOpacity = 1
            btnsOffset = 0
        }
    }
}
