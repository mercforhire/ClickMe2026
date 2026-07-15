//
//  LanguageSelectionViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class LanguageSelectionViewModel: ObservableObject {


    // MARK: State
    @Published var searchText: String
    /// Selected language IDs (ISO 639-1 codes, e.g. `"en"`) — tracked as
    /// a Set so toggle is O(1) and we don't need to worry about duplicates.
    @Published var selected: Set<String>
    @Published var allLanguages: [LanguageItem] = []
    @Published var loadState: LoadState = .idle

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Init

    init(
        initialSelection: [LanguageItem] = [],
        searchText: String = "",
        api: ClickMeAPI = .shared
    ) {
        self.selected = Set(initialSelection.map(\.id))
        self.searchText = searchText
        self.api = api
    }

    /// Preview seam — installs canned languages as if `getLanguages` had
    /// succeeded.
    static func previewSeed(
        initialSelection: [LanguageItem] = [],
        all: [LanguageItem] = LanguageSelectionViewModel.previewLanguages
    ) -> LanguageSelectionViewModel {
        let vm = LanguageSelectionViewModel(initialSelection: initialSelection)
        vm.allLanguages = all
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
            let response = try await api.getLanguages()
            allLanguages = response.data.languages
                .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }
    }

    // MARK: Derived

    var filtered: [LanguageItem] {
        guard !searchText.isEmpty else { return allLanguages }
        return allLanguages.filter { $0.label.localizedCaseInsensitiveContains(searchText) }
    }

    /// Selected languages in the canonical order of `allLanguages`.
    var orderedSelection: [LanguageItem] {
        allLanguages.filter { selected.contains($0.id) }
    }

    // MARK: Mutations

    func toggle(_ language: LanguageItem) {
        if selected.contains(language.id) {
            selected.remove(language.id)
        } else {
            selected.insert(language.id)
        }
    }

    func clearSearch() {
        searchText = ""
    }

    // MARK: - Error mapping


    // MARK: - Preview data

    static let previewLanguages: [LanguageItem] = [
        LanguageItem(id: "ar", label: "Arabic"),
        LanguageItem(id: "en", label: "English"),
        LanguageItem(id: "fr", label: "French"),
        LanguageItem(id: "de", label: "German"),
        LanguageItem(id: "hi", label: "Hindi"),
        LanguageItem(id: "it", label: "Italian"),
        LanguageItem(id: "ja", label: "Japanese"),
        LanguageItem(id: "ko", label: "Korean"),
        LanguageItem(id: "zh", label: "Mandarin"),
        LanguageItem(id: "pt", label: "Portuguese"),
        LanguageItem(id: "ru", label: "Russian"),
        LanguageItem(id: "es", label: "Spanish"),
    ]
}
