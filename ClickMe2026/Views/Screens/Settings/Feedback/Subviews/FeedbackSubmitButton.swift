//
//  FeedbackSubmitButton.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Submit / Submitting / Submitted button

struct FeedbackSubmitButton: View {
    let isSubmitting: Bool
    let didSubmit: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(FeedbackBrand.brandGreen)
                    .shadow(color: FeedbackBrand.brandGreen.opacity(0.50), radius: 18, x: 0, y: 5)
                    .frame(height: 56)

                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: FeedbackBrand.onPrimary))
                } else if didSubmit {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body.weight(.semibold))
                        Text("Feedback Sent!")
                            .font(.brand(.callout, weight: .bold))
                    }
                    .foregroundColor(FeedbackBrand.onPrimary)
                } else {
                    Text("Submit Feedback")
                        .font(.brand(.callout, weight: .bold))
                        .foregroundColor(FeedbackBrand.onPrimary)
                }
            }
        }
        .frame(height: 56)
        .disabled(isSubmitting || didSubmit)
        .buttonStyle(PressScaleButtonStyle())
    }
}
