//
//  FeedbackDetailsField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Details TextEditor with placeholder + error text

struct FeedbackDetailsField: View {
    @Binding var text: String
    let showError: Bool
    @FocusState.Binding var isFocused: Bool
    let onTextChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FeedbackFieldLabel("Details")

            ZStack(alignment: .topLeading) {
                FeedbackInputFieldBackground(hasError: showError)
                    .frame(minHeight: 180)

                if text.isEmpty {
                    Text("Describe your experience...")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(FeedbackBrand.onSurfaceVar.opacity(0.55))
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                }

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundColor(FeedbackBrand.onSurface)
                    .font(.system(size: 16, design: .rounded))
                    .tint(FeedbackBrand.brandGreen)
                    .frame(minHeight: 180)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .focused($isFocused)
                    .onChange(of: text) { _ in onTextChange() }
            }

            if showError {
                Text("Please describe your experience before submitting.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(FeedbackBrand.errorRed)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showError)
    }
}
