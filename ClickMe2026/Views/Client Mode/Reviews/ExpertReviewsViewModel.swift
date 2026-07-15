//
//  ExpertReviewsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-29.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ExpertReviewsViewModel: ObservableObject {

    // MARK: Content
    @Published var overallRating: Double
    @Published var totalReviews: Int
    @Published var reviews: [ExpertReview]

    init(
        overallRating: Double = 4.9,
        totalReviews: Int = 128,
        reviews: [ExpertReview] = ExpertReview.samples
    ) {
        self.overallRating = overallRating
        self.totalReviews = totalReviews
        self.reviews = reviews
    }
}
