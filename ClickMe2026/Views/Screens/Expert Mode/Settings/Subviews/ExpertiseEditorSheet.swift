//
//  ExpertiseEditorSheet.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Modal expertise editor. Presented from `ExpertProfileSettingsView` so
/// the expert can pick from the full server catalog. Reuses the signup
/// flow's `TagRow` / `TagsSearchBar` / `SelectedTagChip` components so
/// look-and-feel stays consistent with the initial-setup experience.
///
/// Save fires `PATCH /expert/profile` and calls `onSaved` with the new
/// selection so the parent settings screen can update its inline chip
/// strip without re-fetching.
struct ExpertiseEditorSheet: View {

    @StateObject private var viewModel: ExpertiseEditorViewModel
    @Environment(\.dismiss) private var dismiss

    var onSaved: ([ExpertiseTagItem]) -> Void

    // MARK: Init

    init(
        viewModel: ExpertiseEditorViewModel = ExpertiseEditorViewModel(),
        onSaved: @escaping ([ExpertiseTagItem]) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSaved = onSaved
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [TagsBrand.bgTop, TagsBrand.bgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                content
            }
            .navigationTitle("Edit Expertise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TagsBrand.bgTop, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            if await viewModel.save() {
                                onSaved(viewModel.selectedTags)
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView().tint(TagsBrand.green)
                        } else {
                            Text("Save")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(TagsBrand.green)
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .task { await viewModel.load() }
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
        .presentationBackground(TagsBrand.bgTop)
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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                TagsSearchBar(
                    text: $viewModel.searchText,
                    onClear: { viewModel.clearSearch() }
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 22)

                if !viewModel.selectedTags.isEmpty {
                    sectionLabel("Your Tags")
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    selectedTagsRow
                        .padding(.horizontal, 20)
                        .padding(.bottom, 22)
                }

                sectionLabel("All Expertise")
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)

                tagList
                    .padding(.bottom, 40)
            }
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

    // MARK: - Inline helpers

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
            .padding(.horizontal, 1)
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

#Preview("Editor — 2 selected") {
    ExpertiseEditorSheet(
        viewModel: .previewSeed(
            selected: Array(ExpertiseEditorViewModel.previewTags.prefix(2))
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("Editor — empty") {
    ExpertiseEditorSheet(viewModel: .previewSeed(selected: []))
        .preferredColorScheme(.dark)
}
