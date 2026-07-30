//
//  SignupBasicInfoViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class SignupBasicInfoViewModel: ObservableObject {

    // MARK: Form state
    @Published var firstName: String
    @Published var city: String
    @Published var province: String
    /// ISO-3166-1 alpha-3. Empty until the user picks a country.
    @Published var countryCode: String
    @Published var languages: [LanguageItem]

    // MARK: Save state
    @Published var isSaving: Bool = false
    @Published var saveError: String?

    // MARK: Dependencies

    private let accumulator: SignupAccumulator?
    private let api: ClickMeAPI
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    /// Preview / test init — keeps state local, no accumulator sync.
    init(
        firstName: String = "",
        city: String = "",
        province: String = "",
        countryCode: String = "",
        languages: [LanguageItem] = [],
        api: ClickMeAPI = .shared
    ) {
        self.accumulator = nil
        self.firstName = firstName
        self.city = city
        self.province = province
        self.countryCode = countryCode
        self.languages = languages
        self.api = api
    }

    /// Runtime init — binds bi-directionally to the shared accumulator so
    /// every edit flows straight to the payload that the review screen
    /// will POST to `/expert/profile/setup`.
    init(accumulator: SignupAccumulator, api: ClickMeAPI = .shared) {
        self.accumulator = accumulator
        self.api = api
        self.firstName = accumulator.firstName
        self.city = accumulator.city
        self.province = accumulator.provinceState
        self.countryCode = accumulator.countryCode
        self.languages = accumulator.languages

        // Mirror every field edit onto the accumulator so the flow
        // doesn't rely on the "Continue" button to commit.
        $firstName.dropFirst().sink { [weak accumulator] in accumulator?.firstName = $0 }
            .store(in: &cancellables)
        $city.dropFirst().sink { [weak accumulator] in accumulator?.city = $0 }
            .store(in: &cancellables)
        $province.dropFirst().sink { [weak accumulator] in accumulator?.provinceState = $0 }
            .store(in: &cancellables)
        $countryCode.dropFirst().sink { [weak accumulator] in accumulator?.countryCode = $0 }
            .store(in: &cancellables)
        $languages.dropFirst().sink { [weak accumulator] in accumulator?.languages = $0 }
            .store(in: &cancellables)
    }

    // MARK: Derived

    var payload: PersonalDetailsPayload {
        PersonalDetailsPayload(
            firstName: firstName,
            city: city,
            province: province,
            country: countryCode,
            languages: languages
        )
    }

    // MARK: Mutations

    func removeLanguage(_ language: LanguageItem) {
        languages.removeAll { $0.id == language.id }
    }

    func setLanguages(_ list: [LanguageItem]) {
        languages = list
    }

    // MARK: - Save

    /// Persists the current basic-info slice to `/expert/profile/setup`.
    /// Returns `true` on success so the view can navigate forward.
    /// Previews (no accumulator wired) short-circuit to `true`.
    @discardableResult
    func save() async -> Bool {
        guard accumulator != nil else { return true }

        saveError = nil
        isSaving = true
        defer { isSaving = false }

        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedCity = city.trimmingCharacters(in: .whitespaces)
        let trimmedProvince = province.trimmingCharacters(in: .whitespaces)

        let body = SetupExpertProfileRequest(
            firstName: trimmedFirstName.isEmpty ? nil : trimmedFirstName,
            location: SetupExpertProfileRequest.Location(
                city: trimmedCity.isEmpty ? nil : trimmedCity,
                provinceState: trimmedProvince.isEmpty ? nil : trimmedProvince,
                countryCode: countryCode.isEmpty ? nil : countryCode
            ),
            languages: languages.isEmpty ? nil : languages.map(\.id)
        )

        do {
            _ = try await api.setupExpertProfile(body)
            return true
        } catch {
            saveError = error.userMessage
            return false
        }
    }
}
