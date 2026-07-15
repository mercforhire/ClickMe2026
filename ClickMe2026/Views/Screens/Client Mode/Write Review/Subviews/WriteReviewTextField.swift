//
//  WriteReviewTextField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Multi-line review text field with placeholder

struct WriteReviewTextField: View {
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(WriteReviewBrand.fieldBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(WriteReviewBrand.fieldBorder, lineWidth: 1)
                )
                .frame(minHeight: 160)

            if text.isEmpty {
                Text("Share your experience...")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(WriteReviewBrand.onSurfaceVar.opacity(0.55))
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
            }

            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .foregroundColor(WriteReviewBrand.onSurface)
                .font(.system(size: 16, design: .rounded))
                .frame(minHeight: 160)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .tint(WriteReviewBrand.brandGreen)
        }
    }
}
