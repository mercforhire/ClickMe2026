//
//  CancellationCommentField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Additional comments field

struct CancellationCommentField: View {
    @Binding var comment: String
    @FocusState.Binding var commentFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional Comments (Optional)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(CancellationBrand.onSurfaceVar)
                .padding(.leading, 4)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(CancellationBrand.fieldBg)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(commentFocused ? CancellationBrand.brandGreen.opacity(0.50) : CancellationBrand.outlineVar,
                                lineWidth: 1))
                    .frame(minHeight: 110)

                if comment.isEmpty {
                    Text("Help us understand better...")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(CancellationBrand.onSurfaceVar.opacity(0.55))
                        .padding(.horizontal, 14)
                        .padding(.top, 13)
                }

                TextEditor(text: $comment)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundColor(CancellationBrand.onSurface)
                    .font(.system(size: 15, design: .rounded))
                    .tint(CancellationBrand.brandGreen)
                    .frame(minHeight: 110)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .focused($commentFocused)
            }
        }
    }
}
