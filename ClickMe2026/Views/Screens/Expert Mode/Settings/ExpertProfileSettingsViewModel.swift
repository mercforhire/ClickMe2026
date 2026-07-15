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

    // MARK: Expert-only sections (local state)

    var expertiseTags: [ExpertiseTagChip]
    var newTopic: String

    var rates: [HourlyRateItem]
    var freeConsultation: Bool

    var availabilityExpanded: Bool
    var availability: [AvailabilitySlot]

    // MARK: Save state (for the expert-only Save button)

    var isSaving: Bool = false
    var didSave: Bool = false

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
        rates: [HourlyRateItem] = [
            HourlyRateItem(topic: "Business Strategy", rate: 50),
            HourlyRateItem(topic: "Marketing", rate: 60),
            HourlyRateItem(topic: "Product Management", rate: 70),
        ],
        freeConsultation: Bool = true,
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
        self.rates = rates
        self.freeConsultation = freeConsultation
        self.availabilityExpanded = availabilityExpanded
        self.availability = availability
        self.api = api
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

    /// Local-only save-button used by the expert-only sections. The
    /// client-side fields already round-trip via auto-save.
    func save() {
        guard !isSaving, !didSave else { return }
        withAnimation { isSaving = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self.isSaving = false
                self.didSave = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                withAnimation { self?.didSave = false }
            }
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
            avatarUploadError = Self.errorMessage(for: error)
        }
    }

    // MARK: - Auto-save (client fields → PATCH /user/profile)

    /// Called from the view whenever a client-side field changes. Cancels
    /// any pending save and schedules a fresh one after the debounce window.
    func scheduleAutoSave() {
        autoSaveTask?.cancel()
        if didAutoSave { didAutoSave = false }

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

        isAutoSaving = true
        defer { isAutoSaving = false }
        do {
            _ = try await api.updateUserProfile(body)
            withAnimation(.easeOut(duration: 0.25)) { didAutoSave = true }
        } catch {
            autoSaveError = Self.errorMessage(for: error)
        }
    }

    // MARK: - Error mapping

    private static func errorMessage(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
