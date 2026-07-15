//
//  FavoritesPopulatedList.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Favorites list with section header

struct FavoritesPopulatedList: View {
    let favorites: [FavoriteExpert]
    let onUnfavorite: (FavoriteExpert) -> Void
    let onBookSession: (FavoriteExpert) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "star")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundColor(FavoritesBrand.brandGreen)
                    Text("Favorite Experts")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(FavoritesBrand.onSurface)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 6)

                Text("Manage your curated list of elite professionals.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(FavoritesBrand.onSurfaceVar)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                VStack(spacing: 14) {
                    ForEach(favorites) { expert in
                        FavoriteExpertCard(
                            expert: expert,
                            onUnfavorite: { onUnfavorite(expert) },
                            onBookSession: { onBookSession(expert) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .animation(.easeInOut(duration: 0.25), value: favorites.count)
                .padding(.bottom, 40)
            }
        }
    }
}
