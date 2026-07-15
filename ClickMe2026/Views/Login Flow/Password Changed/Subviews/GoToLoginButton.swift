//
//  GoToLoginButton.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-14.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Go to Login button

struct GoToLoginButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Go to Login")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(PasswordUpdatedBrand.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule()
                        .fill(PasswordUpdatedBrand.green)
                        .shadow(color: PasswordUpdatedBrand.green.opacity(0.55), radius: 20, x: 0, y: 6)
                )
        }
        .buttonStyle(PasswordUpdatedScaleStyle())
    }
}

// MARK: - Button style

struct PasswordUpdatedScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
