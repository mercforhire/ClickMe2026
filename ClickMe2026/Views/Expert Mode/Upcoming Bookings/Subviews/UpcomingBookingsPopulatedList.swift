//
//  UpcomingBookingsPopulatedList.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct UpcomingBookingsPopulatedList: View {
    let sessions: [UpcomingSession]
    var onJoinSession: (UpcomingSession) -> Void
    var onMessage: (UpcomingSession) -> Void
    var onReschedule: (UpcomingSession) -> Void
    var onEarningsDash: () -> Void
    var onAddSession: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header + "N Total" badge
                    HStack(alignment: .top) {
                        Text("Upcoming\nSessions")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(UpcomingBookingsTheme.onSurface)
                            .lineSpacing(2)

                        Spacer()

                        HStack(spacing: 7) {
                            Circle()
                                .fill(UpcomingBookingsTheme.brandGreen)
                                .frame(width: 8, height: 8)
                                .shadow(color: UpcomingBookingsTheme.brandGreen.opacity(0.80), radius: 4)
                            Text("\(sessions.count) Total")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(UpcomingBookingsTheme.onSurface)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(UpcomingBookingsTheme.totalBg)
                                .overlay(Capsule().stroke(UpcomingBookingsTheme.totalBorder, lineWidth: 1))
                        )
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                    // Cards
                    VStack(spacing: 16) {
                        ForEach(sessions) { session in
                            UpcomingBookingsSessionCard(
                                session: session,
                                onJoin: { onJoinSession(session) },
                                onMessage: { onMessage(session) },
                                onReschedule: { onReschedule(session) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Earnings link
                    Button(action: onEarningsDash) {
                        Text("View Earnings Dashboard & History")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(UpcomingBookingsTheme.brandGreen)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 32)
                    .padding(.bottom, 110)
                }
            }

            // FAB
            Button(action: onAddSession) {
                ZStack {
                    Circle()
                        .fill(UpcomingBookingsTheme.brandGreen)
                        .frame(width: 60, height: 60)
                        .shadow(color: UpcomingBookingsTheme.brandGreen.opacity(0.55), radius: 18, x: 0, y: 6)
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(UpcomingBookingsTheme.onPrimary)
                }
            }
            .buttonStyle(UpcomingBookingsScaleStyle())
            .padding(.trailing, 24)
            .padding(.bottom, 28)
        }
    }
}
