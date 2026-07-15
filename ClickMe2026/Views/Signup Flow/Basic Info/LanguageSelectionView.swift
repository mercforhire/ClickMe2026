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

    var onDone: ([String]) -> Void
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
        onDone: @escaping ([String]) -> Void = { _ in },
        onCancel: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onDone = onDone
        self.onCancel = onCancel
    }

    /// Convenience: build the VM from a pre-selected list.
    init(
        initialSelection: [String],
        onDone: @escaping ([String]) -> Void = { _ in },
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

            languageList

            bottomActions
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
        }
        .background(bg.ignoresSafeArea())
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

    // MARK: List

    private var languageList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filtered, id: \.self) { lang in
                    row(lang)
                    if lang != viewModel.filtered.last {
                        Divider()
                            .background(rowDivider)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    private func row(_ language: String) -> some View {
        let isSelected = viewModel.selected.contains(language)

        return Button {
            viewModel.toggle(language)
        } label: {
            HStack(spacing: 14) {
                checkbox(isSelected: isSelected)

                Text(language)
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
    LanguageSelectionView(initialSelection: ["English", "Spanish"])
        .preferredColorScheme(.dark)
}

#Preview("Many selected") {
    LanguageSelectionView(initialSelection: ["English", "Spanish", "French", "German", "Mandarin"])
        .preferredColorScheme(.dark)
}
