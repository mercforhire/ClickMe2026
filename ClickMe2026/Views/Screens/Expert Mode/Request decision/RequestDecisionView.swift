//
//  RequestDecisionView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Display model

/// Local display model — populated from `BookingRequestDetail` at load
/// time. Fields the server doesn't send (`isReturning`, `isOnline`,
/// `isHighPriority`) were dropped; `sessionType` was replaced with the
/// server's `MeetingType` enum verbatim so the labels stay in sync.
struct IncomingRequest: Identifiable {
    /// Server `request_id`. Non-random so navigation stays stable.
    let id: UUID
    let clientName: String
    let topic: String
    let date: String
    let time: String
    let duration: String // e.g. "60m"
    let earnings: Double
    let currency: String
    let meetingType: MeetingType
    let imageURL: String
    let clientNote: String?
    /// True when the source list marked this request expired. Suppresses
    /// the Accept/Decline footer.
    let isExpired: Bool

    var timeRange: String {
        "\(time) (\(duration))"
    }

    /// Human label — `"In-App Voice"` or `"Skype/Zoom"`.
    var meetingTypeLabel: String {
        switch meetingType {
        case .inAppVoice: return "In-App Voice"
        case .skypeZoom:  return "Skype/Zoom"
        }
    }

    /// SF Symbol icon that pairs with the label above.
    var meetingTypeIcon: String {
        switch meetingType {
        case .inAppVoice: return "phone"
        case .skypeZoom:  return "video"
        }
    }
}

// MARK: - Sample data

extension IncomingRequest {
    /// Empty stub the runtime init points at while the real detail fetch
    /// is in flight. Never shown — the view routes loading state to a
    /// spinner instead.
    static let placeholder = IncomingRequest(
        id: UUID(),
        clientName: "",
        topic: "",
        date: "",
        time: "",
        duration: "",
        earnings: 0,
        currency: "USD",
        meetingType: .inAppVoice,
        imageURL: "",
        clientNote: nil,
        isExpired: false
    )

    static let samples: [IncomingRequest] = [
        IncomingRequest(
            id: UUID(),
            clientName: "Elena Rodriguez",
            topic: "Marketing Strategy Review",
            date: "Oct 24, 2026",
            time: "02:30 PM",
            duration: "60m",
            earnings: 180.00,
            currency: "USD",
            meetingType: .inAppVoice,
            imageURL: "https://randomuser.me/api/portraits/women/44.jpg",
            clientNote: nil,
            isExpired: false
        ),
        IncomingRequest(
            id: UUID(),
            clientName: "Dr. Simon K.",
            topic: "Executive Leadership",
            date: "Oct 26, 2026",
            time: "11:00 AM",
            duration: "90m",
            earnings: 275.00,
            currency: "USD",
            meetingType: .skypeZoom,
            imageURL: "https://randomuser.me/api/portraits/men/55.jpg",
            clientNote: nil,
            isExpired: false
        ),
    ]
}

// MARK: - Booking Request Detail View

struct RequestDecisionView: View {
    @StateObject private var viewModel: RequestDecisionViewModel

    // MARK: Init

    /// Runtime init — hydrates from
    /// `GET /expert/booking-requests/:id`. `isExpired` is inherited from
    /// the list so the footer can hide Accept/Decline on stale requests.
    init(requestId: UUID, isExpired: Bool = false) {
        _viewModel = StateObject(wrappedValue: RequestDecisionViewModel(
            requestId: requestId,
            isExpired: isExpired
        ))
    }

