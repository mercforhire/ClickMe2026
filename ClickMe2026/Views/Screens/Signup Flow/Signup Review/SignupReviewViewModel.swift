//
//  SignupReviewViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class SignupReviewViewModel: ObservableObject {

    // MARK: Publish state

    @Published var isPublishing: Bool = false
    @Published var didPublish: Bool = false
    @Published var publishError: String?

    // MARK: Dependencies

    private let accumulator: SignupAccumulator?
    private let previewProfile: ProfileReviewData?
    private let api: ClickMeAPI

    // MARK: Init

    /// Preview / test init — renders a static profile without hitting the network.
    init(profile: ProfileReviewData = SignupReviewViewModel.defaultProfile) {
        self.accumulator = nil
        self.previewProfile = profile
        self.api = .shared
    }

    /// Runtime init — reads display fields off the shared accumulator.
    /// On publish, PATCHes `/expert/profile/setup` with the whole payload
    /// AND `setup_completed: true` to flip the server's completion flag.
    /// (The earlier signup steps have each already persisted their slice
    /// via their own `save()` calls, so this final PATCH is idempotent
    /// with respect to the field values — it exists to flip the flag.)
    init(accumulator: SignupAccumulator, api: ClickMeAPI = .shared) {
        self.accumulator = accumulator
        self.previewProfile = nil
        self.api = api
    }

    // MARK: - Derived display

    /// Snapshot of accumulator fields shaped for the review cards. Recomputed
    /// on every read so a user hopping back into an edit step sees fresh
    /// values without a refresh call.
    var profile: ProfileReviewData {
        if let previewProfile { return previewProfile }
        guard let accumulator else { return SignupReviewViewModel.defaultProfile }
        return ProfileReviewData(
            firstName: accumulator.firstName,
            location: Self.formatLocation(
                city: accumulator.city,
                province: accumulator.provinceState,
                countryCode: accumulator.countryCode
            ),
            spokenLanguages: accumulator.languages.map(\.label).joined(separator: ", "),
            avatarURL: accumulator.avatarUrl ?? "",
            skills: accumulator.expertiseTags.map(\.label)
        )
    }

    // MARK: - Publish

    /// Publishes the finished profile by PATCHing `/expert/profile/setup`
    /// with the full payload plus `setup_completed: true`. The full
    /// payload is sent (not just the flag) so the server's completeness
    /// check has authoritative values in one atomic write — this defends
    /// against the case where a partial-save call earlier in the flow
    /// failed silently and the accumulator now knows a value the server
    /// doesn't. Returns `true` on success so the caller can navigate away.
    @discardableResult
    func publish() async -> Bool {
        guard let accumulator else {
            // Preview / test path: pretend the request succeeded.
            didPublish = true
            return true
        }
        guard let body = accumulator.buildPublishRequest() else {
            publishError = "Please complete every profile section before publishing."
            return false
        }

        publishError = nil
        isPublishing = true
        defer { isPublishing = false }
        do {
            _ = try await api.setupExpertProfile(body)
            didPublish = true
            return true
        } catch {
            publishError = error.userMessage
            return false
        }
    }

    // MARK: - Helpers

    private static func formatLocation(city: String, province: String, countryCode: String) -> String {
        let country = Countries.find(byCode: countryCode)?.name ?? countryCode
        return [city, province, country]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }


    // MARK: Defaults

    static let defaultProfile = ProfileReviewData(
        firstName: "Sarah",
        location: "New York, NY, United States",
        spokenLanguages: "English, Spanish",
        avatarURL: "https://i.pravatar.cc/240?img=47",
        skills: ["Social Media Strategy", "Content Creation", "SEO"]
    )
}
