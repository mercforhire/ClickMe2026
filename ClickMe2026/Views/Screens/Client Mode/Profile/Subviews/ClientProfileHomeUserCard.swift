//
//  ClientProfileHomeUserCard.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Bento-style user card at the top of the profile hub: green-ringed avatar
/// with online status dot, name, email, and a green edit pencil on the
/// right. Tapping either the avatar/name area or the pencil fires
/// `onEditTap` (both target the same destination).
struct ClientProfileHomeUserCard: View {
    let name: String
    let email: String
    let avatarURL: String
    let isOnline: Bool
    let onEditTap: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(ClientProfileHomeBrand.onSurface)
                    .lineLimit(1)
                Text(email)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ClientProfileHomeBrand.onSurfaceVar)
                    .lineLimit(1)
            }
            Spacer()
            Button(action: onEditTap) {
                ZStack {
                    Circle()
                        .fill(ClientProfileHomeBrand.iconBg)
                        .frame(width: 40, height: 40)
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ClientProfileHomeBrand.primary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit profile")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ClientProfileHomeBrand.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(ClientProfileHomeBrand.outlineVar, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.40), radius: 20, x: 0, y: 4)
        )
    }

    // MARK: Avatar

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .stroke(ClientProfileHomeBrand.primary, lineWidth: 2)
                    .frame(width: 64, height: 64)
                AsyncImage(url: URL(string: avatarURL)) { phase in
                    switch phase {
                    case let .success(img): img.resizable().scaledToFill()
                    default:
                        ZStack {
                            ClientProfileHomeBrand.iconBg
                            Image(systemName: "person.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white.opacity(0.15))
                        }
                    }
                }
                .frame(width: 58, height: 58)
                .clipShape(Circle())
            }

            if isOnline {
                Circle()
                    .fill(ClientProfileHomeBrand.primary)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(ClientProfileHomeBrand.cardBg, lineWidth: 2)
                    )
            }
        }
        .contentShape(Circle())
        .onTapGesture { onEditTap() }
    }
}
