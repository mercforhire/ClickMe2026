//
//  OnboardingIllustrationCard.swift
//  ClickMe2026
//
//  Copyright © 2024 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Illustration card

struct OnboardingIllustrationCard: View {
    let systemImage: String
    let scale: CGFloat
    let opacity: Double

    var body: some View {
        ZStack {
            // Luminescent accent — soft diffuse green halo
            RadialGradient(
                colors: [OnboardingBrand.primary.opacity(0.18), Color.clear],
                center: .center,
                startRadius: 20,
                endRadius: 200
            )
            .frame(width: 340, height: 300)
            .blur(radius: 24)

            // Tonal layered card (1px outline-variant border)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(OnboardingBrand.surfaceContainer)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(OnboardingBrand.outlineVariant, lineWidth: 1)
                )
                .frame(height: 260)

            VStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                OnboardingBrand.primary,
                                OnboardingBrand.primaryContainer,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: OnboardingBrand.primary.opacity(0.40), radius: 16, x: 0, y: 4)

                HStack(spacing: 10) {
                    ForEach(0 ..< 5) { i in
                        Circle()
                            .fill(OnboardingBrand.primary.opacity(i % 2 == 0 ? 0.70 : 0.25))
                            .frame(width: i % 2 == 0 ? 7 : 5, height: i % 2 == 0 ? 7 : 5)
                    }
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .frame(height: 280)
    }
}
