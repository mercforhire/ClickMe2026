//
//  ClientProfileHomeViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ClientProfileHomeViewModel: ObservableObject {

    // MARK: Header content

    @Published var name: String
    @Published var email: String
    @Published var avatarURL: String
    @Published var isOnline: Bool

    // MARK: Load state

    @Published var hasLoadedHeader: Bool

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Inits

    /// Runtime init — starts with empty header text; `.task { load() }`
    /// hydrates from `GET /user/profile`.
    init(api: ClickMeAPI = .shared) {
        self.name = ""
        self.email = ""
        self.avatarURL = ""
        self.isOnline = true
        self.hasLoadedHeader = false
        self.api = api
    }

    /// Preview seam — seeds header content so the canvas can render without
    /// hitting the network.
    static func previewSeed(
        name: String = "Alex Rivera",
        email: String = "alex.design@clickme.app",
        avatarURL: String = "https://randomuser.me/api/portraits/women/44.jpg",
        isOnline: Bool = true
    ) -> ClientProfileHomeViewModel {
        let vm = ClientProfileHomeViewModel()
        vm.name = name
        vm.email = email
        vm.avatarURL = avatarURL
        vm.isOnline = isOnline
        vm.hasLoadedHeader = true
        return vm
    }

    // MARK: - Load

    /// Idempotent. Silent on failure — the header just remains with whatever
    /// content it already had (which is fine for a hub screen).
    func loadHeader() async {
        if hasLoadedHeader { return }
        do {
            let response = try await api.getUserProfile()
            let data = response.data
            let personal = data.personalDetails
            let composed = [personal.firstName, personal.lastName]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            name = composed.isEmpty ? "Your Profile" : composed
            email = personal.email ?? ""
            avatarURL = personal.avatarUrl ?? ""
            hasLoadedHeader = true
        } catch {
            // Non-fatal — the hub still works with empty header text.
        }
    }

    // MARK: - Actions

    func logOut() {
        UserManager.shared.logout()
    }
}
