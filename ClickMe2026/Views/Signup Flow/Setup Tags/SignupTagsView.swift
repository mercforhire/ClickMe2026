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
    @Environment(\.dismiss) private var dismiss

    var onDone: ([String]) -> Void

    // MARK: Init

    init(
        viewModel: SignupTagsViewModel = SignupTagsViewModel(),
        onDone: @escaping ([String]) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onDone = onDone
    }

    /// Convenience: build the VM directly from an initial tag list.
    init(
        initialTags: [String],
        onDone: @escaping ([String]) -> Void = { _ in }
    ) {
        self.init(
            viewModel: SignupTagsViewModel(initialTags: initialTags),
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

            VStack(spacing: 0) {
                TagsNavBar(onBack: { dismiss() })
                    .padding(.top, 8)

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

                        CustomTagSection(
                            text: $viewModel.customTagText,
                            onAdd: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.addCustomTag()
                                }
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 120) // space for pinned button
            }

            TagsDoneButton(action: { onDone(viewModel.selectedTags) })
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
        }
        .opacity(contentOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { contentOpacity = 1 }
        }
        .navigationBarHidden(true)
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
                ForEach(viewModel.selectedTags, id: \.self) { tag in
                    SelectedTagChip(tag: tag) {
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
            ForEach(viewModel.filteredTags, id: \.self) { tag in
                TagRow(
                    tag: tag,
                    isSelected: viewModel.selectedTags.contains(tag)
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.toggleTag(tag)
                    }
                }
                if tag != viewModel.filteredTags.last {
                    Divider()
                        .background(TagsBrand.rowDivider)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Default — 2 selected") {
    SignupTagsView()
        .preferredColorScheme(.dark)
}

#Preview("Empty — no selection") {
    SignupTagsView(initialTags: [])
        .preferredColorScheme(.dark)
}

#Preview("Many selected") {
    SignupTagsView(
        initialTags: ["UX Design", "Digital Marketing", "Financial Planning", "Product Management"]
    )
    .preferredColorScheme(.dark)
}
