//
//  ClientProfileView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import PhotosUI
import SwiftUI

// MARK: - Models

struct ClientBookingHistory: Identifiable {
    let id = UUID()
    let title: String
    let status: BookingHistoryStatus
    let date: String
    let amount: Int
}

enum BookingHistoryStatus {
    case upcoming, completed, cancelled

    var label: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var icon: String {
        switch self {
        case .upcoming: return "calendar"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .upcoming: return Color(red: 0.267, green: 0.965, blue: 0.592)
        case .completed: return Color(red: 0.267, green: 0.965, blue: 0.592)
        case .cancelled: return Color(red: 1.000, green: 0.706, blue: 0.671)
        }
    }
}

// MARK: - Client Profile View

struct ClientProfileView: View {

    @StateObject private var viewModel: ClientProfileViewModel

    // MARK: Inits

    init(viewModel: ClientProfileViewModel = ClientProfileViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    /// Convenience init mirroring the prior signature so existing call sites
    /// that pass individual content fields keep compiling.
    init(
        name: String = "Sophia Carter",
        email: String = "sophia.carter@example.com",
        bio: String = "Passionate about connecting with experts and learning new skills.",
        bookingHistory: [ClientBookingHistory] = ClientProfileViewModel.defaultBookingHistory
    ) {
        self.init(
            viewModel: ClientProfileViewModel(
                name: name,
                email: email,
                bio: bio,
                bookingHistory: bookingHistory
            )
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ClientProfileBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ClientProfileAvatar(
                        selectedPhoto: $viewModel.selectedPhoto,
                        profileImage: $viewModel.profileImage,
                        glowPulse: viewModel.glowPulse
                    )
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                    ClientProfileNameBadge(name: viewModel.name)
                        .padding(.bottom, 32)

                    ClientProfilePersonalInfo(
                        name: $viewModel.name,
                        email: $viewModel.email,
                        bio: $viewModel.bio
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)

                    ClientProfileBookingHistory(bookingHistory: viewModel.bookingHistory)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 48)
                }
            }
        }
        .navigationTitle("Client Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ClientProfileBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.startGlowPulse() }
    }
}

// MARK: - Preview harness

private enum ClientProfilePreviewRoute: Hashable {
    case defaultProfile
    case noBookings
}

/// Wraps the client-profile screen inside a NavigationStack with a dummy
/// "My Clients" parent already pushed, so the system back chevron renders
/// in the canvas.
private struct ClientProfilePreviewHarness: View {
    let route: ClientProfilePreviewRoute
    @State private var path: [ClientProfilePreviewRoute]

    init(route: ClientProfilePreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Active clients")
                NavigationLink("Sophia Carter", value: route)
            }
            .navigationTitle("My Clients")
            .navigationDestination(for: ClientProfilePreviewRoute.self) { dest in
                switch dest {
                case .defaultProfile:
                    ClientProfileView()
                case .noBookings:
                    ClientProfileView(
                        name: "Elena Rodriguez",
                        email: "elena@example.com",
                        bio: "Entrepreneur and product strategist.",
                        bookingHistory: []
                    )
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Client Profile") {
    ClientProfilePreviewHarness(route: .defaultProfile)
        .preferredColorScheme(.dark)
}

#Preview("No Bookings") {
    ClientProfilePreviewHarness(route: .noBookings)
        .preferredColorScheme(.dark)
}
