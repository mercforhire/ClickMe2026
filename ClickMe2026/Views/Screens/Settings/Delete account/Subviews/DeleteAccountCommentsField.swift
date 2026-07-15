//
//  DeleteAccountCommentsField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - "Additional comments" optional field

struct DeleteAccountCommentsField: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional comments (optional)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(DeleteAccountBrand.onSurface)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DeleteAccountBrand.fieldBg)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(DeleteAccountBrand.fieldBorder, lineWidth: 1))
                    .frame(minHeight: 100)

                if text.isEmpty {
                    Text("Share any additional thoughts...")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(DeleteAccountBrand.onSurfaceVar.opacity(0.55))
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                }

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundColor(DeleteAccountBrand.onSurface)
                    .font(.system(size: 14, design: .rounded))
                    .tint(DeleteAccountBrand.errorRed)
                    .frame(minHeight: 100)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .focused($isFocused)
            }
        }
    }
}
