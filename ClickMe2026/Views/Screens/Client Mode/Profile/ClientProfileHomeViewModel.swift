//
//  ClientProfileHomeViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class ClientProfileHomeViewModel: ObservableObject {

    // MARK: Header content

    @Published var name: String
    @Published var email: String
    @Published var avatarURL: String
    @Published var isOnline: Bool

    // MARK: Dependencies

    private let api: ClickMeAPI
    private let userManager: UserManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: Inits

    /// Runtime init — seeds immediately from `UserManager.profile`
    /// (which restores from the on-disk cache on cold launch), then
    /// subscribes so subsequent `refreshProfile()` calls or edits from
    /// other screens propagate in real time.
    init(userManager: UserManager = .shared, api: ClickMeAPI = .shared) {
        self.userManager = userManager
        self.api = api
        self.name = ""
        self.email = ""
        self.avatarURL = ""
        self.isOnline = true

        apply(profile: userManager.profile)
        userManager.$profile
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.apply(profile: $0) }
            .store(in: &cancellables)
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
        return vm
    }

    // MARK: - Load

    /// Cache-first, revalidate always. The view already renders whatever
    /// `UserManager.profile` had at init time (cached or nil); this call
    /// hits `GET /user/profile` and lets the sink propagate any change.
    /// Silent on failure — the header keeps its cached content.
    func loadHeader() async {
        try? await userManager.refreshProfile()
    }

    // MARK: - Actions

    func logOut() {
        userManager.logout()
    }

    // MARK: - Private

    private func apply(profile: UserProfileData?) {
        guard let personal = profile?.personalDetails else { return }
        let composed = [personal.firstName, personal.lastName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        name = composed.isEmpty ? "Your Profile" : composed
        email = personal.email ?? ""
        avatarURL = personal.avatarUrl ?? ""
    }
}
