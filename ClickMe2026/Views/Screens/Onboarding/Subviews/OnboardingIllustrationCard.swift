//
//  OnboardingIllustrationCard.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Illustration key

/// Identifies which onboarding step is being illustrated. Each case
/// resolves to a bundled asset-catalog image name.
enum OnboardingIllustration {
    case welcome        // "Welcome to ClickMe" — connect with top experts
    case discover       // "Discover Top Experts" — search categories
    case booking        // "Book & Schedule Instantly" — appointments + payments
    case communication  // "Seamless Communication" — chat / voice / video

    /// Asset-catalog name for the illustration. Images are bundled in
    /// `Assets.xcassets` so they load instantly offline — the previous
    /// `pollinations.ai` round-trip is gone.
    var assetName: String {
        switch self {
        case .welcome:       return "welcome"
        case .discover:      return "discover"
        case .booking:       return "booking"
        case .communication: return "communication"
        }
    }
}

// MARK: - Illustration card

struct OnboardingIllustrationCard: View {
    let illustration: OnboardingIllustration
    let scale: CGFloat
    let opacity: Double

    private let cardCornerRadius: CGFloat = 16
    private let cardHeight: CGFloat = 260

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

            Image(illustration.assetName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: cardHeight)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                        .stroke(OnboardingBrand.outlineVariant, lineWidth: 1)
                )
                // Bottom-edge scrim keeps the title area below the card
                // readable if the illustration has a bright lower band.
                .overlay(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.35)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
                    .allowsHitTesting(false)
                )
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .frame(height: 280)
    }
}
