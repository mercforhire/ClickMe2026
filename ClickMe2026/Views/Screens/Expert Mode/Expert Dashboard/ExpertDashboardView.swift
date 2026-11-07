//
//  ExpertDashboardView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-24.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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
    /// Owns the ASWebAuthenticationSession for the Stripe Connect
    /// onboarding flow. See `ConnectOnboardingSession` for details.
    @State private var onboardingSession = ConnectOnboardingSession()

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
        // Present the Stripe hosted onboarding URL in an in-app
        // ASWebAuthenticationSession. Backend 302s to
        // clickme://connect/return when the flow completes; the
        // session closes and we refresh status. Refresh variant
        // reopens onboarding automatically.
        .onChange(of: viewModel.connectOnboardingURL) { _, url in
            guard let url else { return }
            viewModel.connectOnboardingURL = nil
            onboardingSession.start(url: url) { outcome in
                switch outcome {
                case .completed(let callback):
                    Task {
                        if callback.isConnectRefresh {
                            await viewModel.startOnboarding()
                        } else {
                            await viewModel.reload()
                        }
                    }
                case .cancelled:
                    break
                }
            }
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
        // Silent refresh on tab-return so today's session count,
        // pending request badge, and balance stay current without a
        // spinner flash. `.task` still owns the first fetch;
        // `silentReload` early-returns until it lands.
        .onAppear { Task { await viewModel.silentReload() } }
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
        .micPermissionDeniedAlert(isPresented: Binding(
            get: { callCenter.micPermissionDenied },
            set: { if !$0 { callCenter.micPermissionDenied = false } }
        ))
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
                if viewModel.rescheduleRequestCount > 0 {
                    rescheduleBanner
                }
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
                .font(.brand(.caption))
                .foregroundColor(onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title.weight(.light))
                .foregroundColor(onSurfaceVar)
            Text("Couldn't load dashboard")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(onSurface)
            Text(message)
                .font(.brand(.caption))
                .foregroundColor(onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.brand(.subheadline, weight: .semibold))
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
                .font(.brand(.caption2, weight: .semibold))
                .foregroundColor(onSurfaceVar)
                .tracking(1.4)

            Text("Hello, \(greetingName)")
                .font(.brand(.title, weight: .bold))
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
                        .font(.title3.weight(.regular))
                        .foregroundColor(brandGreen)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(viewModel.pendingCount) Pending Requests")
                        .font(.brand(.callout, weight: .bold))
                        .foregroundColor(brandGreen)
                    Text("Review and confirm new bookings")
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(onSurfaceVar)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
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

    // MARK: - Reschedule banner

    /// Amber-toned counterpart to `pendingBanner`. Only rendered when
    /// there's at least one client-initiated reschedule proposal
    /// awaiting this expert's decision. Tapping lands on the Upcoming
    /// Sessions screen — those rows now carry a "Client proposed a new
    /// time" pill and open the summary's Accept/Decline surface.
    private var rescheduleBanner: some View {
        Button { push(.calendar) } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.orange.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.title3.weight(.regular))
                        .foregroundColor(.orange)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(viewModel.rescheduleRequestCount) Reschedule Request\(viewModel.rescheduleRequestCount == 1 ? "" : "s")")
                        .font(.brand(.callout, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Review pending time changes")
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(onSurfaceVar)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.orange)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.orange.opacity(0.10))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.orange.opacity(0.45), lineWidth: 1))
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    // MARK: - Today's Sessions

    private var todaysSessions: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Sessions")
                    .font(.brand(.title3, weight: .bold))
                    .foregroundColor(onSurface)
                Spacer()
                Button { push(.calendar) } label: {
                    Text("View Calendar")
                        .font(.brand(.caption, weight: .semibold))
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
                .font(.title2.weight(.light))
                .foregroundColor(onSurfaceVar)
            Text("No sessions today")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(onSurface)
            Text("Enjoy the breather — new bookings will show up here.")
                .font(.brand(.caption, weight: .regular))
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
            // Info block (client row + time) is its own tap region so
            // hitting the Join button below doesn't also fire the
            // summary push. Mirrors the pattern on the past-session
            // and past-booking cards.
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
                                    .font(.callout)
                                    .foregroundColor(.white.opacity(0.15))
                            }
                        }
                    }
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(brandGreen.opacity(0.50), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.client.name ?? "Client")
                            .font(.brand(.subheadline, weight: .bold))
                            .foregroundColor(onSurface)
                        Text(session.session.topic ?? "")
                            .font(.brand(.caption, weight: .regular))
                            .foregroundColor(onSurfaceVar)
                    }

                    Spacer()

                    if viewModel.isStartingNow(session) {
                        Text("STARTING NOW")
                            .font(.brand(.caption2, weight: .bold))
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
                        .font(.subheadline.weight(.regular))
                        .foregroundColor(onSurfaceVar)
                    Text(viewModel.timeLabel(session))
                        .font(.brand(.subheadline, weight: .regular))
                        .foregroundColor(onSurface)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Push a shell-level route (registered on the
                // dashboardTab NavigationStack in HomeExpertView) —
                // not `ExpertDashboardRoute`, which is scoped to this
                // screen's own destinations.
                navPath?.push(HomeRoute.expertBookingSummary(bookingId: session.bookingId))
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
                    scheduledEnd: session.session.endTime,
                    meetingType: session.session.meetingType,
                    isRejoin: session.status.code == .completed
                )
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "video.fill")
                        .font(.callout.weight(.semibold))
                    Text("Join Session")
                        .font(.brand(.callout, weight: .bold))
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
                .font(.brand(.title3, weight: .bold))
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
                            .font(.brand(.caption, weight: .regular))
                            .foregroundColor(onSurfaceVar)
                        Text(weeklyEarningsLabel)
                            .font(.brand(.title, weight: .bold))
                            .foregroundColor(brandGreen)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Available Payout")
                            .font(.brand(.caption, weight: .regular))
                            .foregroundColor(onSurfaceVar)
                        Text(availablePayoutLabel)
                            .font(.brand(.title, weight: .bold))
                            .foregroundColor(onSurface)
                    }
                }

                // Payout meta
                HStack(spacing: 8) {
                    Image(systemName: "banknote")
                        .font(.subheadline.weight(.regular))
                        .foregroundColor(brandGreen)
                    Text(nextPayoutLabel)
                        .font(.brand(.caption, weight: .regular))
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
    ///
    /// While the mint is in flight (`isMintingOnboarding == true`) the
    /// chevron swaps for a spinner and the button is disabled — the
    /// Stripe call can take a few seconds and repeat presses used to
    /// fire the request multiple times with no feedback.
    private var onboardPayoutCard: some View {
        let isBusy = viewModel.isMintingOnboarding
        return Button {
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
                        .font(.title3.weight(.regular))
                        .foregroundColor(brandGreen)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(isBusy ? "Opening secure setup…" : "Complete payout setup")
                        .font(.brand(.callout, weight: .bold))
                        .foregroundColor(brandGreen)
                    Text("Verify your identity and add a bank account to receive earnings.")
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(onSurfaceVar)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Swap chevron ↔ spinner in the same slot to avoid a
                // layout jump when the mint starts / ends.
                if isBusy {
                    ProgressView()
                        .controlSize(.small)
                        .tint(brandGreen)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(brandGreen)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(pendingBg)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(pendingBdr, lineWidth: 1))
            )
            .opacity(isBusy ? 0.7 : 1)
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(isBusy)
        .animation(.easeInOut(duration: 0.2), value: isBusy)
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
                .font(.brand(.title3, weight: .bold))
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
                        .font(.title2.weight(.regular))
                        .foregroundColor(brandGreen)
                }
                Text(label)
                    .font(.brand(.subheadline, weight: .bold))
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
