//
//  SearchExpertView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct ExpertSearchResult: Identifiable, Hashable {
    let id = UUID()
    /// Server-issued expert UUID. Nil for preview/loading placeholders.
    let expertId: UUID?
    let name: String
    let title: String
    let bio: String
    let rating: Double
    let imageURL: String
    let tags: [String]
}

// MARK: - Expert Search View

struct SearchExpertView: View {

    @StateObject private var viewModel: SearchExpertViewModel
    /// Push path is provided by the enclosing `HomeClientView` via
    /// `@Environment(\.homeNavigationPath)`. When rendered outside the
    /// shell (previews, tests) the fallback `_localPath` provides a
    /// self-contained NavigationStack so the screen still works.
    @Environment(\.homeNavigationPath) private var navPath
    @State private var _localPath: [ExpertSearchResult] = []

    // MARK: Init

    init(viewModel: SearchExpertViewModel = SearchExpertViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    /// Convenience init for callers that just want to seed the experts list
    /// (used by previews to bypass the network).
    init(experts: [ExpertSearchResult]) {
        self.init(viewModel: SearchExpertViewModel(previewExperts: experts))
    }

    // MARK: Body

    var body: some View {
        Group {
            if navPath != nil {
                contentWithDestinations
            } else {
                NavigationStack(path: $_localPath) {
                    contentWithDestinations
                }
            }
        }
    }

    private var contentWithDestinations: some View {
        content
            .navigationDestination(for: ExpertSearchResult.self) { result in
                ExpertProfileView(expert: PublicExpertProfile(from: result))
            }
    }

    private func push(_ expert: ExpertSearchResult) {
        if let navPath {
            navPath.push(expert)
        } else {
            _localPath.append(expert)
        }
    }

    private var content: some View {
        ZStack {
            SearchExpertBrand.bg.ignoresSafeArea()
            GreenGlowBlobLayer().ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 20)

                VStack(spacing: 14) {
                    SearchExpertSearchBar(text: $viewModel.searchText)
                        .padding(.horizontal, 20)

                    SearchExpertCategoryChips(
                        categories: viewModel.categories,
                        selectedCategorySlug: $viewModel.selectedCategorySlug
                    )

                    SearchExpertSortRow(
                        sortOption: viewModel.sortOption,
                        onTap: { viewModel.showSortPicker = true }
                    )
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 8)

                resultsContent
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .confirmationDialog("Sort by", isPresented: $viewModel.showSortPicker, titleVisibility: .visible) {
            ForEach(viewModel.sortOptions, id: \.self) { opt in
                Button(opt) { viewModel.sortOption = opt }
            }
        }
        .onAppear { viewModel.glowPulse = true }
    }

    // MARK: Results content by load state

    @ViewBuilder
    private var resultsContent: some View {
        ScrollView(showsIndicators: false) {
            switch viewModel.state {
            case .idle, .loading:
                loadingList
            case .loaded:
                if viewModel.experts.isEmpty {
                    emptyResultsView
                } else {
                    resultsList
                }
            case .failed(let message):
                errorList(message: message)
            }
        }
        .refreshable { await viewModel.reload() }
    }

    /// Inline "no results" view rendered inside the results area so the
    /// search bar and category chips stay visible for the user to refine the
    /// query. No action buttons — this is a status message, not a dead end.
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            SearchExpertGlowingIllustration(glowPulse: viewModel.glowPulse)

            VStack(spacing: 8) {
                Text("No Experts Found")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(SearchExpertBrand.onSurface)

                Text("Try adjusting your search or picking a different category.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(SearchExpertBrand.onSurfaceVar)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
        .padding(.bottom, 40)
    }

    private var loadingList: some View {
        VStack(spacing: 12) {
            ForEach(0 ..< 3, id: \.self) { _ in
                SearchExpertCard(
                    expert: ExpertSearchResult(
                        expertId: nil,
                        name: "\u{2003}\u{2003}\u{2003}\u{2003}",
                        title: "\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}",
                        bio: "\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}",
                        rating: 5.0,
                        imageURL: "",
                        tags: ["\u{2003}\u{2003}", "\u{2003}\u{2003}"]
                    ),
                    action: {}
                )
                .redacted(reason: .placeholder)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    private var resultsList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.experts) { expert in
                SearchExpertCard(
                    expert: expert,
                    action: { push(expert) }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    private func errorList(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(SearchExpertBrand.onSurfaceVar)
            Text("Couldn't load results")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(SearchExpertBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(SearchExpertBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(SearchExpertBrand.onPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(SearchExpertBrand.brandGreen))
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - ExpertSearchResult → PublicExpertProfile mapping

private extension PublicExpertProfile {
    init(from result: ExpertSearchResult) {
        // Seed only what the search card knows; `loadProfileDetails()` on
        // view-appear fills in bio (if empty), stats, and topics from the
        // server.
        self.init(
            expertId: result.expertId,
            name: result.name,
            title: result.title,
            rating: result.rating,
            reviewCount: 0,
            yearsExp: "",
            bookings: "",
            isOnline: true,
            bio: result.bio,
            expertiseTags: result.tags.map { PublicExpertTag(label: $0, isHighlighted: false) },
            topics: [],
            reviews: [],
            imageURL: result.imageURL
        )
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

/// Hits `/experts/search` on appear (empty `q` → default result set) and
/// re-runs the query on every text change (300 ms debounce) or sort change.
/// Bearer token comes from the gitignored `PreviewSecrets.swift`.
#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
    return SearchExpertView()
        .preferredColorScheme(.dark)
}
