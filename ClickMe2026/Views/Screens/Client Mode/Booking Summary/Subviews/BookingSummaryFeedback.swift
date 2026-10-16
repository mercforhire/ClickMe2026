//
//  BookingSummaryFeedback.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Feedback section — stars + optional review text

struct BookingSummaryFeedback: View {
    let feedbackStars: Int
    let feedbackText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BookingSummarySectionHeader(icon: "star", label: "YOUR FEEDBACK")

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    ForEach(1 ... 5, id: \.self) { i in
                        Image(systemName: i <= feedbackStars ? "star.fill" : "star")
                            .font(.title2.weight(.regular))
                            .foregroundColor(
                                i <= feedbackStars
                                    ? BookingSummaryBrand.brandGreen
                                    : BookingSummaryBrand.onSurfaceVar.opacity(0.40)
                            )
                    }
                }

                if let text = feedbackText {
                    Text(text)
                        .font(.brand(.subheadline, weight: .regular))
                        .foregroundColor(BookingSummaryBrand.onSurfaceVar)
                        .italic()
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(BookingSummaryGlassCardBackground())
        }
    }
}
