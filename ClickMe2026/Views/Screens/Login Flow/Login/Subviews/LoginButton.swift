//
//  LoginButton.swift
//  ClickMe2026
//

import SwiftUI

struct LoginButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LoginBrand.green)
                    .shadow(color: LoginBrand.green.opacity(0.45), radius: 14, x: 0, y: 6)
                    .frame(height: 56)

                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    }
                    Text("Login")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 56)
    }
}
