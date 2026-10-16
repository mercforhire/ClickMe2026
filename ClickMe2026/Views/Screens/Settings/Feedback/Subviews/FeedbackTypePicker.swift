//
//  FeedbackTypePicker.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - "Feedback Type" select row

struct FeedbackTypePicker: View {
    let feedbackType: String
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FeedbackFieldLabel("Feedback Type")

            Button(action: onTap) {
                HStack {
                    Text(feedbackType)
                        .font(.brand(.callout))
                        .foregroundColor(FeedbackBrand.onSurface)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(FeedbackBrand.onSurfaceVar)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(FeedbackInputFieldBackground())
            }
            .buttonStyle(.plain)
        }
    }
}
