//
//  ClientProfileSettingsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

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

    // MARK: Dependencies

    private let api: ClickMeAPI

    init(
        firstName: String = "Sophia",
        lastName: String = "Carter",
        phone: String = "+1 234 567 890",
        bio: String = "Passionate digital marketing expert with over 10 years of experience helping brands grow their online presence.",
        jobTitle: String = "Digital Marketing Expert",
        company: String = "Self-Employed",
        city: String = "San Francisco",
        state: String = "CA",
        country: String = "USA",
        languages: [String] = ["English", "Spanish"],
        selectedPhoto: PhotosPickerItem? = nil,
        profileImage: Image? = nil,
        showProfSheet: Bool = false,
        showLangSheet: Bool = false,
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
        self.showProfSheet = showProfSheet
        self.showLangSheet = showLangSheet
        self.api = api
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
        } catch {
            avatarUploadError = Self.errorMessage(for: error)
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

    // MARK: - Auto-save

    /// Called by the view whenever an editable field changes. Cancels any
    /// pending save and schedules a fresh one after the debounce window —
    /// so continued typing coalesces into a single API call once the user
    /// pauses.
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
            withAnimation(.easeOut(duration: 0.25)) { didAutoSave = true }
        } catch {
            autoSaveError = Self.errorMessage(for: error)
        }
    }
}
