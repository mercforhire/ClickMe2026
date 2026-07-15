//
//  NotificationSettingsView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct NotificationSetting: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    /// Wire value sent as `sub_category` in
    /// `PATCH /notifications/preferences`. Must match the server enum
    /// (verified against a live GET on 2026-07-09).
    let subCategoryKey: String
    var isOn: Bool
}

struct NotificationSection: Identifiable {
    let id = UUID()
    let title: String
    /// Wire value sent as `category`. Server enum:
    /// `messages`, `bookings`, `promotions`.
    let categoryKey: String
    var settings: [NotificationSetting]
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {

    @StateObject private var viewModel: NotificationSettingsViewModel

    init(viewModel: NotificationSettingsViewModel = NotificationSettingsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            NotificationSettingsBrand.bg.ignoresSafeArea()
            content
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(NotificationSettingsBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                autoSaveStatusIcon
            }
        }
        .task { await viewModel.load() }
        .onChange(of: autoSaveSnapshot) {
            viewModel.scheduleAutoSave()
        }
        .alert(
            "Couldn't save preferences",
            isPresented: Binding(
                get: { viewModel.autoSaveError != nil },
                set: { if !$0 { viewModel.autoSaveError = nil } }
            ),
            presenting: viewModel.autoSaveError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Auto-save chrome

    /// Trailing-nav-bar spinner while saving, checkmark right after a
    /// successful save. Empty in all other states so the bar stays clean.
    @ViewBuilder
    private var autoSaveStatusIcon: some View {
        if viewModel.isAutoSaving {
            ProgressView()
                .controlSize(.small)
                .tint(NotificationSettingsBrand.onSurface)
        } else if viewModel.didAutoSave {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(NotificationSettingsBrand.brandGreen)
                .transition(.opacity)
        }
    }

    /// Compact string that changes whenever any toggle flips. A single
    /// `.onChange` on this drives the debounced auto-save scheduler.
    private var autoSaveSnapshot: String {
        viewModel.sections.flatMap { section in
            section.settings.map { "\(section.categoryKey).\($0.subCategoryKey)=\($0.isOn)" }
        }.joined(separator: "|")
    }

    // MARK: - Content router

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
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
            VStack(spacing: 16) {
                ForEach(viewModel.sections.indices, id: \.self) { si in
                    NotificationSectionCard(
                        title: viewModel.sections[si].title,
                        settings: $viewModel.sections[si].settings
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(NotificationSettingsBrand.onSurface)
            Text("Loading preferences…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(NotificationSettingsBrand.onSurface.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(NotificationSettingsBrand.onSurface.opacity(0.6))
            Text("Couldn't load preferences")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(NotificationSettingsBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(NotificationSettingsBrand.onSurface.opacity(0.6))
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
                    .background(Capsule().fill(NotificationSettingsBrand.brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview("Notification Settings") {
    PreviewNavHarness(parentText: "Account", navTitle: "Settings", rowTitle: "Notifications") {
        NotificationSettingsView(viewModel: .previewSeed())
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
    return PreviewNavHarness(parentText: "Account", navTitle: "Settings", rowTitle: "Notifications") {
        NotificationSettingsView()
    }
    .preferredColorScheme(.dark)
}
