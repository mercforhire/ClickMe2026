//
//  SearchExpertView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct ExpertSearchResult: Identifiable {
    let id = UUID()
    let name: String
    let title: String
    let bio: String
    let rating: Double
    let imageURL: String
}

// MARK: - Expert Search View

struct SearchExpertView: View {

    @StateObject private var viewModel: SearchExpertViewModel
    var onSelectExpert: (ExpertSearchResult) -> Void
    var onBrowseAll: () -> Void

    // MARK: Init

    init(
        viewModel: SearchExpertViewModel = SearchExpertViewModel(),
        onSelectExpert: @escaping (ExpertSearchResult) -> Void = { _ in },
        onBrowseAll: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSelectExpert = onSelectExpert
        self.onBrowseAll = onBrowseAll
    }

    /// Convenience init for callers that just want to seed the experts list.
    init(
        experts: [ExpertSearchResult],
        onSelectExpert: @escaping (ExpertSearchResult) -> Void = { _ in },
        onBrowseAll: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: SearchExpertViewModel(allExperts: experts),
            onSelectExpert: onSelectExpert,
            onBrowseAll: onBrowseAll
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            SearchExpertBrand.bg.ignoresSafeArea()
            SearchExpertBlobLayer().ignoresSafeArea()

            VStack(spacing: 0) {
                SearchExpertWordmark()
                    .padding(.top, 52)
                    .padding(.bottom, 16)

                if viewModel.showEmpty {
                    SearchExpertEmptyState(
                        glowPulse: viewModel.glowPulse,
                        onBrowseAll: onBrowseAll
                    )
                } else {
                    VStack(spacing: 14) {
                        SearchExpertSearchBar(text: $viewModel.searchText)
                            .padding(.horizontal, 20)

                        SearchExpertCategoryChips(
                            categories: viewModel.categories,
                            selectedCategory: $viewModel.selectedCategory
                        )

                        SearchExpertSortRow(
                            sortOption: viewModel.sortOption,
                            onTap: { viewModel.showSortPicker = true }
                        )
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 8)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(viewModel.filteredExperts) { expert in
                                SearchExpertCard(
                                    expert: expert,
                                    action: { onSelectExpert(expert) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.showEmpty)
        }
        .confirmationDialog("Sort by", isPresented: $viewModel.showSortPicker, titleVisibility: .visible) {
            ForEach(viewModel.sortOptions, id: \.self) { opt in
                Button(opt) { viewModel.sortOption = opt }
            }
        }
        .onAppear { viewModel.glowPulse = true }
    }
}

// MARK: - Previews

#Preview("Search Results") {
    SearchExpertView()
        .preferredColorScheme(.dark)
}

#Preview("Empty State") {
    SearchExpertView(experts: [])
        .preferredColorScheme(.dark)
}
