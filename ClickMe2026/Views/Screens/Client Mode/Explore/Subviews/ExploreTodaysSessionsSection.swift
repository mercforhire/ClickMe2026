//
//  ExploreTodaysSessionsSection.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Client-side counterpart to the expert dashboard's "Today's Sessions"
/// strip. Rendered at the top of the Explore screen so a client can jump
/// straight into an imminent booking without opening the Bookings tab.
///
/// The section itself is hidden entirely when there are no joinable
/// sessions today (the caller gates on `!sessions.isEmpty`).
struct ExploreTodaysSessionsSection: View {
    let sessions: [UpcomingBooking]
    var onJoinCall: (UpcomingBooking) -> Void
    var onTapCard: (UpcomingBooking) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Today's Sessions")
                    .font(.brand(.title3, weight: .bold))
                    .foregroundColor(.white)
                    .layoutPriority(1)
                Spacer(minLength: 8)
                // The device zone, the zone the session times are formatted in
                // (D-18, BOOK-03); the same helper as the slots card. Omitted
                // when the device has no readable name.
                if let zone = DateUtil.zoneName() {
                    Text(zone)
                        .font(.brand(.caption, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                ForEach(sessions) { session in
                    sessionCard(session)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func sessionCard(_ session: UpcomingBooking) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                avatar(session.imageURL)

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.expertName)
                        .font(.brand(.subheadline, weight: .bold))
                        .foregroundColor(.white)
                    Text(session.topic)
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                }

                Spacer()

                if isStartingNow(session) {
                    Text("STARTING NOW")
                        .font(.brand(.caption2, weight: .bold))
                        .foregroundColor(.black)
                        .tracking(0.5)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(ExploreBrand.brandGreen)
                                .shadow(color: ExploreBrand.brandGreen.opacity(0.55), radius: 6)
                        )
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.subheadline.weight(.regular))
                    .foregroundColor(.white.opacity(0.65))
                Text(session.timeRange)
                    .font(.brand(.subheadline, weight: .regular))
                    .foregroundColor(.white)
            }

            // Join Call button — mirrors the expert dashboard strip. Enabled
            // on the shared `JoinWindow` rule (CALL-02) through
            // `session.isWithinJoinWindow`, which the TimelineView re-reads
            // every minute so the button enables at start − 60 min without
            // leaving the screen. Rendered for every card and disabled
            // (dimmed; VoiceOver announces "dimmed") while the window is
            // closed or the status is not joinable, so a pending_reschedule
            // card shows a disabled Join rather than none, as Android does
            // (user decision 2026-11-10, supersedes the D-12 hide). The
            // server still has the final say via the `MeetingCallView` join
            // flow, which surfaces any refusal message on the parent.
            if JoinWindow.showsJoinButton(status: session.status) {
                TimelineView(.periodic(from: .now, by: 60)) { _ in
                    let inWindow = session.isWithinJoinWindow
                    Button {
                        onJoinCall(session)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "video.fill")
                                .font(.callout.weight(.semibold))
                            Text("Join Call")
                                .font(.brand(.callout, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(ExploreBrand.brandGreen.opacity(inWindow ? 1.0 : 0.55))
                                .shadow(
                                    color: ExploreBrand.brandGreen.opacity(inWindow ? 0.45 : 0),
                                    radius: 14, x: 0, y: 4
                                )
                        )
                    }
                    .disabled(!inWindow)
                    // Same disabled-state wording as Android's shared Join
                    // button (`explore_join_call_state`).
                    .accessibilityHint(inWindow ? "" : "Available closer to the session start")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ExploreBrand.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture { onTapCard(session) }
    }

    private func avatar(_ url: String) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case let .success(img):
                img.resizable().scaledToFill()
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
        .overlay(Circle().stroke(ExploreBrand.brandGreen.opacity(0.50), lineWidth: 1))
    }

    /// The "starting now" pill only: the start is within ±60 min of now.
    /// Deliberately its own arithmetic, not the `JoinWindow` rule that drives
    /// the Join button (02-UI-SPEC §2).
    private func isStartingNow(_ session: UpcomingBooking) -> Bool {
        let delta = session.startTime.timeIntervalSinceNow
        return delta <= 3600 && delta >= -3600
    }
}
