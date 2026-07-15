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

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

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
    func load() async {
        categoriesState = .loading
        expertsState = .loading
        do {
            let response = try await api.getClientHome()
            categories = response.data.trendingCategories.map(Self.mapCategory)
            experts = response.data.recommendedExperts.map(Self.mapExpert)
            categoriesState = .loaded
            expertsState = .loaded
        } catch {
            let msg = Self.message(for: error)
            categoriesState = .failed(msg)
            expertsState = .failed(msg)
        }
    }

    /// Pull-to-refresh handler.
    func reload() async {
        await load()
    }

    // MARK: - Category selection

    /// Single-select highlight only on the trending-categories row — no
    /// network side-effect. The persistent multi-select filter is owned by
    /// `selectedCategorySlugs` and driven by the categories modal.
    func selectCategory(at index: Int) {
        for i in categories.indices {
            categories[i].isSelected = (i == index)
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
            icon: CategoryIconMap.sfSymbol(forSlug: tc.id),
            name: tc.name ?? "Category",
            isSelected: false
        )
    }

    private static func mapExpert(_ re: ClientHomeData.RecommendedExpert) -> Expert {
        Expert(
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
