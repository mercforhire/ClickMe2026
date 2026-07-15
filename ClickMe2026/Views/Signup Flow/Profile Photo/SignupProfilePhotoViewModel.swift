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

@MainActor
final class SignupProfilePhotoViewModel: ObservableObject {

    // MARK: Photo state
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var profileImage: Image?
    @Published var zoomScale: CGFloat = 0.5

    // MARK: Submission state
    @Published var isSaving: Bool = false
    @Published var isSaved: Bool = false

    var hasPhoto: Bool { profileImage != nil }

    init(
        selectedPhoto: PhotosPickerItem? = nil,
        profileImage: Image? = nil,
        zoomScale: CGFloat = 0.5
    ) {
        self.selectedPhoto = selectedPhoto
        self.profileImage = profileImage
        self.zoomScale = zoomScale
    }

    // MARK: - Photo handling

    /// Loads the image data for the currently selected `PhotosPickerItem`.
    func loadSelectedPhoto() async {
        guard let item = selectedPhoto else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            profileImage = Image(uiImage: uiImage)
            zoomScale = 0.5
        }
    }

    func removePhoto() {
        withAnimation(.easeInOut(duration: 0.25)) {
            profileImage = nil
            selectedPhoto = nil
            zoomScale = 0.5
        }
    }

    // MARK: - Save

    func save() async {
        isSaving = true
        try? await Task.sleep(for: .seconds(0.8))
        isSaving = false
        isSaved = true
    }
}
