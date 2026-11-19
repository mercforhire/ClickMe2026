//
//  ExploreClientViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ExploreClientViewModel: ObservableObject {


    // MARK: View state
    @Published var showAllCategories: Bool = false

    // MARK: Sections
    @Published var categories: [ExpertCategory] = []
    @Published var experts: [Expert] = []
    /// Curated topics for the "Featured Topics" strip. Hidden on the UI
    /// while empty — no dedicated loading skeleton because the section
    /// isn't in the design as a required always-visible block.
    @Published var featuredTopics: [FeaturedTopic] = []
    /// All of the client's own bookings scheduled for today (client
    /// local timezone), filtered to statuses that actually qualify for
    /// joining (excludes `pendingApproval` etc.). Empty means the
    /// section is hidden entirely — no header, no placeholder.
    @Published var todaysSessions: [UpcomingBooking] = []
    @Published var categoriesState: LoadState = .idle
    @Published var expertsState: LoadState = .idle
    @Published var featuredTopicsState: LoadState = .idle

    /// Slug IDs (matching `/categories`) selected in the "All Categories"
    /// modal. Empty set means the "All" chip is active — no filter applied.
    @Published var selectedCategorySlugs: Set<String> = []

    // MARK: Dependencies
    private let api: ClickMeAPI
    private let toasts: ToastCenter

    /// Orders the `/client/home` fetches (WR-08). Each fetch takes the next value when it
    /// starts and applies its response only while it still holds the newest one, so a slower
    /// response for an older filter can never overwrite a newer one.
    private var fetchGeneration = 0

    // MARK: Inits

    init(api: ClickMeAPI = .shared, toasts: ToastCenter = .shared) {
        self.api = api
        self.toasts = toasts
    }

    /// Preview seam — bypasses the network entirely and installs canned data
    /// as if a load had already succeeded.
    init(
        previewCategories: [ExpertCategory],
        previewExperts: [Expert],
        previewFeaturedTopics: [FeaturedTopic] = []
    ) {
        self.api = .shared
        self.toasts = .shared
        self.categories = previewCategories
        self.experts = previewExperts
        self.featuredTopics = previewFeaturedTopics
        self.categoriesState = .loaded
        self.expertsState = .loaded
        self.featuredTopicsState = .loaded
    }

    // MARK: - Load

    /// Fetches `/client/home` and populates both sections in one round trip.
    /// When `selectedCategorySlugs` is non-empty, forwards them as the
    /// `?category=` filter so the server narrows `recommended_experts`.
    ///
    /// Also fires `getClientBookings(.upcoming)` in the background so the
    /// "Today's Sessions" strip at the top of the screen has data. That
    /// fetch is a soft dependency — a failure there just hides the strip
    /// (matches the "empty means hidden" behavior).
    ///
    /// SwiftUI cancels the `.refreshable` task when the ScrollView re-renders
    /// mid-refresh, and the `.task` task when the screen disappears. The fetch
    /// runs in an unstructured `Task`, which is not a child of its caller, so
    /// that cancellation never reaches URLSession (G-04-3). Awaiting its value
    /// keeps the refresh spinner up until the fetch ends. Sections that already
    /// show content keep it until the response replaces it, and also when the
    /// refresh fails: the error then shows as a toast (IN-11).
    func load() async {
        await Task { await self.fetchHome(replacingLoadedContent: false) }.value
    }

    /// One `/client/home` round trip, then Today's Sessions.
    ///
    /// - Parameter replacingLoadedContent: When `false` (a refresh, a retry or a
    ///   reappear), a section that is already `.loaded` stays on screen until the
    ///   response replaces it. When `true` (a category change), every section shows
    ///   its skeleton, because the loaded experts no longer match the new filter.
    private func fetchHome(replacingLoadedContent: Bool) async {
        fetchGeneration += 1
        let generation = fetchGeneration
        // What each section showed before this fetch, for a cancelled fetch to restore.
        let categoriesBefore = categoriesState
        let expertsBefore = expertsState
        let featuredBefore = featuredTopicsState
        // A refresh keeps a loaded section on screen; everything else shows its skeleton.
        func begin(_ state: LoadState) -> LoadState {
            (state == .loaded && !replacingLoadedContent) ? state : .loading
        }
        set(\.categoriesState, to: begin(categoriesState))
        set(\.expertsState, to: begin(expertsState))
        set(\.featuredTopicsState, to: begin(featuredTopicsState))
        do {
            let response = try await api.getClientHome(
                categorySlugs: selectedCategorySlugs.isEmpty ? nil : selectedCategorySlugs.sorted()
            )
            // A newer fetch owns the screen. Its own response settles every section.
            guard generation == fetchGeneration else { return }
            categories = response.data.trendingCategories.map(Self.mapCategory)
            experts = response.data.recommendedExperts.map(Self.mapExpert)
            featuredTopics = (response.data.featuredTopics ?? []).map(Self.mapFeaturedTopic)
            syncCategorySelection()
            categoriesState = .loaded
            expertsState = .loaded
            featuredTopicsState = .loaded
        } catch {
            guard generation == fetchGeneration else { return }
            // A cancelled fetch (`URLError.cancelled` or `CancellationError`) is not a
            // failure. Since `load()` shields the fetch, only the URL loading system can
            // still cancel it, and no other fetch is guaranteed to follow. The old revert
            // to idle left skeletons with nothing loading (G-04-3). Each section still
            // loading returns to what it showed before this fetch, and a section another
            // fetch has already settled is left alone.
            if error.isCancellation {
                set(\.categoriesState, to: Self.stateAfterCancelledFetch(current: categoriesState, before: categoriesBefore))
                set(\.expertsState, to: Self.stateAfterCancelledFetch(current: expertsState, before: expertsBefore))
                set(\.featuredTopicsState, to: Self.stateAfterCancelledFetch(current: featuredTopicsState, before: featuredBefore))
            } else {
                let msg = error.userMessage
                // IN-11: a refresh over content that is on screen keeps it and reports the failure
                // as a toast, so pulling to refresh offline does not replace the experts the user
                // was looking at with a Retry card. A first load, a Retry and a category change
                // (the content no longer matches the filter) still show the failure in the section.
                let keepsCategories = !replacingLoadedContent && categoriesBefore == .loaded
                let keepsExperts = !replacingLoadedContent && expertsBefore == .loaded
                let keepsFeatured = !replacingLoadedContent && featuredBefore == .loaded
                // Don't leave stale Featured Topics beside a section error.
                if !keepsFeatured { featuredTopics = [] }
                set(\.categoriesState, to: keepsCategories ? .loaded : .failed(msg))
                set(\.expertsState, to: keepsExperts ? .loaded : .failed(msg))
                set(\.featuredTopicsState, to: keepsFeatured ? .loaded : .failed(msg))
                if keepsCategories || keepsExperts || keepsFeatured {
                    toasts.show(msg, systemImage: "exclamationmark.triangle.fill")
                }
            }
        }

        guard generation == fetchGeneration else { return }
        await loadTodaysSessions()
    }

    /// Assigns a section's state only when it changes, so a refresh over loaded content publishes nothing.
    private func set(_ section: ReferenceWritableKeyPath<ExploreClientViewModel, LoadState>, to state: LoadState) {
        if self[keyPath: section] != state { self[keyPath: section] = state }
    }

    /// Populates `todaysSessions` from `GET /client/bookings?type=upcoming`.
    /// Filtered to bookings whose `startTime` is today (client's local
    /// calendar) AND whose status qualifies as joinable — mirrors the
    /// expert dashboard's rule so pending-approval bookings don't render
    /// a Join button before the expert has accepted.
    ///
    /// Silent on failure: leaves `todaysSessions` empty, which hides the
    /// whole section — the discovery content below is the primary
    /// experience, no need to surface a noisy error banner for this
    /// secondary strip.
    private func loadTodaysSessions() async {
        do {
            let response = try await api.getClientBookings(type: .upcoming)
            let calendar = Calendar.current
            todaysSessions = response.data.bookings
                .filter { calendar.isDateInToday($0.startTime) }
                .sorted { $0.startTime < $1.startTime }
                .compactMap(Self.mapTodaysSessionIfJoinable)
        } catch {
            todaysSessions = []
        }
    }

    /// `ClientBookingItem` → `UpcomingBooking` for the today-strip. Returns
    /// nil for statuses that don't qualify (pendingApproval, completed,
    /// cancelled, etc.) — same rule as the expert dashboard.
    private static func mapTodaysSessionIfJoinable(_ item: ClientBookingItem) -> UpcomingBooking? {
        guard let status = BookingStatus(rawValue: item.status), isJoinable(status) else {
            return nil
        }
        return UpcomingBooking(
            id: item.bookingId,
            expertId: item.expert.id,
            expertName: item.expert.fullName ?? "Expert",
            topic: item.topic ?? "Consultation",
            date: dateString(item.startTime),
            timeRange: timeRangeString(from: item.startTime, to: item.endTime),
            imageURL: item.expert.avatarUrl ?? "",
            startTime: item.startTime,
            endTime: item.endTime,
            status: status,
            meetingType: item.meetingType,
            privateNotePreview: item.privateNotePreview,
            reschedule: item.reschedule
        )
    }

    private static func isJoinable(_ status: BookingStatus) -> Bool {
        switch status {
        case .confirmed, .inProgress, .pendingReschedule:
            return true
        case .pendingApproval, .completed, .cancelled, .declined, .missed, .expired,
             .rescheduled, .unknown:
            // `rescheduled` and `unknown` are not strip members; whether
            // Join is offered is decided by the join helper (plan 02-04).
            return false
        }
    }

    private static func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    /// Start and end in the device's time style (12 or 24 hour, BOOK-04), joined
    /// by " - ". Internal so tests can pass an explicit zone and locale.
    static func timeRangeString(
        from start: Date,
        to end: Date,
        timeZone: TimeZone = .current,
        locale: Locale = .current
    ) -> String {
        let startText = DateUtil.shortTime(start, timeZone: timeZone, locale: locale)
        let endText = DateUtil.shortTime(end, timeZone: timeZone, locale: locale)
        return "\(startText) - \(endText)"
    }

    /// After a fresh load remaps categories (wiping their `isSelected` flags),
    /// mirror the persistent `selectedCategorySlugs` set back onto each chip
    /// so the visual highlight survives across refreshes.
    private func syncCategorySelection() {
        for i in categories.indices {
            categories[i].isSelected = selectedCategorySlugs.contains(categories[i].slug)
        }
    }

    /// Pull-to-refresh and section Retry handler; same as `load()`.
    func reload() async {
        await load()
    }

    // MARK: - Category selection

    /// Single-select toggle on the trending-categories row: tapping a chip
    /// applies that slug as the server-side filter; tapping the currently
    /// selected chip clears the filter. Mutates both the local `isSelected`
    /// flag (drives the green highlight) and the persistent
    /// `selectedCategorySlugs` set (drives `?category=` on the next load).
    func selectCategory(at index: Int) {
        guard categories.indices.contains(index) else { return }
        let tapped = categories[index]
        let wasSelected = tapped.isSelected

        for i in categories.indices {
            categories[i].isSelected = false
        }

        if wasSelected {
            applySelectedCategories([])
        } else {
            categories[index].isSelected = true
            applySelectedCategories([tapped.slug])
        }
    }

    /// Called by the "All Categories" modal when it dismisses. Stores the new
    /// selection and refreshes the recommended experts list if the set
    /// actually changed.
    func applySelectedCategories(_ slugs: Set<String>) {
        guard slugs != selectedCategorySlugs else { return }
        selectedCategorySlugs = slugs
        // The loaded experts no longer match the new filter, so this path keeps its skeletons (unchanged).
        // This Task is already unstructured and nobody cancels it.
        Task { await fetchHome(replacingLoadedContent: true) }
    }

    // MARK: - Mapping helpers

    private static func mapCategory(_ tc: ClientHomeData.TrendingCategory) -> ExpertCategory {
        ExpertCategory(
            slug: tc.id,
            icon: CategoryIconMap.sfSymbol(forSlug: tc.id),
            name: tc.name ?? "Category",
            isSelected: false
        )
    }

    private static func mapExpert(_ re: ClientHomeData.RecommendedExpert) -> Expert {
        Expert(
            expertId: re.expertId,
            name: re.fullName ?? "Expert",
            title: re.title ?? "",
            tags: re.expertiseTags ?? [],
            rating: re.rating ?? 0,
            reviewCount: re.reviewCount ?? 0,
            imageURL: re.profileImageUrl ?? ""
        )
    }

    /// Formats the server's minor-units rate into a display label like
    /// `"$120"` or `"Free"`. Falls back to `"—"` when the amount or the
    /// currency is missing.
    private static func mapFeaturedTopic(_ t: ClientHomeData.FeaturedTopic) -> FeaturedTopic {
        FeaturedTopic(
            topicId: t.topicId,
            title: t.title,
            priceLabel: formatPrice(t.hourlyRate, isFree: t.isFree),
            expertId: t.expert.expertId,
            expertName: t.expert.fullName ?? "Expert",
            expertImageURL: t.expert.profileImageUrl ?? ""
        )
    }

    /// Renders the topic's per-session flat price (e.g. `"$50.00"`). The
    /// server ships this value under a `hourly_rate` key on
    /// `/client/home.featured_topics`, but the amount is what the client
    /// actually pays per booking — misleading key, per-session semantics.
    private static func formatPrice(
        _ rate: ClientHomeData.FeaturedTopic.HourlyRate?,
        isFree: Bool?
    ) -> String {
        if isFree == true { return "Free" }
        guard let amount = rate?.amount, let currency = rate?.currency else { return "—" }
        return Money.format(minorUnits: amount, currency: currency)
    }

    // MARK: - Error helpers

    /// The app's one generic failure sentence (`NetworkError`'s fixed `errorDescription`).
    /// Shown when a section's first load is cancelled, so the section offers Retry instead
    /// of a skeleton with nothing loading. It adds no new copy.
    static let interruptedLoadMessage = NetworkError.invalidResponse.userMessage

    /// Where a section lands when its fetch is cancelled.
    ///
    /// Only the newest fetch settles anything (`fetchGeneration`), so a section still `.loading` when
    /// this runs was set by this fetch or by an older one that the generation guard dropped. Either way
    /// no other fetch is in flight for it, so it must not stay on a skeleton. Anything other than
    /// `.loading` stays as it is, because another fetch has already settled it.
    ///
    /// For a section still `.loading`, `before` is what it showed ahead of the cancelled fetch:
    /// - `.loaded` returns `.loaded`, since the content arrays were never cleared.
    /// - `.failed` returns the same failure, with its Retry.
    /// - `.idle` returns the generic failure with Retry, because a first load must not strand a skeleton.
    /// - `.loading` means an older, dropped fetch left the skeleton and nothing is loading it, so it is
    ///   treated like `.idle`.
    static func stateAfterCancelledFetch(current: LoadState, before: LoadState) -> LoadState {
        guard current == .loading else { return current }
        switch before {
        case .loaded, .failed:
            return before
        case .idle, .loading:
            return .failed(interruptedLoadMessage)
        }
    }
}
