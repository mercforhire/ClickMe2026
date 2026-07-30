//
//  SignupTagsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class SignupTagsViewModel: ObservableObject {


    // MARK: State
    @Published var searchText: String
    /// Server-provided tag catalog.
    @Published var allTags: [ExpertiseTagItem] = []
    /// Selection tracked by id — O(1) toggle, no duplicate risk.
    @Published var selectedIds: Set<UUID>
    @Published var loadState: LoadState = .idle

    // MARK: Save state
    @Published var isSaving: Bool = false
    @Published var saveError: String?

    // MARK: Dependencies

    private let accumulator: SignupAccumulator?
    private let api: ClickMeAPI

    // MARK: Init

    init(
        initialTags: [ExpertiseTagItem] = [],
        searchText: String = "",
        accumulator: SignupAccumulator? = nil,
        api: ClickMeAPI = .shared
    ) {
        self.accumulator = accumulator
        self.api = api
        self.searchText = searchText

        // Hydrate selection from accumulator if present; else use the
        // passed-in seed (preview path).
        let seed = accumulator?.expertiseTags ?? initialTags
        self.selectedIds = Set(seed.map(\.id))
        // Seed the visible catalog with the initial tags so previews
        // render something before load() runs.
        if accumulator == nil {
            self.allTags = initialTags
        }
    }

    /// Preview seam — installs canned tags as if `getExpertiseTags` had
    /// succeeded.
    static func previewSeed(
        selected: [ExpertiseTagItem] = [],
        all: [ExpertiseTagItem] = SignupTagsViewModel.previewTags
    ) -> SignupTagsViewModel {
        let vm = SignupTagsViewModel(initialTags: selected)
        vm.allTags = all
        vm.selectedIds = Set(selected.map(\.id))
        vm.loadState = .loaded
        return vm
    }

    // MARK: - Load

    /// Idempotent — skips when already loaded so preview seeds aren't
    /// clobbered.
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
            let response = try await api.getExpertiseTags()
            allTags = response.data.tags
                .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }
    }

    // MARK: Derived

    var filteredTags: [ExpertiseTagItem] {
        guard !searchText.isEmpty else { return allTags }
        return allTags.filter { $0.label.localizedCaseInsensitiveContains(searchText) }
    }

    /// Currently-picked tags in catalog order — used by the "Selected
    /// Tags" strip and the accumulator sync.
    var selectedTags: [ExpertiseTagItem] {
        allTags.filter { selectedIds.contains($0.id) }
    }

    // MARK: Mutations

    func toggleTag(_ tag: ExpertiseTagItem) {
        if selectedIds.contains(tag.id) {
            selectedIds.remove(tag.id)
        } else {
            selectedIds.insert(tag.id)
        }
        syncToAccumulator()
    }

    func removeTag(_ tag: ExpertiseTagItem) {
        selectedIds.remove(tag.id)
        syncToAccumulator()
    }

    func clearSearch() {
        searchText = ""
    }

    private func syncToAccumulator() {
        accumulator?.expertiseTags = selectedTags
    }

    // MARK: - Save

    /// Persists the current tag selection to `/expert/profile/setup` as
    /// a partial update. Sends bare UUID strings — first element is the
    /// primary tag. Guards against `[]` because the backend interprets an
    /// empty array as "clear all tags" (destructive) rather than "skip."
    @discardableResult
    func save() async -> Bool {
        syncToAccumulator()
        guard accumulator != nil else { return true }
        guard !selectedTags.isEmpty else {
            saveError = "Pick at least one tag before continuing."
            return false
        }

        saveError = nil
        isSaving = true
        defer { isSaving = false }

        let body = SetupExpertProfileRequest(
            expertiseTags: selectedTags.map { $0.id.uuidString }
        )
        do {
            _ = try await api.setupExpertProfile(body)
            return true
        } catch {
            saveError = error.userMessage
            return false
        }
    }

    // MARK: - Error mapping


    // MARK: - Preview data

    static let previewTags: [ExpertiseTagItem] = [
        ExpertiseTagItem(id: UUID(), label: "Brand Strategy",       categoryId: "business"),
        ExpertiseTagItem(id: UUID(), label: "Content Writing",      categoryId: "creative"),
        ExpertiseTagItem(id: UUID(), label: "Data Science",         categoryId: "technology"),
        ExpertiseTagItem(id: UUID(), label: "Digital Marketing",    categoryId: "business"),
        ExpertiseTagItem(id: UUID(), label: "Financial Planning",   categoryId: "business"),
        ExpertiseTagItem(id: UUID(), label: "Leadership Coaching",  categoryId: "business"),
        ExpertiseTagItem(id: UUID(), label: "Product Management",   categoryId: "business"),
        ExpertiseTagItem(id: UUID(), label: "Public Speaking",      categoryId: "business"),
        ExpertiseTagItem(id: UUID(), label: "Software Engineering", categoryId: "technology"),
        ExpertiseTagItem(id: UUID(), label: "UX Design",            categoryId: "creative"),
    ]
}
