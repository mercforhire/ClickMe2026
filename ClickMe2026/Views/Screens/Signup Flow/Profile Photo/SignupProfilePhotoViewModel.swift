//
//  SignupProfilePhotoViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-22.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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
    /// The photo picked this session. Held so `save()` can render the square
    /// the preview shows at the current `zoomScale` (SIGN-05); an `Image`
    /// can't be turned back into pixels. Stays nil for a downloaded avatar.
    private var pickedImage: UIImage?

    // MARK: Submission state
    @Published var isSaving: Bool = false
    @Published var isSaved: Bool = false
    @Published var saveError: String?

    var hasPhoto: Bool { profileImage != nil }

    /// Whether the zoom slider can change what Save uploads. Only a newly
    /// picked photo can be re-rendered; a downloaded avatar is display-only.
    var canZoom: Bool { pickedImage != nil }

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

    /// If the accumulator was hydrated from `GET /expert/profile` with a
    /// previously-uploaded avatar URL, download the image so the ring
    /// renders the same photo the user saw before quitting. No-op when
    /// there's no URL (fresh flow) or when a local image is already set
    /// (user just picked one this session).
    func loadExistingAvatarIfNeeded() async {
        guard profileImage == nil,
              let urlString = accumulator?.avatarUrl,
              let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let uiImage = UIImage(data: data) else { return }
            profileImage = Image(uiImage: uiImage)
        } catch {
            // Silent — the user can still re-pick a photo if this fails.
        }
    }

    /// Loads the image data for the currently selected `PhotosPickerItem`
    /// and shows it in the ring. `save()` crops and encodes it later.
    func loadSelectedPhoto() async {
        guard let item = selectedPhoto else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }
        usePickedImage(uiImage)
    }

    /// Makes `image` the photo to upload: shows it in the ring and resets the
    /// zoom to its default.
    func usePickedImage(_ image: UIImage) {
        pickedImage = image
        withAnimation(.easeInOut(duration: 0.3)) {
            profileImage = Image(uiImage: image)
            zoomScale = 0.5
        }
    }

    /// Removes the photo both locally AND server-side (`DELETE /user/profile/avatar`).
    /// Server-side removal matters because `hydrate(from:)` on the next
    /// launch would otherwise re-populate `accumulator.avatarUrl` from
    /// `GET /expert/profile` and `loadExistingAvatarIfNeeded()` would
    /// re-fetch the image — effectively undoing this action. Only
    /// commits the local clear on 2xx. Preview path (no accumulator)
    /// skips the network call and just clears local state so the
    /// canvas still behaves.
    func removePhoto() async {
        guard accumulator != nil else {
            performLocalRemove()
            return
        }

        saveError = nil
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await api.deleteAvatar()
            performLocalRemove()
        } catch {
            saveError = error.userMessage
        }
    }

    private func performLocalRemove() {
        withAnimation(.easeInOut(duration: 0.25)) {
            profileImage = nil
            selectedPhoto = nil
            pickedImage = nil
            zoomScale = 0.5
        }
        // Clear the accumulator so the checklist reflects the removal.
        accumulator?.avatarUrl = nil
    }

    // MARK: - Save

    /// Uploads the square the preview shows (the picked photo cropped at the
    /// current zoom, see `ProfilePhotoCropper`) via `POST /user/profile/avatar`
    /// and mirrors the returned URL onto the accumulator. Skips the network
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
        guard let pickedImage else {
            // Nothing to upload (user hit Save with no photo picked, or kept
            // the downloaded avatar). Treat as no-op success so the flow can
            // continue.
            isSaved = true
            return
        }

        guard let data = ProfilePhotoCropper.squareCrop(pickedImage, zoom: zoomScale) else {
            saveError = "Couldn't prepare this photo. Please choose another one."
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
