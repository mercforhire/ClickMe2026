//
//  ExpertDashboardView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Navigation routes

private enum ExpertDashboardRoute: Hashable {
    case pendingRequests
    case calendar
    case availability
    case editTopics
    case profileSettings
}

// MARK: - Expert Home View

struct ExpertDashboardView: View {

    @StateObject private var viewModel: ExpertDashboardViewModel
    @State private var path: [ExpertDashboardRoute] = []

    // MARK: Design tokens — Luminous Dark

    private let bg = Color(red: 0.075, green: 0.075, blue: 0.075)
    private let cardBg = Color(red: 0.110, green: 0.110, blue: 0.115)
    private let cardBorder = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let pendingBg = Color(red: 0.078, green: 0.145, blue: 0.100)
    private let pendingBdr = Color(red: 0.155, green: 0.290, blue: 0.200)
    private let sessionBg = Color(red: 0.095, green: 0.120, blue: 0.100)
    private let toolBg = Color(red: 0.100, green: 0.110, blue: 0.110)
    private let toolIconBg = Color(red: 0.130, green: 0.155, blue: 0.138)
    private let brandGreen = Color(red: 0.267, green: 0.965, blue: 0.592)
    private let onSurface = Color(red: 0.898, green: 0.886, blue: 0.882)
    private let onSurfaceVar = Color(red: 0.580, green: 0.640, blue: 0.610)
    private let onPrimary = Color(red: 0.000, green: 0.224, blue: 0.114)

    // MARK: Init

    init(viewModel: ExpertDashboardViewModel = ExpertDashboardViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                bg.ignoresSafeArea()
                content
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.reload() }
            .navigationDestination(for: ExpertDashboardRoute.self) { route in
                destination(for: route)
            }
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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                heroHeader
                pendingBanner
                todaysSessions
                expertTools
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 48)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(onSurface)
            Text("Loading dashboard…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(onSurfaceVar)
            Text("Couldn't load dashboard")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(onSurfaceVar)
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
                    .background(Capsule().fill(brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Destination router

    @ViewBuilder
    private func destination(for route: ExpertDashboardRoute) -> some View {
        switch route {
        case .pendingRequests:
            IncomingRequestsView()
        case .calendar:
            UpcomingBookingsView()
        case .availability:
            AvailiabilitySettingsView()
        case .editTopics:
            TopicsSetupView()
        case .profileSettings:
            ExpertProfileSettingsView()
        }
    }

    // MARK: - Hero header

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DASHBOARD OVERVIEW")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(onSurfaceVar)
                .tracking(1.4)

            Text("Hello, \(greetingName)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(onSurface)
        }
    }

    private var greetingName: String {
        let first = viewModel.expertFirstName
        let last = viewModel.expertLastName
        if first.isEmpty && last.isEmpty { return "there" }
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Pending banner

    private var pendingBanner: some View {
        Button { path.append(.pendingRequests) } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(brandGreen.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "bell.badge")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(brandGreen)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(viewModel.pendingCount) Pending Requests")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(brandGreen)
                    Text("Review and confirm new bookings")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(onSurfaceVar)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(brandGreen)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(pendingBg)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(pendingBdr, lineWidth: 1))
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    // MARK: - Today's Sessions

    private var todaysSessions: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Sessions")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(onSurface)
                Spacer()
                Button { path.append(.calendar) } label: {
                    Text("View Calendar")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(brandGreen)
                }
                .buttonStyle(.plain)
            }

            if viewModel.todaysSessions.isEmpty {
                emptyTodaysSessions
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.todaysSessions, id: \.bookingId) { session in
                        sessionCard(for: session)
                    }
                }
            }
        }
    }

    private var emptyTodaysSessions: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(onSurfaceVar)
            Text("No sessions today")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(onSurface)
            Text("Enjoy the breather — new bookings will show up here.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(onSurfaceVar)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(sessionBg)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(cardBorder, lineWidth: 1))
        )
    }

    private func sessionCard(for session: ExpertBookingItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Client row
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: session.client.avatarUrl ?? "")) { phase in
                    switch phase {
                    case let .success(img): img.resizable().scaledToFill()
                    default:
                        ZStack {
                            Color(red: 0.12, green: 0.18, blue: 0.14)
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.15))
                        }
                    }
                }
                .frame(width: 42, height: 42)
                .clipShape(Circle())
                .overlay(Circle().stroke(brandGreen.opacity(0.50), lineWidth: 1))

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.client.name ?? "Client")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(onSurface)
                    Text(session.session.topic ?? "")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(onSurfaceVar)
                }

                Spacer()

                if viewModel.isStartingNow(session) {
                    Text("STARTING NOW")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(onPrimary)
                        .tracking(0.5)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(brandGreen)
                            .shadow(color: brandGreen.opacity(0.55), radius: 6))
                }
            }

            // Time
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(onSurfaceVar)
                Text(viewModel.timeLabel(session))
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(onSurface)
            }

            // Join Session button — enabled only when the server says we can
            // (`actions.canJoin`) so the button doesn't lead to a rejected
            // request outside the join window.
            Button {
                // TODO: wire join flow via AgoraManager once the expert-side
                // in-app call handshake is fully wired.
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Join Session")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(brandGreen.opacity(session.actions.canJoin ? 1.0 : 0.55))
                        .shadow(
                            color: brandGreen.opacity(session.actions.canJoin ? 0.45 : 0),
                            radius: 14, x: 0, y: 4
                        )
                )
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(!session.actions.canJoin)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(sessionBg)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(cardBorder, lineWidth: 1))
        )
    }

    // MARK: - Expert Tools

    private var expertTools: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Expert Tools")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(onSurface)

            // "Payouts" tile is deliberately omitted until a backend
            // payouts / withdrawal endpoint ships (financial data hidden
            // per current product decision).
            let tools: [(String, String, ExpertDashboardRoute)] = [
                ("calendar.badge.clock", "Availability", .availability),
                ("pencil.and.list.clipboard", "Edit Topics", .editTopics),
                ("gearshape", "Profile Settings", .profileSettings),
                ("calendar", "Bookings", .calendar),
            ]

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 14
            ) {
                ForEach(tools, id: \.1) { icon, label, route in
                    toolCell(icon: icon, label: label) { path.append(route) }
                }
            }
        }
    }

    private func toolCell(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(toolIconBg)
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(brandGreen)
                }
                Text(label)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(onSurface)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(toolBg)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(cardBorder, lineWidth: 1))
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

// MARK: - Previews

#Preview("Expert Home") {
    ExpertDashboardView(viewModel: .previewSeed())
        .preferredColorScheme(.dark)
}

#Preview("Empty Today") {
    ExpertDashboardView(
        viewModel: .previewSeed(pendingCount: 0, todaysSessions: [])
    )
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return ExpertDashboardView()
        .preferredColorScheme(.dark)
}
