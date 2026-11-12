//
//  SearchExpertCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Single expert search-result card

struct SearchExpertCard: View {
    let expert: ExpertSearchResult
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                AsyncImage(url: URL(string: expert.imageURL)) { phase in
                    switch phase {
                    case let .success(img): img.resizable().scaledToFill()
                    default:
                        ZStack {
                            Color(red: 0.12, green: 0.18, blue: 0.14)
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.15))
                        }
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(expert.name)
                            .font(.brand(.body, weight: .bold))
                            .foregroundColor(SearchExpertBrand.onSurface)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(SearchExpertBrand.starYellow)
                            Text(String(format: "%.1f", expert.rating))
                                .font(.brand(.subheadline, weight: .bold))
                                .foregroundColor(SearchExpertBrand.onSurface)
                        }
                    }

                    Text(expert.title)
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(SearchExpertBrand.onSurfaceVar)

                    if !expert.bio.isEmpty {
                        Text(expert.bio)
                            .font(.brand(.caption, weight: .regular))
                            .foregroundColor(SearchExpertBrand.onSurface.opacity(0.75))
                            .lineLimit(2)
                            .lineSpacing(2)
                    }

                    if !expert.tags.isEmpty {
                        tagsRow
                            .padding(.top, 2)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(SearchExpertBrand.cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(SearchExpertBrand.cardBorder, lineWidth: 1))
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    // MARK: Tags

    /// At most 3 pills in a flow layout (EXPL-04): a pill that does not fit moves
    /// to the next line, and a pill wider than the row wraps its own text, so no
    /// tag is ever cut off.
    private var tagsRow: some View {
        TopicsSetupFlowLayout(horizontalSpacing: 8, verticalSpacing: 4) {
            ForEach(expert.tags.prefix(3), id: \.self) { tag in
                Text(tag)
                    .font(.brand(.caption2, weight: .medium))
                    .foregroundColor(SearchExpertBrand.onSurface.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(SearchExpertBrand.cardBorder, lineWidth: 1)
                            )
                    )
            }
        }
    }
}

// MARK: - Previews

#Preview("Long tags") {
    SearchExpertCard(
        expert: ExpertSearchResult(
            expertId: nil,
            name: "Sophia Carter",
            title: "Financial strategist",
            bio: "Helps founders plan their first raise.",
            rating: 4.9,
            imageURL: "",
            tags: [
                "Cross-border corporate restructuring and international tax planning for early stage founders",
                "\u{8DE8}\u{5883}\u{516C}\u{53F8}\u{91CD}\u{7EC4}\u{4E0E}\u{56FD}\u{9645}\u{7A0E}\u{52A1}\u{89C4}\u{5212}\u{54A8}\u{8BE2}\u{670D}\u{52A1}",
                "Seed",
            ]
        ),
        action: {}
    )
    .padding(16)
    .background(SearchExpertBrand.bg)
    .preferredColorScheme(.dark)
}
