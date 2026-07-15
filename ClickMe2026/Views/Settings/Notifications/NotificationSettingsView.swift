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
    var isOn: Bool
}

struct NotificationSection: Identifiable {
    let id = UUID()
    let title: String
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

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(viewModel.sections.indices, id: \.self) { si in
                        NotificationSectionCard(
                            title: viewModel.sections[si].title,
                            settings: $viewModel.sections[si].settings
                        )
                    }

                    NotificationQuietHoursCard(
                        isEnabled: $viewModel.quietHoursEnabled,
                        startValue: viewModel.quietStart,
                        endValue: viewModel.quietEnd,
                        onTapStart: { viewModel.presentStartPicker() },
                        onTapEnd: { viewModel.presentEndPicker() }
                    )

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
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(NotificationSettingsBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .confirmationDialog("Start Time", isPresented: $viewModel.showStartPicker, titleVisibility: .visible) {
            ForEach(viewModel.quietTimes, id: \.self) { t in
                Button(t) { viewModel.quietStart = t }
            }
        }
        .confirmationDialog("End Time", isPresented: $viewModel.showEndPicker, titleVisibility: .visible) {
            ForEach(viewModel.quietTimes, id: \.self) { t in
                Button(t) { viewModel.quietEnd = t }
            }
        }
    }
}

// MARK: - Preview harness

private enum NotificationSettingsPreviewRoute: Hashable {
    case `default`
    case quietHoursDisabled
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
                    NotificationSettingsView()
                case .quietHoursDisabled:
                    NotificationSettingsView(
                        viewModel: NotificationSettingsViewModel(quietHoursEnabled: false)
                    )
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Notification Settings") {
    NotificationSettingsPreviewHarness(route: .default)
        .preferredColorScheme(.dark)
}

#Preview("Quiet Hours Disabled") {
    NotificationSettingsPreviewHarness(route: .quietHoursDisabled)
        .preferredColorScheme(.dark)
}
