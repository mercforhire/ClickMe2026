//
//  NotificationSettingsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-29.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class NotificationSettingsViewModel: ObservableObject {

    // MARK: Sections
    @Published var sections: [NotificationSection]

    // MARK: Quiet hours
    @Published var quietHoursEnabled: Bool
    @Published var quietStart: String
    @Published var quietEnd: String
    @Published var showStartPicker: Bool
    @Published var showEndPicker: Bool

    // MARK: Save state
    @Published var isSaving: Bool
    @Published var didSave: Bool

    let quietTimes: [String]

    init(
        sections: [NotificationSection] = NotificationSettingsViewModel.defaultSections,
        quietHoursEnabled: Bool = true,
        quietStart: String = "10:00 PM",
        quietEnd: String = "7:00 AM",
        showStartPicker: Bool = false,
        showEndPicker: Bool = false,
        isSaving: Bool = false,
        didSave: Bool = false,
        quietTimes: [String] = NotificationSettingsViewModel.defaultQuietTimes
    ) {
        self.sections = sections
        self.quietHoursEnabled = quietHoursEnabled
        self.quietStart = quietStart
        self.quietEnd = quietEnd
        self.showStartPicker = showStartPicker
        self.showEndPicker = showEndPicker
        self.isSaving = isSaving
        self.didSave = didSave
        self.quietTimes = quietTimes
    }

    // MARK: Actions

    /// Run the saving → saved animation choreography.
    /// Networking is intentionally disabled while testing the app flow.
    func saveChanges() {
        guard !isSaving, !didSave else { return }
        withAnimation { isSaving = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
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

    func presentStartPicker() {
        guard quietHoursEnabled else { return }
        showStartPicker = true
    }

    func presentEndPicker() {
        guard quietHoursEnabled else { return }
        showEndPicker = true
    }

    // MARK: Defaults

    static let defaultSections: [NotificationSection] = [
        NotificationSection(title: "Messages", settings: [
            NotificationSetting(title: "New Messages", subtitle: "In-app, Email, Push", isOn: true),
            NotificationSetting(title: "Message Replies", subtitle: "In-app, Email, Push", isOn: true),
        ]),
        NotificationSection(title: "Bookings", settings: [
            NotificationSetting(title: "Booking Requests", subtitle: "In-app, Email, Push", isOn: true),
            NotificationSetting(title: "Booking Confirmations", subtitle: "In-app, Email, Push", isOn: true),
            NotificationSetting(title: "Booking Cancellations", subtitle: "In-app, Email, Push", isOn: false),
            NotificationSetting(title: "Booking Reminders", subtitle: "In-app, Email, Push", isOn: true),
        ]),
        NotificationSection(title: "Promotions", settings: [
            NotificationSetting(title: "Special Offers", subtitle: "In-app, Email, Push", isOn: true),
            NotificationSetting(title: "Updates & News", subtitle: "In-app, Email, Push", isOn: true),
        ]),
    ]

    static let defaultQuietTimes: [String] = [
        "6:00 PM", "7:00 PM", "8:00 PM", "9:00 PM", "10:00 PM", "11:00 PM",
        "12:00 AM", "1:00 AM", "2:00 AM", "3:00 AM",
        "5:00 AM", "6:00 AM", "7:00 AM", "8:00 AM", "9:00 AM",
    ]
}
