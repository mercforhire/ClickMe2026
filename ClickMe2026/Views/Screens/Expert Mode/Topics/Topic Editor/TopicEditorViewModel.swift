//
//  TopicEditorViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-11.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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

    /// User-facing message for the last failed `validate()` attempt.
    /// Nil when validation passes or hasn't run. Populated with either
    /// the generic "Please fill in all required fields…" copy or a
    /// specific message (e.g. the below-minimum-price copy). Cleared
    /// by the caller as needed.
    @Published var errorMessage: String?

    /// True when editing an existing topic, false when adding. Drives the
    /// nav title and any "Add" vs "Edit" copy.
    let isEditing: Bool

    /// Default currency for new topics. Backend controls this now via
    /// `PricingLimits.minSessionAmount.defaultCurrency` (per the Pricing
    /// Limits spec §1). The hard-coded `"CAD"` is used only as an
    /// absolute fallback when `/me` hasn't landed yet on cold launch —
    /// the server rejects sub-minimum saves independently with
    /// `PRICE_BELOW_MINIMUM`, so we're not authoritative here.
    var defaultCurrency: String {
        userManager.me?.pricingLimits?.minSessionAmount.defaultCurrency ?? "CAD"
    }

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
        self.errorMessage = nil
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

    /// Applies a fresh profile-tag list from `ExpertiseEditorSheet` after
    /// the user adds/removes tags on their profile from inside the topic
    /// editor. The sheet already saved via `PATCH /expert/profile` and
    /// refreshed `UserManager.expertProfile`; we just mirror the new
    /// list into `availableTags` and drop any topic-level selections that
    /// aren't on the profile anymore (same invariant as `loadTags`).
    func applyProfileTagsUpdate(_ tags: [ExpertiseTagItem]) {
        availableTags = tags.sorted {
            $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending
        }
        let validIds = Set(availableTags.map(\.id))
        selectedTagIds.formIntersection(validIds)
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
    /// closure. Returns nil and populates `errorMessage` on any failure.
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
        let trimmedRate = rate.trimmingCharacters(in: .whitespaces)

        guard !trimmedTitle.isEmpty else {
            withAnimation { errorMessage = "Please fill in all required fields with valid values." }
            return nil
        }

        // Rate parsing: empty OR explicit "0" = free session (allowed).
        // Positive int = paid, subject to the min-price check below.
        // Anything else (non-numeric, negative) = invalid.
        let rateMajor: Int
        if trimmedRate.isEmpty {
            rateMajor = 0
        } else if let parsed = Int(trimmedRate), parsed >= 0 {
            rateMajor = parsed
        } else {
            withAnimation { errorMessage = "Please fill in all required fields with valid values." }
            return nil
        }

        // Server-authoritative floor (per PRICING-LIMITS spec §4) —
        // we validate client-side only for UX, and let the server 422
        // `PRICE_BELOW_MINIMUM` catch anything that slips past
        // (offline cold-launch before `/me` lands, stale cache, etc).
        // Fall through when `pricingLimits` is nil rather than blocking
        // — the server is the authority. Skip entirely for free
        // (`rateMinor == 0`) — the floor doesn't apply to free sessions
        // per spec §4.
        let rateMinor = rateMajor * 100
        let currency = defaultCurrency
        if rateMinor > 0, let limit = userManager.me?.pricingLimits?.minSessionAmount {
            let floor = limit.minMinorUnits(for: currency)
            if rateMinor < floor {
                withAnimation {
                    errorMessage = Self.minPriceMessage(floorMinorUnits: floor, currency: currency)
                }
                return nil
            }
        }

        errorMessage = nil
        return ValidatedTopic(
            title: trimmedTitle,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            durationMinutes: durationMinutes,
            hourlyRateAmount: rateMinor,
            currency: currency,
            iconSlug: iconSlug,
            // Backend validator is case-sensitive; `UUID.uuidString`
            // uppercases hex, so lowercase before sending or the server
            // rejects with "One or more expertise tag ids are not recognized".
            expertiseTagIds: selectedTagIds.map { $0.uuidString.lowercased() }
        )
    }

    /// True while the current typed rate is below the min for the
    /// current currency, non-empty, and non-free. Drives the inline
    /// caption under the price field so the expert sees the constraint
    /// before hitting Save. Returns `false` when `pricingLimits` hasn't
    /// loaded (silent rather than misleading), and for the free case
    /// (empty or `0`) which is exempt from the floor per spec §4.
    var isRateBelowMinimum: Bool {
        guard let limit = userManager.me?.pricingLimits?.minSessionAmount else { return false }
        let trimmed = rate.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let rateMajor = Int(trimmed), rateMajor > 0 else { return false }
        return rateMajor * 100 < limit.minMinorUnits(for: defaultCurrency)
    }

    /// Inline helper caption. Calls out that free is a valid choice so
    /// experts don't assume the min-price applies when they leave the
    /// field blank. `nil` while `pricingLimits` is loading so we don't
    /// render a placeholder that later shifts.
    var minPriceHint: String? {
        guard let limit = userManager.me?.pricingLimits?.minSessionAmount else { return nil }
        let currency = defaultCurrency
        let floor = limit.minMinorUnits(for: currency)
        return "Leave blank or enter 0 for a free session — otherwise min \(Self.formatMinorUnits(floor, currency: currency))."
    }

    // MARK: - Money formatting

    /// User-facing "below the minimum" message shown after a failed
    /// `validate()`. Backend also ships a display-ready message on the
    /// `PRICE_BELOW_MINIMUM` 422 (see spec §4) — save handlers should
    /// prefer the server message when it arrives; this local variant is
    /// for the pre-save (client-side) check.
    private static func minPriceMessage(floorMinorUnits: Int, currency: String) -> String {
        "A paid session must be at least \(formatMinorUnits(floorMinorUnits, currency: currency))."
    }

    /// Formats an integer minor-units value in the given ISO-4217
    /// currency, driving fraction digits off `NumberFormatter.currency`
    /// so zero-decimal currencies (JPY, KRW etc — where a `500` value
    /// really is ¥500, not ¥5.00) render correctly.
    ///
    /// The Pricing Limits spec §5 says symbols and decimals officially
    /// live on `GET /meta/currencies`; this helper is a local
    /// approximation using `NumberFormatter`'s built-in metadata so the
    /// pre-save UX doesn't have to wait on a second fetch. Server
    /// 422 messages are already correctly formatted and should be
    /// preferred on the failure path.
    private static func formatMinorUnits(_ minorUnits: Int, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        let digits = formatter.maximumFractionDigits
        let divisor: Double = pow(10.0, Double(digits))
        let major = Double(minorUnits) / divisor
        return formatter.string(from: NSNumber(value: major))
            ?? "\(currency) \(major)"
    }
}
