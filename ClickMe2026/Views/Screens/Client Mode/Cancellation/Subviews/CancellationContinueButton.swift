//
//  CancellationContinueButton.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Step 1 Continue button

struct CancellationContinueButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text("Continue")
                    .font(.brand(.body, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundColor(CancellationBrand.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(CancellationBrand.brandGreen)
                    .shadow(color: CancellationBrand.brandGreen.opacity(0.45), radius: 18, x: 0, y: 5)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}
