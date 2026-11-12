//
//  FavoritesPopulatedList.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Favorites list with section header

struct FavoritesPopulatedList: View {
    let favorites: [FavoriteExpert]
    /// True while the next page is loading; shows the spinner footer.
    let isLoadingMore: Bool
    let onUnfavorite: (FavoriteExpert) -> Void
    /// Called when a row scrolls into view. The view model decides whether
    /// that row is close enough to the end to fetch the next page.
    let onRowAppear: (FavoriteExpert) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Screen title lives on the nav bar (see
                // `FavoritesView.body`); tagline stays as a subtitle
                // above the list.
                Text("Manage your curated list of elite professionals.")
                    .font(.brand(.subheadline, weight: .regular))
                    .foregroundColor(FavoritesBrand.onSurfaceVar)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                // Lazy so a row's `.onAppear` means "scrolled into view";
                // an eager stack would announce every row at once and page
                // through the whole list on load.
                LazyVStack(spacing: 14) {
                    ForEach(favorites) { expert in
                        NavigationLink(value: expert) {
                            FavoriteExpertCard(
                                expert: expert,
                                onUnfavorite: { onUnfavorite(expert) }
                            )
                        }
                        .buttonStyle(.plain)
                        .onAppear { onRowAppear(expert) }
                    }

                    if isLoadingMore {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: FavoritesBrand.brandGreen))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .padding(.horizontal, 16)
                .animation(.easeInOut(duration: 0.25), value: favorites.count)
                .padding(.bottom, 40)
            }
        }
    }
}
