//
//  OnboardingPageDots.swift
//  ClickMe2026
//
//  Copyright © 2024 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Page indicator dots

struct OnboardingPageDots: View {
    let count: Int
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< count, id: \.self) { i in
                Capsule()
                    .fill(i == currentIndex ? OnboardingBrand.primary : OnboardingBrand.surfaceContainerHigh)
                    .frame(width: i == currentIndex ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentIndex)
            }
        }
    }
}
