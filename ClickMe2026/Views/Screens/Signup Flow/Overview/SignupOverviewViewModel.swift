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

    /// Injected accumulator — when present, `checklist` is derived from
    /// its state so the four rows tick automatically as the user
    /// completes earlier steps.
    private let accumulator: SignupAccumulator?

    @Published var overrideChecklist: [ChecklistItem]?
    @Published var tips: [ProfileTip]

    // MARK: Init

    /// Preview / test init — accepts a canned checklist.
    init(
        checklist: [ChecklistItem]? = SignupOverviewViewModel.defaultChecklist,
        tips: [ProfileTip] = SignupOverviewViewModel.defaultTips
    ) {
        self.accumulator = nil
        self.overrideChecklist = checklist
        self.tips = tips
    }

    /// Runtime init — derives checklist entirely from the accumulator so
    /// the four rows reflect the live payload state.
    init(
        accumulator: SignupAccumulator,
        tips: [ProfileTip] = SignupOverviewViewModel.defaultTips
    ) {
        self.accumulator = accumulator
        self.overrideChecklist = nil
        self.tips = tips
    }

    // MARK: - Derived

    /// Checklist rendered by the view. If an override was provided
    /// (preview path), use it; else compute from the accumulator's
    /// `checklist` flags.
    var checklist: [ChecklistItem] {
        if let overrideChecklist { return overrideChecklist }
        guard let accumulator else { return SignupOverviewViewModel.defaultChecklist }
        let c = accumulator.checklist
        return [
            ChecklistItem(kind: .basicInfo,      title: "Personal details",    isComplete: c.basicInfo),
            ChecklistItem(kind: .timezone,       title: "Confirm timezone",    isComplete: c.timezone),
            ChecklistItem(kind: .profilePicture, title: "Add profile picture", isComplete: c.profilePhoto),
            ChecklistItem(kind: .verifyEmail,    title: "Verify email",        isComplete: c.emailVerified),
            ChecklistItem(kind: .expertise,      title: "Add expertise",       isComplete: c.expertise),
        ]
    }

    var progress: Double {
        guard !checklist.isEmpty else { return 0 }
        let done = checklist.filter(\.isComplete).count
        return Double(done) / Double(checklist.count)
    }

    // MARK: - Defaults

    static let defaultChecklist = [
        ChecklistItem(kind: .basicInfo,      title: "Personal details",    isComplete: true),
        ChecklistItem(kind: .timezone,       title: "Confirm timezone",    isComplete: true),
        ChecklistItem(kind: .profilePicture, title: "Add profile picture", isComplete: true),
        ChecklistItem(kind: .verifyEmail,    title: "Verify email",        isComplete: true),
        ChecklistItem(kind: .expertise,      title: "Add expertise",       isComplete: false),
    ]

    static let defaultTips = [
        ProfileTip(title: "Craft a Compelling Bio",
                   detail: "Lead with the problem you solve. Keep it to 2–3 sentences and write the way you'd talk to a client."),
        ProfileTip(title: "Choose a Professional Picture",
                   detail: "A clear, well-lit headshot with a simple background builds instant trust."),
        ProfileTip(title: "Clearly Define Your Expertise",
                   detail: "Pick focused tags over broad ones — specificity helps the right clients find you."),
    ]
}
