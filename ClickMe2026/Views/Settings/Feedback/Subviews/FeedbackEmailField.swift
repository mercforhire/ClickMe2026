//
//  FeedbackEmailField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Optional email TextField

struct FeedbackEmailField: View {
    @Binding var email: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FeedbackFieldLabel("Email (Optional)")

            HStack {
                TextField("you@example.com", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .foregroundColor(FeedbackBrand.onSurface)
                    .font(.system(size: 16, design: .rounded))
                    .tint(FeedbackBrand.brandGreen)
                    .focused($isFocused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(FeedbackInputFieldBackground())
        }
    }
}
