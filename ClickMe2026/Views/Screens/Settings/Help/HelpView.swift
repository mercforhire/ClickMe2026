//
//  HelpView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Help View

struct HelpView: View {

    @StateObject private var viewModel: HelpViewModel

    init(viewModel: HelpViewModel = HelpViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            HelpBrand.bg.ignoresSafeArea()
            content
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(HelpBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
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
            VStack(alignment: .leading, spacing: 24) {
                faqSection
                contactSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(HelpBrand.onSurface)
            Text("Loading help…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(HelpBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(HelpBrand.onSurfaceVar)
            Text("Couldn't load help")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(HelpBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(HelpBrand.onSurfaceVar)
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
                    .background(Capsule().fill(HelpBrand.brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - FAQ section

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HelpSectionHeader("Frequently Asked Questions")

            VStack(spacing: 12) {
                ForEach(viewModel.categories, id: \.id) { category in
                    HelpFAQCard(
                        category: category,
                        isExpanded: viewModel.isExpanded(category),
                        onTap: { viewModel.toggle(category) }
                    )
                }
            }
        }
    }

    // MARK: - Contact section

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HelpSectionHeader("Contact Us")

            HelpContactRow(
                icon: "envelope",
                title: "Email Us",
                action: {}
            )
        }
    }
}

// MARK: - Previews

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
    return PreviewNavHarness(parentText: "Support", navTitle: "Settings", rowTitle: "Help") {
        HelpView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Help — Collapsed") {
    PreviewNavHarness(parentText: "Support", navTitle: "Settings", rowTitle: "Help") {
        HelpView(viewModel: .previewSeed())
    }
    .preferredColorScheme(.dark)
}

#Preview("Help — All Expanded") {
    let seed = HelpViewModel.previewSeed()
    seed.expandedCategories = Set(seed.categories.map { $0.id })
    return PreviewNavHarness(parentText: "Support", navTitle: "Settings", rowTitle: "Help") {
        HelpView(viewModel: seed)
    }
    .preferredColorScheme(.dark)
}
