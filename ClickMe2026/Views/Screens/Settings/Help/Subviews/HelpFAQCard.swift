//
//  HelpFAQCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - FAQ category card with iridescent border + expandable Q&A

struct HelpFAQCard: View {
    let category: FaqCategory
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            Button(action: onTap) {
                HStack(spacing: 12) {
                    if let iconUrl = category.iconUrl, let url = URL(string: iconUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case let .success(image):
                                image.resizable().scaledToFit()
                            default:
                                Color.clear
                            }
                        }
                        .frame(width: 24, height: 24)
                    }

                    Text(category.title)
                        .font(.brand(.title3, weight: .bold))
                        .foregroundColor(HelpBrand.onSurface)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(HelpBrand.onSurfaceVar)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressScaleButtonStyle())

            // Expanded Q&A list — each item shows `question` + optional
            // `snippet` from `FaqArticlePreview`. Full article body lives
            // on `GET /help/faqs/articles/:id` if we later want a detail
            // screen, but v1 renders snippets inline only.
            if isExpanded {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(category.featuredArticles, id: \.id) { article in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(article.question)
                                .font(.brand(.subheadline, weight: .semibold))
                                .foregroundColor(HelpBrand.onSurface)
                            if let snippet = article.snippet, !snippet.isEmpty {
                                Text(snippet)
                                    .font(.brand(.subheadline, weight: .regular))
                                    .foregroundColor(HelpBrand.onSurfaceVar)
                                    .lineSpacing(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(HelpBrand.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(HelpBrand.iridBorder, lineWidth: 1.2)
                )
        )
    }
}
