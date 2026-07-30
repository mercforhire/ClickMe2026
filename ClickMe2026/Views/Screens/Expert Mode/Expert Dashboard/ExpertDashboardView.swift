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
    case payouts
}

// MARK: - Expert Home View

struct ExpertDashboardView: View {

    @StateObject private var viewModel: ExpertDashboardViewModel
    /// Push path is provided by the enclosing `HomeExpertView` via
    /// `@Environment(\.homeNavigationPath)`. When rendered outside the
    /// shell (previews, tests) the fallback `_localPath` provides a
    /// self-contained NavigationStack so the screen still works.
    @Environment(\.homeNavigationPath) private var navPath
    @State private var _localPath: [ExpertDashboardRoute] = []
    @Environment(\.openURL) private var openURL

    /// Bound to `CallCenter.shared.joinError` — surfaces the alert on
    /// this screen when a join fails. Actual call presentation is
    /// hosted globally by `CallOverlayHost` on `HomeExpertView`.
    @ObservedObject private var callCenter = CallCenter.shared

    // MARK: Design tokens — Luminous Dark

    private let bg = Brand.surface
    private let cardBg = Color(red: 0.110, green: 0.110, blue: 0.115)
    private let cardBorder = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let pendingBg = Color(red: 0.078, green: 0.145, blue: 0.100)
    private let pendingBdr = Color(red: 0.155, green: 0.290, blue: 0.200)
    private let sessionBg = Color(red: 0.095, green: 0.120, blue: 0.100)
    private let toolBg = Color(red: 0.100, green: 0.110, blue: 0.110)
    private let toolIconBg = Color(red: 0.130, green: 0.155, blue: 0.138)
    private let brandGreen = Brand.primary
    private let onSurface = Brand.onSurface
    private let onSurfaceVar = Color(red: 0.580, green: 0.640, blue: 0.610)
    private let onPrimary = Brand.onPrimary

    // MARK: Init

