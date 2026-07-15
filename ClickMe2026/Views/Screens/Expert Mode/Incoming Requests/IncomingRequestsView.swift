//
//  IncomingRequests.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//
import SwiftUI

// MARK: - Display model

struct BookingRequest: Identifiable {
    /// Server request UUID (`request_id`). Used for the route into
    /// `RequestDecisionView`.
    let id: UUID
    let clientName: String
    let clientImageURL: String
    let topic: String
    let dateTime: String
    let earnings: String
    let expiresInHours: Int
    /// True when `expiresInHours < 6` (and the request isn't already
    /// expired). Drives the amber avatar ring.
    let isHighPriority: Bool
    /// True when the server marked the request `expired` or `expiresAt`
    /// has already passed. Dimmed + labeled in the UI.
    let isExpired: Bool
}

// MARK: - Navigation push payload

/// Identifiable wrapper used with `.navigationDestination(item:)` so the
/// destination pushes into whatever NavigationStack is in scope — the
/// dashboard's outer stack in production, the preview harness's stack in
/// canvas. This screen deliberately does NOT own a NavigationStack so it
/// stays composable as a pushed destination.
///
/// Carries `isExpired` alongside the id so the detail screen can render
/// read-only (hide Accept/Decline) without a second fetch.
private struct PushedRequest: Hashable, Identifiable {
    let id: UUID
    let isExpired: Bool
}

// MARK: - Incoming Requests View

struct IncomingRequestsView: View {
    @StateObject private var viewModel: IncomingRequestsViewModel
    @State private var pushedRequest: PushedRequest?

    init(viewModel: IncomingRequestsViewModel = IncomingRequestsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Brand.surface.ignoresSafeArea()
            GreenGlowBlobLayer().ignoresSafeArea()
            content
        }
        .navigationTitle("Incoming requests")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .navigationDestination(item: $pushedRequest) { pushed in
            RequestDecisionView(requestId: pushed.id, isExpired: pushed.isExpired)
        }
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
        Group {
            if viewModel.requests.isEmpty {
                emptyContent
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(viewModel.requests) { request in
                            IncomingRequestCard(request: request) { tapped in
                                // Expired rows push the same decision screen —
                                // it renders read-only (no Accept/Decline
                                // footer) because we forward `isExpired`
                                // through the route payload.
                                pushedRequest = PushedRequest(
                                    id: tapped.id,
                                    isExpired: tapped.isExpired
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(Brand.onSurface)
            Text("Loading requests…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(Brand.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyContent: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 30, weight: .light))
                .foregroundColor(Brand.onSurfaceVariant)
            Text("No pending requests")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Brand.onSurface)
            Text("New bookings will show up here.")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(Brand.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(Brand.onSurfaceVariant)
            Text("Couldn't load requests")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Brand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(Brand.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Brand.onPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Brand.primary))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sample data

extension BookingRequest {
    static let samples: [BookingRequest] = [
        BookingRequest(
            id: UUID(),
            clientName: "Liam Carter",
            clientImageURL: "https://randomuser.me/api/portraits/men/55.jpg",
            topic: "Career Advice",
            dateTime: "Oct 15, 10:00 AM - 11:00 AM",
            earnings: "$75.00",
            expiresInHours: 14,
            isHighPriority: false,
            isExpired: false
        ),
        BookingRequest(
            id: UUID(),
            clientName: "Sarah Jones",
            clientImageURL: "https://randomuser.me/api/portraits/women/44.jpg",
            topic: "Design Review",
            dateTime: "Oct 16, 2:00 PM - 3:00 PM",
            earnings: "$120.00",
            expiresInHours: 1,
            isHighPriority: true,
            isExpired: false
        ),
        BookingRequest(
            id: UUID(),
            clientName: "Michael Chen",
            clientImageURL: "https://randomuser.me/api/portraits/men/32.jpg",
            topic: "Portfolio Feedback",
            dateTime: "Oct 17, 4:30 PM - 5:30 PM",
            earnings: "$90.00",
            expiresInHours: 0,
            isHighPriority: false,
            isExpired: true
        ),
    ]
}

// MARK: - Previews

#Preview("Incoming Requests") {
    PreviewNavHarness(parentText: "Dashboard", navTitle: "Expert", rowTitle: "Incoming requests") {
        IncomingRequestsView(viewModel: .previewSeed())
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty") {
    PreviewNavHarness(parentText: "Dashboard", navTitle: "Expert", rowTitle: "Incoming requests") {
        IncomingRequestsView(viewModel: .previewSeed(requests: []))
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return PreviewNavHarness(parentText: "Dashboard", navTitle: "Expert", rowTitle: "Incoming requests") {
        IncomingRequestsView()
    }
    .preferredColorScheme(.dark)
}
