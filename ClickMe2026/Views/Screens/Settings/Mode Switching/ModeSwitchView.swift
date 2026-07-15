//
//  ModeSwitchView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-16.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Mode model

enum AppMode: CaseIterable {
    case client, expert

    var title: String {
        self == .client ? "Client Mode" : "Expert Mode"
    }

    var subtitle: String {
        self == .client ? "Find and book experts" : "Manage bookings and profile"
    }

    var description: String {
        self == .client
            ? "Browse a wide range of experts and book sessions that fit your needs."
            : "Manage your bookings, update your profile, and connect with clients."
    }

    var imageURL: String {
        self == .client
            ? "https://lh3.googleusercontent.com/aida-public/AB6AXuDI3SjPbx21Wdts7TMWgv_CqWdtUcqwuPXaXHb9DMU2O0Rljn0pm0O-kl0E0wIkcBKpf6s5u1wPq4jfo046C7jwHNU7pgnf79_g9alalALh7okJUcVmXqij8Bzi-SUpwJpNeBGRWBwYmor0scCIkT5QNPawfjd9q__Sw0C6wJcbiyqgVrHiSA2i2UvIr9bF9tbRQ93OxVENLBYd9EtqxLljRg8YVJEFMUmHaHIsjklbRxuDNbtaa8_aIeC-Gbjp1Xf7mH8JNEU2WIg"
            : "https://lh3.googleusercontent.com/aida-public/AB6AXuCjVb8uP0KYBs2wBlIAtZbo2N5YedP7bxXIu4lh2IQXx6o0UvKCwgjFz7VIsKgTAcGDowTOarvSRsUItcRjHdewbqsSoH-p_jZZ7VfMJmdWyUneMYbgjhIFHvBfNHYuXb1-kQzSRvCCsE-CtEzg1Dh8wIEaeURwlZPBQEfFtBMk4pzstItnSv-s07X-3w4Hl54DQ6AfKcdRAtCCj5BqgNdRBCZkGvVnV1GqkmVQchWUBS2J3f5I7XqppPsfmaTkkJJoKwKhEHIzafk"
    }
}

// MARK: - Mode Switcher View

struct ModeSwitchView: View {
    @StateObject private var viewModel: ModeSwitchViewModel

    var onConfirm: (AppMode) -> Void

    // MARK: Init

    init(
        viewModel: ModeSwitchViewModel = ModeSwitchViewModel(),
        onConfirm: @escaping (AppMode) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onConfirm = onConfirm
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ModeSwitchBrand.bgDark.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 14) {
                    ForEach(AppMode.allCases, id: \.title) { mode in
                        ModeSwitchCard(
                            mode: mode,
                            isActive: viewModel.selectedMode == mode,
                            onTap: { viewModel.select(mode) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)

                Spacer()

                ModeSwitchConfirmButton(
                    selectedMode: viewModel.selectedMode,
                    action: { onConfirm(viewModel.selectedMode) }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("Mode Switcher")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ModeSwitchBrand.bgDark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Previews

#Preview("Client Active") {
    PreviewNavHarness(parentText: "Account", navTitle: "Settings", rowTitle: "Mode Switcher") {
        ModeSwitchView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Expert Active") {
    PreviewNavHarness(parentText: "Account", navTitle: "Settings", rowTitle: "Mode Switcher") {
        ModeSwitchView()
    }
    .preferredColorScheme(.dark)
}
