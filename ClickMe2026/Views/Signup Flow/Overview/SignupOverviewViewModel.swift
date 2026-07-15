//
//  SignupOverviewViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class SignupOverviewViewModel: ObservableObject {

    @Published var checklist: [ChecklistItem]
    @Published var tips: [ProfileTip]

    init(
        checklist: [ChecklistItem] = SignupOverviewViewModel.defaultChecklist,
        tips: [ProfileTip] = SignupOverviewViewModel.defaultTips
    ) {
        self.checklist = checklist
        self.tips = tips
    }

    // MARK: - Derived

    var progress: Double {
        guard !checklist.isEmpty else { return 0 }
        let done = checklist.filter(\.isComplete).count
        return Double(done) / Double(checklist.count)
    }

    // MARK: - Defaults

    static let defaultChecklist = [
        ChecklistItem(title: "Add profile picture", isComplete: true),
        ChecklistItem(title: "Verify email",        isComplete: true),
        ChecklistItem(title: "Set hourly rate",     isComplete: true),
        ChecklistItem(title: "Add expertise",       isComplete: false),
    ]

    static let defaultTips = [
        ProfileTip(title: "Craft a Compelling Bio",
                   detail: "Lead with the problem you solve. Keep it to 2–3 sentences and write the way you'd talk to a client."),
        ProfileTip(title: "Choose a Professional Picture",
                   detail: "A clear, well-lit headshot with a simple background builds instant trust."),
        ProfileTip(title: "Clearly Define Your Expertise",
                   detail: "Pick focused tags over broad ones — specificity helps the right clients find you."),
        ProfileTip(title: "Set Competitive Rates",
                   detail: "Check what others in your field charge, then price for the value you deliver."),
    ]
}
