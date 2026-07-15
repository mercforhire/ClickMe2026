//
//  CategoriesModalView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - All Categories Modal View

struct AllCategoriesView: View {

    struct CategoryItem: Identifiable {
        let id = UUID()
        let icon: String // SF Symbol name
        let name: String
        var isSelected: Bool = false
    }

    @StateObject private var viewModel: CategoriesModalViewModel
    @Environment(\.dismiss) private var dismiss
    var onSelectCategory: (String) -> Void

    private let cols = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    init(
        viewModel: CategoriesModalViewModel = CategoriesModalViewModel(),
        onSelectCategory: @escaping (String) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSelectCategory = onSelectCategory
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                AllCategoriesHeader(onClose: { dismiss() })

                AllCategoriesSearchBar(text: $viewModel.searchText)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                AllCategoriesQuickChips(
                    categories: viewModel.allCategories,
                    onToggle: { viewModel.toggle(at: $0) }
                )
                .padding(.bottom, 20)
            }
            .background(AllCategoriesBrand.sheetBg)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: cols, spacing: 16) {
                    ForEach(viewModel.filtered) { cat in
                        AllCategoriesGridCell(category: cat) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                                viewModel.toggle(id: cat.id)
                            }
                            onSelectCategory(cat.name)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(AllCategoriesBrand.bg)
        }
        .background(AllCategoriesBrand.bg)
    }
}

// MARK: - Preview

#Preview("All Categories Sheet") {
    AllCategoriesView(onSelectCategory: { _ in })
        .preferredColorScheme(.dark)
}
