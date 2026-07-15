//
//  CategoriesModalViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class CategoriesModalViewModel: ObservableObject {

    // MARK: View state
    @Published var searchText: String
    @Published var allCategories: [AllCategoriesView.CategoryItem]

    init(
        searchText: String = "",
        allCategories: [AllCategoriesView.CategoryItem] = CategoriesModalViewModel.defaultCategories
    ) {
        self.searchText = searchText
        self.allCategories = allCategories
    }

    // MARK: Derived

    var filtered: [AllCategoriesView.CategoryItem] {
        guard !searchText.isEmpty else { return allCategories }
        return allCategories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: Actions

    func toggle(at index: Int) {
        allCategories[index].isSelected.toggle()
    }

    func toggle(id: UUID) {
        guard let idx = allCategories.firstIndex(where: { $0.id == id }) else { return }
        allCategories[idx].isSelected.toggle()
    }

    // MARK: Sample data

    static let defaultCategories: [AllCategoriesView.CategoryItem] = [
        .init(icon: "scalemass", name: "Legal", isSelected: true),
        .init(icon: "stethoscope", name: "Healthcare", isSelected: false),
        .init(icon: "chevron.left.forwardslash.chevron.right", name: "Tech", isSelected: true),
        .init(icon: "briefcase", name: "Finance", isSelected: false),
        .init(icon: "megaphone.fill", name: "Marketing", isSelected: false),
        .init(icon: "pencil.and.ruler", name: "Design", isSelected: false),
        .init(icon: "handshake", name: "Consulting", isSelected: false),
        .init(icon: "book", name: "Education", isSelected: false),
        .init(icon: "speedometer", name: "Productivity", isSelected: false),
        .init(icon: "gearshape", name: "Engineering", isSelected: false),
        .init(icon: "figure.walk", name: "Fitness", isSelected: false),
        .init(icon: "music.note", name: "Arts", isSelected: false),
    ]
}
