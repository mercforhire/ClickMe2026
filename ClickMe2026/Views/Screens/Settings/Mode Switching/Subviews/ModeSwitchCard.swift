//
//  ModeSwitchCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-16.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Selectable mode card with illustration + Active badge

struct ModeSwitchCard: View {
    let mode: AppMode
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                illustration

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title)
                        .font(.brand(.callout, weight: .bold))
                        .foregroundColor(ModeSwitchBrand.textPrimary)

                    Text(mode.subtitle)
                        .font(.brand(.subheadline, weight: .medium))
                        .foregroundColor(ModeSwitchBrand.textSub)

                    Text(mode.description)
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(ModeSwitchBrand.textMuted)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(
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
            )
            .overlay(alignment: .topTrailing) {
                if isActive { activeBadge }
            }
        }
        .buttonStyle(PressScaleButtonStyle())
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
                        .font(.title)
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
                .font(.brand(.caption, weight: .bold))
                .foregroundColor(ModeSwitchBrand.brandGreen)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .padding(.top, 12)
        .padding(.trailing, 12)
        .transition(.opacity.combined(with: .scale(scale: 0.85)))
    }
}
