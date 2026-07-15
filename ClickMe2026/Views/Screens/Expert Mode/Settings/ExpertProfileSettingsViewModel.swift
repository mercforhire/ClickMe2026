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
    var city: String
    var state: String
    /// ISO-3166-1 alpha-3 code (e.g. "USA") — matches server contract.
    var country: String
    var languages: [String]

    // MARK: Photo

    var selectedPhoto: PhotosPickerItem?
    var profileImage: Image?

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


    // MARK: Expert-only sections (local state)

    var expertiseTags: [ExpertiseTagChip]
    var newTopic: String

    var availabilityExpanded: Bool
    var availability: [AvailabilitySlot]

    // MARK: Dependencies

    @ObservationIgnored
    private let api: ClickMeAPI

    // MARK: Init

    init(
        firstName: String = "Ethan",
        lastName: String = "Carter",
        phone: String = "+1 234 567 890",
        bio: String = "Passionate expert with over 10 years of experience helping brands grow.",
        jobTitle: String = "Digital Marketing Expert",
        company: String = "Self-Employed",
        city: String = "San Francisco",
        state: String = "CA",
        country: String = "USA",
        languages: [String] = ["English", "Spanish"],
        selectedPhoto: PhotosPickerItem? = nil,
        profileImage: Image? = nil,
        expertiseTags: [ExpertiseTagChip] = [
            ExpertiseTagChip(name: "Business Strategy"),
            ExpertiseTagChip(name: "Marketing"),
        ],
        newTopic: String = "",
        availabilityExpanded: Bool = true,
        availability: [AvailabilitySlot] = [
            AvailabilitySlot(day: "Mon", columns: [true, false, false, false, false], timeRange: "9:00 AM - 5:00 PM"),
            AvailabilitySlot(day: "Tue", columns: [false, true, false, false, false], timeRange: "9:00 AM - 5:00 PM"),
            AvailabilitySlot(day: "Wed", columns: [true, true, false, false, false], timeRange: "9:00 AM - 5:00 PM"),
            AvailabilitySlot(day: "Fri", columns: [false, true, false, false, false], timeRange: "9:00 AM - 5:00 PM"),
        ],
        api: ClickMeAPI = .shared
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.bio = bio
        self.jobTitle = jobTitle
        self.company = company
        self.city = city
        self.state = state
        self.country = country
        self.languages = languages
        self.selectedPhoto = selectedPhoto
        self.profileImage = profileImage
        self.expertiseTags = expertiseTags
        self.newTopic = newTopic
        self.availabilityExpanded = availabilityExpanded
        self.availability = availability
        self.api = api
    }

    /// Preview seam — installs canned data as if the fetch had succeeded.
    static func previewSeed() -> ExpertProfileSettingsViewModel {
        let vm = ExpertProfileSettingsViewModel()
        vm.loadState = .loaded
        vm.lastPersistedSnapshot = vm.currentSnapshot
        return vm
    }

    // MARK: - Intents (expert-only)

    func addTopic() {
        let trimmed = newTopic.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            expertiseTags.append(ExpertiseTagChip(name: trimmed))
            newTopic = ""
        }
    }

    func toggleAvailability() {
        withAnimation(.easeInOut(duration: 0.25)) {
            availabilityExpanded.toggle()
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
    }

    private func hydrate(from data: UserProfileData) {
        let personal = data.personalDetails
        let professional = data.professionalDetails
        let location = data.location
        firstName = personal.firstName ?? ""
        lastName = personal.lastName ?? ""
        phone = personal.phone ?? ""
        bio = personal.bio ?? ""
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

        isAutoSaving = true
        defer { isAutoSaving = false }
        do {
            _ = try await api.updateUserProfile(body)
            lastPersistedSnapshot = snapshotAtSaveTime
            withAnimation(.easeOut(duration: 0.25)) { didAutoSave = true }
        } catch {
            autoSaveError = error.userMessage
        }
    }

    /// Concatenated view of the auto-save-tracked fields. Used to dedup
    /// the debounced save against the server's known state.
    private var currentSnapshot: String {
        [firstName, lastName, phone, bio, jobTitle, company, city, state, country]
            .joined(separator: "|")
    }

    // MARK: - Error mapping

}
