//
//  WriteReviewStarRating.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Five-star rating row with springy entrance animation

struct WriteReviewStarRating: View {
    let selectedStars: Int
    let hoverStar: Int
    let starsAnimated: Bool
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 14) {
            ForEach(1 ... 5, id: \.self) { star in
                let filled = star <= (hoverStar > 0 ? hoverStar : selectedStars)

                Button {
                    onSelect(star)
                } label: {
                    Image(systemName: filled ? "star.fill" : "star")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(
                            filled
                                ? LinearGradient(
                                    colors: [WriteReviewBrand.brandGreen, WriteReviewBrand.brandGreenAlt],
                                    startPoint: .top, endPoint: .bottom
                                )
                                : LinearGradient(
                                    colors: [WriteReviewBrand.onSurfaceVar.opacity(0.40),
                                             WriteReviewBrand.onSurfaceVar.opacity(0.25)],
                                    startPoint: .top, endPoint: .bottom
                                )
                        )
                        .shadow(
                            color: filled ? WriteReviewBrand.brandGreen.opacity(0.55) : .clear,
                            radius: 8, x: 0, y: 0
                        )
                        .scaleEffect(starsAnimated ? 1.0 : 0.60)
                        .opacity(starsAnimated ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.40, dampingFraction: 0.60)
                                .delay(Double(star - 1) * 0.06),
                            value: starsAnimated
                        )
                }
                .buttonStyle(StarButtonStyle())
            }
        }
    }
}
