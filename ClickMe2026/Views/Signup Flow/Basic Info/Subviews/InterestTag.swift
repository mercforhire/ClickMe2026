//
//  InterestTag.swift
//  ClickMe2026
//

import SwiftUI

/// Capsule tag in the interests grid. Outlined when idle, green border + glow
/// when selected.
struct InterestTag: View {
    let label: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? BasicInfoBrand.brandGreen : BasicInfoBrand.onSurface)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(BasicInfoBrand.chipBg)
                        .overlay(
                            Capsule()
                                .stroke(
                                    isSelected ? BasicInfoBrand.brandGreen : BasicInfoBrand.fieldBorder,
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: isSelected ? BasicInfoBrand.brandGreen.opacity(0.28) : .clear, radius: 8)
                )
        }
        .buttonStyle(DetailsOnboardingScale())
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}
