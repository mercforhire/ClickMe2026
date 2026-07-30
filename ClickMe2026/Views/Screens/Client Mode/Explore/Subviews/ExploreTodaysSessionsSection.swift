//
//  ExploreTodaysSessionsSection.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
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
            Text("Today's Sessions")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
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
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(session.topic)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                }

                Spacer()

                if isStartingNow(session) {
                    Text("STARTING NOW")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
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
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.65))
                Text(session.timeRange)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white)
            }

            // Join Call button — mirrors the expert dashboard: dim +
            // disabled when we're outside the ±1 hour window. Server
            // still has the final say via the `MeetingCallView` join
            // flow, which surfaces any refusal message on the parent.
            let inWindow = session.isWithinJoinWindow
            Button {
                onJoinCall(session)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Join Call")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
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
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.15))
                }
            }
        }
        .frame(width: 42, height: 42)
        .clipShape(Circle())
        .overlay(Circle().stroke(ExploreBrand.brandGreen.opacity(0.50), lineWidth: 1))
    }

    /// Same ±1 hour rule as `UpcomingBooking.isWithinJoinWindow`, but only
    /// the "starting soon" cue — negative delta up to 60 min after start.
    private func isStartingNow(_ session: UpcomingBooking) -> Bool {
        let delta = session.startTime.timeIntervalSinceNow
        return delta <= 3600 && delta >= -3600
    }
}
