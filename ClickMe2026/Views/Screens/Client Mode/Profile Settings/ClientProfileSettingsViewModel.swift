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
    @Published var email: String
    @Published var phone: String
    @Published var bio: String

    // MARK: Professional
    @Published var jobTitle: String
    @Published var company: String
    @Published var location: String
    @Published var location2: String
    @Published var city: String
    @Published var state: String
    @Published var country: String
    @Published var education: String
    @Published var languages: [String]

    // MARK: Photo
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var profileImage: Image?

    // MARK: Sheet state
    @Published var showProfSheet: Bool
    @Published var showLangSheet: Bool

    // MARK: Save state
    @Published var isSaving: Bool
    @Published var didSave: Bool

    init(
        firstName: String = "Sophia",
        lastName: String = "Carter",
        email: String = "sophia.carter@example.com",
        phone: String = "+1 234 567 890",
        bio: String = "Passionate digital marketing expert with over 10 years of experience helping brands grow their online presence.",
        jobTitle: String = "Digital Marketing Expert",
        company: String = "Self-Employed",
        location: String = "San Francisco",
        location2: String = "Self-Employed",
        city: String = "San Francisco",
        state: String = "CA",
        country: String = "USA",
        education: String = "Master of Science in Marketing",
        languages: [String] = ["English", "Spanish"],
        selectedPhoto: PhotosPickerItem? = nil,
        profileImage: Image? = nil,
        showProfSheet: Bool = false,
        showLangSheet: Bool = false,
        isSaving: Bool = false,
        didSave: Bool = false
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.bio = bio
        self.jobTitle = jobTitle
        self.company = company
        self.location = location
        self.location2 = location2
        self.city = city
        self.state = state
        self.country = country
        self.education = education
        self.languages = languages
        self.selectedPhoto = selectedPhoto
        self.profileImage = profileImage
        self.showProfSheet = showProfSheet
        self.showLangSheet = showLangSheet
        self.isSaving = isSaving
        self.didSave = didSave
    }

    // MARK: Photo loading

    func loadSelectedPhoto() async {
        guard let item = selectedPhoto,
              let data = try? await item.loadTransferable(type: Data.self),
              let ui = UIImage(data: data) else { return }
        withAnimation { profileImage = Image(uiImage: ui) }
    }

    // MARK: Save action

    func save() {
        guard !isSaving, !didSave else { return }
        withAnimation { isSaving = true }
        // Networking disabled while testing the app flow.
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
}
