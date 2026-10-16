//
//  ExpertReviewsOverallCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-22.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Overall rating card (big number + stars + total reviews count)

struct ExpertReviewsOverallCard: View {
    let overallRating: Double
    let totalReviews: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overall Rating")
                .font(.brand(.callout, weight: .semibold))
                .foregroundColor(ExpertReviewsBrand.onSurface)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(String(format: "%.1f", overallRating))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(ExpertReviewsBrand.onSurface)

                VStack(alignment: .leading, spacing: 4) {
                    ExpertReviewsStarRow(rating: overallRating, size: 24)
                    Text("\(totalReviews) Total Reviews")
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(ExpertReviewsBrand.onSurfaceVar)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ExpertReviewsBrand.ratingCardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(ExpertReviewsBrand.cardBorder, lineWidth: 1)
                )
        )
    }
}
