//
//  LanguageEditorSheet.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Language Editor Sheet

struct LanguageEditorSheet: View {
    @Binding var languages: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    private let allLanguages = [
        "French", "German", "Italian", "Mandarin", "Japanese",
        "Portuguese", "Arabic", "Hindi", "Korean", "Dutch", "Russian", "Turkish",
    ]

    private var filtered: [String] {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return allLanguages.filter { !languages.contains($0) } }
        return allLanguages.filter { $0.localizedCaseInsensitiveContains(q) && !languages.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Languages")
                .font(.brand(.title2, weight: .bold))
                .foregroundColor(ProfileSettingsBrand.onSurface)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            currentLanguagesSection

            searchBar

            languageList

            Spacer()

            Button { dismiss() } label: {
                Text("Done")
                    .font(.brand(.callout, weight: .bold))
                    .foregroundColor(ProfileSettingsBrand.onPrimary)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(Capsule().fill(ProfileSettingsBrand.brandGreen)
                        .shadow(color: ProfileSettingsBrand.brandGreen.opacity(0.45), radius: 10))
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
        // Sheet presentation context — app-root keyboard toolbar
        // doesn't reach the search TextField.
        .keyboardDismissToolbar()
    }

    // MARK: Current

    private var currentLanguagesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current Languages")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(ProfileSettingsBrand.onSurface)

            ProfileFlowLayout(spacing: 8) {
                ForEach(languages, id: \.self) { lang in
                    HStack(spacing: 5) {
                        Text(lang)
                            .font(.brand(.caption, weight: .medium))
                            .foregroundColor(ProfileSettingsBrand.onSurface)
                        Button {
                            withAnimation { languages.removeAll { $0 == lang } }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(ProfileSettingsBrand.onSurface)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(ProfileSettingsBrand.chipBg)
                            .overlay(Capsule().stroke(ProfileSettingsBrand.brandGreen.opacity(0.65), lineWidth: 1.2))
                    )
                }
            }
        }
    }

    // MARK: Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            TextField("Search and Add", text: $searchText)
                .font(.brand(.subheadline))
                .foregroundColor(ProfileSettingsBrand.onSurface)
                .tint(ProfileSettingsBrand.brandGreen)
                .focused($searchFocused)
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundColor(ProfileSettingsBrand.onSurfaceVar)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ProfileSettingsBrand.fieldBg)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(ProfileSettingsBrand.fieldBorder, lineWidth: 1))
        )
    }

    // MARK: List

    private var languageList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(filtered, id: \.self) { lang in
                    Button {
                        withAnimation { languages.append(lang) }
                        searchText = ""
                    } label: {
                        Text(lang)
                            .font(.brand(.subheadline, weight: .regular))
                            .foregroundColor(ProfileSettingsBrand.onSurface)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().background(Color(red: 0.18, green: 0.28, blue: 0.20))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ProfileSettingsBrand.fieldBg)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(ProfileSettingsBrand.fieldBorder, lineWidth: 1))
            )
        }
        .frame(maxHeight: 220)
    }
}