    init(viewModel: ExpertDashboardViewModel = ExpertDashboardViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        Group {
            if navPath != nil {
                screenWithDestinations
            } else {
                NavigationStack(path: $_localPath) {
                    screenWithDestinations
                }
            }
        }
        // Stripe hands us a fresh single-use URL — open it immediately in
        // Safari (or the system default browser) and clear the field so a
        // subsequent onboarding tap gets a new URL.
        .onChange(of: viewModel.connectOnboardingURL) { _, url in
            guard let url else { return }
            openURL(url)
            viewModel.connectOnboardingURL = nil
        }
        .alert(
            "Couldn't open payout setup",
            isPresented: Binding(
                get: { viewModel.connectError != nil },
                set: { if !$0 { viewModel.connectError = nil } }
            ),
            presenting: viewModel.connectError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private var screenWithDestinations: some View {
        ZStack {
            bg.ignoresSafeArea()
            content
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .navigationDestination(for: ExpertDashboardRoute.self) { route in
            destination(for: route)
        }
        // Call surface is hosted globally by `CallOverlayHost` on
        // `HomeExpertView`. This screen just surfaces a join-failure
        // alert bound to CallCenter's shared error field.
        .alert(
            "Couldn't join session",
            isPresented: Binding(
                get: { callCenter.joinError != nil },
                set: { if !$0 { callCenter.joinError = nil } }
            ),
            presenting: callCenter.joinError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private func push(_ route: ExpertDashboardRoute) {
        if let navPath {
            navPath.push(route)
        } else {
            _localPath.append(route)
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
                financialSummary
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
            AvailabilitySettingsView()
        case .editTopics:
            TopicsSetupView()
        case .profileSettings:
            ExpertProfileSettingsView()
        case .payouts:
            PayoutsView()
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
        Button { push(.pendingRequests) } label: {
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
                Button { push(.calendar) } label: {
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

            // Join Session button — visible when the session is within
            // one hour of start (±60 min). Deliberately matches the
            // client-side `UpcomingBooking.isWithinJoinWindow` window
            // instead of the server's tighter `actions.canJoin` (~5 min)
            // so the button appears at the same time for both roles.
            // If the server refuses at tap time, `MeetingCallView`'s
            // `onJoinFailure` surfaces the reason on this screen.
            let inWindow = Self.isWithinJoinWindow(startTime: session.session.startTime)
            Button {
                CallCenter.shared.startCall(
                    bookingId: session.bookingId,
                    peerId: session.client.id,
                    peerName: session.client.name ?? "Client",
                    peerImageURL: session.client.avatarUrl ?? "",
                    topic: session.session.topic ?? "",
                    scheduledStart: session.session.startTime,
                    scheduledEnd: session.session.endTime
                )
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
                        .fill(brandGreen.opacity(inWindow ? 1.0 : 0.55))
                        .shadow(
                            color: brandGreen.opacity(inWindow ? 0.45 : 0),
                            radius: 14, x: 0, y: 4
                        )
                )
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(!inWindow)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(sessionBg)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(cardBorder, lineWidth: 1))
        )
    }

    /// Client-side join window used on both the dashboard's Join
    /// Session button and the Upcoming Sessions card. Matches the
    /// client-side `UpcomingBooking.isWithinJoinWindow` (±1 hour of
    /// start) — kept in sync so both roles get the same affordance
    /// timing. The server may reject at tap time if its own window is
    /// tighter, in which case `MeetingCallView.onJoinFailure` surfaces
    /// the reason.
    private static func isWithinJoinWindow(startTime: Date) -> Bool {
        let delta = startTime.timeIntervalSinceNow
        return delta <= 3600 && delta >= -3600
    }

    // MARK: - Financial Summary

    /// Section for the "This Week" earnings + "Available Payout" balance.
    /// Falls back to a Stripe Connect onboarding CTA when
    /// `payoutOnboardingRequired` is true (server returned 400
    /// NO_PAYOUT_METHOD / KYC_INCOMPLETE).
    private var financialSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Financial Summary")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(onSurface)

            if viewModel.payoutOnboardingRequired {
                onboardPayoutCard
            } else {
                balanceCard
            }
        }
    }

    /// The whole balance card is tappable — pushes the dedicated
    /// `PayoutsView` for the full breakdown. Payouts arrive automatically
    /// on Stripe's schedule; there is no manual withdrawal.
    private var balanceCard: some View {
        Button {
            push(.payouts)
        } label: {
            VStack(spacing: 18) {
                // Earnings row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("This Week")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(onSurfaceVar)
                        Text(weeklyEarningsLabel)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(brandGreen)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Available Payout")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(onSurfaceVar)
                        Text(availablePayoutLabel)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(onSurface)
                    }
                }

                // Payout meta
                HStack(spacing: 8) {
                    Image(systemName: "banknote")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(brandGreen)
                    Text(nextPayoutLabel)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(onSurfaceVar)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(cardBorder, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    /// Displayed in place of the balance block when Stripe Connect isn't
    /// fully onboarded. Tapping fires `startConnectOnboarding` and opens
    /// the returned single-use Account Link URL in Safari.
    private var onboardPayoutCard: some View {
        Button {
            // Stripe Connect onboarding hands off to a browser —
            // interrupts the audio session. Gate it.
            guard CallCenter.shared.attempt("set up payouts") else { return }
            Task { await viewModel.startOnboarding() }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(brandGreen.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "creditcard")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(brandGreen)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Complete payout setup")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(brandGreen)
                    Text("Verify your identity and add a bank account to receive earnings.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(onSurfaceVar)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
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

    // MARK: Financial formatting

    private var weeklyEarningsLabel: String {
        guard let e = viewModel.weeklyEarnings else { return "—" }
        return ExpertDashboardViewModel.currencyLabel(minorUnits: e.netAmount, currency: e.currency)
    }

    private var availablePayoutLabel: String {
        guard let s = viewModel.payoutSummary else { return "—" }
        return ExpertDashboardViewModel.currencyLabel(minorUnits: s.availableAmount, currency: s.currency)
    }

    private var nextPayoutLabel: String {
        guard let s = viewModel.payoutSummary else { return "Payout schedule unavailable" }
        if let iso = s.nextPayoutDate {
            return "Next payout on \(ExpertDashboardViewModel.payoutDateLabel(iso))"
        }
        return "Payouts are on manual schedule"
    }

    // MARK: - Expert Tools

    private var expertTools: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Expert Tools")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(onSurface)

            let tools: [(String, String, ExpertDashboardRoute)] = [
                ("calendar.badge.clock", "Availability", .availability),
                ("pencil.and.list.clipboard", "Edit Topics", .editTopics),
                ("creditcard", "Payouts", .payouts),
                ("gearshape", "Profile Settings", .profileSettings),
                ("calendar", "Bookings", .calendar),
            ]

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 14
            ) {
                ForEach(tools, id: \.1) { icon, label, route in
                    toolCell(icon: icon, label: label) { push(route) }
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

#Preview("Payout Onboarding") {
    ExpertDashboardView(
        viewModel: .previewSeed(payoutSummary: nil, payoutOnboardingRequired: true)
    )
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return ExpertDashboardView()
        .preferredColorScheme(.dark)
}
