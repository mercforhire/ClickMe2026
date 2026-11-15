//
//  ClientProfileSettingsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import Observation
import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class ClientProfileSettingsViewModel: ObservableObject {

    // MARK: Basic info
    @Published var firstName: String
    @Published var lastName: String
    @Published var bio: String

    // MARK: Professional
    @Published var jobTitle: String
    @Published var company: String
    @Published var city: String
    @Published var state: String
    /// ISO-3166-1 alpha-3 code (e.g. "USA") — matches server contract.
    @Published var country: String
    /// Catalog languages (id + label) in the order the user picked them.
    /// Only these ids are sent as `language_ids`.
    @Published var languageItems: [LanguageItem]
    /// Id-less (custom) languages the server already holds. The picker cannot
    /// add or remove them, but a languages save is a full replace, so they are
    /// always sent back as `custom_languages` or the save would delete them.
    @Published private(set) var customLanguages: [String]

    /// Display labels for the language row: catalog languages, then customs.
    var languages: [String] { languageItems.map(\.label) + customLanguages }

    // MARK: Photo
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var profileImage: Image?

    /// True while the currently-selected photo is being uploaded to
    /// `POST /user/profile/avatar`. The avatar section renders an inline
    /// spinner over the image while this is true.
    @Published var isUploadingAvatar: Bool = false
    /// Surfaced when the avatar upload fails so the view can show an alert.
    @Published var avatarUploadError: String?

    // MARK: Sheet state
    @Published var showProfSheet: Bool
    @Published var showLangSheet: Bool

    // MARK: Auto-save state

    /// True while a debounced auto-save is currently uploading. The nav bar
    /// renders a small spinner in that case.
    @Published var isAutoSaving: Bool = false

    /// True immediately after a successful auto-save. Cleared as soon as the
    /// user edits another field (the nav bar's checkmark hides).
    @Published var didAutoSave: Bool = false

    /// Surfaced to the view for an alert when an auto-save fails.
    @Published var autoSaveError: String?

    /// Task holding the pending debounce sleep + save. Cancelled whenever a
    /// new field change comes in so only the trailing save fires.
    private var autoSaveTask: Task<Void, Never>?

    /// Debounce window between the last field edit and the actual API call.
    /// Long enough that continued typing keeps rescheduling, short enough
    /// that a picker tap or paused typing saves quickly.
    private let autoSaveDebounce: UInt64

    /// What the server holds as of the last hydration or successful save.
    /// `scheduleAutoSave()` compares the current fields against this and skips
    /// when they match — that's how we avoid firing a redundant save immediately
    /// after `UserManager.refreshProfile()` publishes new values into the sink.
    /// `makeProfileUpdateBody()` sends only what differs from it (G-05-6).
    private var baseline = ProfileSettingsSnapshot()

    // MARK: Dependencies

    private let api: ClickMeAPI
    private let userManager: UserManager

    // MARK: Init

    /// Runtime init — starts with empty fields, then observes
    /// `UserManager.profile` to populate them the moment the cached (or
    /// freshly-fetched) profile arrives. Field edits after that trigger
    /// the auto-save debounce as usual.
    init(
        userManager: UserManager = .shared,
        api: ClickMeAPI = .shared,
        autoSaveDebounce: UInt64 = 1_200_000_000 // 1.2 s
    ) {
        self.firstName = ""
        self.lastName = ""
        self.bio = ""
        self.jobTitle = ""
        self.company = ""
        self.city = ""
        self.state = ""
        self.country = ""
        self.languageItems = []
        self.customLanguages = []
        self.selectedPhoto = nil
        self.profileImage = nil
        self.showProfSheet = false
        self.showLangSheet = false
        self.userManager = userManager
        self.api = api
        self.autoSaveDebounce = autoSaveDebounce

        // Seed immediately from the on-disk cache (if any), then
        // observe so revalidation writes propagate.
        if let profile = userManager.profile { hydrate(from: profile) }
        observeProfileChanges()
    }

    /// Observation-framework equivalent of the old Combine `sink` on
    /// `userManager.$profile`. `withObservationTracking` fires its
    /// `onChange` exactly once per read tracked in `apply`, so we
    /// re-arm from inside the callback to keep the subscription live
    /// for the ViewModel's lifetime.
    private func observeProfileChanges() {
        withObservationTracking {
            _ = userManager.profile
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let profile = userManager.profile { hydrate(from: profile) }
                observeProfileChanges()
            }
        }
    }

    /// Preview / test seam — installs canned data without hitting
    /// `UserManager`. Used by the SwiftUI previews.
    static func previewSeed(
        firstName: String = "Sophia",
        lastName: String = "Carter",
        bio: String = "Passionate digital marketing expert with over 10 years of experience helping brands grow their online presence.",
        jobTitle: String = "Digital Marketing Expert",
        company: String = "Self-Employed",
        city: String = "San Francisco",
        state: String = "CA",
        country: String = "USA",
        languageItems: [LanguageItem] = [
            LanguageItem(id: "en", label: "English"),
            LanguageItem(id: "es", label: "Spanish")
        ]
    ) -> ClientProfileSettingsViewModel {
        let vm = ClientProfileSettingsViewModel()
        vm.firstName = firstName
        vm.lastName = lastName
        vm.bio = bio
        vm.jobTitle = jobTitle
        vm.company = company
        vm.city = city
        vm.state = state
        vm.country = country
        vm.languageItems = languageItems
        vm.baseline = vm.currentSnapshot()
        return vm
    }

    // MARK: - Hydration

    /// Copies server-known values from a `UserProfileData` into the local
    /// @Published fields, then records the resulting snapshot as
    /// `baseline` so the immediately-following autosave check
    /// short-circuits. Non-existent server fields default to empty so
    /// the field UI shows a placeholder rather than a stale local value.
    func hydrate(from profile: UserProfileData) {
        let personal = profile.personalDetails
        let location = profile.location
        let professional = profile.professionalDetails

        firstName = personal.firstName ?? ""
        lastName = personal.lastName ?? ""
        bio = personal.bio ?? ""

        jobTitle = professional.jobTitle ?? ""
        company = professional.company ?? ""

        city = location.city ?? ""
        state = location.stateProvince ?? ""
        country = location.country ?? ""

        // An entry with an id is a catalog language; an id-less entry carries
        // its `custom_label` as the label (userProfile.controller.js).
        languageItems = profile.languages.compactMap { entry in
            guard let id = entry.id, let label = entry.label else { return nil }
            return LanguageItem(id: id, label: label)
        }
        customLanguages = profile.languages.compactMap { entry in
            entry.id == nil ? entry.label : nil
        }

        baseline = currentSnapshot()
    }

    /// The auto-saveable fields as a trimmed snapshot, for the equality check
    /// and for building the changed-groups body.
    private func currentSnapshot() -> ProfileSettingsSnapshot {
        ProfileSettingsSnapshot(
            firstName: firstName, lastName: lastName, bio: bio,
            jobTitle: jobTitle, company: company,
            city: city, stateProvince: state, country: country,
            languageIds: languageItems.map(\.id),
            customLanguages: customLanguages
        )
    }

    /// Set when the user has cleared a first name the profile already holds.
    /// The empty name is never sent (the server keeps the saved one), so this
    /// is what tells the user why. Plan 05-20 shows it under the field.
    var firstNameError: String? { currentSnapshot().firstNameError(from: baseline) }

    /// Same as `firstNameError`, for the last name.
    var lastNameError: String? { currentSnapshot().lastNameError(from: baseline) }

    // MARK: Photo loading + upload

    /// Called from the view's `.onChange(of: selectedPhoto)`. Decodes the
    /// picked image locally, shows it optimistically, then immediately
    /// uploads the raw bytes to `POST /user/profile/avatar`. Failure keeps
    /// the local preview and surfaces `avatarUploadError` for an alert.
    func loadSelectedPhoto() async {
        guard let item = selectedPhoto,
              let data = try? await item.loadTransferable(type: Data.self),
              let ui = UIImage(data: data) else { return }

        // Optimistic local preview.
        withAnimation { profileImage = Image(uiImage: ui) }

        // Re-encode to JPEG for a smaller upload than the raw HEIC/PNG.
        let jpegData = ui.jpegData(compressionQuality: 0.85) ?? data
        await uploadAvatar(data: jpegData)
    }

    private func uploadAvatar(data: Data) async {
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }
        do {
            _ = try await api.uploadAvatar(imageData: data)
            // Refresh so `UserManager.profile` picks up the new
            // avatarUrl and downstream views (top-bar avatar chip, this
            // section's remote fallback) see it.
            try? await userManager.refreshProfile()
        } catch {
            avatarUploadError = error.userMessage
        }
    }


    // MARK: - Auto-save

    /// Called by the view whenever an editable field changes. Cancels any
    /// pending save and schedules a fresh one after the debounce window —
    /// so continued typing coalesces into a single API call once the user
    /// pauses.
    ///
    /// Skips scheduling entirely when the current fields match the last
    /// applied server snapshot — this is what suppresses the redundant
    /// save that would otherwise fire immediately after
    /// `UserManager.$profile` publishes new values into our sink.
    func scheduleAutoSave() {
        if currentSnapshot() == baseline { return }

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

    /// Applies the picker's Done result. A selection that would leave the
    /// profile with no language at all (no catalog id and no custom label) is
    /// never applied: the backend would accept the empty list and delete every
    /// row, so this guard is the only protection (UI-SPEC EM4, A9). A profile
    /// that already had none gets a silent no-op.
    func applyLanguageSelection(_ picked: [LanguageItem]) {
        if picked.isEmpty && customLanguages.isEmpty {
            if !languageItems.isEmpty {
                autoSaveError = "Keep at least one language."
            }
            return
        }
        languageItems = picked
    }

    /// Builds the `PATCH /user/profile` body for what changed since the last
    /// hydration or save, or nil when nothing can be sent.
    ///
    /// Only changed groups go out, each whole and trimmed (Android parity). An
    /// empty name is never sent: the backend's `min(1)` rule would 422 the whole
    /// save (G-05-6), and a set name the user cleared is held so the server
    /// keeps it. The `languages` group is a full replace on the server, so it is
    /// sent only when the picked ids changed, always with the custom languages,
    /// and never when it would leave zero languages (A9). An emptied
    /// State/Province goes out as "" (D-07). `email` is 403 on this endpoint, so
    /// it is never sent.
    func makeProfileUpdateBody() -> UpdateUserProfileRequest? {
        currentSnapshot().patch(from: baseline)
    }

    func performAutoSave() async {
        // Built before the request, so an edit made while it is in flight is
        // not recorded as saved. Nothing to send means no request and no
        // checkmark.
        guard let body = makeProfileUpdateBody() else { return }

        isAutoSaving = true
        defer { isAutoSaving = false }
        do {
            _ = try await api.updateUserProfile(body)
            // Record what we just persisted so a subsequent server sink
            // publishing the same values doesn't trigger a redundant save.
            baseline = baseline.merging(body)
            withAnimation(.easeOut(duration: 0.25)) { didAutoSave = true }
        } catch {
            autoSaveError = error.userMessage
        }
    }
}
