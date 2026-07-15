//
//  ExpertReviewsStarRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Fractional 5-star row (supports half-star fills)

struct ExpertReviewsStarRow: View {
    let rating: Double
    let size: CGFloat

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1 ... 5, id: \.self) { i in
                let d = Double(i)
                let filled = d <= rating
                let halfFill = !filled && (d - 0.5) <= rating

                Image(systemName: filled ? "star.fill"
                    : halfFill ? "star.leadinghalf.filled"
                    : "star")
                    .font(.system(size: size, weight: .medium))
                    .foregroundColor(filled || halfFill
                                     ? ExpertReviewsBrand.starGreen
                                     : ExpertReviewsBrand.starEmpty)
            }
        }
    }
}
