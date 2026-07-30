//
//  ExpertiseEditorViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

/// Backs `ExpertiseEditorSheet`. Loads the full expertise-tag catalog
/// from `/meta/expertise-tags`, seeds selection from the currently-signed-in
/// expert's profile, and saves via `PATCH /expert/profile` on demand.
///
/// On successful save it also refreshes `UserManager.expertProfile` so
/// other screens reading `expertProfile.expertiseTags` see the new list
/// without waiting for their next cold load.
@MainActor
final class ExpertiseEditorViewModel: ObservableObject {

    // MARK: State
    @Published var searchText: String = ""
    @Published var allTags: [ExpertiseTagItem] = []
    /// Selection tracked by tag id — O(1) toggle, no dup risk.
    @Published var selectedIds: Set<UUID>
    @Published var loadState: LoadState = .idle

    /// The tag id that was `is_primary=true` when the sheet opened.
    /// Preserved across edits so the primary sticks unless the user
    /// deselects it, in which case the first remaining tag becomes
    /// primary. Nil when the expert had no tags at open time.
    private var primaryId: UUID?

    // MARK: Save state
    @Published var isSaving: Bool = false
    @Published var saveError: String?
    @Published var didSave: Bool = false

    // MARK: Dependencies
    private let api: ClickMeAPI
    private let userManager: UserManager

    // MARK: Init

    /// Runtime init — hydrates selection from `UserManager.expertProfile`
    /// (already refreshed at splash / login). Fetches the catalog on
    /// `load()`.
    init(
        api: ClickMeAPI = .shared,
        userManager: UserManager = .shared
    ) {
        self.api = api
        self.userManager = userManager
        let currentEntries = userManager.expertProfile?.expertiseTags ?? []
        self.selectedIds = Set(currentEntries.map(\.id))
        self.primaryId = currentEntries.first(where: { $0.isPrimary })?.id
    }

    /// Preview seam — installs a canned catalog + selection as if the
    /// fetch had already succeeded.
    static func previewSeed(
        selected: [ExpertiseTagItem] = [],
        all: [ExpertiseTagItem] = ExpertiseEditorViewModel.previewTags
    ) -> ExpertiseEditorViewModel {
        let vm = ExpertiseEditorViewModel()
        vm.allTags = all
        vm.selectedIds = Set(selected.map(\.id))
        vm.primaryId = selected.first?.id
        vm.loadState = .loaded
        return vm
    }

    // MARK: - Load

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

    // MARK: - Derived

    /// Catalog filtered by the search string.
    var filteredTags: [ExpertiseTagItem] {
        guard !searchText.isEmpty else { return allTags }
        return allTags.filter { $0.label.localizedCaseInsensitiveContains(searchText) }
    }

    /// Currently-picked tags in catalog order. The primary is surfaced
    /// first so callers rendering a chip strip can highlight it.
    var selectedTags: [ExpertiseTagItem] {
        let inCatalog = allTags.filter { selectedIds.contains($0.id) }
        guard let primaryId, let primaryIdx = inCatalog.firstIndex(where: { $0.id == primaryId }) else {
            return inCatalog
        }
        var ordered = inCatalog
        let primary = ordered.remove(at: primaryIdx)
        ordered.insert(primary, at: 0)
        return ordered
    }

    // MARK: - Mutations

    func toggleTag(_ tag: ExpertiseTagItem) {
        if selectedIds.contains(tag.id) {
            selectedIds.remove(tag.id)
            // If the user deselected the primary, promote the first
            // remaining selection so the server request always includes
            // a primary (server default assumes first entry).
            if primaryId == tag.id {
                primaryId = selectedIds.first
            }
        } else {
            selectedIds.insert(tag.id)
            // First-ever selection auto-becomes primary.
            if primaryId == nil { primaryId = tag.id }
        }
        didSave = false
    }

    func removeTag(_ tag: ExpertiseTagItem) {
        selectedIds.remove(tag.id)
        if primaryId == tag.id {
            primaryId = selectedIds.first
        }
        didSave = false
    }

    func clearSearch() { searchText = "" }

    // MARK: - Save

    /// Persists the current selection via `PATCH /expert/profile`. On
    /// success refreshes `UserManager.expertProfile` so any observer of
    /// that snapshot (settings screen, public profile) sees the new
    /// tags without waiting for its own reload.
    @discardableResult
    func save() async -> Bool {
        guard !isSaving else { return false }
        guard !selectedTags.isEmpty else {
            saveError = "Pick at least one expertise tag before saving."
            return false
        }

        saveError = nil
        isSaving = true
        defer { isSaving = false }

        let ordered = selectedTags
        let effectivePrimary = primaryId ?? ordered.first?.id
        // Lowercase the UUID — Swift's `.uuidString` returns uppercase but
        // the backend looks tags up case-sensitively and rejects
        // uppercase strings with a validation error.
        let tags = ordered.map { tag in
            UpdateExpertProfileRequest.ExpertiseTag(
                tagId: tag.id.uuidString.lowercased(),
                isPrimary: tag.id == effectivePrimary
            )
        }

        let body = UpdateExpertProfileRequest(
            personalInfo: nil,
            professionalDetails: nil,
            locationDetails: nil,
            languages: nil,
            expertiseTags: tags
        )
        do {
            _ = try await api.updateExpertProfile(body)
            try? await userManager.refreshExpertProfile()
            withAnimation(.easeOut(duration: 0.2)) { didSave = true }
            return true
        } catch {
            saveError = error.userMessage
            return false
        }
    }

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
