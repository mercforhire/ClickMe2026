//
//  ProfileAvatarRing.swift
//  ClickMe2026
//

import SwiftUI

/// Circular avatar with an outer glow + green border ring. Shows the supplied
/// `image` (with the given zoom scale) or a placeholder when `image` is nil.
struct ProfileAvatarRing: View {
    let image: Image?
    let zoomScale: CGFloat
    var size: CGFloat = 220

    private var hasPhoto: Bool { image != nil }

    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ProfilePhotoBrand.green.opacity(hasPhoto ? 0.45 : 0.18),
                            ProfilePhotoBrand.green.opacity(0.08),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: size * 0.42,
                        endRadius: size * 0.70
                    )
                )
                .frame(width: size * 1.28, height: size * 1.28)
                .blur(radius: 10)
                .animation(.easeInOut(duration: 0.4), value: hasPhoto)

            // Green border ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            ProfilePhotoBrand.green.opacity(hasPhoto ? 0.90 : 0.35),
                            ProfilePhotoBrand.green.opacity(hasPhoto ? 0.55 : 0.18),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: hasPhoto ? 3 : 1.5
                )
                .frame(width: size, height: size)
                .animation(.easeInOut(duration: 0.3), value: hasPhoto)

            if let image {
                image
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(1 + zoomScale)
                    .frame(width: size - 4, height: size - 4)
                    .clipShape(Circle())
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            } else {
                placeholder
                    .frame(width: size - 4, height: size - 4)
                    .clipShape(Circle())
                    .transition(.opacity)
            }
        }
        .frame(width: size * 1.28, height: size * 1.28)
        .animation(.easeInOut(duration: 0.3), value: hasPhoto)
    }

    private var placeholder: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.14, green: 0.18, blue: 0.15))

            VStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .font(.system(size: 68))
                    .foregroundColor(Color.white.opacity(0.15))
                Text("Add Photo")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.25))
            }
        }
    }
}
