//
//  ReportChatReasonField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Reason picker Menu + inline validation error

struct ReportChatReasonField: View {
    let reasons: [UserReportReason]
    let selectedReason: UserReportReason?
    let showError: Bool
    let onSelect: (UserReportReason) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reason for reporting")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(ReportChatBrand.onSurface)

            Menu {
                ForEach(reasons) { reason in
                    Button(reason.displayLabel) { onSelect(reason) }
                }
            } label: {
                HStack {
                    Text(selectedReason?.displayLabel ?? "Select a reason")
                        .font(.brand(.subheadline))
                        .foregroundColor(selectedReason == nil
                                         ? ReportChatBrand.onSurfaceVar
                                         : ReportChatBrand.onSurface)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.medium))
                        .foregroundColor(ReportChatBrand.onSurfaceVar)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(ReportChatBrand.fieldBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    showError
                                        ? ReportChatBrand.errorRed.opacity(0.70)
                                        : ReportChatBrand.fieldBorder,
                                    lineWidth: 1
                                )
                        )
                )
            }

            if showError {
                Text("Please select a reason before submitting.")
                    .font(.brand(.caption, weight: .medium))
                    .foregroundColor(ReportChatBrand.errorRed)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showError)
    }
}
