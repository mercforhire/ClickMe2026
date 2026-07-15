//
//  WriteReviewSubmitButton.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Submit button with loading + submitted states

struct WriteReviewSubmitButton: View {
    let isSubmitting: Bool
    let didSubmit: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        didSubmit
                            ? LinearGradient(
                                colors: [WriteReviewBrand.brandGreen.opacity(0.70),
                                         WriteReviewBrand.brandGreen.opacity(0.55)],
                                startPoint: .leading, endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [WriteReviewBrand.brandGreen, WriteReviewBrand.brandGreenAlt2],
                                startPoint: .leading, endPoint: .trailing
                            )
                    )
                    .shadow(color: WriteReviewBrand.brandGreen.opacity(0.45), radius: 18, x: 0, y: 5)
                    .frame(height: 58)

                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: WriteReviewBrand.onPrimary))
                } else if didSubmit {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Review Submitted!")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(WriteReviewBrand.onPrimary)
                } else {
                    Text("Submit Review")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(WriteReviewBrand.onPrimary)
                }
            }
        }
        .frame(height: 58)
        .disabled(isSubmitting || didSubmit)
        .buttonStyle(ReviewSubmitStyle())
    }
}
