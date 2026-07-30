//
//  ExpertProfileSettingsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import Observation
import PhotosUI
import SwiftUI
import UIKit

@Observable
@MainActor
final class ExpertProfileSettingsViewModel {

    // MARK: Basic info (client-side profile)

    var firstName: String
    var lastName: String
    var phone: String
    var bio: String

    // MARK: Professional / location / languages

    var jobTitle: String
    var company: String
    /// Persistent Skype / Zoom / Google Meet link the expert uses for every
    /// video-call booking on this account. Empty when unset — the booking
    /// details view surfaces "Link will be shared" as a fallback.
    /// Round-trips through `PATCH /expert/profile` (professional_details.meeting_url).
    var meetingUrl: String
    var city: String
    var state: String
    /// ISO-3166-1 alpha-3 code (e.g. "USA") — matches server contract.
    var country: String
    var languages: [String]

    // MARK: Photo

    var selectedPhoto: PhotosPickerItem?
    var profileImage: Image?
    /// Server-hosted avatar URL from `GET /user/profile`. Rendered by the
    /// avatar subview whenever `profileImage` (the just-picked local
    /// UIImage) is nil, so a returning user sees their real avatar
    /// instead of a placeholder.
    var avatarUrl: String?

    /// True while the currently-selected photo is uploading. The avatar
    /// section can render a spinner if desired.
    var isUploadingAvatar: Bool = false
    /// Non-fatal error message from the avatar upload.
    var avatarUploadError: String?

    // MARK: Sheets (professional + language editor)

    var showProfSheet: Bool = false
    var showLangSheet: Bool = false

    // MARK: Auto-save (client fields → PATCH /user/profile)

    /// True while a debounced auto-save is currently uploading.
    var isAutoSaving: Bool = false
    /// True immediately after a successful auto-save. Cleared as soon as
    /// the user edits another field.
    var didAutoSave: Bool = false
    /// Non-fatal error surfaced from the PATCH.
    var autoSaveError: String?

    @ObservationIgnored
    private var autoSaveTask: Task<Void, Never>?

    /// Debounce window between the last field edit and the actual API call.
    @ObservationIgnored
    private let autoSaveDebounce: UInt64 = 1_200_000_000 // 1.2s

    /// Snapshot of the fields as they last were on the server. Set after
    /// `load()` hydrates from `GET /user/profile` and after each successful
    /// PATCH. Used by `scheduleAutoSave` to skip no-op saves — critical
    /// during the initial-load render when `.onChange` would otherwise
    /// PATCH the just-fetched values right back.
    @ObservationIgnored
    private var lastPersistedSnapshot: String?

    // MARK: Load state

    var loadState: LoadState = .idle


    // MARK: Expertise

    /// Currently-picked expertise tags for this expert, from
    /// `/expert/profile`. Drives the read-only chip strip in the
    /// settings screen; edits are performed inside `ExpertiseEditorSheet`.
    var expertiseEntries: [ExpertProfileData.ExpertiseTagEntry] = []
    /// Controls the presentation of `ExpertiseEditorSheet`.
    var showExpertiseSheet: Bool = false

    // MARK: Dependencies

    @ObservationIgnored
    private let api: ClickMeAPI
    @ObservationIgnored
    private let userManager: UserManager

    // MARK: Init

    init(
        firstName: String = "Ethan",
        lastName: String = "Carter",
        phone: String = "+1 234 567 890",
        bio: String = "Passionate expert with over 10 years of experience helping brands grow.",
        jobTitle: String = "Digital Marketing Expert",
        company: String = "Self-Employed",
        meetingUrl: String = "",
        city: String = "San Francisco",
        state: String = "CA",
        country: String = "USA",
        languages: [String] = ["English", "Spanish"],
        selectedPhoto: PhotosPickerItem? = nil,
        profileImage: Image? = nil,
        api: ClickMeAPI = .shared,
        userManager: UserManager = .shared
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.bio = bio
        self.jobTitle = jobTitle
        self.company = company
        self.meetingUrl = meetingUrl
        self.city = city
        self.state = state
        self.country = country
        self.languages = languages
        self.selectedPhoto = selectedPhoto
        self.profileImage = profileImage
        self.api = api
        self.userManager = userManager
        self.expertiseEntries = userManager.expertProfile?.expertiseTags ?? []
        self.meetingUrl = userManager.expertProfile?.professionalDetails.meetingUrl ?? meetingUrl
    }

    /// Preview seam — installs canned data as if the fetch had succeeded.
    static func previewSeed() -> ExpertProfileSettingsViewModel {
        let vm = ExpertProfileSettingsViewModel()
        vm.loadState = .loaded
        vm.lastPersistedSnapshot = vm.currentSnapshot
        return vm
    }

    // MARK: - Intents (expert-only)

    /// Called by `ExpertiseEditorSheet` after a successful save. Updates
    /// the in-memory display list so the settings screen's inline chip
    /// strip reflects the change without waiting for its own reload.
    func applyExpertiseEdits(_ tags: [ExpertiseTagItem]) {
        expertiseEntries = tags.enumerated().map { index, tag in
            ExpertProfileData.ExpertiseTagEntry(
                id: tag.id,
                label: tag.label,
                isPrimary: index == 0,
                categoryId: tag.categoryId
            )
        }
    }

