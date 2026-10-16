//
//  SelectedTagChip.swift
//  ClickMe2026
//

import SwiftUI

/// Capsule chip showing a selected tag with a × remove button.
///
/// Optionally renders a leading star toggle when `isPrimary` +
/// `onMakePrimary` are supplied — used by the expertise editor to let
/// experts change which tag is their "primary" (server-side
/// `is_primary`, surfaced first in discovery/search). Signup-flow
/// callers omit both params so the star doesn't show up in a context
/// where the primary concept doesn't apply.
struct SelectedTagChip: View {
    let tag: String
    let onRemove: () -> Void
    var isPrimary: Bool? = nil
    var onMakePrimary: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let isPrimary, let onMakePrimary {
                Button(action: onMakePrimary) {
                    Image(systemName: isPrimary ? "star.fill" : "star")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(isPrimary ? TagsBrand.green : Color.white.opacity(0.55))
                }
                .buttonStyle(.plain)
                .disabled(isPrimary)
                .accessibilityLabel(isPrimary ? "Primary expertise" : "Make primary")
            }

            Text(tag)
                .font(.brand(.subheadline, weight: .medium))
                .foregroundColor(.white)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
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
