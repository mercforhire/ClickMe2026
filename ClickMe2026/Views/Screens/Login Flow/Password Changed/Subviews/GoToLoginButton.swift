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
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(PasswordUpdatedBrand.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule()
                        .fill(PasswordUpdatedBrand.green)
                        .shadow(color: PasswordUpdatedBrand.green.opacity(0.55), radius: 20, x: 0, y: 6)
                )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

