//
//  SignupProfilePhotoViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class SignupProfilePhotoViewModel: ObservableObject {

    // MARK: Photo state
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var profileImage: Image?
    @Published var zoomScale: CGFloat = 0.5
    /// Raw JPEG bytes of the currently-picked photo. Held so `save()`
    /// can upload the exact image that's on-screen; a re-encode from
    /// `Image` back to Data isn't trivially reversible.
    private var pendingJpegData: Data?

    // MARK: Submission state
    @Published var isSaving: Bool = false
    @Published var isSaved: Bool = false
    @Published var saveError: String?

    var hasPhoto: Bool { profileImage != nil }

    // MARK: Dependencies

    private let accumulator: SignupAccumulator?
    private let api: ClickMeAPI

    // MARK: Init

    init(
        selectedPhoto: PhotosPickerItem? = nil,
        profileImage: Image? = nil,
        zoomScale: CGFloat = 0.5,
        accumulator: SignupAccumulator? = nil,
        api: ClickMeAPI = .shared
    ) {
        self.selectedPhoto = selectedPhoto
        self.profileImage = profileImage
        self.zoomScale = zoomScale
        self.accumulator = accumulator
        self.api = api
    }

    // MARK: - Photo handling

    /// Loads the image data for the currently selected `PhotosPickerItem`.
    /// Re-encodes to JPEG so `save()` can hand a stable, compact byte
    /// buffer to `POST /user/profile/avatar`.
    func loadSelectedPhoto() async {
        guard let item = selectedPhoto else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }

        // Re-encode for a smaller upload than the raw HEIC/PNG.
        let jpeg = uiImage.jpegData(compressionQuality: 0.85) ?? data
        pendingJpegData = jpeg

        withAnimation(.easeInOut(duration: 0.3)) {
            profileImage = Image(uiImage: uiImage)
            zoomScale = 0.5
        }
    }

    func removePhoto() {
        withAnimation(.easeInOut(duration: 0.25)) {
            profileImage = nil
            selectedPhoto = nil
            pendingJpegData = nil
            zoomScale = 0.5
        }
        // Clear the accumulator so the checklist reflects the removal.
        accumulator?.avatarUrl = nil
    }

    // MARK: - Save

    /// Uploads the pending photo via `POST /user/profile/avatar` and
    /// mirrors the returned URL onto the accumulator. Skips the network
    /// call in the preview / design path (no accumulator wired) so the
    /// canvas still animates the "Saved" state.
    func save() async {
        // Preview path — no accumulator, canned animation.
        guard accumulator != nil else {
            isSaving = true
            try? await Task.sleep(for: .seconds(0.8))
            isSaving = false
            isSaved = true
            return
        }

        // Runtime path — real upload.
        guard let data = pendingJpegData else {
            // Nothing to upload (user hit Save with no photo picked).
            // Treat as no-op success so the flow can continue.
            isSaved = true
            return
        }

        saveError = nil
        isSaving = true
        defer { isSaving = false }
        do {
            let response = try await api.uploadAvatar(imageData: data)
            accumulator?.avatarUrl = response.data.avatarUrl
            withAnimation(.easeInOut(duration: 0.25)) { isSaved = true }
        } catch {
            saveError = error.userMessage
        }
    }

    // MARK: - Error mapping

}
