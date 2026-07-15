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
        .task { await viewModel.load() }
        .alert(
            "Couldn't save preferences",
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

                NotificationSaveButton(
                    isSaving: viewModel.isSaving,
                    didSave: viewModel.didSave,
                    action: { viewModel.saveChanges() }
                )
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
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

// MARK: - Preview harness

private enum NotificationSettingsPreviewRoute: Hashable {
    case `default`
}

/// Wraps the notification-settings screen inside a NavigationStack with a
/// dummy "Settings" parent already pushed, so the system back chevron
/// renders in the canvas.
private struct NotificationSettingsPreviewHarness: View {
    let route: NotificationSettingsPreviewRoute
    @State private var path: [NotificationSettingsPreviewRoute]

    init(route: NotificationSettingsPreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Account")
                NavigationLink("Notifications", value: route)
            }
            .navigationTitle("Settings")
            .navigationDestination(for: NotificationSettingsPreviewRoute.self) { dest in
                switch dest {
                case .default:
                    NotificationSettingsView(viewModel: .previewSeed())
                }
            }
        }
    }
}

// MARK: - Live fetch preview harness

private enum LiveFetchNotificationSettingsRoute: Hashable {
    case notifications
}

/// Live-fetch harness. Sets the bearer token from `PreviewSecrets`, wraps
/// the screen in a dummy "Settings" parent, and lets the view fetch its
/// own state via `GET /notifications/preferences`. Toggling + hitting Save
/// exercises the real `PATCH /notifications/preferences` round trip.
private struct LiveFetchNotificationSettingsPreviewHarness: View {
    @State private var path: [LiveFetchNotificationSettingsRoute] = [.notifications]

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Account")
                NavigationLink("Notifications", value: LiveFetchNotificationSettingsRoute.notifications)
            }
            .navigationTitle("Settings")
            .navigationDestination(for: LiveFetchNotificationSettingsRoute.self) { _ in
                NotificationSettingsView()
            }
        }
    }
}

// MARK: - Previews

#Preview("Notification Settings") {
    NotificationSettingsPreviewHarness(route: .default)
        .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
    return LiveFetchNotificationSettingsPreviewHarness()
        .preferredColorScheme(.dark)
}
