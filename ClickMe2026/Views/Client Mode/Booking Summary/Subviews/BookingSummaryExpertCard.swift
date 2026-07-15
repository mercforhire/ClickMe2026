//
//  BookingSummaryExpertCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Expert + topic glass card

struct BookingSummaryExpertCard: View {
    let expertName: String
    let expertTitle: String
    let expertImageURL: String
    let topic: String
    let dateTime: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topRow
                .padding(16)

            Rectangle()
                .fill(BookingSummaryBrand.divider.opacity(0.40))
                .frame(height: 1)
                .padding(.horizontal, 16)

            topicSection
                .padding(16)
        }
        .background(BookingSummaryGlassCardBackground())
    }

    // MARK: Top row

    private var topRow: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .stroke(BookingSummaryBrand.brandGreen, lineWidth: 2)
                    .shadow(color: BookingSummaryBrand.brandGreen.opacity(0.45), radius: 5)
                    .frame(width: 68, height: 68)

                AsyncImage(url: URL(string: expertImageURL)) { phase in
                    switch phase {
                    case let .success(img): img.resizable().scaledToFill()
                    default:
                        ZStack {
                            Color(red: 0.12, green: 0.16, blue: 0.14)
                            Image(systemName: "person.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white.opacity(0.15))
                        }
                    }
                }
                .frame(width: 62, height: 62)
                .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(expertName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(BookingSummaryBrand.onSurface)
                Text(expertTitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(BookingSummaryBrand.onSurfaceVar)
            }

            Spacer()

            Text("Completed")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(BookingSummaryBrand.brandGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(BookingSummaryBrand.brandGreen.opacity(0.10))
                        .overlay(Capsule().stroke(BookingSummaryBrand.brandGreen.opacity(0.25), lineWidth: 1))
                )
        }
    }

    // MARK: Topic + date

    private var topicSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("TOPIC")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(BookingSummaryBrand.onSurfaceVar)
                .tracking(1.4)
            Text(topic)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(BookingSummaryBrand.brandGreen)
            Text(dateTime)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(BookingSummaryBrand.onSurfaceVar)
        }
    }
}
