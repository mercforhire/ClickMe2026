//
//  ExpertProfileViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ExpertProfileViewModel: ObservableObject {

    // MARK: View state
    @Published var glowPulse: Bool
    @Published var isFavorited: Bool

    // MARK: Data
    @Published var expert: PublicExpertProfile

    init(
        expert: PublicExpertProfile = .sarahChen,
        glowPulse: Bool = false,
        isFavorited: Bool = false
    ) {
        self.expert = expert
        self.glowPulse = glowPulse
        self.isFavorited = isFavorited
    }

    // MARK: Actions

    func toggleFavorite() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            isFavorited.toggle()
        }
    }
}
