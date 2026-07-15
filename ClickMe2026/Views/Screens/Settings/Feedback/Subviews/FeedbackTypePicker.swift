//
//  FeedbackTypePicker.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
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
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(FeedbackBrand.onSurface)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
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
