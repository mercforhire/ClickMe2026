//
//  LanguageChip.swift
//  ClickMe2026
//

import SwiftUI

/// Capsule chip showing a language with a small × remove button.
struct LanguageChip: View {
    let language: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 5) {
            Text(language)
                .font(.brand(.subheadline, weight: .medium))
                .foregroundColor(BasicInfoBrand.onSurface)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(BasicInfoBrand.onSurfaceVar)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(BasicInfoBrand.langTagBg)
                .overlay(Capsule().stroke(BasicInfoBrand.fieldBorder, lineWidth: 1))
        )
    }
}
