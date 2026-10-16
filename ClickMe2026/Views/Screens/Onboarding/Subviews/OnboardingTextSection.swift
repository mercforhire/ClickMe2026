//
//  OnboardingTextSection.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Title + subtitle block

struct OnboardingTextSection: View {
    let title: String
    let subtitle: String
    let pageIndex: Int

    var body: some View {
        VStack(spacing: 16) {
            // headline-xl: 32 / 700 / -0.02em
            Text(title)
                .font(.title.weight(.bold))
                .tracking(-0.64)
                .foregroundColor(OnboardingBrand.onSurface)
                .multilineTextAlignment(.center)
                .lineSpacing(8)

            // body-lg: 16 / 400 / lineHeight 24
            Text(subtitle)
                .font(.callout.weight(.regular))
                .foregroundColor(OnboardingBrand.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
        }
        .id(pageIndex)
        .transition(.opacity.combined(with: .move(edge: .trailing)))
        .animation(.easeInOut(duration: 0.35), value: pageIndex)
    }
}
