//
//  RescheduleMessageCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Optional message TextEditor with placeholder

struct RescheduleMessageCard: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message Text (optional)")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(RescheduleBrand.onSurface)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(RescheduleBrand.chipBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(RescheduleBrand.chipBorder, lineWidth: 1)
                    )
                    .frame(minHeight: 88)

                if text.isEmpty {
                    Text("Message text (optional)")
                        .font(.brand(.subheadline))
                        .foregroundColor(RescheduleBrand.onSurfaceVar.opacity(0.6))
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                }

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundColor(RescheduleBrand.onSurface)
                    .font(.brand(.subheadline))
                    .tint(RescheduleBrand.brandGreen)
                    .frame(minHeight: 88)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .focused($isFocused)
            }
        }
        .padding(14)
        .background(RescheduleCardBackground())
    }
}
