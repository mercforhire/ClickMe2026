//
//  SignupBasicInfoViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class SignupBasicInfoViewModel: ObservableObject {

    // MARK: Form state
    @Published var firstName: String
    @Published var city: String
    @Published var province: String
    @Published var country: String
    @Published var languages: [String]

    init(
        firstName: String = "",
        city: String = "",
        province: String = "",
        country: String = "",
        languages: [String] = ["English", "Spanish"]
    ) {
        self.firstName = firstName
        self.city = city
        self.province = province
        self.country = country
        self.languages = languages
    }

    // MARK: Derived

    var payload: PersonalDetailsPayload {
        PersonalDetailsPayload(
            firstName: firstName,
            city: city,
            province: province,
            country: country,
            languages: languages
        )
    }

    // MARK: Mutations

    func removeLanguage(_ language: String) {
        languages.removeAll { $0 == language }
    }

    func setLanguages(_ list: [String]) {
        languages = list
    }
}