    /// Preview / test seam — inject a pre-configured view model.
    init(viewModel: RequestDecisionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Brand.surface.ignoresSafeArea()
            content

            // ── Bottom-sheet overlays ──
            if viewModel.showAcceptSheet {
                sheetOverlay {
                    RequestDecisionAcceptSheet(
                        request: viewModel.request,
                        onCancel: viewModel.dismissSheets,
                        onConfirm: { message in
                            Task { await viewModel.confirmAccept(message: message) }
                        }
                    )
                }
            }

            if viewModel.showDeclineSheet {
                sheetOverlay {
                    RequestDecisionDeclineSheet(
                        request: viewModel.request,
                        onCancel: viewModel.dismissSheets,
                        onDecline: { reasonCode, reasonText in
                            Task {
                                await viewModel.confirmDecline(
                                    reasonCode: reasonCode,
                                    reasonText: reasonText
                                )
                            }
                        }
                    )
                }
            }
        }
        .navigationTitle("Booking Details")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { viewModel.submitError != nil },
                set: { if !$0 { viewModel.submitError = nil } }
            ),
            presenting: viewModel.submitError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
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
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    RequestDecisionClientHeader(request: viewModel.request) {
                        viewModel.viewProfileTapped()
                    }
                    RequestDecisionDetailsCard(request: viewModel.request)

                    if viewModel.isExpired {
                        expiredBanner
                    } else {
                        RequestDecisionMessageSection(clientMessage: viewModel.clientMessage)
                        RequestDecisionEarningsSection(potentialEarnings: viewModel.potentialEarnings)
                    }
                }
                .padding(16)
                .padding(.bottom, 8)
            }

            // Footer is hidden for expired requests — nothing to accept
            // or decline once the window has closed.
            if !viewModel.isExpired {
                Divider().background(Brand.overlayWhite10)
                RequestDecisionActionFooter(
                    isAccepted: viewModel.isAccepted,
                    isDeclined: viewModel.isDeclined,
                    onMessage: viewModel.messageTapped,
                    onDeclineTap: viewModel.openDeclineSheet,
                    onAcceptTap: viewModel.openAcceptSheet
                )
            }
        }
    }

    /// Banner shown in place of the client message + earnings + footer
    /// when the request has already expired.
    private var expiredBanner: some View {
        VStack(spacing: 6) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 26, weight: .light))
                .foregroundColor(Brand.overlayWhite60)
            Text("This request has expired")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Brand.onSurface)
            Text("You can no longer accept or decline this booking.")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(Brand.overlayWhite60)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Brand.overlayWhite05)
        )
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(Brand.onSurface)
            Text("Loading request…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(Brand.overlayWhite60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(Brand.overlayWhite60)
            Text("Couldn't load request")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Brand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(Brand.overlayWhite60)
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

    // MARK: - Sheet overlay wrapper (consistent positioning)

    private func sheetOverlay<Sheet: View>(@ViewBuilder sheet: () -> Sheet) -> some View {
        ZStack(alignment: .bottom) {
            // Scrim
            Color.black.opacity(0.60)
                .ignoresSafeArea()
                .onTapGesture { viewModel.dismissSheets() }

            // Sheet slides up from the bottom
            sheet()
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .ignoresSafeArea()
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: viewModel.showAcceptSheet)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: viewModel.showDeclineSheet)
    }
}

// MARK: - Live-fetch bootstrap

/// Resolves a real request UUID from `GET /expert/booking-requests` and
/// hands it to `RequestDecisionView(requestId:)`.
private struct LiveFetchRequestDecisionBootstrap: View {
    @State private var resolved: (id: UUID, isExpired: Bool)?
    @State private var errorMessage: String?

    var body: some View {
        if let resolved {
            RequestDecisionView(requestId: resolved.id, isExpired: resolved.isExpired)
        } else if let errorMessage {
            Text(errorMessage)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        } else {
            ProgressView("Resolving request…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .task { await resolveRequest() }
        }
    }

    private func resolveRequest() async {
        do {
            let response = try await ClickMeAPI.shared.getBookingRequests(page: 1, limit: 5)
            guard let first = response.data.requests.first else {
                errorMessage = "No booking requests on this account."
                return
            }
            let now = Date()
            let isExpired = first.status == "expired"
                || (first.expiresAt.map { $0 <= now } ?? false)
            resolved = (first.requestId, isExpired)
        } catch {
            errorMessage = error.userMessage
        }
    }
}

// MARK: - Previews

#Preview("Default") {
    PreviewNavHarness(parentText: "Dashboard", navTitle: "Incoming requests", rowTitle: "Booking request") {
        RequestDecisionView(viewModel: RequestDecisionViewModel())
    }
    .preferredColorScheme(.dark)
}

#Preview("Expired") {
    PreviewNavHarness(parentText: "Dashboard", navTitle: "Incoming requests", rowTitle: "Booking request") {
        RequestDecisionView(viewModel: RequestDecisionViewModel(isExpired: true))
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return PreviewNavHarness(parentText: "Dashboard", navTitle: "Incoming requests", rowTitle: "First booking request") {
        LiveFetchRequestDecisionBootstrap()
    }
    .preferredColorScheme(.dark)
}

#Preview("Accept Sheet open") {
    AcceptSheetPreview()
        .preferredColorScheme(.dark)
}

#Preview("Decline Sheet open") {
    DeclineSheetPreview()
        .preferredColorScheme(.dark)
}

/// Preview wrappers to show sheets immediately
private struct AcceptSheetPreview: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Brand.surface.ignoresSafeArea()
            RequestDecisionAcceptSheet(
                request: IncomingRequest.samples[0],
                onCancel: {},
                onConfirm: { _ in }
            )
        }
    }
}

private struct DeclineSheetPreview: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Brand.surface.ignoresSafeArea()
            RequestDecisionDeclineSheet(
                request: IncomingRequest.samples[0],
                onCancel: {},
                onDecline: { _, _ in }
            )
        }
    }
}
