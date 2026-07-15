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

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: Sections
    @Published var sections: [NotificationSection]

    // MARK: Load state
    @Published var state: LoadState

    // MARK: Save state
    @Published var isSaving: Bool
    @Published var didSave: Bool
    /// Surfaced to the view for an alert when the PATCH fails.
    @Published var saveError: String?

    // MARK: Dependencies

    private let api: ClickMeAPI

    init(
        sections: [NotificationSection] = NotificationSettingsViewModel.defaultSections,
        state: LoadState = .idle,
        isSaving: Bool = false,
        didSave: Bool = false,
        api: ClickMeAPI = .shared
    ) {
        self.sections = sections
        self.state = state
        self.isSaving = isSaving
        self.didSave = didSave
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
            state = .failed(Self.errorMessage(for: error))
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

    // MARK: - Save

    /// Bulk-updates the user's notification preferences via
    /// `PATCH /notifications/preferences`. Each UI toggle flips all three
    /// channels (push / email / in-app) for that sub-category; the master
    /// toggle UX matches the current design.
    func saveChanges() {
        guard !isSaving, !didSave else { return }
        withAnimation { isSaving = true }

        Task {
            defer {
                withAnimation { isSaving = false }
            }
            do {
                let inputs = buildPreferenceInputs()
                _ = try await api.updateNotificationPreferences(
                    UpdateNotificationPreferencesRequest(preferences: inputs)
                )
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    didSave = true
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation { didSave = false }
            } catch {
                saveError = Self.errorMessage(for: error)
            }
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

    private static func errorMessage(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    // MARK: Defaults
    //
    // Sub-category keys mirror the server-side taxonomy verified against
    // GET /notifications/preferences. Bookings has 7 real server keys; we
    // expose 4 in the UI (the ones matching the design mock). Server rows
    // we don't render (e.g. `promotions` — hidden by design — and the extra
    // bookings sub-categories `declines / reschedules / completions /
    // expirations`) are simply ignored when hydrating.

    static let defaultSections: [NotificationSection] = [
        NotificationSection(
            title: "Messages",
            categoryKey: "messages",
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
            title: "Bookings",
            categoryKey: "bookings",
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
            ]
        ),
    ]
}
