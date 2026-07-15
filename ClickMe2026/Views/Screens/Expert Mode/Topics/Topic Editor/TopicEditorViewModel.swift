//
//  TopicEditorViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-11.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

/// State for the Add/Edit Topic screen. Local to the editor — the parent
/// screen (`TopicsSetupView`) receives the validated values via the
/// `onSave` closure and performs the actual POST/PATCH.
@MainActor
final class TopicEditorViewModel: ObservableObject {

    // MARK: Form state
    @Published var title: String
    @Published var descriptionText: String
    /// Displayed in major currency units (dollars) — converted to minor
    /// units (cents) at submit time.
    @Published var rate: String
    @Published var durationMinutes: String
    @Published var iconSlug: String?

    /// True when the last validate attempt failed. Cleared once the user
    /// edits any field so the error banner doesn't linger.
    @Published var showError: Bool

    /// True when editing an existing topic, false when adding. Drives the
    /// nav title and any "Add" vs "Edit" copy.
    let isEditing: Bool

    /// Default currency for new topics. Server accepts any ISO 4217 code,
    /// but the editor doesn't (yet) offer a picker — most experts on the
    /// platform bill in USD, so start there.
    let defaultCurrency = "USD"

    /// Slugs shown in the icon picker. Curated subset of
    /// `CategoryIconMap.table` covering the most common expert topic
    /// categories. Alphabetical for stable scan-ability.
    let pickableSlugs: [String] = [
        "ai", "business", "career", "coaching", "consulting", "design",
        "education", "engineering", "finance", "fitness", "healthcare",
        "language", "legal", "marketing", "music", "photography",
        "productivity", "psychology", "science", "startup", "tech",
        "travel", "wellness", "writing"
    ]

    // MARK: Init

    /// Seed from an existing topic (edit mode) or nil (add mode).
    init(topic: ExpertTopicItem?) {
        self.isEditing = topic != nil
        self.title = topic?.title ?? ""
        self.descriptionText = topic?.description ?? ""
        // Server sends amount in minor units — show major units in the field.
        self.rate = topic?.hourlyRate.map { String($0.amount / 100) } ?? ""
        self.durationMinutes = topic?.durationMins.map { String($0) } ?? "60"
        self.iconSlug = topic?.iconSlug
        self.showError = false
    }

    // MARK: Icon picker

    func toggleIcon(_ slug: String) {
        // Tap the currently-selected chip to clear the selection.
        iconSlug = (iconSlug == slug) ? nil : slug
    }

    func isSelectedIcon(_ slug: String) -> Bool {
        iconSlug == slug
    }

    // MARK: Validation

    /// Parsed, validated payload ready to hand to the parent's save
    /// closure. Returns nil and flips `showError` on any failure.
    struct ValidatedTopic {
        let title: String
        let description: String?
        let durationMinutes: Int
        /// Minor units — already converted from the major-unit field.
        let hourlyRateAmount: Int
        let currency: String
        let iconSlug: String?
    }

    func validate() -> ValidatedTopic? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty,
              let rateMajor = Int(rate.trimmingCharacters(in: .whitespaces)), rateMajor > 0,
              let duration = Int(durationMinutes.trimmingCharacters(in: .whitespaces)), duration > 0
        else {
            withAnimation { showError = true }
            return nil
        }
        return ValidatedTopic(
            title: trimmedTitle,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            durationMinutes: duration,
            hourlyRateAmount: rateMajor * 100,
            currency: defaultCurrency,
            iconSlug: iconSlug
        )
    }
}
