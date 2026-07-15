//
//  ExpertCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ExpertCard: View {
    let expert: Expert
    var onViewProfile: () -> Void = {}

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            avatar
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    Text(expert.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    StarRatingRow(rating: expert.rating)
                }

                if !expert.tags.isEmpty {
                    tagsRow
                }

                Spacer(minLength: 0)

                viewProfileButton
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ExploreBrand.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: Avatar

    @ViewBuilder
    private var avatar: some View {
        if let url = URL(string: expert.imageURL), !expert.imageURL.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .empty, .failure:
                    placeholderBackground
                @unknown default:
                    placeholderBackground
                }
            }
        } else {
            placeholderBackground
        }
    }

    private var placeholderBackground: some View {
        ZStack {
            LinearGradient(
                colors: placeholderGradient(for: expert.name),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "person.fill")
                .font(.system(size: 34))
                .foregroundColor(.white.opacity(0.14))
        }
    }

    // MARK: Tags

    private var tagsRow: some View {
        HStack(spacing: 6) {
            ForEach(expert.tags.prefix(3), id: \.self) { tag in
                ExpertTagChip(text: tag)
            }
        }
    }

    // MARK: View Profile button (outlined secondary)

    private var viewProfileButton: some View {
        Button(action: onViewProfile) {
            Text("View Profile")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(ExploreBrand.brandGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.35))
                        .overlay(
                            Capsule()
                                .stroke(ExploreBrand.brandGreen.opacity(0.55), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Placeholder gradient helper

    private func placeholderGradient(for name: String) -> [Color] {
        switch name {
        case "Elena Rodriguez":
            return [Color(red: 0.08, green: 0.22, blue: 0.28), Color(red: 0.04, green: 0.10, blue: 0.14)]
        case "Marcus Chen":
            return [Color(red: 0.10, green: 0.14, blue: 0.22), Color(red: 0.04, green: 0.06, blue: 0.12)]
        default:
            return [Color(red: 0.12, green: 0.10, blue: 0.20), Color(red: 0.06, green: 0.06, blue: 0.10)]
        }
    }
}

// MARK: - Inline star rating row

private struct StarRatingRow: View {
    let rating: Double

    private var filled: Int {
        let clamped = max(0, min(5, rating))
        return Int(clamped.rounded())
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0 ..< 5, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(i < filled ? Color(red: 1.00, green: 0.80, blue: 0.20)
                                                : Color.white.opacity(0.18))
            }
        }
    }
}
