//
//  PublishProfileButton.swift
//  ClickMe2026
//

import SwiftUI

/// Brand-green capsule "Publish Profile" CTA. Swaps its label for a spinner
/// while `isLoading` is true and disables the tap so a double-fire can't
/// send two `PATCH /expert/profile/setup` requests.
struct PublishProfileButton: View {
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Brand.onPrimary)
                } else {
                    Text("Publish Profile")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Brand.onPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule()
                    .fill(Brand.primary)
                    .shadow(color: Brand.primary.opacity(0.45), radius: 16, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}
