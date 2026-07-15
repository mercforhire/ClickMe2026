//
//  GlowingCheckmark.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-14.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Glowing neon checkmark

struct GlowingCheckmark: View {
    var scale: CGFloat
    var opacity: Double
    var glowRadius: CGFloat

    var body: some View {
        ZStack {
            // Outer diffuse glow
            Image(systemName: "checkmark")
                .font(.system(size: 90, weight: .medium))
                .foregroundColor(PasswordUpdatedBrand.green.opacity(0.12))
                .blur(radius: glowRadius * 1.4)
                .scaleEffect(1.3)

            // Mid glow
            Image(systemName: "checkmark")
                .font(.system(size: 80, weight: .medium))
                .foregroundColor(PasswordUpdatedBrand.green.opacity(0.25))
                .blur(radius: glowRadius * 0.7)

            // Sharp neon stroke
            Image(systemName: "checkmark")
                .font(.system(size: 72, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.35, green: 1.00, blue: 0.68),
                            PasswordUpdatedBrand.green,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: PasswordUpdatedBrand.green.opacity(0.90), radius: 16)
                .shadow(color: PasswordUpdatedBrand.green.opacity(0.55), radius: 32)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .frame(height: 120)
    }
}
