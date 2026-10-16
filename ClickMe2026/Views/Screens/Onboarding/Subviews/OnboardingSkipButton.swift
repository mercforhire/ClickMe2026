//
//  OnboardingSkipButton.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Skip text button

struct OnboardingSkipButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // label-lg: 14 / 600 / letterSpacing 0.02em
            Text("Skip")
                .font(.subheadline.weight(.semibold))
                .tracking(0.28)
                .foregroundColor(OnboardingBrand.onSurfaceVariant)
                .padding(.vertical, 8)
        }
    }
}
