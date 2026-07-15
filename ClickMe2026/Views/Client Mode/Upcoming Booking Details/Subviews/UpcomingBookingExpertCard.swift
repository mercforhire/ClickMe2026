//
//  UpcomingBookingExpertCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Expert profile card: green-ringed avatar + name/title/rating

struct UpcomingBookingExpertCard: View {
    let expertName: String
    let expertTitle: String
    let expertImageURL: String
    let expertRating: Double
    let reviewCount: Int

    var body: some View {
        HStack(spacing: 16) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                Text(expertName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(UpcomingBookingBrand.onSurface)
                Text(expertTitle)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(UpcomingBookingBrand.onSurfaceVar)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(UpcomingBookingBrand.brandGreen)
                    Text(String(format: "%.1f", expertRating))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(UpcomingBookingBrand.brandGreen)
                    Text("(\(reviewCount) reviews)")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(UpcomingBookingBrand.brandGreen)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(UpcomingBookingGlassCard())
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .stroke(UpcomingBookingBrand.brandGreen, lineWidth: 2.5)
                .shadow(color: UpcomingBookingBrand.brandGreen.opacity(0.50), radius: 8)
                .frame(width: 78, height: 78)

            AsyncImage(url: URL(string: expertImageURL)) { phase in
                switch phase {
                case let .success(img): img.resizable().scaledToFill()
                default:
                    ZStack {
                        UpcomingBookingBrand.avatarFallback
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())
        }
    }
}
