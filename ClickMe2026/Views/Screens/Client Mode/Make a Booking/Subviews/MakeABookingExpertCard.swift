//
//  MakeABookingExpertCard.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

struct MakeABookingExpertCard: View {
    let expertName: String
    let expertTitle: String
    let expertImageURL: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MakeABookingSectionHeader(title: "Expert")

            HStack(spacing: 14) {
                AsyncImage(url: URL(string: expertImageURL)) { phase in
                    switch phase {
                    case let .success(img): img.resizable().scaledToFill()
                    default:
                        ZStack {
                            Color(red: 0.14, green: 0.18, blue: 0.15)
                            Image(systemName: "person.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.15))
                        }
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(expertName)
                        .font(.brand(.callout, weight: .bold))
                        .foregroundColor(MakeABookingBrand.onSurface)
                    Text(expertTitle)
                        .font(.brand(.subheadline, weight: .regular))
                        .foregroundColor(MakeABookingBrand.onSurfaceVar)
                }
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(MakeABookingBrand.surface)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(MakeABookingBrand.outlineVar, lineWidth: 1))
            )
        }
    }
}
