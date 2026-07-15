//
//  ClientProfileViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-02.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class ClientProfileViewModel: ObservableObject {

    // MARK: Form fields
    @Published var name: String
    @Published var email: String
    @Published var bio: String

    // MARK: Photo picker
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var profileImage: Image?

    // MARK: Animation
    @Published var glowPulse: Bool

    // MARK: Content
    @Published var bookingHistory: [ClientBookingHistory]

    init(
        name: String = "Sophia Carter",
        email: String = "sophia.carter@example.com",
        bio: String = "Passionate about connecting with experts and learning new skills.",
        bookingHistory: [ClientBookingHistory] = ClientProfileViewModel.defaultBookingHistory,
        selectedPhoto: PhotosPickerItem? = nil,
        profileImage: Image? = nil,
        glowPulse: Bool = false
    ) {
        self.name = name
        self.email = email
        self.bio = bio
        self.bookingHistory = bookingHistory
        self.selectedPhoto = selectedPhoto
        self.profileImage = profileImage
        self.glowPulse = glowPulse
    }

    // MARK: Actions

    func startGlowPulse() {
        glowPulse = true
    }

    /// Load the newly-selected pasteboard photo into `profileImage`.
    func loadSelectedPhoto() async {
        guard
            let item = selectedPhoto,
            let data = try? await item.loadTransferable(type: Data.self),
            let ui = UIImage(data: data)
        else { return }
        withAnimation { profileImage = Image(uiImage: ui) }
    }

    // MARK: Defaults

    static let defaultBookingHistory: [ClientBookingHistory] = [
        ClientBookingHistory(title: "SEO Audit Review", status: .upcoming, date: "June 5, 2024", amount: 200),
        ClientBookingHistory(title: "Digital Marketing Strategy", status: .completed, date: "May 12, 2024", amount: 250),
        ClientBookingHistory(title: "Brand Growth Session", status: .completed, date: "Apr 3, 2024", amount: 150),
    ]
}
