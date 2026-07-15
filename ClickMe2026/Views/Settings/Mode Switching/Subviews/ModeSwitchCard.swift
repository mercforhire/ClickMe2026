//
//  ModeSwitchCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-16.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Selectable mode card with illustration + Active badge

struct ModeSwitchCard: View {
    let mode: AppMode
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                // Card background + border
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isActive ? ModeSwitchBrand.brandGreen.opacity(0.15) : ModeSwitchBrand.cardIdle)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isActive ? ModeSwitchBrand.brandGreen : ModeSwitchBrand.borderIdle,
                                lineWidth: isActive ? 1.5 : 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: isActive)

                // Card content
                HStack(alignment: .top, spacing: 14) {
                    illustration

                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(ModeSwitchBrand.textPrimary)

                        Text(mode.subtitle)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(ModeSwitchBrand.textSub)

                        Text(mode.description)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(ModeSwitchBrand.textMuted)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)

                if isActive { activeBadge }
            }
        }
        .buttonStyle(ModeScaleButtonStyle())
    }

    // MARK: Illustration

    private var illustration: some View {
        AsyncImage(url: URL(string: mode.imageURL)) { phase in
            switch phase {
            case let .success(img):
                img.resizable().scaledToFill()
            default:
                ZStack {
                    Color(red: 0.14, green: 0.18, blue: 0.15)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.15))
                }
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: Active badge

    private var activeBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(ModeSwitchBrand.brandGreen)
                .frame(width: 10, height: 10)
            Text("Active")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(ModeSwitchBrand.brandGreen)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .padding(.top, 12)
        .padding(.trailing, 12)
        .transition(.opacity.combined(with: .scale(scale: 0.85)))
    }
}