    // MARK: - Photo loading + upload

    /// Called from `.onChange(of: selectedPhoto)`. Decodes the picked image
    /// locally, shows it optimistically, then uploads the raw bytes to
    /// `POST /user/profile/avatar`.
    func loadSelectedPhoto() async {
        guard let item = selectedPhoto,
              let data = try? await item.loadTransferable(type: Data.self),
              let ui = UIImage(data: data) else { return }

        withAnimation { profileImage = Image(uiImage: ui) }

        let jpegData = ui.jpegData(compressionQuality: 0.85) ?? data
        await uploadAvatar(data: jpegData)
    }

    private func uploadAvatar(data: Data) async {
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }
        do {
            _ = try await api.uploadAvatar(imageData: data)
        } catch {
            avatarUploadError = error.userMessage
        }
    }

    // MARK: - Load

    /// Fetches `/user/profile` and hydrates fields. Idempotent — skips
    /// when already loaded so preview seeds aren't clobbered. Auto-save
    /// is dedup'd against the loaded snapshot so this initial hydration
    /// doesn't trigger a no-op PATCH.
    func load() async {
        if case .loaded = loadState { return }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        loadState = .loading
        do {
            let response = try await api.getUserProfile()
            hydrate(from: response.data)
            lastPersistedSnapshot = currentSnapshot
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }

        // Refresh the expert-scoped profile so `expertiseEntries` +
        // `meetingUrl` reflect the latest server state. Silent on
        // failure — the cached copy (if any) stays displayed. Re-baseline
        // the snapshot AFTER the meeting-url hydration so `.onChange`
        // firing on the just-loaded value doesn't trip a no-op PATCH.
        try? await userManager.refreshExpertProfile()
        expertiseEntries = userManager.expertProfile?.expertiseTags ?? expertiseEntries
        meetingUrl = userManager.expertProfile?.professionalDetails.meetingUrl ?? meetingUrl
        lastPersistedSnapshot = currentSnapshot
    }

    private func hydrate(from data: UserProfileData) {
        let personal = data.personalDetails
        let professional = data.professionalDetails
        let location = data.location
        firstName = personal.firstName ?? ""
        lastName = personal.lastName ?? ""
        phone = personal.phone ?? ""
        bio = personal.bio ?? ""
        avatarUrl = personal.avatarUrl
        jobTitle = professional.jobTitle ?? ""
        company = professional.company ?? ""
        city = location.city ?? ""
        state = location.stateProvince ?? ""
        country = location.country ?? ""
        languages = data.languages.compactMap(\.label)
    }

    // MARK: - Auto-save (client fields → PATCH /user/profile)

    /// Called from the view whenever a client-side field changes. Cancels
    /// any pending save and schedules a fresh one after the debounce window.
    /// Short-circuits if the current state matches what we last persisted —
    /// this prevents the initial `.onChange` firing after `load()` from
    /// PATCHing the just-fetched values back to the server.
    func scheduleAutoSave() {
        autoSaveTask?.cancel()
        if didAutoSave { didAutoSave = false }

        guard currentSnapshot != lastPersistedSnapshot else { return }

        autoSaveTask = Task { [weak self] in
            guard let debounce = self?.autoSaveDebounce else { return }
            try? await Task.sleep(nanoseconds: debounce)
            guard !Task.isCancelled else { return }
            await self?.performAutoSave()
        }
    }

    private func performAutoSave() async {
        // `email` is 403 on this endpoint, so it's omitted. `languages` is
        // skipped because the VM stores display strings and the server needs
        // `language_ids` — wire once a picker sources IDs from GET /meta/languages.
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

        let snapshotAtSaveTime = currentSnapshot
        let trimmedMeetingUrl = meetingUrl.trimmingCharacters(in: .whitespacesAndNewlines)

        isAutoSaving = true
        defer { isAutoSaving = false }
        do {
            _ = try await api.updateUserProfile(body)

            // Meeting URL lives on the expert-scoped record — `PATCH /user/profile`
            // doesn't carry it, so it needs a second call. Fired unconditionally
            // whenever the snapshot changed; the server treats an unchanged
            // meeting_url as a no-op merge.
            let expertBody = UpdateExpertProfileRequest(
                personalInfo: nil,
                professionalDetails: .init(
                    jobTitle: nil,
                    company: nil,
                    education: nil,
                    meetingUrl: trimmedMeetingUrl
                ),
                locationDetails: nil,
                languages: nil,
                expertiseTags: nil
            )
            _ = try await api.updateExpertProfile(expertBody)
            try? await userManager.refreshExpertProfile()

            lastPersistedSnapshot = snapshotAtSaveTime
            withAnimation(.easeOut(duration: 0.25)) { didAutoSave = true }
        } catch {
            autoSaveError = error.userMessage
        }
    }

    /// Concatenated view of the auto-save-tracked fields. Used to dedup
    /// the debounced save against the server's known state.
    private var currentSnapshot: String {
        [firstName, lastName, phone, bio, jobTitle, company, meetingUrl, city, state, country]
            .joined(separator: "|")
    }

    // MARK: - Error mapping

}
