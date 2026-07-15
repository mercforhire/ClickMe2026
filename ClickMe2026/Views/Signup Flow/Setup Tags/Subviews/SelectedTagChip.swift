//
//  SelectedTagChip.swift
//  ClickMe2026
//

import SwiftUI

/// Capsule chip showing a selected tag with a × remove button.
struct SelectedTagChip: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(tag)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.75))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.52, blue: 0.28),
                            Color(red: 0.08, green: 0.38, blue: 0.20),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(TagsBrand.green.opacity(0.45), lineWidth: 1)
                )
        )
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }
}
