//
//  HelpViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-29.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class HelpViewModel: ObservableObject {

    // MARK: View state
    @Published var expandedFAQs: Set<HelpFAQCategory>

    init(expandedFAQs: Set<HelpFAQCategory> = Set(HelpFAQCategory.allCases)) {
        self.expandedFAQs = expandedFAQs
    }

    // MARK: Actions

    func isExpanded(_ category: HelpFAQCategory) -> Bool {
        expandedFAQs.contains(category)
    }

    func toggle(_ category: HelpFAQCategory) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedFAQs.contains(category) {
                expandedFAQs.remove(category)
            } else {
                expandedFAQs.insert(category)
            }
        }
    }
}
