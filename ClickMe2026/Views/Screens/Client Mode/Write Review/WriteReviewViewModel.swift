//
//  WriteReviewViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class WriteReviewViewModel: ObservableObject {


    // MARK: Required inputs

    let bookingId: UUID
    let bookingStatus: PastBookingStatus

    // MARK: Loaded content (seeded by caller, refreshed by /reviews/context)

    @Published var expertName: String
    @Published var expertImageURL: String
    @Published var sessionTopic: String?

    // MARK: Form state

    @Published var selectedStars: Int
    @Published var hoverStar: Int
    @Published var reviewText: String

    /// True when the server already has a review from this user for this
    /// booking — the endpoint has upsert-on-resubmit semantics, so we still
    /// let the user submit again (edit).
    @Published var hasSubmittedBefore: Bool

    // MARK: Submission state

    @Published var contextState: LoadState
    @Published var isSubmitting: Bool
    @Published var didSubmit: Bool
    @Published var submitError: String?

    // MARK: Animation state

    @Published var glowPulse: Bool
    @Published var starsAnimated: Bool

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Inits

    /// Runtime init. Reviews are only permitted for completed bookings; the
    /// view enforces that via `isEligible` derived from `bookingStatus`.
    init(
        bookingId: UUID,
        bookingStatus: PastBookingStatus,
        seedExpertName: String = "",
        seedExpertImageURL: String = "",
        api: ClickMeAPI = .shared
    ) {
        self.bookingId = bookingId
        self.bookingStatus = bookingStatus
        self.expertName = seedExpertName
        self.expertImageURL = seedExpertImageURL
        self.sessionTopic = nil
        self.selectedStars = 5
        self.hoverStar = 0
        self.reviewText = ""
        self.hasSubmittedBefore = false
        self.contextState = .idle
        self.isSubmitting = false
        self.didSubmit = false
        self.submitError = nil
        self.glowPulse = false
        self.starsAnimated = false
        self.api = api
    }

    /// Preview seam — pre-installs display state without hitting the network.
    static func previewSeed(
        bookingId: UUID = UUID(),
        bookingStatus: PastBookingStatus = .completed,
        expertName: String = "Dr. Anya Sharma",
        expertImageURL: String = "https://randomuser.me/api/portraits/women/55.jpg",
        sessionTopic: String? = "Career Coaching",
        selectedStars: Int = 5,
        reviewText: String = "",
        hasSubmittedBefore: Bool = false,
        didSubmit: Bool = false,
        starsAnimated: Bool = false
    ) -> WriteReviewViewModel {
        let vm = WriteReviewViewModel(
            bookingId: bookingId,
            bookingStatus: bookingStatus,
            seedExpertName: expertName,
            seedExpertImageURL: expertImageURL
        )
        vm.sessionTopic = sessionTopic
        vm.selectedStars = selectedStars
        vm.reviewText = reviewText
        vm.hasSubmittedBefore = hasSubmittedBefore
        vm.didSubmit = didSubmit
        vm.starsAnimated = starsAnimated
        vm.contextState = bookingStatus == .completed ? .loaded : .idle
        return vm
    }

    // MARK: Derived

    /// Only completed bookings can be reviewed. Cancelled / missed / expired
    /// / declined all block the form from showing.
    var isEligible: Bool { bookingStatus == .completed }

    // MARK: - Load

    /// Fetches the review context on view appear. No-op for ineligible
    /// bookings (the view shows the locked state instead) and for the
    /// preview seed (state already `.loaded`).
    func onAppear() async {
        guard isEligible else { return }
        if case .loaded = contextState { return }
        await loadContext()
    }

    private func loadContext() async {
        contextState = .loading
        do {
            let response = try await api.getReviewContext(bookingId: bookingId)
            let data = response.data
            if let name = data.reviewTarget.name { expertName = name }
            if let avatar = data.reviewTarget.avatarUrl { expertImageURL = avatar }
            sessionTopic = data.sessionTopic
            hasSubmittedBefore = data.hasSubmitted
            if data.hasSubmitted, let prefill = data.prefill {
                selectedStars = prefill.rating
                reviewText = prefill.comment ?? ""
            }
            contextState = .loaded
        } catch {
            contextState = .failed(Self.message(for: error))
        }
    }

    // MARK: - Actions

    func selectStar(_ star: Int) {
        withAnimation(.spring(response: 0.30, dampingFraction: 0.55)) {
            selectedStars = star
        }
    }

    /// Submits the review to `POST /bookings/:id/reviews`. Calls `onSuccess`
    /// after the server acknowledges. Guarded by `isEligible` — ineligible
    /// bookings will silently no-op instead of hitting the endpoint.
    func submit(onSuccess: @escaping (Int, String) -> Void) {
        guard isEligible, !isSubmitting, !didSubmit else { return }
        withAnimation(.easeInOut(duration: 0.2)) { isSubmitting = true }

        Task {
            defer {
                withAnimation(.easeInOut(duration: 0.2)) { isSubmitting = false }
            }
            do {
                let trimmed = reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
                _ = try await api.postReview(
                    bookingId: bookingId,
                    rating: selectedStars,
                    comment: trimmed.isEmpty ? nil : trimmed,
                    tags: []
                )
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    didSubmit = true
                    hasSubmittedBefore = true
                }
                onSuccess(selectedStars, trimmed)
            } catch {
                submitError = Self.message(for: error)
            }
        }
    }

    // MARK: - Error helpers

    private static func message(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
