//
//  RescheduleExpertCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Expert booking card: green-ringed avatar + name/role/current date

struct RescheduleExpertCard: View {
    let booking: RescheduleBooking

    var body: some View {
        HStack(spacing: 14) {
            avatar

            VStack(alignment: .leading, spacing: 3) {
                Text(booking.expertName)
                    .font(.brand(.callout, weight: .bold))
                    .foregroundColor(RescheduleBrand.onSurface)
                Text(booking.role)
                    .font(.brand(.caption, weight: .regular))
                    .foregroundColor(RescheduleBrand.onSurfaceVar)
                Text(booking.currentDateLabel)
                    .font(.brand(.caption, weight: .regular))
                    .foregroundColor(RescheduleBrand.onSurfaceVar.opacity(0.85))
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(RescheduleCardBackground())
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .stroke(RescheduleBrand.brandGreen, lineWidth: 2)
                .shadow(color: RescheduleBrand.brandGreen.opacity(0.45), radius: 5)
                .frame(width: 60, height: 60)

            AsyncImage(url: URL(string: booking.imageURL)) { phase in
                switch phase {
                case let .success(img): img.resizable().scaledToFill()
                default:
                    ZStack {
                        RescheduleBrand.avatarFallback
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(Circle())
        }
    }
}
