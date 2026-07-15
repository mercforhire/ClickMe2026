//
//  ReportChatDescriptionField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - "Description" TextEditor with placeholder

struct ReportChatDescriptionField: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ReportChatBrand.onSurface)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ReportChatBrand.fieldBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(ReportChatBrand.fieldBorder, lineWidth: 1)
                    )
                    .frame(minHeight: 140)

                if text.isEmpty {
                    Text("Please provide any additional details...")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(ReportChatBrand.onSurfaceVar)
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                }

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundColor(ReportChatBrand.onSurface)
                    .font(.system(size: 15, design: .rounded))
                    .tint(ReportChatBrand.brandGreen)
                    .frame(minHeight: 140)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .focused($isFocused)
            }
        }
    }
}
