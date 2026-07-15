//
//  ReadyToStartCallView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Connect via Skype View

struct ReadyToStartCallView: View {
    @StateObject private var viewModel: ReadyToStartCallViewModel

    var onContactSupport: () -> Void
    var onMessageParticipant: () -> Void

    @Environment(\.openURL) private var openURL

    // MARK: Init

    /// Runtime init — fetches the Skype/Zoom meeting link via
    /// `POST /bookings/:id/join`. Tapping "Join" opens the returned URL
    /// via the system `openURL` environment action.
    init(
        bookingId: UUID,
        onContactSupport: @escaping () -> Void = {},
        onMessageParticipant: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: ReadyToStartCallViewModel(bookingId: bookingId))
        self.onContactSupport = onContactSupport
        self.onMessageParticipant = onMessageParticipant
    }

    /// Preview / test seam.
    init(
        viewModel: ReadyToStartCallViewModel = ReadyToStartCallViewModel(),
        onContactSupport: @escaping () -> Void = {},
        onMessageParticipant: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onContactSupport = onContactSupport
        self.onMessageParticipant = onMessageParticipant
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ReadyToStartCallBrand.bg.ignoresSafeArea()
            GreenGlowBlobLayer().ignoresSafeArea()
            content
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .navigationTitle("Connect via Skype")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ReadyToStartCallBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.runEntryAnimation() }
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
            VStack(spacing: 32) {
                ReadyToStartCallSkypeIcon(
                    scale: viewModel.iconScale,
                    opacity: viewModel.iconOpacity,
                    glowPulse: viewModel.glowPulse
                )

                ReadyToStartCallHeadline(
                    opacity: viewModel.bodyOpacity,
                    yOffset: viewModel.bodyOffset
                )

                ReadyToStartCallJoinButton(
                    opacity: viewModel.bodyOpacity,
                    yOffset: viewModel.bodyOffset,
                    action: openMeetingLink
                )

                ReadyToStartCallLinkCard(
                    skypeLink: viewModel.skypeLink,
                    didCopy: viewModel.didCopy,
                    opacity: viewModel.bodyOpacity,
                    yOffset: viewModel.bodyOffset,
                    onCopy: { viewModel.copyLink() }
                )

                ReadyToStartCallSupportRow(
                    opacity: viewModel.bodyOpacity,
                    yOffset: viewModel.bodyOffset,
                    onContactSupport: onContactSupport
                )

                ReadyToStartCallMessageButton(
                    opacity: viewModel.bodyOpacity,
                    yOffset: viewModel.bodyOffset,
                    action: onMessageParticipant
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 48)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(ReadyToStartCallBrand.onSurface)
            Text("Preparing meeting link…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(ReadyToStartCallBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(ReadyToStartCallBrand.onSurfaceVar)
            Text("Couldn't join call")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(ReadyToStartCallBrand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(ReadyToStartCallBrand.onSurfaceVar)
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
                    .background(Capsule().fill(ReadyToStartCallBrand.brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func openMeetingLink() {
        guard let url = URL(string: viewModel.skypeLink) else { return }
        openURL(url)
    }
}

// MARK: - Live-fetch bootstrap

/// Resolves a real Skype/Zoom booking id from `GET /expert/bookings` and
/// hands off to `ReadyToStartCallView` with it. Skips in-app-voice bookings
/// (they use the Agora call screen instead).
private struct LiveFetchReadyToStartCallBootstrap: View {
    @State private var resolvedBookingId: UUID?
    @State private var errorMessage: String?

    var body: some View {
        if let id = resolvedBookingId {
            ReadyToStartCallView(bookingId: id)
        } else if let errorMessage {
            Text(errorMessage)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        } else {
            ProgressView("Resolving booking…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .task { await resolve() }
        }
    }

    private func resolve() async {
        do {
            let response = try await ClickMeAPI.shared.getExpertBookings(page: 1, limit: 20)
            let now = Date()
            let picked = response.data.bookings.first {
                $0.session.meetingType == .skypeZoom && $0.session.endTime > now
            }
            guard let picked else {
                errorMessage = "No upcoming Skype/Zoom bookings on this account."
                return
            }
            resolvedBookingId = picked.bookingId
        } catch {
            errorMessage = error.userMessage
        }
    }
}

// MARK: - Previews

#Preview("Connect via Skype") {
    PreviewNavHarness(parentText: "Session details", navTitle: "Upcoming session", rowTitle: "Ready to join") {
        ReadyToStartCallView(viewModel: .previewSeed())
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return PreviewNavHarness(parentText: "Session details", navTitle: "Upcoming session", rowTitle: "Ready to join") {
        LiveFetchReadyToStartCallBootstrap()
    }
    .preferredColorScheme(.dark)
}
