//
//  OnboardingIllustrationCard.swift
//  ClickMe2026
//
//  Copyright © 2024 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Illustration key

/// Identifies which onboarding step is being illustrated. Each case exposes
/// a remote `imageURL` (currently picsum.photos placeholders with stable
/// seeds — replace with the final AI-generated CDN URLs).
enum OnboardingIllustration {
    case welcome        // Meet the community
    case discover       // Find rated experts
    case booking        // Schedule + confirm
    case communication  // Chat / voice / video

    var imageURL: URL? {
        let raw: String
        switch self {
        case .welcome:
            raw = "https://picsum.photos/seed/clickme-welcome/720/540"
        case .discover:
            raw = "https://picsum.photos/seed/clickme-discover/720/540"
        case .booking:
            raw = "https://picsum.photos/seed/clickme-booking/720/540"
        case .communication:
            raw = "https://picsum.photos/seed/clickme-communication/720/540"
        }
        return URL(string: raw)
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

            // Photo card
            AsyncImage(url: illustration.imageURL, transaction: Transaction(animation: .easeOut(duration: 0.25))) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
            .frame(height: cardHeight)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .stroke(OnboardingBrand.outlineVariant, lineWidth: 1)
            )
            // Bottom-edge scrim so the title area below the card reads well
            // even if the photo has a bright lower band.
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

    // MARK: Placeholder (loading / failure)

    /// Neutral placeholder shown while the remote photo loads or if the fetch
    /// fails. Same footprint as the loaded image so there's no layout jump.
    private var placeholder: some View {
        ZStack {
            OnboardingBrand.surfaceContainer

            Image(systemName: "photo")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(OnboardingBrand.outlineVariant)
        }
    }
}
