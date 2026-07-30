//
//  VerifyCodeButton.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Brand-green pill "Verify" button. Disabled while the code is < 6
/// digits so the tap can't fire an obviously-invalid request.
struct VerifyCodeButton: View {
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(VerifyEmailBrand.green)
                    .shadow(color: VerifyEmailBrand.green.opacity(0.40), radius: 14, x: 0, y: 5)
                    .frame(height: 56)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Verify")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 56)
        .disabled(isLoading || !isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
    }
}
