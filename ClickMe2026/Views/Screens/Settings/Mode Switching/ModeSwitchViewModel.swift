//
//  ModeSwitchViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-29.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ModeSwitchViewModel: ObservableObject {

    // MARK: View state
    @Published var selectedMode: AppMode

    /// Defaults to the app's active mode so the switcher opens with the
    /// correct card highlighted. Callers can override for previews/tests.
    init(selectedMode: AppMode? = nil) {
        self.selectedMode = selectedMode ?? UserManager.shared.currentMode
    }

    // MARK: Actions

    func select(_ mode: AppMode) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            selectedMode = mode
        }
    }
}
