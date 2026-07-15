//
//  ExpertDashboardView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Expert Home View

struct ExpertDashboardView: View {
    let viewModel: ExpertDashboardViewModel

    // MARK: Design tokens — Luminous Dark

    private let bg = Color(red: 0.075, green: 0.075, blue: 0.075)
    private let cardBg = Color(red: 0.110, green: 0.110, blue: 0.115)
    private let cardBorder = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let pendingBg = Color(red: 0.078, green: 0.145, blue: 0.100)
    private let pendingBdr = Color(red: 0.155, green: 0.290, blue: 0.200)
    private let sessionBg = Color(red: 0.095, green: 0.120, blue: 0.100)
    private let toolBg = Color(red: 0.100, green: 0.110, blue: 0.110)
    private let toolIconBg = Color(red: 0.130, green: 0.155, blue: 0.138)
    private let withdrawBg = Color(red: 0.160, green: 0.165, blue: 0.170)
    private let brandGreen = Color(red: 0.267, green: 0.965, blue: 0.592)
    private let onSurface = Color(red: 0.898, green: 0.886, blue: 0.882)
    private let onSurfaceVar = Color(red: 0.580, green: 0.640, blue: 0.610)
    private let onPrimary = Color(red: 0.000, green: 0.224, blue: 0.114)

    // MARK: Init

    init(viewModel: ExpertDashboardViewModel = ExpertDashboardViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

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
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Spacer()

            Text("ClickMe")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(brandGreen)

            Spacer()

            Button { viewModel.onAvatarTap() } label: {
                AsyncImage(url: URL(string: viewModel.avatarURL)) { phase in
                    switch phase {
                    case let .success(img): img.resizable().scaledToFill()
                    default: Color(red: 0.14, green: 0.18, blue: 0.15)
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(brandGreen, lineWidth: 2)
                    .shadow(color: brandGreen.opacity(0.45), radius: 5))
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 52)
        .padding(.top, 16)
    }

    // MARK: - Hero header

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DASHBOARD OVERVIEW")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(onSurfaceVar)
                .tracking(1.4)

            Text("Hello, \(viewModel.expertFirstName) \(viewModel.expertLastName)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(onSurface)
        }
    }

    // MARK: - Pending banner

    private var pendingBanner: some View {
        Button { viewModel.onPendingRequests() } label: {
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
        .buttonStyle(ExpertHomeScaleStyle())
    }

    // MARK: - Today's Sessions

    private var todaysSessions: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Sessions")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(onSurface)
                Spacer()
                Button { viewModel.onViewCalendar() } label: {
                    Text("View Calendar")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(brandGreen)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 14) {
                // Client row
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: "https://randomuser.me/api/portraits/women/44.jpg")) { phase in
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
                        Text(viewModel.sessionName)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(onSurface)
                        Text(viewModel.sessionTopic)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(onSurfaceVar)
                    }

                    Spacer()

                    if viewModel.isStartingNow {
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
                    Text(viewModel.sessionTime)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(onSurface)
                }

                // Join Session button
                Button { viewModel.onJoinSession() } label: {
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
                            .fill(brandGreen)
                            .shadow(color: brandGreen.opacity(0.45), radius: 14, x: 0, y: 4)
                    )
                }
                .buttonStyle(ExpertHomeScaleStyle())
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(sessionBg)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(cardBorder, lineWidth: 1))
            )
        }
    }

    // MARK: - Financial Summary

    private var financialSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Financial Summary")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(onSurface)

            VStack(spacing: 18) {
                // Earnings row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("This Week")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(onSurfaceVar)
                        Text(viewModel.weekEarnings)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(brandGreen)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Available Payout")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(onSurfaceVar)
                        Text(viewModel.availablePayout)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(onSurface)
                    }
                }

                // Payout + withdraw row
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "banknote")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(brandGreen)
                        Text("Next payout on \(viewModel.nextPayoutDate)")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(onSurfaceVar)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Button { viewModel.onWithdraw() } label: {
                        Text("Withdraw")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(onSurface)
                            .padding(.horizontal, 20)
                            .frame(height: 40)
                            .background(Capsule()
                                .fill(withdrawBg)
                                .overlay(Capsule().stroke(cardBorder, lineWidth: 1)))
                    }
                    .buttonStyle(ExpertHomeScaleStyle())
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
    }

    // MARK: - Expert Tools

    private var expertTools: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Expert Tools")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(onSurface)

            let tools: [(String, String, () -> Void)] = [
                ("calendar.badge.clock", "Availability", viewModel.onAvailability),
                ("pencil.and.list.clipboard", "Edit Topics", viewModel.onEditTopics),
                ("creditcard", "Payouts", viewModel.onPayouts),
                ("gearshape", "Profile Settings", viewModel.onProfileSettings),
            ]

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 14
            ) {
                ForEach(tools, id: \.1) { icon, label, action in
                    toolCell(icon: icon, label: label, action: action)
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
        .buttonStyle(ExpertHomeScaleStyle())
    }
}

// MARK: - Button style

private struct ExpertHomeScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Expert Home") {
    ExpertDashboardView()
        .preferredColorScheme(.dark)
}

#Preview("No Pending / Not Starting Now") {
    ExpertDashboardView(
        viewModel: ExpertDashboardViewModel(pendingCount: 0, isStartingNow: false)
    )
    .preferredColorScheme(.dark)
}
