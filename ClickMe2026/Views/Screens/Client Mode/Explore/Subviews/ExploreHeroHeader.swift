//
//  ExploreHeroHeader.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ExploreHeroHeader: View {
    /// Invoked when the user taps the heart icon on the right of the hero.
    /// Wired by `ExploreClientView` to push `FavoritesView` onto the nav stack.
    var onFavoritesTap: () -> Void = {}

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Find your next expert")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Connect with the top 1% of industry leaders.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.50))
            }

            Spacer(minLength: 8)

            Button(action: onFavoritesTap) {
                Image(systemName: "heart")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Favorites")
        }
    }
}
