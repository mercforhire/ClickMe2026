//
//  OnboardingNextButton.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Primary CTA — full-width, neon green, dark text, soft glow

struct OnboardingNextButton: View {
    let title: String
    let pageIndex: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(OnboardingBrand.primary)
                    .shadow(color: OnboardingBrand.primaryContainer.opacity(0.30), radius: 20, x: 0, y: 4)
                    .frame(height: 56)

                // button-text: 16 / 700 / lineHeight 20
                Text(title)
                    .font(.callout.weight(.bold))
                    .foregroundColor(OnboardingBrand.onPrimary)
                    .animation(.none, value: pageIndex)
            }
        }
        .frame(height: 56)
    }
}
