//
//  PublishProfileButton.swift
//  ClickMe2026
//

import SwiftUI

/// Brand-green capsule "Publish Profile" CTA.
struct PublishProfileButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Publish Profile")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(ReviewTheme.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(ReviewTheme.brandGreen)
                        .shadow(color: ReviewTheme.brandGreen.opacity(0.45), radius: 16, x: 0, y: 6)
                )
        }
        .buttonStyle(.plain)
    }
}
