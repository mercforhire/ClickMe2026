//
//  ExpertCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

struct ExpertCard: View {
    let expert: Expert
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                avatar
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(expert.name)
                        .font(.brand(.body, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    ratingRow

                    if !expert.title.isEmpty {
                        Text(expert.title)
                            .font(.brand(.subheadline, weight: .regular))
                            .foregroundColor(.white.opacity(0.72))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !expert.tags.isEmpty {
                        tagsRow
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .buttonStyle(.plain)
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

    // MARK: Rating row

    private var ratingRow: some View {
        HStack(spacing: 6) {
            StarRatingRow(rating: expert.rating)
            Text(String(format: "%.1f", expert.rating))
                .font(.brand(.caption, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
            if expert.reviewCount > 0 {
                Text("· \(expert.reviewCount) review\(expert.reviewCount == 1 ? "" : "s")")
                    .font(.brand(.caption, weight: .regular))
                    .foregroundColor(.white.opacity(0.55))
            }
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
                    .font(.caption2)
                    .foregroundColor(i < filled ? Color(red: 1.00, green: 0.80, blue: 0.20)
                                                : Color.white.opacity(0.18))
            }
        }
    }
}
