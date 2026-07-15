//
//  ClientProfileView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Booking history display model

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

/// Expert-facing read-only view of one of the expert's clients. Fetches
/// `GET /expert/clients/:id` and filters `GET /expert/bookings` down to
/// this client's booking history.
struct ClientProfileView: View {

    @StateObject private var viewModel: ClientProfileViewModel

    // MARK: Inits

    /// Runtime init — requires the client's UUID so the view can fetch.
    init(clientId: UUID) {
        _viewModel = StateObject(wrappedValue: ClientProfileViewModel(clientId: clientId))
    }

    /// Preview / seam init.
    init(viewModel: ClientProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ClientProfileBackground()
            content
        }
        .navigationTitle("Client Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ClientProfileBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .onAppear { viewModel.startGlowPulse() }
    }

    // MARK: - Content router

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            loadingContent
        case .failed(let message):
            errorContent(message: message)
        case .loaded:
            loadedContent
        }
    }

    private var loadedContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ClientProfileAvatar(
                    avatarUrl: viewModel.profile?.personalDetails.avatarUrl,
                    glowPulse: viewModel.glowPulse
                )
                .padding(.top, 16)
                .padding(.bottom, 20)

                ClientProfileNameBadge(name: displayName)
                    .padding(.bottom, 32)

                ClientProfilePersonalInfo(
                    bio: viewModel.profile?.personalDetails.bio,
                    city: viewModel.profile?.location.city,
                    stateProvince: viewModel.profile?.location.stateProvince,
                    country: viewModel.profile?.location.country,
                    timezone: viewModel.profile?.location.timezone,
                    languages: viewModel.profile?.languages ?? [],
                    memberSince: viewModel.profile?.memberSince
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 32)

                if let relationship = viewModel.profile?.relationship {
                    ClientProfileRelationshipCard(
                        totalSessions: relationship.totalSessions,
                        firstSessionDate: relationship.firstSessionDate,
                        lastSessionDate: relationship.lastSessionDate
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }

                if !viewModel.bookingHistory.isEmpty {
                    ClientProfileBookingHistory(bookingHistory: viewModel.bookingHistory)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 48)
                }
            }
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(ClientProfileBrand.onSurface)
            Text("Loading profile…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(ClientProfileBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(ClientProfileBrand.onSurfaceVar)
            Text("Couldn't load profile")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(ClientProfileBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(ClientProfileBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(ClientProfileBrand.brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Derived labels

    private var displayName: String {
        viewModel.profile?.personalDetails.fullName ?? "Client"
    }
}

// MARK: - Preview harness

private enum ClientProfilePreviewRoute: Hashable {
    case profile
}

private struct ClientProfilePreviewHarness: View {
    let viewModel: ClientProfileViewModel?
    let liveClientId: UUID?
    @State private var path: [ClientProfilePreviewRoute] = [.profile]

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Active clients")
                NavigationLink("Sophia Carter", value: ClientProfilePreviewRoute.profile)
            }
            .navigationTitle("My Clients")
            .navigationDestination(for: ClientProfilePreviewRoute.self) { _ in
                if let vm = viewModel {
                    ClientProfileView(viewModel: vm)
                } else if let clientId = liveClientId {
                    ClientProfileView(clientId: clientId)
                } else {
                    Text("No client")
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Client Profile") {
    ClientProfilePreviewHarness(
        viewModel: .previewSeed(),
        liveClientId: nil
    )
    .preferredColorScheme(.dark)
}

#Preview("No Bookings") {
    ClientProfilePreviewHarness(
        viewModel: .previewSeed(bookingHistory: []),
        liveClientId: nil
    )
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    // Replace with a real client UUID from your dev environment for a
    // real fetch. Kept as a fresh UUID here so the preview compiles.
    return ClientProfilePreviewHarness(
        viewModel: nil,
        liveClientId: UUID()
    )
    .preferredColorScheme(.dark)
}
