//
//  SignupContinueButton.swift
//  ClickMe2026
//

import SwiftUI

/// Brand-green pill button with an embedded loading spinner.
struct SignupContinueButton: View {
    var title: String = "Continue"
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(SignupBrand.green)
                    .shadow(color: SignupBrand.green.opacity(0.45), radius: 16, x: 0, y: 6)
                    .frame(height: 56)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 56)
        .disabled(isLoading)
    }
}
