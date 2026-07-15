//
//  ReportChatReportCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Report User card: reason picker + description + submit button

struct ReportChatReportCard: View {
    let reasons: [String]
    let selectedReason: String
    let showReasonError: Bool
    @Binding var description: String
    @FocusState.Binding var descFocused: Bool
    let isSubmitting: Bool
    let didSubmit: Bool
    let onSelectReason: (String) -> Void
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Report User")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(ReportChatBrand.onSurface)

                Text("If this user is violating our terms of service, please let us know. Your report is anonymous.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(ReportChatBrand.onSurfaceVar)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ReportChatReasonField(
                reasons: reasons,
                selectedReason: selectedReason,
                showError: showReasonError,
                onSelect: onSelectReason
            )

            ReportChatDescriptionField(
                text: $description,
                isFocused: $descFocused
            )

            ReportChatSubmitButton(
                isSubmitting: isSubmitting,
                didSubmit: didSubmit,
                action: onSubmit
            )
        }
        .padding(20)
        .background(ReportChatGlassCard())
    }
}
