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
    var onCardTap: (UpcomingSession) -> Void = { _ in }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // "N Total" badge
                HStack {
                    Spacer()
                    HStack(spacing: 7) {
                        Circle()
                            .fill(Brand.primary)
                            .frame(width: 8, height: 8)
                            .shadow(color: Brand.primary.opacity(0.80), radius: 4)
                        Text("\(sessions.count) Total")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Brand.onSurface)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Brand.surfaceContainerLow)
                            .overlay(Capsule().stroke(Brand.outlineVariant, lineWidth: 1))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)

                // Cards
                VStack(spacing: 16) {
                    ForEach(sessions) { session in
                        UpcomingBookingsSessionCard(
                            session: session,
                            onJoin: { onJoinSession(session) },
                            onMessage: { onMessage(session) },
                            onReschedule: { onReschedule(session) },
                            onCardTap: { onCardTap(session) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}
