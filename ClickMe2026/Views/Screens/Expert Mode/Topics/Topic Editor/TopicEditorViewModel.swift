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
    /// Session length in whole minutes. Edited via a stepper in 30-min
    /// increments; defaults to 60 (one hour).
    @Published var durationMinutes: Int
    @Published var iconSlug: String?

    /// Tags picked from `GET /meta/expertise-tags`. Cap enforced in
    /// `toggleTag`; server also enforces (validation error at 4+).
    @Published var selectedTagIds: Set<UUID>
    /// Fetched from `GET /meta/expertise-tags` on `load()`. Empty until
    /// the fetch resolves; the picker renders a compact "Loading…" row
    /// during that window.
    @Published var availableTags: [ExpertiseTagItem]
    @Published var isLoadingTags: Bool

    /// Client-side substring filter for the tag picker. Purely local —
    /// no re-fetch when it changes. Matched case-insensitively against
    /// each tag's label.
    @Published var tagFilter: String = ""

    /// Bounds and step for the duration stepper.
    let durationRange: ClosedRange<Int> = 30...480
    let durationStep: Int = 30

    /// Per-topic tag cap. Matches the server-side limit — anything higher
    /// gets rejected as `VALIDATION_ERROR`.
    let maxTagSelection = 3

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

    /// Curated slug set covering the most common expert topic
    /// categories, alphabetical for stable scan-ability.
    private let baseSlugs: [String] = [
        "ai", "business", "career", "coaching", "consulting", "design",
        "education", "engineering", "finance", "fitness", "healthcare",
        "language", "legal", "marketing", "music", "photography",
        "productivity", "psychology", "science", "startup", "tech",
        "travel", "wellness", "writing"
    ]

    /// Slugs shown in the icon picker. Includes `baseSlugs` plus the
    /// topic's current `iconSlug` if it happens to be off-list (e.g.,
    /// a slug added by the server that predates this hardcoded set).
    /// That guarantees the pre-selected chip always renders in the
    /// picker so it can visibly highlight.
    var pickableSlugs: [String] {
        guard let current = iconSlug, !current.isEmpty, !baseSlugs.contains(current) else {
            return baseSlugs
        }
        return [current] + baseSlugs
    }

    // MARK: Dependencies

    private let api: ClickMeAPI
    private let userManager: UserManager

    // MARK: Init

    /// Seed from an existing topic (edit mode) or nil (add mode).
    init(
        topic: ExpertTopicItem?,
        api: ClickMeAPI = .shared,
        userManager: UserManager = .shared
    ) {
        self.isEditing = topic != nil
        self.title = topic?.title ?? ""
        self.descriptionText = topic?.description ?? ""
        // Server sends amount in minor units — show major units in the field.
        // Prefer `hourlyRate` (present on the expert's own topic list) but
        // fall back to `price.amount` when older/public payloads omit it.
        let minorAmount = topic?.hourlyRate?.amount ?? topic?.price.amount
        self.rate = minorAmount.map { String($0 / 100) } ?? ""
        self.durationMinutes = topic?.durationMins ?? 60
        self.iconSlug = topic?.iconSlug
        self.selectedTagIds = Set(topic?.expertiseTags?.map(\.id) ?? [])
        self.availableTags = []
        self.isLoadingTags = false
        self.showError = false
        self.api = api
        self.userManager = userManager
    }

    /// Preview seam — installs canned tag list without hitting the network.
    static func previewSeed(
        topic: ExpertTopicItem? = nil,
        availableTags: [ExpertiseTagItem] = []
    ) -> TopicEditorViewModel {
        let vm = TopicEditorViewModel(topic: topic)
        vm.availableTags = availableTags
        return vm
    }

    // MARK: - Tag load

    /// Populates the tag picker from the expert's own **profile** expertise
    /// tags — NOT the full `/meta/expertise-tags` catalog. The server
    /// rejects any topic tag that isn't on the expert's profile
    /// (`VALIDATION_ERROR: "Topic tags must be selected from your profile
    /// expertise tags"`), so scoping the picker here mirrors the constraint
    /// and prevents impossible selections.
    ///
    /// If the profile snapshot isn't cached yet, refreshes it once. Silent
    /// on failure — the picker just renders "No tags available" until a
    /// later attempt succeeds.
    func loadTags() async {
        guard availableTags.isEmpty, !isLoadingTags else { return }
        isLoadingTags = true
        defer { isLoadingTags = false }

        if userManager.expertProfile == nil {
            try? await userManager.refreshExpertProfile()
        }

        let entries = userManager.expertProfile?.expertiseTags ?? []
        availableTags = entries
            .map { ExpertiseTagItem(id: $0.id, label: $0.label, categoryId: $0.categoryId ?? "") }
            .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }

        // Drop any pre-seeded selections that aren't on the expert's current
        // profile — otherwise the server rejects the save with a 422
        // ("One or more expertise tags are not in your profile").
        let validIds = Set(availableTags.map(\.id))
        selectedTagIds.formIntersection(validIds)
    }

    // MARK: Icon picker

    func toggleIcon(_ slug: String) {
        // Tap the currently-selected chip to clear the selection.
        iconSlug = (iconSlug == slug) ? nil : slug
    }

    func isSelectedIcon(_ slug: String) -> Bool {
        iconSlug == slug
    }

    // MARK: Tag picker

    func isSelectedTag(_ tag: ExpertiseTagItem) -> Bool {
        selectedTagIds.contains(tag.id)
    }

    /// `availableTags` narrowed by the current `tagFilter`. Empty filter
    /// returns the full list. Already-selected tags are always kept
    /// visible even when they'd otherwise be filtered out, so the user
    /// can see & de-select them without clearing the search first.
    var filteredTags: [ExpertiseTagItem] {
        let trimmed = tagFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return availableTags }
        return availableTags.filter {
            selectedTagIds.contains($0.id)
                || $0.label.localizedCaseInsensitiveContains(trimmed)
        }
    }

    /// Toggle tag selection. Honors the `maxTagSelection` cap on the way
    /// in — removals always succeed.
    func toggleTag(_ tag: ExpertiseTagItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedTagIds.contains(tag.id) {
                selectedTagIds.remove(tag.id)
            } else if selectedTagIds.count < maxTagSelection {
                selectedTagIds.insert(tag.id)
            }
        }
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
        let expertiseTagIds: [String]
    }

    func validate() -> ValidatedTopic? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty,
              let rateMajor = Int(rate.trimmingCharacters(in: .whitespaces)), rateMajor > 0
        else {
            withAnimation { showError = true }
            return nil
        }
        return ValidatedTopic(
            title: trimmedTitle,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            durationMinutes: durationMinutes,
            hourlyRateAmount: rateMajor * 100,
            currency: defaultCurrency,
            iconSlug: iconSlug,
            // Backend validator is case-sensitive; `UUID.uuidString`
            // uppercases hex, so lowercase before sending or the server
            // rejects with "One or more expertise tag ids are not recognized".
            expertiseTagIds: selectedTagIds.map { $0.uuidString.lowercased() }
        )
    }
}
