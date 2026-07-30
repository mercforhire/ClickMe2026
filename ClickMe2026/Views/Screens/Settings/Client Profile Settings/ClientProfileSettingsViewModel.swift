//
//  ClientProfileSettingsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Combine
import Foundation
import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class ClientProfileSettingsViewModel: ObservableObject {

    // MARK: Basic info
    @Published var firstName: String
    @Published var lastName: String
    @Published var phone: String
    @Published var bio: String

    // MARK: Professional
    @Published var jobTitle: String
    @Published var company: String
    @Published var city: String
    @Published var state: String
    /// ISO-3166-1 alpha-3 code (e.g. "USA") — matches server contract.
    @Published var country: String
    @Published var languages: [String]

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
    private let autoSaveDebounce: UInt64 = 1_200_000_000 // 1.2 s

    /// Snapshot of the fields at the moment we last hydrated from the
    /// server (or last successfully saved). `scheduleAutoSave()` compares
    /// the current fields against this and skips when they match — that's
    /// how we avoid firing a redundant save immediately after
    /// `UserManager.refreshProfile()` publishes new values into the sink.
    private var lastAppliedSnapshot: String = ""

    // MARK: Dependencies

    private let api: ClickMeAPI
    private let userManager: UserManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    /// Runtime init — starts with empty fields, then sinks
    /// `UserManager.$profile` to populate them the moment the cached (or
    /// freshly-fetched) profile arrives. Field edits after that trigger
    /// the auto-save debounce as usual.
    init(
        userManager: UserManager = .shared,
        api: ClickMeAPI = .shared
    ) {
        self.firstName = ""
        self.lastName = ""
        self.phone = ""
        self.bio = ""
        self.jobTitle = ""
        self.company = ""
        self.city = ""
        self.state = ""
        self.country = ""
        self.languages = []
        self.selectedPhoto = nil
        self.profileImage = nil
        self.showProfSheet = false
        self.showLangSheet = false
        self.userManager = userManager
        self.api = api

        // Seed immediately from the on-disk cache (if any), then
        // subscribe so revalidation writes propagate.
        apply(profile: userManager.profile)
        userManager.$profile
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.apply(profile: $0) }
            .store(in: &cancellables)
    }

    /// Preview / test seam — installs canned data without hitting
    /// `UserManager`. Used by the SwiftUI previews.
    static func previewSeed(
        firstName: String = "Sophia",
        lastName: String = "Carter",
        phone: String = "+1 234 567 890",
        bio: String = "Passionate digital marketing expert with over 10 years of experience helping brands grow their online presence.",
        jobTitle: String = "Digital Marketing Expert",
        company: String = "Self-Employed",
        city: String = "San Francisco",
        state: String = "CA",
        country: String = "USA",
        languages: [String] = ["English", "Spanish"]
    ) -> ClientProfileSettingsViewModel {
        let vm = ClientProfileSettingsViewModel()
        vm.firstName = firstName
        vm.lastName = lastName
        vm.phone = phone
        vm.bio = bio
        vm.jobTitle = jobTitle
        vm.company = company
        vm.city = city
        vm.state = state
        vm.country = country
        vm.languages = languages
        vm.lastAppliedSnapshot = vm.currentSnapshot()
        return vm
    }

    // MARK: - Hydration

    /// Copies server-known values from a `UserProfileData` into the local
    /// @Published fields, then records the resulting snapshot as
    /// `lastAppliedSnapshot` so the immediately-following autosave check
    /// short-circuits. Non-existent server fields default to empty so
    /// the field UI shows a placeholder rather than a stale local value.
    private func apply(profile: UserProfileData?) {
        guard let profile else { return }
        let personal = profile.personalDetails
        let location = profile.location
        let professional = profile.professionalDetails

        firstName = personal.firstName ?? ""
        lastName = personal.lastName ?? ""
        phone = personal.phone ?? ""
        bio = personal.bio ?? ""

        jobTitle = professional.jobTitle ?? ""
        company = professional.company ?? ""

        city = location.city ?? ""
        state = location.stateProvince ?? ""
        country = location.country ?? ""

        languages = profile.languages.compactMap { $0.label }

        lastAppliedSnapshot = currentSnapshot()
    }

    /// Serialized view of the auto-saveable fields. Order + separator
    /// must stay stable — this is only used for equality checks, not
    /// display.
    private func currentSnapshot() -> String {
        [
            firstName, lastName, phone, bio,
            jobTitle, company,
            city, state, country,
            languages.joined(separator: ","),
        ].joined(separator: "|")
    }

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
        if currentSnapshot() == lastAppliedSnapshot { return }

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
        // Build a payload that only carries fields we can actually round-trip
        // safely. Notably: `email` is 403 on this endpoint, so it's omitted.
        // `languages` is skipped because the VM stores display strings and
        // the server needs `language_ids` — wire that once we have a real
        // language picker sourcing IDs from GET /meta/languages.
        var body = UpdateUserProfileRequest()
        body.basic = .init(
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            phone: phone.trimmingCharacters(in: .whitespaces),
            bio: bio.trimmingCharacters(in: .whitespaces)
        )
        body.location = .init(
            city: city.trimmingCharacters(in: .whitespaces),
            stateProvince: state.trimmingCharacters(in: .whitespaces),
            countryCode: country.isEmpty ? nil : country
        )
        body.professional = .init(
            jobTitle: jobTitle.trimmingCharacters(in: .whitespaces),
            company: company.trimmingCharacters(in: .whitespaces)
        )

        isAutoSaving = true
        defer { isAutoSaving = false }
        do {
            _ = try await api.updateUserProfile(body)
            // Record what we just persisted so a subsequent server sink
            // publishing the same values doesn't trigger a redundant save.
            lastAppliedSnapshot = currentSnapshot()
            withAnimation(.easeOut(duration: 0.25)) { didAutoSave = true }
        } catch {
            autoSaveError = error.userMessage
        }
    }
}
