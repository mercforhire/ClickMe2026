//
//  LanguageSelectionView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Language Selection Sheet

struct LanguageSelectionView: View {

    @StateObject private var viewModel: LanguageSelectionViewModel

    @Environment(\.dismiss) private var dismiss

    /// Returns the picked language items in the order they appear in the
    /// server's canonical list.
    var onDone: ([LanguageItem]) -> Void
    var onCancel: () -> Void

    // MARK: Design tokens

    private let bg          = Color(red: 0.075, green: 0.075, blue: 0.075)
    private let fieldBg     = Color(red: 0.118, green: 0.118, blue: 0.118)
    private let fieldBorder = Color(red: 0.200, green: 0.200, blue: 0.200)
    private let brandGreen  = Color(red: 0.267, green: 0.965, blue: 0.592)
    private let onSurface   = Color(red: 0.95, green: 0.95, blue: 0.95)
    private let onSurfaceVar = Color(red: 0.55, green: 0.58, blue: 0.55)
    private let onPrimary   = Color.black
    private let rowDivider  = Color.white.opacity(0.06)

    // MARK: Init

    init(
        viewModel: LanguageSelectionViewModel = LanguageSelectionViewModel(),
        onDone: @escaping ([LanguageItem]) -> Void = { _ in },
        onCancel: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onDone = onDone
        self.onCancel = onCancel
    }

    /// Convenience: build the VM from a pre-selected list of language items.
    init(
        initialSelection: [LanguageItem],
        onDone: @escaping ([LanguageItem]) -> Void = { _ in },
        onCancel: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: LanguageSelectionViewModel(initialSelection: initialSelection),
            onDone: onDone,
            onCancel: onCancel
        )
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            dragIndicator
                .padding(.top, 10)
                .padding(.bottom, 14)

            Text("Select Spoken Languages")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(onSurface)
                .padding(.bottom, 16)

            searchBar
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            content

            bottomActions
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
        }
        .background(bg.ignoresSafeArea())
        .task { await viewModel.load() }
    }

    // MARK: Drag indicator

    private var dragIndicator: some View {
        Capsule()
            .fill(Color.white.opacity(0.25))
            .frame(width: 38, height: 4)
    }

    // MARK: Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(onSurfaceVar)

            TextField("", text: $viewModel.searchText)
                .placeholder(when: viewModel.searchText.isEmpty) {
                    Text("Search languages...")
                        .foregroundColor(onSurfaceVar)
                        .font(.system(size: 15, design: .rounded))
                }
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(onSurface)
                .tint(brandGreen)
                .autocapitalization(.words)
                .disableAutocorrection(true)

            if !viewModel.searchText.isEmpty {
                Button { viewModel.clearSearch() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(onSurfaceVar.opacity(0.65))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(fieldBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(fieldBorder, lineWidth: 1)
                )
        )
    }

    // MARK: Content router

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            loadingContent
        case .failed(let message):
            errorContent(message: message)
        case .loaded:
            languageList
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(onSurface)
            Text("Loading languages…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 26, weight: .light))
                .foregroundColor(onSurfaceVar)
            Text("Couldn't load languages")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(onPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: List

    private var languageList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filtered, id: \.id) { lang in
                    row(lang)
                    if lang.id != viewModel.filtered.last?.id {
                        Divider()
                            .background(rowDivider)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    private func row(_ language: LanguageItem) -> some View {
        let isSelected = viewModel.selected.contains(language.id)

        return Button {
            viewModel.toggle(language)
        } label: {
            HStack(spacing: 14) {
                checkbox(isSelected: isSelected)

                Text(language.label)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(onSurface)

                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func checkbox(isSelected: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(isSelected ? brandGreen : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(
                            isSelected ? brandGreen : Color.white.opacity(0.35),
                            lineWidth: 1.5
                        )
                )
                .frame(width: 22, height: 22)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(onPrimary)
            }
        }
    }

    // MARK: Bottom actions

    private var bottomActions: some View {
        HStack(spacing: 12) {
            Button {
                onCancel()
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(onSurface)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        Capsule().fill(fieldBg)
                    )
            }
            .buttonStyle(.plain)

            Button {
                onDone(viewModel.orderedSelection)
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        Capsule().fill(brandGreen)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Previews

#Preview("Default") {
    let all = LanguageSelectionViewModel.previewLanguages
    let seeded = Array(all.prefix(2))
    return LanguageSelectionView(viewModel: .previewSeed(initialSelection: seeded, all: all))
        .preferredColorScheme(.dark)
}

#Preview("Many selected") {
    let all = LanguageSelectionViewModel.previewLanguages
    let seeded = Array(all.prefix(5))
    return LanguageSelectionView(viewModel: .previewSeed(initialSelection: seeded, all: all))
        .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return LanguageSelectionView()
        .preferredColorScheme(.dark)
}
