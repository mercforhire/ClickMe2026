//
//  SearchExpertCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
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
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.15))
                        }
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(expert.name)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(SearchExpertBrand.onSurface)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 13))
                                .foregroundColor(SearchExpertBrand.starYellow)
                            Text(String(format: "%.1f", expert.rating))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(SearchExpertBrand.onSurface)
                        }
                    }

                    Text(expert.title)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(SearchExpertBrand.onSurfaceVar)

                    Text(expert.bio)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(SearchExpertBrand.onSurface.opacity(0.75))
                        .lineLimit(2)
                        .lineSpacing(2)
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
        .buttonStyle(SearchScaleStyle())
    }
}
