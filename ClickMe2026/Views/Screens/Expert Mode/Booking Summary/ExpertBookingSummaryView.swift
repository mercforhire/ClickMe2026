//
//  ExpertBookingSummaryView.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Expert Booking Summary View

/// Pushed when the expert taps an upcoming session card. Renders the
/// booking as seen from the expert's perspective: client identity,
/// session schedule + topic + fee, prep notes (client's message at
/// booking time), and a Message-client CTA that hands off to the shell
/// via `openChatThread`.
///
/// Data source: `GET /expert/bookings/:id/details` → `ExpertBookingDetail`.
struct ExpertBookingSummaryView: View {

    @StateObject private var viewModel: ExpertBookingSummaryViewModel

    @Environment(\.openChatThread) private var openChatThread
    @Environment(\.homeNavigationPath) private var homeNavigationPath

    // MARK: Init

    init(bookingId: UUID) {
        _viewModel = StateObject(wrappedValue: ExpertBookingSummaryViewModel(bookingId: bookingId))
    }

    /// Preview / test seam.
    init(viewModel: ExpertBookingSummaryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Brand.surface.ignoresSafeArea()
            content
        }
        .navigationTitle("Booking Summary")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
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
            if let detail = viewModel.detail {
                loadedContent(detail: detail)
            } else {
                loadingContent
            }
        }
    }

    private func loadedContent(detail: ExpertBookingDetail) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                clientHeader(detail: detail)
                statusBadge(detail: detail)
                detailsCard(detail: detail)

                if let notes = detail.preparationNotes.text?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                   !notes.isEmpty
                {
                    prepNotesCard(text: notes)
                }

                if detail.actions.canMessage {
                    messageClientButton(detail: detail)
                        .padding(.top, 4)
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Client header

    private func clientHeader(detail: ExpertBookingDetail) -> some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: detail.client.avatarUrl ?? "")) { phase in
                switch phase {
                case let .success(img): img.resizable().scaledToFill()
                default:
                    ZStack {
                        Color(red: 0.14, green: 0.20, blue: 0.16)
                        Image(systemName: "person.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(detail.client.name ?? "Client")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Brand.onSurface)

                Button {
                    guard let navPath = homeNavigationPath else { return }
                    navPath.push(HomeRoute.peerProfile(
                        userId: detail.client.id,
                        name: detail.client.name ?? "Client",
                        avatarURL: detail.client.avatarUrl ?? ""
                    ))
                } label: {
                    Text("View Profile")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Brand.primary)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    // MARK: - Status badge

    private func statusBadge(detail: ExpertBookingDetail) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Brand.primary)
                .frame(width: 7, height: 7)
                .shadow(color: Brand.primary.opacity(0.75), radius: 4)
            Text(detail.status.label.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundColor(Brand.onSurface)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Brand.overlayWhite05)
                .overlay(Capsule().stroke(Brand.outlineVariant, lineWidth: 1))
        )
    }

    // MARK: - Details card

    private func detailsCard(detail: ExpertBookingDetail) -> some View {
        VStack(spacing: 0) {
            detailRow(label: "Date") {
                Text(viewModel.dateLabel)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Brand.onSurface)
            }
            rowDivider
            detailRow(label: "Time") {
                Text(viewModel.timeRangeLabel)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Brand.onSurface)
            }
            rowDivider
            detailRow(label: "Duration") {
                Text(viewModel.durationLabel)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Brand.onSurface)
            }
            rowDivider
            detailRow(label: "Topic") {
                Text(detail.session.topicTitle ?? "Session")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Brand.onSurface)
                    .multilineTextAlignment(.trailing)
            }
            rowDivider
            detailRow(label: "Meeting Type") {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.meetingTypeIcon)
                        .font(.system(size: 14))
                        .foregroundColor(Brand.onSurface)
                    Text(viewModel.meetingTypeLabel)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Brand.onSurface)
                }
            }
            rowDivider
            detailRow(label: "Consultation Fee") {
                Text(viewModel.feeLabel)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Brand.primary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Brand.overlayWhite05)
        )
    }

    private func detailRow<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(Brand.overlayWhite60)
            Spacer()
            content()
        }
        .padding(.vertical, 12)
    }

    private var rowDivider: some View {
        Rectangle().fill(Brand.overlayWhite10).frame(height: 1)
    }

    // MARK: - Prep notes

    private func prepNotesCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Client's message")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(0.6)
                .foregroundColor(Brand.overlayWhite60)
            Text(text)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(Brand.onSurface)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Brand.overlayWhite05)
        )
    }

    // MARK: - Message CTA

    private func messageClientButton(detail: ExpertBookingDetail) -> some View {
        Button {
            handleMessage(detail: detail)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text("Message Client")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(Brand.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Brand.primary)
                    .shadow(color: Brand.primary.opacity(0.50), radius: 14, x: 0, y: 4)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    /// `initiateChat` is idempotent — repeat calls return the existing thread.
    /// No-op when rendered outside a shell (previews).
    private func handleMessage(detail: ExpertBookingDetail) {
        guard let openChatThread else { return }
        let clientId = detail.client.id
        let peerName = detail.client.name ?? "Client"
        let peerAvatarURL = detail.client.avatarUrl ?? ""
        Task {
            guard let response = try? await ClickMeAPI.shared.initiateChat(peerId: clientId)
            else { return }
            openChatThread(
                threadId: response.data.threadId,
                peerName: peerName,
                peerAvatarURL: peerAvatarURL
            )
        }
    }

    // MARK: - Load / error states

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(Brand.onSurface)
            Text("Loading booking…")
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
            Text("Couldn't load booking")
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

// MARK: - Live-fetch bootstrap

/// Picks the first upcoming expert booking to preview the summary against
/// a real record. Swallows errors verbosely so the preview surface is
/// useful when the seed account has no upcoming sessions.
private struct LiveFetchExpertBookingSummaryBootstrap: View {
    @State private var bookingId: UUID?
    @State private var errorMessage: String?

    var body: some View {
        if let bookingId {
            ExpertBookingSummaryView(bookingId: bookingId)
        } else if let errorMessage {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.white.opacity(0.6))
                Text("Preview bootstrap failed")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(errorMessage)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Brand.surface.ignoresSafeArea())
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Brand.surface.ignoresSafeArea())
                .task { await bootstrap() }
        }
    }

    private func bootstrap() async {
        ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
        do {
            let response = try await ClickMeAPI.shared.getExpertBookings(page: 1, limit: 20)
            if let soonest = response.data.bookings.sorted(by: { $0.session.startTime < $1.session.startTime }).first {
                bookingId = soonest.bookingId
                return
            }
            errorMessage = "No expert bookings on this account."
        } catch {
            errorMessage = error.userMessage
        }
    }
}

// MARK: - Previews

#Preview("Live Fetch") {
    NavigationStack {
        LiveFetchExpertBookingSummaryBootstrap()
    }
    .preferredColorScheme(.dark)
}
