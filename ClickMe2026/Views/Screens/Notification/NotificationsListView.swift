//
//  NotificationsListView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// The notifications list. Renders grouped sections (Today / Yesterday /
/// Earlier) of `NotificationRow` cards, plus a bottom "End of recent
/// updates" pill. Designed to be embedded inside `HomeClientView` /
/// `HomeExpertView` — the shell provides the top bar and tab bar, so
/// this screen just handles the pushed nav-toolbar (title + Clear all)
/// and the content list.
struct NotificationsListView: View {

    @StateObject private var viewModel: NotificationsListViewModel

    // MARK: Init

    init(viewModel: NotificationsListViewModel = NotificationsListViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Brand.surface.ignoresSafeArea()
            content
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear all") {
                    viewModel.clearAll()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Brand.primary)
                .opacity(viewModel.sections.isEmpty ? 0.3 : 1)
                .disabled(viewModel.sections.isEmpty)
            }
        }
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

    // MARK: - States

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(Brand.onSurface)
            Text("Loading notifications…")
                .font(.system(size: 13))
                .foregroundColor(Brand.onSurfaceVariant.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 26, weight: .light))
                .foregroundColor(Brand.onSurfaceVariant.opacity(0.7))
            Text("Couldn't load notifications")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Brand.onSurface)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Brand.onSurfaceVariant.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Brand.onPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Brand.primary))
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var loadedContent: some View {
        if viewModel.sections.isEmpty {
            emptyContent
        } else {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    ForEach(viewModel.sections) { section in
                        sectionView(section)
                    }
                    endOfUpdatesBanner
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .refreshable { await viewModel.reload() }
        }
    }

    private var emptyContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 34, weight: .light))
                .foregroundColor(Brand.onSurfaceVariant.opacity(0.65))
            Text("You're all caught up")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Brand.onSurface)
            Text("No new notifications right now.")
                .font(.system(size: 13))
                .foregroundColor(Brand.onSurfaceVariant.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Section

    private func sectionView(_ section: NotificationsListSection) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(section.kind.title)
                .font(.system(size: 14, weight: .semibold))
                .kerning(1.4)
                .foregroundColor(Brand.onSurfaceVariant)

            VStack(spacing: 16) {
                ForEach(section.items, id: \.id) { item in
                    NotificationRow(item: item)
                }
            }
        }
    }

    private var endOfUpdatesBanner: some View {
        Text("End of recent updates")
            .font(.system(size: 12, weight: .medium))
            .italic()
            .foregroundColor(Brand.onSurfaceVariant.opacity(0.7))
            .frame(maxWidth: .infinity)
            .frame(height: 128)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Brand.surfaceContainerLowest)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Brand.outlineVariant, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Previews

#Preview("Seeded — 3 sections") {
    PreviewNavHarness(parentText: "Home", navTitle: "ClickMe", rowTitle: "Notifications") {
        NotificationsListView(viewModel: .previewSeed())
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty") {
    PreviewNavHarness(parentText: "Home", navTitle: "ClickMe", rowTitle: "Notifications") {
        NotificationsListView(viewModel: .previewSeed(sections: []))
    }
    .preferredColorScheme(.dark)
}

#Preview("Loading") {
    PreviewNavHarness(parentText: "Home", navTitle: "ClickMe", rowTitle: "Notifications") {
        NotificationsListView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
    return PreviewNavHarness(parentText: "Home", navTitle: "ClickMe", rowTitle: "Notifications") {
        NotificationsListView()
    }
    .preferredColorScheme(.dark)
}
