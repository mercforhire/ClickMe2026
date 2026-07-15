//
//  ReportChatSubmitButton.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Submit / Submitting / Submitted primary button

struct ReportChatSubmitButton: View {
    let isSubmitting: Bool
    let didSubmit: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(didSubmit
                          ? ReportChatBrand.brandGreen.opacity(0.60)
                          : ReportChatBrand.brandGreen)
                    .shadow(color: ReportChatBrand.brandGreen.opacity(0.45), radius: 16, x: 0, y: 5)
                    .frame(height: 56)

                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ReportChatBrand.onPrimary))
                } else if didSubmit {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Report Submitted")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(ReportChatBrand.onPrimary)
                } else {
                    Text("Submit Report")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(ReportChatBrand.onPrimary)
                }
            }
        }
        .frame(height: 56)
        .disabled(isSubmitting || didSubmit)
        .buttonStyle(PressScaleButtonStyle())
    }
}
