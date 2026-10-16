//
//  NewPasswordSubmitButton.swift
//  ClickMe2026
//

import SwiftUI

/// Submit pill that swaps between idle "Set New Password", spinning loading, and
/// "Password Updated!" success states.
struct NewPasswordSubmitButton: View {
    let isLoading: Bool
    let isSuccess: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(NewPasswordBrand.green)
                    .shadow(color: NewPasswordBrand.green.opacity(0.38), radius: 12, x: 0, y: 5)
                    .frame(height: 56)

                if isSuccess {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3.weight(.semibold))
                        Text("Password Updated!")
                            .font(.brand(.title3, weight: .bold))
                    }
                    .foregroundColor(.white)
                } else if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Set New Password")
                        .font(.brand(.title3, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 56)
        .disabled(isLoading || isSuccess)
    }
}
