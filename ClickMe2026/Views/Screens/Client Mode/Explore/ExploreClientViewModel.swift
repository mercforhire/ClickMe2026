//
//  ExploreClientViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
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

    // MARK: Inits

    init(api: ClickMeAPI = .shared) {
        self.api = api
    }

    /// Preview seam — bypasses the network entirely and installs canned data
    /// as if a load had already succeeded.
    init(
        previewCategories: [ExpertCategory],
        previewExperts: [Expert],
        previewFeaturedTopics: [FeaturedTopic] = []
    ) {
        self.api = .shared
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
    func load() async {
        categoriesState = .loading
        expertsState = .loading
        featuredTopicsState = .loading
        do {
            let response = try await api.getClientHome(
                categorySlugs: selectedCategorySlugs.isEmpty ? nil : selectedCategorySlugs.sorted()
            )
            categories = response.data.trendingCategories.map(Self.mapCategory)
            experts = response.data.recommendedExperts.map(Self.mapExpert)
            featuredTopics = (response.data.featuredTopics ?? []).map(Self.mapFeaturedTopic)
            syncCategorySelection()
            categoriesState = .loaded
            expertsState = .loaded
            featuredTopicsState = .loaded
        } catch {
            let msg = Self.message(for: error)
            categoriesState = .failed(msg)
            expertsState = .failed(msg)
            featuredTopicsState = .failed(msg)
        }

        await loadTodaysSessions()
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
            status: status
        )
    }

    private static func isJoinable(_ status: BookingStatus) -> Bool {
        switch status {
        case .confirmed, .inProgress, .pendingReschedule:
            return true
        case .pendingApproval, .completed, .cancelled, .declined, .missed, .expired:
            return false
        }
    }

    private static func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    private static func timeRangeString(from start: Date, to end: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        return "\(f.string(from: start)) - \(f.string(from: end))"
    }

    /// After a fresh load remaps categories (wiping their `isSelected` flags),
    /// mirror the persistent `selectedCategorySlugs` set back onto each chip
    /// so the visual highlight survives across refreshes.
    private func syncCategorySelection() {
        for i in categories.indices {
            categories[i].isSelected = selectedCategorySlugs.contains(categories[i].slug)
        }
    }

    /// Pull-to-refresh handler.
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
        Task { await reload() }
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
            imageURL: re.profileImageUrl ?? ""
        )
    }

    /// Formats the server's minor-units rate into a display label like
    /// `"$120"` or `"Free"`. Falls back to `"—"` when both amount and
    /// currency are missing.
    private static func mapFeaturedTopic(_ t: ClientHomeData.FeaturedTopic) -> FeaturedTopic {
        FeaturedTopic(
            topicId: t.topicId,
            title: t.title,
            priceLabel: formatPrice(t.hourlyRate),
            expertId: t.expert.expertId,
            expertName: t.expert.fullName ?? "Expert",
            expertImageURL: t.expert.profileImageUrl ?? ""
        )
    }

    /// Renders the topic's per-session flat price (e.g. `"$50"`). The
    /// server ships this value under a `hourly_rate` key on
    /// `/client/home.featured_topics`, but the amount is what the client
    /// actually pays per booking — misleading key, per-session semantics.
    private static func formatPrice(_ rate: ClientHomeData.FeaturedTopic.HourlyRate?) -> String {
        guard let rate else { return "—" }
        let amountMajor = Double(rate.amount) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = rate.currency
        formatter.maximumFractionDigits = amountMajor.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: amountMajor))
            ?? "\(rate.currency) \(String(format: "%.0f", amountMajor))"
    }

    // MARK: - Error helpers

    private static func message(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
