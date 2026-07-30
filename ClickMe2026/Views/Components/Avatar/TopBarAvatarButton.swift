//
//  TopBarAvatarButton.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// The circular avatar tap-target on the right edge of `HomeClientTopBar`
/// and `HomeExpertTopBar`. Renders the user's avatar image when the URL
/// is available; falls back to the SF Symbol silhouette otherwise so
/// the icon still has visual weight on a fresh account.
///
/// Tapping is wired by the caller (currently: push the ModeSwitchView).
struct TopBarAvatarButton: View {
    let avatarURL: String?
    let action: () -> Void

    private static let size: CGFloat = 32

    var body: some View {
        Button(action: action) {
            avatarContent
                .frame(width: Self.size, height: Self.size)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let urlString = avatarURL,
           !urlString.isEmpty,
           let url = URL(string: urlString)
        {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    fallback
                }
            }
        } else {
            fallback
        }
    }

    private var fallback: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Brand.onSurfaceVariant, Brand.surfaceContainerLow)
    }
}
