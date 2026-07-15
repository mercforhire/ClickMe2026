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

    @StateObject private var viewModel: CategoriesModalViewModel
    @Environment(\.dismiss) private var dismiss
    var onSelectCategory: (Category) -> Void

    private let cols = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    init(
        viewModel: CategoriesModalViewModel = CategoriesModalViewModel(),
        onSelectCategory: @escaping (Category) -> Void
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
                    categories: viewModel.categories,
                    isSelected: { viewModel.isSelected($0) },
                    onToggle: { viewModel.toggle($0) }
                )
                .padding(.bottom, 20)
            }
            .background(AllCategoriesBrand.sheetBg)

            content
                .background(AllCategoriesBrand.bg)
        }
        .background(AllCategoriesBrand.bg)
        .task { await viewModel.load() }
    }

    // MARK: Content by load state

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingView
        case .loaded:
            grid
        case .failed(let message):
            errorView(message)
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AllCategoriesBrand.brandGreen))
                .scaleEffect(1.2)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(AllCategoriesBrand.onSurface.opacity(0.7))
            Text("Couldn't load categories")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(AllCategoriesBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(AllCategoriesBrand.onSurface.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task { await viewModel.retry() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AllCategoriesBrand.onPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(AllCategoriesBrand.brandGreen))
            }
            .padding(.top, 4)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var grid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: cols, spacing: 16) {
                ForEach(viewModel.filtered) { cat in
                    AllCategoriesGridCell(
                        category: cat,
                        isSelected: viewModel.isSelected(cat)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                            viewModel.toggle(cat)
                        }
                        onSelectCategory(cat)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Preview

#Preview("All Categories Sheet") {
    AllCategoriesView(
        viewModel: CategoriesModalViewModel(
            categories: [
                Category(id: "ai", name: "AI & Technology", iconName: "cpu", colorAccent: "#6366F1", description: nil),
                Category(id: "business", name: "Business", iconName: "briefcase", colorAccent: "#F59E0B", description: nil),
                Category(id: "design", name: "Design", iconName: "pencil-ruler", colorAccent: nil, description: nil),
                Category(id: "finance", name: "Finance", iconName: "chart-line", colorAccent: nil, description: nil),
                Category(id: "legal", name: "Legal", iconName: "scale", colorAccent: nil, description: nil),
                Category(id: "healthcare", name: "Healthcare", iconName: "stethoscope", colorAccent: nil, description: nil),
                Category(id: "marketing", name: "Marketing", iconName: "megaphone", colorAccent: nil, description: nil),
                Category(id: "real-estate", name: "Real Estate", iconName: "home", colorAccent: nil, description: nil)
            ],
            selectedIds: ["ai", "legal"],
            state: .loaded
        ),
        onSelectCategory: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("Loading") {
    AllCategoriesView(
        viewModel: CategoriesModalViewModel(state: .loading),
        onSelectCategory: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("Error") {
    AllCategoriesView(
        viewModel: CategoriesModalViewModel(
            state: .failed("The internet connection appears to be offline.")
        ),
        onSelectCategory: { _ in }
    )
    .preferredColorScheme(.dark)
}
