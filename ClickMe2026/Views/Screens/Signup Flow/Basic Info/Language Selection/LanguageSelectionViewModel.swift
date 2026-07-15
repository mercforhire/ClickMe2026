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

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: State
    @Published var searchText: String
    /// Selected language IDs — tracked as a Set so toggle is O(1) and
    /// we don't need to worry about duplicates.
    @Published var selected: Set<UUID>
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
            loadState = .failed(Self.errorMessage(for: error))
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

    private static func errorMessage(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    // MARK: - Preview data

    static let previewLanguages: [LanguageItem] = [
        LanguageItem(id: UUID(), label: "Arabic"),
        LanguageItem(id: UUID(), label: "English"),
        LanguageItem(id: UUID(), label: "French"),
        LanguageItem(id: UUID(), label: "German"),
        LanguageItem(id: UUID(), label: "Hindi"),
        LanguageItem(id: UUID(), label: "Italian"),
        LanguageItem(id: UUID(), label: "Japanese"),
        LanguageItem(id: UUID(), label: "Korean"),
        LanguageItem(id: UUID(), label: "Mandarin"),
        LanguageItem(id: UUID(), label: "Portuguese"),
        LanguageItem(id: UUID(), label: "Russian"),
        LanguageItem(id: UUID(), label: "Spanish"),
    ]
}
