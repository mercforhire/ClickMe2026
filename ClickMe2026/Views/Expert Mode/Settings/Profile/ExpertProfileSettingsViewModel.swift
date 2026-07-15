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

@Observable
final class ExpertProfileSettingsViewModel {
    // MARK: Basics

    var name: String
    var email: String

    // MARK: Photo

    var selectedPhoto: PhotosPickerItem?
    var profileImage: Image?

    // MARK: Expertise

    var expertiseTags: [ExpertiseTagChip]
    var newTopic: String

    // MARK: Rates

    var rates: [HourlyRateItem]
    var freeConsultation: Bool

    // MARK: Availability

    var availabilityExpanded: Bool
    var availability: [AvailabilitySlot]

    // MARK: Additional info

    var additionalExpanded: Bool
    var bio: String
    var location: String
    var languages: String

    // MARK: Save state

    var isSaving: Bool = false
    var didSave: Bool = false

    // MARK: Init

    init(
        name: String = "Ethan Carter",
        email: String = "ethan@gmail.com",
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
        additionalExpanded: Bool = true,
        bio: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. It...",
        location: String = "ethan@gmail.com",
        languages: String = "English, Language, spoken"
    ) {
        self.name = name
        self.email = email
        self.expertiseTags = expertiseTags
        self.newTopic = newTopic
        self.rates = rates
        self.freeConsultation = freeConsultation
        self.availabilityExpanded = availabilityExpanded
        self.availability = availability
        self.additionalExpanded = additionalExpanded
        self.bio = bio
        self.location = location
        self.languages = languages
    }

    // MARK: Intents

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

    func toggleAdditional() {
        withAnimation(.easeInOut(duration: 0.25)) {
            additionalExpanded.toggle()
        }
    }

    func loadSelectedPhoto() async {
        guard let item = selectedPhoto,
              let data = try? await item.loadTransferable(type: Data.self),
              let ui = UIImage(data: data)
        else { return }
        await MainActor.run {
            withAnimation { profileImage = Image(uiImage: ui) }
        }
    }

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
}
