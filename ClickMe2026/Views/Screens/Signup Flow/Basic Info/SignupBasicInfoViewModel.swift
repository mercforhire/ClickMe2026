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

    // MARK: Dependencies

    private let accumulator: SignupAccumulator?
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    /// Preview / test init — keeps state local, no accumulator sync.
    init(
        firstName: String = "",
        city: String = "",
        province: String = "",
        countryCode: String = "",
        languages: [LanguageItem] = []
    ) {
        self.accumulator = nil
        self.firstName = firstName
        self.city = city
        self.province = province
        self.countryCode = countryCode
        self.languages = languages
    }

    /// Runtime init — binds bi-directionally to the shared accumulator so
    /// every edit flows straight to the payload that the review screen
    /// will POST to `/expert/profile/setup`.
    init(accumulator: SignupAccumulator) {
        self.accumulator = accumulator
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
}
