//
//  ExpertProfileHero.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Hero — glowing avatar, name, title, rating

struct ExpertProfileHero: View {
    let expert: PublicExpertProfile
    let glowPulse: Bool
    /// True once the reviews summary has landed. While false, the
    /// rating row renders em-dash placeholders so a first-visit doesn't
    /// misleadingly show "0.0 (0 reviews)" before the fetch completes.
    var summaryLoaded: Bool = true

    var body: some View {
        VStack(spacing: 12) {
            avatar
                .frame(width: 120, height: 120)

            Text(expert.name)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(ExpertProfileBrand.onSurface)

            Text(expert.title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ExpertProfileBrand.brandGreen)
                .tracking(0.3)

            ratingRow
        }
    }

    // MARK: Avatar

    private var avatar: some View {
        ZStack {
            // Glow — layout-neutral
            Circle()
                .fill(RadialGradient(
                    colors: [ExpertProfileBrand.brandGreen.opacity(glowPulse ? 0.30 : 0.10), .clear],
                    center: .center, startRadius: 50, endRadius: 110
                ))
                .frame(width: 220, height: 220)
                .blur(radius: 14)
                .animation(Animation.easeInOut(duration: 2.3).repeatForever(autoreverses: true),
                           value: glowPulse)
                .allowsHitTesting(false)

            // Ring
            Circle()
                .stroke(ExpertProfileBrand.brandGreen, lineWidth: 2.5)
                .frame(width: 120, height: 120)
                .shadow(color: ExpertProfileBrand.brandGreen.opacity(0.65), radius: 10)

            // Photo
            AsyncImage(url: URL(string: expert.imageURL)) { phase in
                switch phase {
                case let .success(img): img.resizable().scaledToFill()
                default:
                    ZStack {
                        Color(red: 0.12, green: 0.17, blue: 0.13)
                        Image(systemName: "person.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 114, height: 114)
            .clipShape(Circle())

            // Online dot — 45° bottom-right of the ring
            if expert.isOnline {
                Circle()
                    .fill(ExpertProfileBrand.brandGreen)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(ExpertProfileBrand.bg, lineWidth: 2.5))
                    .shadow(color: ExpertProfileBrand.brandGreen.opacity(0.70), radius: 6)
                    .offset(x: 120 * 0.5 * 0.707 - 2,
                            y: 120 * 0.5 * 0.707 - 2)
            }
        }
    }

    // MARK: Rating

    private var ratingRow: some View {
        HStack(spacing: 5) {
            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundColor(ExpertProfileBrand.starYellow)
            Text(summaryLoaded ? String(format: "%.1f", expert.rating) : "—")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(ExpertProfileBrand.onSurface)
            Text(summaryLoaded ? "(\(expert.reviewCount) reviews)" : "(— reviews)")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(ExpertProfileBrand.onSurfaceVar)
        }
    }
}
