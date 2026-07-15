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

    // MARK: Form state
    @Published var searchText: String
    @Published var selectedTags: [String]
    @Published var customTagText: String

    // MARK: Data
    let suggestedTags: [String]

    init(
        initialTags: [String] = ["UX Design", "Digital Marketing"],
        searchText: String = "",
        customTagText: String = "",
        suggestedTags: [String] = SignupTagsViewModel.defaultSuggestedTags
    ) {
        self.selectedTags = initialTags
        self.searchText = searchText
        self.customTagText = customTagText
        self.suggestedTags = suggestedTags
    }

    // MARK: Derived

    var filteredTags: [String] {
        let all = suggestedTags + selectedTags.filter { !suggestedTags.contains($0) }
        let deduped = Array(Set(all)).sorted()
        guard !searchText.isEmpty else { return deduped }
        return deduped.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: Mutations

    func toggleTag(_ tag: String) {
        if let index = selectedTags.firstIndex(of: tag) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }

    func removeTag(_ tag: String) {
        selectedTags.removeAll { $0 == tag }
    }

    func addCustomTag() {
        let trimmed = customTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !selectedTags.contains(trimmed) else { return }
        selectedTags.append(trimmed)
        customTagText = ""
    }

    func clearSearch() {
        searchText = ""
    }

    // MARK: Defaults

    static let defaultSuggestedTags: [String] = [
        "UX Design",
        "Digital Marketing",
        "Financial Planning",
        "Product Management",
        "Software Engineering",
        "Data Science",
        "Brand Strategy",
        "Content Writing",
        "Public Speaking",
        "Leadership Coaching",
    ]
}
