//
//  FavoriteExpertCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Single favorite expert card

struct FavoriteExpertCard: View {
    let expert: FavoriteExpert
    let onUnfavorite: () -> Void
    let onBookSession: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            topRow
            tagsRow
            bioRow
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(FavoritesBrand.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(FavoritesBrand.cardBorder, lineWidth: 1))
        )
    }

    // MARK: Top row

    private var topRow: some View {
        HStack(alignment: .top, spacing: 14) {
            AsyncImage(url: URL(string: expert.imageURL)) { phase in
                switch phase {
                case let .success(img): img.resizable().scaledToFill()
                default:
                    ZStack {
                        Color(red: 0.10, green: 0.12, blue: 0.12)
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 72, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(expert.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(FavoritesBrand.onSurface)
                Text(expert.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(FavoritesBrand.brandGreen)
            }

            Spacer()

            Button(action: onUnfavorite) {
                Image(systemName: "heart")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(FavoritesBrand.heartColor)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Tags

    private var tagsRow: some View {
        HStack(spacing: 8) {
            ForEach(expert.tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(FavoritesBrand.onSurface)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(FavoritesBrand.chipBg)
                            .overlay(Capsule().stroke(FavoritesBrand.chipBorder, lineWidth: 1))
                    )
            }
        }
    }

    // MARK: Bio + Book Session

    private var bioRow: some View {
        HStack(alignment: .bottom, spacing: 14) {
            Text(expert.bio)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(FavoritesBrand.onSurfaceVar)
                .lineLimit(3)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onBookSession) {
                Text("Book Session")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(FavoritesBrand.onPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(FavoritesBrand.brandGreen)
                            .shadow(color: FavoritesBrand.brandGreen.opacity(0.50), radius: 12, x: 0, y: 4)
                    )
            }
            .buttonStyle(PressScaleButtonStyle())
            .fixedSize()
        }
    }
}
