//
//  SignupTagsView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-14.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Expertise Tags Screen

struct SignupTagsView: View {

    @StateObject private var viewModel: SignupTagsViewModel

    // UI-only state
    @State private var contentOpacity: Double = 0

    /// Returns the picked tags (server ids + labels) in catalog order.
    var onDone: ([ExpertiseTagItem]) -> Void

    // MARK: Init

    init(
        viewModel: SignupTagsViewModel = SignupTagsViewModel(),
        onDone: @escaping ([ExpertiseTagItem]) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onDone = onDone
    }

    /// Runtime init bound directly to the shared `SignupAccumulator`.
    init(
        accumulator: SignupAccumulator,
        onDone: @escaping ([ExpertiseTagItem]) -> Void = { _ in }
    ) {
        self.init(
            viewModel: SignupTagsViewModel(accumulator: accumulator),
            onDone: onDone
        )
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [TagsBrand.bgTop, TagsBrand.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Fade the foreground only — background stays opaque so the
            // push transition doesn't briefly reveal white.
            Group {
                content

                if case .loaded = viewModel.loadState {
                    TagsDoneButton(isLoading: viewModel.isSaving) {
                        Task {
                            if await viewModel.save() {
                                onDone(viewModel.selectedTags)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
            .opacity(contentOpacity)
        }
        .task { await viewModel.load() }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { contentOpacity = 1 }
        }
        .navigationTitle("Expertise Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TagsBrand.bgTop, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert(
            "Couldn't save",
            isPresented: Binding(
                get: { viewModel.saveError != nil },
                set: { if !$0 { viewModel.saveError = nil } }
            ),
            presenting: viewModel.saveError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Content router

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            loadingContent
        case .failed(let message):
            errorContent(message: message)
        case .loaded:
            loadedContent
        }
    }

    private var loadedContent: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    TagsSearchBar(
                        text: $viewModel.searchText,
                        onClear: { viewModel.clearSearch() }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                    if !viewModel.selectedTags.isEmpty {
                        sectionLabel("Selected Tags")
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)

                        selectedTagsRow
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                    }

                    sectionLabel("Suggested Tags")
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)

                    tagList
                        .padding(.bottom, 32)
                }
            }
            .padding(.bottom, 120) // space for pinned button
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(.white)
            Text("Loading tags…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 26, weight: .light))
                .foregroundColor(.white.opacity(0.6))
            Text("Couldn't load tags")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Brand.primary))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Inline helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(Color.white.opacity(0.40))
    }

    private var selectedTagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.selectedTags, id: \.id) { tag in
                    SelectedTagChip(tag: tag.label) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.removeTag(tag)
                        }
                    }
                }
            }
            .padding(.horizontal, 1) // avoid clipping shadow
        }
    }

    private var tagList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.filteredTags, id: \.id) { tag in
                TagRow(
                    tag: tag.label,
                    isSelected: viewModel.selectedIds.contains(tag.id)
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.toggleTag(tag)
                    }
                }
                if tag.id != viewModel.filteredTags.last?.id {
                    Divider()
                        .background(TagsBrand.rowDivider)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
private func tagsPreview<Content: View>(@ViewBuilder _ content: @escaping () -> Content) -> some View {
    PreviewNavHarness(parentText: "Complete your profile", navTitle: "Profile setup", rowTitle: "Add expertise") {
        content()
    }
    .preferredColorScheme(.dark)
}
#endif

#Preview("Default — 2 selected") {
    tagsPreview {
        SignupTagsView(viewModel: .previewSeed(selected: Array(SignupTagsViewModel.previewTags.prefix(2))))
    }
}

#Preview("Empty — no selection") {
    tagsPreview {
        SignupTagsView(viewModel: .previewSeed(selected: []))
    }
}

#Preview("Many selected") {
    tagsPreview {
        SignupTagsView(viewModel: .previewSeed(selected: Array(SignupTagsViewModel.previewTags.prefix(4))))
    }
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return tagsPreview { SignupTagsView() }
}
