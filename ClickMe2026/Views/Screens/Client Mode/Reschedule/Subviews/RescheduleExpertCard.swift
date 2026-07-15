//
//  RescheduleExpertCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
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
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(RescheduleBrand.onSurface)
                Text(booking.role)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(RescheduleBrand.onSurfaceVar)
                Text(booking.currentDateLabel)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
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
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(Circle())
        }
    }
}
