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

    @Published var profile: ProfileReviewData

    init(profile: ProfileReviewData = SignupReviewViewModel.defaultProfile) {
        self.profile = profile
    }

    // MARK: Defaults

    static let defaultProfile = ProfileReviewData(
        firstName: "Sarah",
        location: "New York, NY, United States",
        spokenLanguages: "English, Spanish",
        avatarURL: "https://i.pravatar.cc/240?img=47",
        hourlyRate: 80,
        category: "Marketing",
        skills: ["Social Media Strategy", "Content Creation", "SEO"]
    )
}
