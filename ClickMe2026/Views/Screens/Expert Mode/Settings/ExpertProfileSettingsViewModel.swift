//
//  ExpertProfileSettingsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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
    /// Catalog languages (id + label) in the order the user picked them.
    /// Only these ids are sent as `language_ids`.
    var languageItems: [LanguageItem]
    /// Id-less (custom) languages the server already holds. The picker cannot
    /// add or remove them, but a languages save is a full replace, so they are
    /// always sent back as `custom_languages` or the save would delete them.
    private(set) var customLanguages: [String] = []

    /// Display labels for the language row: catalog languages, then customs.
    var languages: [String] { languageItems.map(\.label) + customLanguages }

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

    /// The fields as they last were on the server. Set after `load()` hydrates
    /// from `GET /user/profile` and after each successful PATCH. Used by
    /// `scheduleAutoSave` to skip no-op saves — critical during the
    /// initial-load render when `.onChange` would otherwise PATCH the
    /// just-fetched values right back — and by `makeProfileUpdateBody()` to send
    /// only what changed (G-05-6).
    @ObservationIgnored
    private var baseline = ProfileSettingsSnapshot()

    /// The meeting link the server holds, trimmed. It lives on the expert-scoped
    /// record, so it has its own baseline apart from `baseline`.
    @ObservationIgnored
    private var baselineMeetingUrl = ""

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
        bio: String = "Passionate expert with over 10 years of experience helping brands grow.",
        jobTitle: String = "Digital Marketing Expert",
        company: String = "Self-Employed",
        meetingUrl: String = "",
        city: String = "San Francisco",
        state: String = "CA",
        country: String = "USA",
        languageItems: [LanguageItem] = [
            LanguageItem(id: "en", label: "English"),
            LanguageItem(id: "es", label: "Spanish")
        ],
        selectedPhoto: PhotosPickerItem? = nil,
        profileImage: Image? = nil,
        api: ClickMeAPI = .shared,
        userManager: UserManager = .shared
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.bio = bio
        self.jobTitle = jobTitle
        self.company = company
        self.meetingUrl = meetingUrl
        self.city = city
        self.state = state
        self.country = country
        self.languageItems = languageItems
        self.selectedPhoto = selectedPhoto
        self.profileImage = profileImage
        self.api = api
        self.userManager = userManager
        self.expertiseEntries = userManager.expertProfile?.expertiseTags ?? []
        self.meetingUrl = userManager.expertProfile?.professionalDetails.meetingUrl ?? meetingUrl
        self.baseline = currentSnapshot
        self.baselineMeetingUrl = trimmedMeetingUrl
    }

    /// Preview seam — installs canned data as if the fetch had succeeded.
    static func previewSeed() -> ExpertProfileSettingsViewModel {
        let vm = ExpertProfileSettingsViewModel()
        vm.loadState = .loaded
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
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }

        // Refresh the expert-scoped profile so `expertiseEntries` +
        // `meetingUrl` reflect the latest server state. Silent on
        // failure — the cached copy (if any) stays displayed. Re-baseline
        // the meeting link AFTER its hydration so `.onChange` firing on the
        // just-loaded value doesn't trip a no-op PATCH.
        try? await userManager.refreshExpertProfile()
        expertiseEntries = userManager.expertProfile?.expertiseTags ?? expertiseEntries
        meetingUrl = userManager.expertProfile?.professionalDetails.meetingUrl ?? meetingUrl
        baselineMeetingUrl = trimmedMeetingUrl
    }

    func hydrate(from data: UserProfileData) {
        let personal = data.personalDetails
        let professional = data.professionalDetails
        let location = data.location
        firstName = personal.firstName ?? ""
        lastName = personal.lastName ?? ""
        bio = personal.bio ?? ""
        avatarUrl = personal.avatarUrl
        jobTitle = professional.jobTitle ?? ""
        company = professional.company ?? ""
        city = location.city ?? ""
        state = location.stateProvince ?? ""
        country = location.country ?? ""
        // An entry with an id is a catalog language; an id-less entry carries
        // its `custom_label` as the label (userProfile.controller.js).
        languageItems = data.languages.compactMap { entry in
            guard let id = entry.id, let label = entry.label else { return nil }
            return LanguageItem(id: id, label: label)
        }
        customLanguages = data.languages.compactMap { entry in
            entry.id == nil ? entry.label : nil
        }
        baseline = currentSnapshot
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

        guard currentSnapshot != baseline || trimmedMeetingUrl != baselineMeetingUrl else { return }

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
        currentSnapshot.patch(from: baseline)
    }

    /// Builds the `PATCH /expert/profile` body for the meeting link, or nil when
    /// the trimmed link equals what the server holds.
    func makeExpertProfileUpdateBody() -> UpdateExpertProfileRequest? {
        let link = trimmedMeetingUrl
        guard link != baselineMeetingUrl else { return nil }
        // Coerce empty → nil so the key is dropped from the JSON body.
        // The server URL-validates this field and 422s on `""` — every
        // expert who hasn't yet set a Skype/Zoom link (which is most of
        // them) previously saw a "Couldn't save changes" alert on the
        // very first field edit because the expert PATCH always
        // carried `meeting_url: ""`. Omitting the key relies on the
        // partial-merge contract ("missing key = leave untouched").
        let meetingUrlForPatch: String? = link.isEmpty ? nil : link
        return UpdateExpertProfileRequest(
            personalInfo: nil,
            professionalDetails: .init(
                jobTitle: nil,
                company: nil,
                education: nil,
                meetingUrl: meetingUrlForPatch
            ),
            locationDetails: nil,
            languages: nil,
            expertiseTags: nil
        )
    }

    private func performAutoSave() async {
        // Both bodies are built before any request, so an edit made while a
        // request is in flight is not recorded as saved.
        let body = makeProfileUpdateBody()
        let expertBody = makeExpertProfileUpdateBody()
        guard body != nil || expertBody != nil else { return }
        let sentMeetingUrl = trimmedMeetingUrl

        isAutoSaving = true
        defer { isAutoSaving = false }
        do {
            if let body {
                _ = try await api.updateUserProfile(body)
                baseline = baseline.merging(body)
            }
            // Meeting URL lives on the expert-scoped record — `PATCH /user/profile`
            // doesn't carry it, so it needs its own call, sent only when the
            // link changed.
            if let expertBody {
                _ = try await api.updateExpertProfile(expertBody)
                baselineMeetingUrl = sentMeetingUrl
            }
            try? await userManager.refreshExpertProfile()

            withAnimation(.easeOut(duration: 0.25)) { didAutoSave = true }
        } catch {
            autoSaveError = error.userMessage
        }
    }

    /// The auto-saved fields as a trimmed snapshot, for the equality check and
    /// for building the changed-groups body. The meeting link is left out; it
    /// has its own baseline.
    private var currentSnapshot: ProfileSettingsSnapshot {
        ProfileSettingsSnapshot(
            firstName: firstName, lastName: lastName, bio: bio,
            jobTitle: jobTitle, company: company,
            city: city, stateProvince: state, country: country,
            languageIds: languageItems.map(\.id),
            customLanguages: customLanguages
        )
    }

    private var trimmedMeetingUrl: String {
        meetingUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Set when the user has cleared a first name the profile already holds.
    /// The empty name is never sent (the server keeps the saved one), so this
    /// is what tells the user why. Plan 05-20 shows it under the field.
    var firstNameError: String? { currentSnapshot.firstNameError(from: baseline) }

    /// Same as `firstNameError`, for the last name.
    var lastNameError: String? { currentSnapshot.lastNameError(from: baseline) }

    // MARK: - Error mapping

}
