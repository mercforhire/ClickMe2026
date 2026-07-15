//
//  ExploreClientView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct ExpertCategory: Identifiable {
    let id = UUID()
    let icon: String
    let name: String
    var isSelected: Bool = false
}

struct Expert: Identifiable {
    let id = UUID()
    let name: String
    let title: String
    let tags: [String]
    let rate: Int
    let rating: Double
    let imageName: String // use asset name; falls back to placeholder
}

// MARK: - Explore View

struct ExploreClientView: View {

    @StateObject private var viewModel: ExploreClientViewModel

    init(viewModel: ExploreClientViewModel = ExploreClientViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            ExploreBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ExploreHeroHeader()
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 20)

                    ExploreSearchBar(text: $viewModel.searchText)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    ExploreCategoriesSection(
                        categories: viewModel.categories,
                        onSelect: { viewModel.selectCategory(at: $0) },
                        onViewAll: { viewModel.showAllCategories = true }
                    )
                    .padding(.bottom, 32)

                    ExploreExpertsSection(experts: viewModel.experts)
                        .padding(.bottom, 32)
                }
            }
        }
        .sheet(isPresented: $viewModel.showAllCategories) {
            AllCategoriesView { selectedCategory in
                viewModel.selectCategory(named: selectedCategory)
            }
            .presentationDragIndicator(.hidden)
        }
    }
}

// MARK: - Preview

#Preview {
    ExploreClientView()
        .preferredColorScheme(.dark)
}
