//
//  ExploreFeaturedTopicsSection.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Horizontally-scrolling "Featured Topics" strip on the client Explore
/// screen. Cards show topic title + hourly rate + expert avatar/name; a
/// green left-edge accent bar matches the design system's "luminescent
/// accent" pattern.
///
/// Tapping a card fires `onTapTopic(_:)` — the parent pushes the expert's
/// public profile so the client can review before booking.
struct ExploreFeaturedTopicsSection: View {
    let topics: [FeaturedTopic]
    var onSeeAll: () -> Void = {}
    var onTapTopic: (FeaturedTopic) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Featured Topics")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button("See all", action: onSeeAll)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(ExploreBrand.brandGreen)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(topics) { topic in
                        FeaturedTopicCard(topic: topic) {
                            onTapTopic(topic)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Card

private struct FeaturedTopicCard: View {
    let topic: FeaturedTopic
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(ExploreBrand.brandGreen)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(topic.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)

                        Text(topic.priceLabel)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(ExploreBrand.brandGreen)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 0)

                    HStack(spacing: 8) {
                        avatar
                        Text(topic.expertName)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                }
                .padding(14)
            }
            .frame(width: 220, height: 176, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var avatar: some View {
        Group {
            if let url = URL(string: topic.expertImageURL), !topic.expertImageURL.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(img): img.resizable().scaledToFill()
                    default: avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: 22, height: 22)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Color(red: 0.14, green: 0.20, blue: 0.16)
            Image(systemName: "person.fill")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.35))
        }
    }
}
