//
//  NotificationSettingsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-29.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class NotificationSettingsViewModel: ObservableObject {


    // MARK: Sections
    @Published var sections: [NotificationSection]

    // MARK: Load state
    @Published var state: LoadState

    // MARK: Auto-save state

    /// True while a debounced auto-save is currently uploading.
    @Published var isAutoSaving: Bool = false
    /// True immediately after a successful auto-save. Cleared as soon as
    /// the user flips another toggle.
    @Published var didAutoSave: Bool = false
    /// Surfaced to the view for an alert when the PATCH fails.
    @Published var autoSaveError: String?

    /// Task holding the pending debounce sleep + PATCH. Cancelled whenever
    /// a new toggle flip comes in so only the trailing save fires.
    private var autoSaveTask: Task<Void, Never>?

    /// Debounce window between the last toggle change and the actual PATCH.
    /// Long enough that rapid multi-toggle flips coalesce into one request,
    /// short enough that a single tap feels near-instant.
    private let autoSaveDebounce: UInt64 = 800_000_000 // 0.8 s

    // MARK: Dependencies

    private let api: ClickMeAPI

    init(
        sections: [NotificationSection] = NotificationSettingsViewModel.defaultSections,
        state: LoadState = .idle,
        api: ClickMeAPI = .shared
    ) {
        self.sections = sections
        self.state = state
        self.api = api
    }

    /// Preview seam — installs canned data as if a load had already succeeded.
    static func previewSeed(
        sections: [NotificationSection] = NotificationSettingsViewModel.defaultSections
    ) -> NotificationSettingsViewModel {
        NotificationSettingsViewModel(sections: sections, state: .loaded)
    }

    // MARK: - Load

    /// Fetches the user's saved preferences via `GET /notifications/preferences`
    /// and hydrates the master toggle for each row. Idempotent — skips when
    /// already loaded so it doesn't clobber preview seeds.
    func load() async {
        if case .loaded = state { return }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        state = .loading
        do {
            let response = try await api.getNotificationPreferences()
            apply(preferences: response.data.preferences)
            state = .loaded
        } catch {
            state = .failed(error.userMessage)
        }
    }

    /// Overlays the server's preference rows onto our known
    /// `(category, sub_category)` grid. Server rows we don't render (e.g.
    /// `promotions`) are ignored. Missing rows keep the default `true`.
    private func apply(preferences: [NotificationPreferencesData.Preference]) {
        let index = Dictionary(
            uniqueKeysWithValues: preferences.map {
                ("\($0.category)|\($0.subCategory)", $0.isAnyChannelEnabled)
            }
        )
        for si in sections.indices {
            for ii in sections[si].settings.indices {
                let key = "\(sections[si].categoryKey)|\(sections[si].settings[ii].subCategoryKey)"
                if let value = index[key] {
                    sections[si].settings[ii].isOn = value
                }
            }
        }
    }

    // MARK: - Auto-save

    /// Called by the view whenever any toggle flips. Cancels any pending
    /// PATCH and schedules a fresh one after the debounce window — rapid
    /// multi-toggle flips coalesce into a single trailing request.
    func scheduleAutoSave() {
        autoSaveTask?.cancel()
        // Hide the "saved" checkmark while the user is actively editing.
        if didAutoSave { didAutoSave = false }

        autoSaveTask = Task { [weak self] in
            guard let debounce = self?.autoSaveDebounce else { return }
            try? await Task.sleep(nanoseconds: debounce)
            guard !Task.isCancelled else { return }
            await self?.performAutoSave()
        }
    }

    private func performAutoSave() async {
        isAutoSaving = true
        defer { isAutoSaving = false }
        do {
            let inputs = buildPreferenceInputs()
            _ = try await api.updateNotificationPreferences(
                UpdateNotificationPreferencesRequest(preferences: inputs)
            )
            withAnimation(.easeOut(duration: 0.25)) { didAutoSave = true }
        } catch {
            autoSaveError = error.userMessage
        }
    }

    private func buildPreferenceInputs() -> [NotificationPreferenceInput] {
        sections.flatMap { section in
            section.settings.map { setting in
                NotificationPreferenceInput(
                    category: section.categoryKey,
                    subCategory: setting.subCategoryKey,
                    pushEnabled: setting.isOn,
                    emailEnabled: setting.isOn,
                    inAppEnabled: setting.isOn
                )
            }
        }
    }


    // MARK: Defaults
    //
    // Sub-category keys mirror the server-side taxonomy verified against
    // GET /notifications/preferences. Category keys are SINGULAR to match
    // the backend enum; the previous plural forms (`bookings`,
    // `messages`) silently failed to hydrate.
    //
    // Rendered categories: `booking`, `session`, `message`, `review`.
    // The `payout` and `account` categories still exist on the server
    // but are intentionally not surfaced here — payout/account events
    // are considered non-optional transactional notifications.
    //
    // The channel breakdown is collapsed into a single master toggle
    // per row (see `buildPreferenceInputs()` — the toggle mirrors across
    // push/email/in-app so the "off" experience is universal).

    static let defaultSections: [NotificationSection] = [
        NotificationSection(
            title: "Bookings",
            categoryKey: "booking",
            settings: [
                NotificationSetting(
                    title: "Booking Requests",
                    subtitle: "In-app, Email, Push",
                    subCategoryKey: "requests",
                    isOn: true
                ),
                NotificationSetting(
                    title: "Booking Confirmations",
                    subtitle: "In-app, Email, Push",
                    subCategoryKey: "confirmations",
                    isOn: true
                ),
                NotificationSetting(
                    title: "Booking Declines",
                    subtitle: "In-app, Email, Push",
                    subCategoryKey: "declines",
                    isOn: true
                ),
                NotificationSetting(
                    title: "Booking Cancellations",
                    subtitle: "In-app, Email, Push",
                    subCategoryKey: "cancellations",
                    isOn: true
                ),
                NotificationSetting(
                    title: "Booking Reschedules",
                    subtitle: "In-app, Email, Push",
                    subCategoryKey: "reschedules",
                    isOn: true
                ),
                NotificationSetting(
                    title: "Booking Expirations",
                    subtitle: "In-app, Email, Push",
                    subCategoryKey: "expirations",
                    isOn: true
                ),
                NotificationSetting(
                    title: "Refunds",
                    subtitle: "In-app, Email, Push",
                    subCategoryKey: "refunds",
                    isOn: true
                ),
            ]
        ),
        NotificationSection(
            title: "Sessions",
            categoryKey: "session",
            settings: [
                NotificationSetting(
                    title: "Session Reminders",
                    subtitle: "In-app, Email, Push",
                    subCategoryKey: "reminder",
                    isOn: true
                ),
                NotificationSetting(
                    title: "Partner No-Show",
                    subtitle: "In-app, Email, Push",
                    subCategoryKey: "no_show",
                    isOn: true
                ),
                NotificationSetting(
                    title: "Session Ended",
                    subtitle: "In-app, Email, Push",
                    subCategoryKey: "ended",
                    isOn: true
                ),
            ]
        ),
        NotificationSection(
            title: "Messages",
            categoryKey: "message",
            settings: [
                NotificationSetting(
                    title: "New Messages",
                    subtitle: "In-app, Email, Push",
                    subCategoryKey: "new_message",
                    isOn: true
                ),
            ]
        ),
        NotificationSection(
            title: "Reviews",
            categoryKey: "review",
            settings: [
                NotificationSetting(
                    title: "New Reviews",
                    subtitle: "In-app, Email, Push",
                    subCategoryKey: "received",
                    isOn: true
                ),
                NotificationSetting(
                    title: "Review Reminders",
                    subtitle: "In-app, Email, Push",
                    subCategoryKey: "nudge",
                    isOn: true
                ),
            ]
        ),
    ]
}
