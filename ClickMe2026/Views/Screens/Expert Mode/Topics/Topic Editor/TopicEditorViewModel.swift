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
    /// Price text in major units. Seeded losslessly from the topic's stored
    /// minor amount with the topic currency's digit count (`12550` USD seeds
    /// `"125.50"`, `12500` seeds `"125"`, `1200` JPY seeds `"1200"`; D-11),
    /// so a price with cents is shown to the cent instead of being truncated
    /// by integer division. While the trimmed text still equals that seed,
    /// `validate()` sends the stored minor amount back unchanged (D-19).
    /// Once the expert edits it, the text is parsed in the currency's fraction
    /// digits by `TopicPriceRules.parseMinor` (D-05: `12.50` and `12,50` are
    /// 1250 CAD). Either way the amount is priced in `currency`, the topic's
    /// own currency (backend Phase 34 D-18). Typing goes through
    /// `updateRate(_:)`, which filters the text first.
    @Published var rate: String
    /// The currency this topic is priced in. Seeded from the topic's own
    /// stored currency (never the account default) or, for a new topic or a
    /// topic that carries none, from the backend default. A blank or malformed
    /// stored code counts as no currency (G-06-1-currency). Picked from
    /// `pickableCurrencies` unless `isCurrencyLocked`. Sent with every save,
    /// on typed and untouched prices alike, and always a 3-letter code.
    @Published var currency: String
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

    /// True when the picker must not change `currency`: an existing paid
    /// topic that already carries a currency. Mirrors the server's paid-topic
    /// lock (`422 TOPIC_CURRENCY_LOCKED`, backend Phase 34 D-04). A free
    /// topic, new or existing, may pick any allowed currency.
    let isCurrencyLocked: Bool

    /// Default currency for new topics. Backend controls this now via
    /// `PricingLimits.minSessionAmount.defaultCurrency` (per the Pricing
    /// Limits spec §1). The hard-coded `"CAD"` is used only as an
    /// absolute fallback when `/me` hasn't landed yet on cold launch —
    /// the server rejects sub-minimum saves independently with
    /// `PRICE_BELOW_MINIMUM`, so we're not authoritative here. Only a seed
    /// for a new topic; an existing topic keeps its own `currency`.
    var defaultCurrency: String {
        Self.accountDefaultCurrency(currentMe)
    }

    /// Currencies a topic may be priced in: `pricing_limits.allowed_currencies`,
    /// or just the default currency when the backend omits the key (older
    /// server, or `/me` not loaded yet). See `docs/ios/USD-TOPIC-PRICING.md` §1.
    var allowedCurrencies: [String] {
        Self.allowedCurrencies(in: currentMe)
    }

    /// Currencies shown in the picker: `allowedCurrencies` plus the current
    /// `currency` when it is missing from the list, so the selection always
    /// renders and an edit never blocks (same idea as `pickableSlugs`). A
    /// blank or malformed `currency` is never appended (G-06-1-currency), so
    /// the picker has no invisible extra segment.
    var pickableCurrencies: [String] {
        let allowed = allowedCurrencies
        guard !allowed.contains(currency), TopicPriceRules.validCurrencyCode(currency) != nil else {
            return allowed
        }
        return allowed + [currency]
    }

    /// Short symbol for the price field label: `US$`, `CA$`, else the ISO code.
    var currencySymbol: String {
        switch currency {
        case "USD": return "US$"
        case "CAD": return "CA$"
        default: return currency
        }
    }

    /// True while the USD FX notice should show.
    var showsUSDFXNotice: Bool { currency == "USD" }

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
    /// Reads the account's `/me` for the currency rules and the price floor.
    /// The default reads the signed-in `userManager.me` live, so a `/me` that
    /// lands after the editor opens is used. Tests inject a fixed `MeData`:
    /// `UserManager`'s private init rewires the shared API client's token
    /// refresher and connects the shared realtime socket, so a test cannot
    /// build its own instance (06-REVIEW IN-07).
    private let meProvider: @MainActor () -> MeData?
    private var currentMe: MeData? { meProvider() }

    // MARK: Price seed (D-19)

    /// The text `rate` was seeded with. `validate()` compares the trimmed
    /// field against this to tell an untouched price from an edited one.
    private let seededRate: String
    /// The topic's stored minor amount, or nil for a new topic or one with
    /// no amount. Sent back as-is on an untouched save so a `12.50` topic
    /// is never rewritten to `12.00` by the whole-number parser.
    private let seededRateMinor: Int?

    // MARK: Currency resolution (backend Phase 34 D-18)

    /// The currency the editor starts on, uppercased: the topic's own stored
    /// currency (`ExpertTopicItem.storedCurrency`), else `defaultCurrency`
    /// when it is a valid code, else `CAD` (Android `resolveCurrency` parity).
    /// A blank or malformed stored code counts as no currency (G-06-1-currency).
    /// Never the account default for a topic that carries a currency; that
    /// was the bug that re-priced a USD topic in CAD on a retyped price.
    static func resolveInitialCurrency(topic: ExpertTopicItem?, defaultCurrency: String) -> String {
        topic?.storedCurrency ?? TopicPriceRules.validCurrencyCode(defaultCurrency) ?? "CAD"
    }

    /// True for an existing topic that is paid and carries a valid stored
    /// currency. A paid topic with a blank or malformed code is unlocked on
    /// the default (G-06-1-currency).
    static func isCurrencyLocked(topic: ExpertTopicItem?) -> Bool {
        guard let topic else { return false }
        return !topic.price.isFree && topic.storedCurrency != nil
    }

    private static func accountDefaultCurrency(_ me: MeData?) -> String {
        me?.pricingLimits?.minSessionAmount.defaultCurrency ?? "CAD"
    }

    private static func allowedCurrencies(in me: MeData?) -> [String] {
        me?.pricingLimits?.allowedCurrencies?.map { $0.uppercased() }
            ?? [accountDefaultCurrency(me)]
    }

    /// The currency a new topic starts on, and the one a topic with no valid
    /// stored currency opens in: the backend default when it is pickable,
    /// otherwise the first allowed currency. Passed to
    /// `resolveInitialCurrency`, which validates it and falls back to CAD.
    /// `TopicsSetupTopicCard` calls it too, so the card prices such a topic in
    /// the editor's currency (G-06-1-card-cents, user decision 2026-11-16).
    static func newTopicDefaultCurrency(in me: MeData?) -> String {
        let accountDefault = accountDefaultCurrency(me)
        let allowed = allowedCurrencies(in: me)
        return allowed.contains(accountDefault.uppercased())
            ? accountDefault
            : (allowed.first ?? accountDefault)
    }

    // MARK: Init

    /// Seed from an existing topic (edit mode) or nil (add mode).
    init(
        topic: ExpertTopicItem?,
        api: ClickMeAPI = .shared,
        userManager: UserManager = .shared,
        meProvider: (@MainActor () -> MeData?)? = nil
    ) {
        let meProvider = meProvider ?? { userManager.me }
        let me = meProvider()
        self.isEditing = topic != nil
        self.title = topic?.title ?? ""
        self.descriptionText = topic?.description ?? ""
        // Server sends the amount in minor units. Prefer `hourlyRate`
        // (present on the expert's own topic list) but fall back to
        // `price.amount` when older/public payloads omit it. The field shows
        // the stored amount without loss, using the digit count of the
        // topic's own currency (or the account default when the topic has
        // none or a blank one, which is the currency the backend assumes for
        // it). The seed and the stored amount are kept so an untouched save
        // can send the amount back unchanged (D-19). The currency starts on the topic's
        // own stored currency, never the account default (backend Phase 34
        // D-18); only a topic with none (a blank or malformed stored code
        // counts as none, G-06-1-currency), or a new topic, takes the default.
        let minorAmount = topic?.hourlyRate?.amount ?? topic?.price.amount
        let storedCurrency = topic?.storedCurrency
        let accountDefault = Self.accountDefaultCurrency(me)
        let seedCurrency = storedCurrency ?? accountDefault
        let seed = minorAmount.map { Self.editableAmount(minorUnits: $0, currency: seedCurrency) } ?? ""
        self.rate = seed
        self.seededRate = seed
        self.seededRateMinor = minorAmount
        self.currency = Self.resolveInitialCurrency(
            topic: topic,
            defaultCurrency: Self.newTopicDefaultCurrency(in: me)
        )
        self.isCurrencyLocked = Self.isCurrencyLocked(topic: topic)
        self.durationMinutes = topic?.durationMins ?? 60
        self.iconSlug = topic?.iconSlug
        self.selectedTagIds = Set(topic?.expertiseTags?.map(\.id) ?? [])
        self.availableTags = []
        self.isLoadingTags = false
        self.errorMessage = nil
        self.api = api
        self.userManager = userManager
        self.meProvider = meProvider
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

    // MARK: Price input

    /// Stores what the price field keeps of `raw`: digits and one separator,
    /// capped to the currency's fraction digits (`TopicPriceRules.filterInput`).
    /// Switching `currency` never calls this, so the typed text survives a
    /// currency change untouched (D-03).
    func updateRate(_ raw: String) {
        rate = TopicPriceRules.filterInput(raw, currency: currency)
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
        /// Minor units. The topic's stored amount when the price field was
        /// left at its seed (D-19), otherwise the typed text parsed in the
        /// currency's fraction digits (D-05).
        let hourlyRateAmount: Int
        /// The editor's `currency`: the topic's own stored currency for an
        /// existing paid topic (locked), the picked one for a new or free
        /// topic. Same on typed and untouched prices (backend Phase 34 D-18).
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

        // Both branches price the amount in `currency`, the topic's own
        // currency (or the one the expert picked on a new or free topic),
        // never the account default (backend Phase 34 D-18).
        let rateMinor: Int
        if let seededRateMinor, trimmedRate == seededRate {
            // Untouched price (D-19): send the stored minor amount back
            // unchanged, so an open-and-save never rewrites it.
            rateMinor = seededRateMinor
        } else {
            // Empty OR explicit "0" = free session (allowed). A positive
            // amount is paid, subject to the min-price check below. Anything
            // the currency cannot represent (non-numeric, negative, too many
            // decimals) = invalid. The live hint reads the same parse (D-05).
            guard let parsed = TopicPriceRules.parseMinor(trimmedRate, currency: currency) else {
                withAnimation { errorMessage = "Please fill in all required fields with valid values." }
                return nil
            }
            rateMinor = parsed
        }

        // Server-authoritative floor (per PRICING-LIMITS spec §4) —
        // we validate client-side only for UX, and let the server 422
        // `PRICE_BELOW_MINIMUM` catch anything that slips past
        // (offline cold-launch before `/me` lands, stale cache, etc).
        // Fall through when `pricingLimits` is nil rather than blocking
        // — the server is the authority. Skip entirely for free
        // (`rateMinor == 0`) — the floor doesn't apply to free sessions
        // per spec §4. The floor is looked up for the currency chosen
        // above, so an untouched USD topic is checked against the USD floor.
        if let limit = currentMe?.pricingLimits?.minSessionAmount {
            let floor = limit.minMinorUnits(for: currency)
            if TopicPriceRules.isBelowFloor(minor: rateMinor, floorMinor: floor) {
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
    /// selected `currency`, non-empty, and non-free. Drives the inline
    /// caption under the price field so the expert sees the constraint
    /// before hitting Save. Returns `false` when `pricingLimits` hasn't
    /// loaded (silent rather than misleading), and for the free case
    /// (empty or `0`) which is exempt from the floor per spec §4.
    var isRateBelowMinimum: Bool {
        TopicPriceRules.isBelowFloor(
            rateText: rate,
            currency: currency,
            floorMinor: currentMe?.pricingLimits?.minSessionAmount.minMinorUnits(for: currency)
        )
    }

    /// Inline helper caption. Calls out that free is a valid choice so
    /// experts don't assume the min-price applies when they leave the
    /// field blank. `nil` while `pricingLimits` is loading so we don't
    /// render a placeholder that later shifts.
    var minPriceHint: String? {
        guard let limit = currentMe?.pricingLimits?.minSessionAmount else { return nil }
        let floor = limit.minMinorUnits(for: currency)
        return "Leave blank or enter 0 for a free session — otherwise min \(Self.formatMinorUnits(floor, currency: currency))."
    }

    // MARK: - Money formatting

    /// Editable text for a stored minor-unit amount, for seeding the price
    /// field (D-11, D-19). Not a label: no symbol and no grouping, because
    /// the expert edits it. The digit count comes from `Money` so the seed
    /// matches what the server means by `amount` in that currency (`1250`
    /// USD is `"12.50"`, `1200` JPY is `"1200"`). A whole amount seeds as a
    /// plain integer (`"12"`, not `"12.00"`); a seed with cents is recognized
    /// by `validate()` and passed through as stored. Integer arithmetic only,
    /// and total: a negative value gets a leading `-`.
    static func editableAmount(minorUnits: Int, currency: String) -> String {
        let digits = Money.fractionDigits(for: currency)
        let sign = minorUnits < 0 ? "-" : ""
        let magnitude = minorUnits.magnitude
        guard digits > 0 else { return sign + String(magnitude) }

        var divisor: UInt = 1
        for _ in 0..<digits { divisor *= 10 }
        let whole = magnitude / divisor
        let fraction = magnitude % divisor
        guard fraction > 0 else { return sign + String(whole) }

        let fractionText = String(fraction)
        let padding = String(repeating: "0", count: digits - fractionText.count)
        return sign + String(whole) + "." + padding + fractionText
    }

    /// User-facing "below the minimum" message shown after a failed
    /// `validate()`. Backend also ships a display-ready message on the
    /// `PRICE_BELOW_MINIMUM` 422 (see spec §4) — save handlers should
    /// prefer the server message when it arrives; this local variant is
    /// for the pre-save (client-side) check.
    private static func minPriceMessage(floorMinorUnits: Int, currency: String) -> String {
        "A paid session must be at least \(formatMinorUnits(floorMinorUnits, currency: currency))."
    }

    /// Formats an integer minor-units value in the given ISO-4217 currency
    /// for the min-price hint and message, through `Money` (BOOK-10): full
    /// minor digits, a fixed symbol (`CA$5.00`), and the backend's
    /// zero-decimal set deciding the digit count (`¥500`, not `¥5.00`).
    ///
    /// The Pricing Limits spec §5 says symbols and decimals officially live
    /// on `GET /meta/currencies`; `Money` mirrors the backend's tables so the
    /// pre-save UX doesn't have to wait on a second fetch. Server 422
    /// messages are already correctly formatted and should be preferred on
    /// the failure path.
    private static func formatMinorUnits(_ minorUnits: Int, currency: String) -> String {
        Money.format(minorUnits: minorUnits, currency: currency)
    }
}
