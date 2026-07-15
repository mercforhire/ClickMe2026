//
//  ReportChatReasonField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Reason picker Menu + inline validation error

struct ReportChatReasonField: View {
    let reasons: [String]
    let selectedReason: String
    let showError: Bool
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reason for reporting")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ReportChatBrand.onSurface)

            Menu {
                ForEach(reasons, id: \.self) { reason in
                    Button(reason) { onSelect(reason) }
                }
            } label: {
                HStack {
                    Text(selectedReason.isEmpty ? "Select a reason" : selectedReason)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(selectedReason.isEmpty
                                         ? ReportChatBrand.onSurfaceVar
                                         : ReportChatBrand.onSurface)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .medium))
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
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(ReportChatBrand.errorRed)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showError)
    }
}
