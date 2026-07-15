//
//  ExpertReviewsCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Individual review card with avatar, name, topic, stars, body preview

struct ExpertReviewsCard: View {
    let review: ExpertReview

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                avatar

                VStack(alignment: .leading, spacing: 3) {
                    Text(review.reviewerName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(ExpertReviewsBrand.onSurface)

                    HStack(spacing: 4) {
                        Text("Topic:")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(ExpertReviewsBrand.onSurfaceVar)
                        Text(review.topic)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(ExpertReviewsBrand.onSurfaceVar)
                    }

                    if let date = review.dateLabel {
                        Text(date)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(ExpertReviewsBrand.onSurfaceVar.opacity(0.70))
                    }
                }

                Spacer()

                ExpertReviewsStarRow(rating: review.stars, size: 16)
            }

            Text(review.body)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(ExpertReviewsBrand.onSurface)
                .lineLimit(2)
                .lineSpacing(3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ExpertReviewsBrand.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ExpertReviewsBrand.cardBorder, lineWidth: 1)
                )
        )
    }

    // MARK: Avatar with green ring

    private var avatar: some View {
        ZStack {
            Circle()
                .stroke(ExpertReviewsBrand.brandGreen, lineWidth: 2)
                .shadow(color: ExpertReviewsBrand.brandGreen.opacity(0.45), radius: 5)
                .frame(width: 54, height: 54)

            AsyncImage(url: URL(string: review.reviewerImageURL)) { phase in
                switch phase {
                case let .success(img): img.resizable().scaledToFill()
                default:
                    ZStack {
                        ExpertReviewsBrand.avatarFallback
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
        }
    }
}
