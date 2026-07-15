//
//  ModeSwitchViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-29.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ModeSwitchViewModel: ObservableObject {

    // MARK: View state
    @Published var selectedMode: AppMode

    init(selectedMode: AppMode = .client) {
        self.selectedMode = selectedMode
    }

    // MARK: Actions

    func select(_ mode: AppMode) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            selectedMode = mode
        }
    }
}
