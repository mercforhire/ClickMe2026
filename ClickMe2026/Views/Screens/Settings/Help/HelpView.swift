//
//  HelpView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Help View

struct HelpView: View {

    @StateObject private var viewModel: HelpViewModel
    @Environment(\.openURL) private var openURL

    /// Support inbox surfaced by the "Email Us" contact row. Swap
    /// here (not per-callsite) if the address ever changes.
    private static let supportEmail = "support@clickme.app"

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
                .font(.brand(.caption))
                .foregroundColor(HelpBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title.weight(.light))
                .foregroundColor(HelpBrand.onSurfaceVar)
            Text("Couldn't load help")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(HelpBrand.onSurface)
            Text(message)
                .font(.brand(.caption))
                .foregroundColor(HelpBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.brand(.subheadline, weight: .semibold))
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
                action: openSupportEmail
            )
        }
    }

    /// Hand off to the system with a `mailto:` URL. iOS routes to
    /// whichever mail client the user has picked as default
    /// (Mail / Gmail / Outlook / Spark). Silently no-ops on
    /// simulator builds that have no mail handler configured — the
    /// button "does nothing" only in that edge case.
    private func openSupportEmail() {
        guard let url = URL(string: "mailto:\(Self.supportEmail)") else { return }
        openURL(url)
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
