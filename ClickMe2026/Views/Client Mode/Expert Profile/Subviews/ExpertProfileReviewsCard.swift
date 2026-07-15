//
//  ExpertProfileReviewsCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Recent reviews card with "See all"

struct ExpertProfileReviewsCard: View {
    let reviews: [PublicReview]
    let onSeeAllReviews: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider().background(ExpertProfileBrand.cardBorder)

            ForEach(reviews.indices, id: \.self) { i in
                row(reviews[i])
                if i < reviews.count - 1 {
                    Divider().background(ExpertProfileBrand.cardBorder).padding(.horizontal, 16)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ExpertProfileBrand.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ExpertProfileBrand.cardBorder, lineWidth: 1))
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var header: some View {
        HStack {
            Text("Recent Reviews")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(ExpertProfileBrand.onSurface)
            Spacer()
            Button(action: onSeeAllReviews) {
                Text("See all")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(ExpertProfileBrand.brandGreen)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func row(_ review: PublicReview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(review.reviewer)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(ExpertProfileBrand.onSurface)
                Spacer()
                starRow(review.stars)
            }
            Text(review.body)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(ExpertProfileBrand.onSurfaceVar)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func starRow(_ count: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(1 ... 5, id: \.self) { i in
                Image(systemName: i <= count ? "star.fill" : "star")
                    .font(.system(size: 12))
                    .foregroundColor(ExpertProfileBrand.starYellow)
            }
        }
    }
}
