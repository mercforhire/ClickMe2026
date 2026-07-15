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
        VStack(alignment: .leading, spacing: 0) {
            photoArea
                .padding(.bottom, 14)

            infoBlock
                .padding(.horizontal, 4)
                .padding(.bottom, 14)

            footerRow
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(ExploreBrand.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: Photo

    private var photoArea: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geo in
                ZStack {
                    LinearGradient(
                        colors: placeholderGradient(for: expert.name),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "person.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white.opacity(0.12))
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            ExpertRatingBadge(rating: expert.rating)
                .padding(12)
        }
    }

    // MARK: Info

    private var infoBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(expert.name)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            Text(expert.title)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(Color.white.opacity(0.50))

            HStack(spacing: 8) {
                ForEach(expert.tags, id: \.self) { tag in
                    ExpertTagChip(text: tag)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: Rate + CTA

    private var footerRow: some View {
        HStack {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("$\(expert.rate)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(ExploreBrand.brandGreen)
                Text("/hr")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.40))
            }

            Spacer()

            Button(action: onViewProfile) {
                Text("View Profile")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(ExploreBrand.brandGreen)
                            .shadow(color: ExploreBrand.brandGreen.opacity(0.38), radius: 8, x: 0, y: 3)
                    )
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
