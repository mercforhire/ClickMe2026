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
        case .upcoming: return Brand.primary
        case .completed: return Brand.primary
        case .cancelled: return Brand.error
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

// MARK: - Live-fetch bootstrap

/// Resolves a real client UUID by fetching `/expert/bookings` first, then
/// hands it to `ClientProfileView`.
private struct LiveFetchClientProfileBootstrap: View {
    @State private var resolvedClientId: UUID?
    @State private var errorMessage: String?

    var body: some View {
        if let clientId = resolvedClientId {
            ClientProfileView(clientId: clientId)
        } else if let errorMessage {
            VStack(spacing: 8) {
                Text("Couldn't resolve a client ID")
                    .font(.system(size: 15, weight: .semibold))
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        } else {
            ProgressView("Resolving client…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .task { await resolveClientId() }
        }
    }

    private func resolveClientId() async {
        do {
            let response = try await ClickMeAPI.shared.getExpertBookings(page: 1, limit: 5)
            guard let clientId = response.data.bookings.first?.client.id else {
                errorMessage = "No bookings on this account — can't derive a client ID for the live fetch."
                return
            }
            resolvedClientId = clientId
        } catch {
            errorMessage = error.userMessage
        }
    }
}

// MARK: - Previews

#Preview("Client Profile") {
    PreviewNavHarness(parentText: "Active clients", navTitle: "My Clients", rowTitle: "Sophia Carter") {
        ClientProfileView(viewModel: .previewSeed())
    }
    .preferredColorScheme(.dark)
}

#Preview("No Bookings") {
    PreviewNavHarness(parentText: "Active clients", navTitle: "My Clients", rowTitle: "Sophia Carter") {
        ClientProfileView(viewModel: .previewSeed(bookingHistory: []))
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return PreviewNavHarness(parentText: "Active clients", navTitle: "My Clients", rowTitle: "First booking's client") {
        LiveFetchClientProfileBootstrap()
    }
    .preferredColorScheme(.dark)
}
