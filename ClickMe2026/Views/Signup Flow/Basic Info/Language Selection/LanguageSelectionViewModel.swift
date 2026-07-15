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

    @Published var searchText: String
    @Published var selected: Set<String>

    let allLanguages: [String]

    init(
        initialSelection: [String] = ["English"],
        searchText: String = "",
        allLanguages: [String] = LanguageSelectionViewModel.defaultLanguages
    ) {
        self.selected = Set(initialSelection)
        self.searchText = searchText
        self.allLanguages = allLanguages
    }

    // MARK: Derived

    var filtered: [String] {
        guard !searchText.isEmpty else { return allLanguages }
        return allLanguages.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    /// Selected languages in the canonical `allLanguages` order.
    var orderedSelection: [String] {
        allLanguages.filter { selected.contains($0) }
    }

    // MARK: Mutations

    func toggle(_ language: String) {
        if selected.contains(language) {
            selected.remove(language)
        } else {
            selected.insert(language)
        }
    }

    func clearSearch() {
        searchText = ""
    }

    // MARK: Defaults

    static let defaultLanguages: [String] = [
        "English",
        "Spanish",
        "French",
        "German",
        "Mandarin",
        "Arabic",
        "Portuguese",
        "Russian",
        "Japanese",
        "Korean",
        "Italian",
        "Dutch",
        "Hindi",
        "Turkish",
    ]
}
