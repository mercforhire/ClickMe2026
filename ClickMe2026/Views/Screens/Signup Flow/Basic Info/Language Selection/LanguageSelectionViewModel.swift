//
//  LanguageSelectionViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-23.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class LanguageSelectionViewModel: ObservableObject {


    // MARK: State
    @Published var searchText: String
    /// Selected language IDs (ISO 639-1 codes, e.g. `"en"`) — tracked as
    /// a Set so membership is O(1) and we don't need to worry about
    /// duplicates. Order lives in `selectionOrder`; mutate both together.
    @Published private(set) var selected: Set<String>
    /// Selected language IDs in the order the user picked them.
    @Published private(set) var selectionOrder: [String]
    @Published var allLanguages: [LanguageItem] = []
    @Published var loadState: LoadState = .idle

    // MARK: Dependencies

    private let api: ClickMeAPI
    /// Languages the selection started with, so a pre-selected language
    /// still shows before the catalog has loaded (or when it omits it).
    private let seedLanguagesById: [String: LanguageItem]

    // MARK: Init

    init(
        initialSelection: [LanguageItem] = [],
        searchText: String = "",
        api: ClickMeAPI = .shared
    ) {
        var seen = Set<String>()
        self.selected = Set(initialSelection.map(\.id))
        self.selectionOrder = initialSelection.map(\.id).filter { seen.insert($0).inserted }
        self.seedLanguagesById = Dictionary(
            initialSelection.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
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

    /// Selected languages in the order the user picked them. A language
    /// missing from the catalog falls back to the one the selection was
    /// seeded with.
    var orderedSelection: [LanguageItem] {
        let catalog = Dictionary(allLanguages.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return selectionOrder.compactMap { catalog[$0] ?? seedLanguagesById[$0] }
    }

    // MARK: Mutations

    func toggle(_ language: LanguageItem) {
        if selected.contains(language.id) {
            selected.remove(language.id)
            selectionOrder.removeAll { $0 == language.id }
        } else {
            selected.insert(language.id)
            selectionOrder.append(language.id)
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
