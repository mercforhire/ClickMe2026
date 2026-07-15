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
    @Published var categoriesState: LoadState = .idle
    @Published var expertsState: LoadState = .idle

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
    init(previewCategories: [ExpertCategory], previewExperts: [Expert]) {
        self.api = .shared
        self.categories = previewCategories
        self.experts = previewExperts
        self.categoriesState = .loaded
        self.expertsState = .loaded
    }

    // MARK: - Load

    /// Fetches `/client/home` and populates both sections in one round trip.
    /// When `selectedCategorySlugs` is non-empty, forwards them as the
    /// `?category=` filter so the server narrows `recommended_experts`.
    func load() async {
        categoriesState = .loading
        expertsState = .loading
        do {
            let response = try await api.getClientHome(
                categorySlugs: selectedCategorySlugs.isEmpty ? nil : selectedCategorySlugs.sorted()
            )
            categories = response.data.trendingCategories.map(Self.mapCategory)
            experts = response.data.recommendedExperts.map(Self.mapExpert)
            syncCategorySelection()
            categoriesState = .loaded
            expertsState = .loaded
        } catch {
            let msg = Self.message(for: error)
            categoriesState = .failed(msg)
            expertsState = .failed(msg)
        }
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
