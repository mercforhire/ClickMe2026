//
//  ReviewAvatar.swift
//  ClickMe2026
//

import SwiftUI

/// Circular `AsyncImage` with a green ring border and a person-icon placeholder
/// shown while loading or on failure.
struct ReviewAvatar: View {
    let url: String
    var size: CGFloat = 80

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .empty, .failure:
                placeholder
            @unknown default:
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(ReviewTheme.brandGreen.opacity(0.55), lineWidth: 1.5)
        )
    }

    private var placeholder: some View {
        ZStack {
            Color.white.opacity(0.06)
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.45))
                .foregroundColor(Color.white.opacity(0.30))
        }
    }
}
