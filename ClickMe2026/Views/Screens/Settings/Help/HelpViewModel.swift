//
//  HelpViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-29.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class HelpViewModel: ObservableObject {


    // MARK: Data
    @Published var categories: [FaqCategory]
    @Published var loadState: LoadState

    // MARK: Expansion state (all-collapsed by default)
    @Published var expandedCategories: Set<UUID>

    // MARK: Dependencies

    private let api: ClickMeAPI

    /// Runtime init — categories are fetched via `GET /help/faqs` on
    /// `load()`. The expansion set starts empty so every category card
    /// renders collapsed until the user taps it.
    init(api: ClickMeAPI = .shared) {
        self.categories = []
        self.loadState = .idle
        self.expandedCategories = []
        self.api = api
    }

    /// Preview seam — installs canned categories as if the fetch had
    /// already succeeded. Use `expanded:` to preview the expanded state.
    static func previewSeed(
        categories: [FaqCategory] = HelpViewModel.sampleCategories,
        expanded: Set<UUID> = []
    ) -> HelpViewModel {
        let vm = HelpViewModel()
        vm.categories = categories
        vm.expandedCategories = expanded
        vm.loadState = .loaded
        return vm
    }

    // MARK: - Load

    /// Fetches `GET /help/faqs` and sorts categories by `displayOrder` so
    /// the render matches the server's intended ordering. Idempotent —
    /// skips when already loaded so preview seeds aren't clobbered.
    func load() async {
        if case .loaded = loadState { return }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        loadState = .loading
        do {
            let response = try await api.getFAQs()
            // Drop categories that have no featured articles — the server's
            // `/help/faqs` payload only surfaces featured articles, so an
            // empty `featuredArticles` array would render an expandable
            // card with nothing inside. Hide them until either the
            // category gets featured content or backend exposes a
            // per-category articles endpoint.
            categories = response.data.categories
                .filter { !$0.featuredArticles.isEmpty }
                .sorted { $0.displayOrder < $1.displayOrder }
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }
    }

    // MARK: - Expansion

    func isExpanded(_ category: FaqCategory) -> Bool {
        expandedCategories.contains(category.id)
    }

    func toggle(_ category: FaqCategory) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedCategories.contains(category.id) {
                expandedCategories.remove(category.id)
            } else {
                expandedCategories.insert(category.id)
            }
        }
    }

    // MARK: - Error mapping


    // MARK: Sample data

    /// Shape-faithful sample for `#Preview`. Real content comes from
    /// `GET /help/faqs` at runtime.
    static let sampleCategories: [FaqCategory] = [
        FaqCategory(
            id: UUID(),
            title: "Booking",
            iconUrl: nil,
            displayOrder: 1,
            featuredArticles: [
                FaqArticlePreview(
                    id: UUID(),
                    categoryId: UUID(),
                    question: "How do I schedule a session?",
                    snippet: "Navigate to the Categories tab, select your preferred service, and choose an available time slot.",
                    viewCount: 128
                ),
                FaqArticlePreview(
                    id: UUID(),
                    categoryId: UUID(),
                    question: "Can I change my booking time?",
                    snippet: "Yes, you can reschedule bookings up to 24 hours before the start time.",
                    viewCount: 91
                ),
            ]
        ),
        FaqCategory(
            id: UUID(),
            title: "Payments",
            iconUrl: nil,
            displayOrder: 2,
            featuredArticles: [
                FaqArticlePreview(
                    id: UUID(),
                    categoryId: UUID(),
                    question: "What payment methods are supported?",
                    snippet: "We currently support all major credit and debit cards through our secure Stripe integration.",
                    viewCount: 64
                ),
            ]
        ),
    ]
}
