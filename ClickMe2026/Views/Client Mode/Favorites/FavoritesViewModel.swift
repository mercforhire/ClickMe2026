//
//  FavoritesViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-25.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class FavoritesViewModel: ObservableObject {

    // MARK: View state
    @Published var favorites: [FavoriteExpert]
    @Published var glowPulse: Bool

    init(
        favorites: [FavoriteExpert] = FavoriteExpert.samples,
        glowPulse: Bool = false
    ) {
        self.favorites = favorites
        self.glowPulse = glowPulse
    }

    // MARK: Actions

    func removeFavorite(_ expert: FavoriteExpert) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            favorites.removeAll { $0.id == expert.id }
        }
    }
}
