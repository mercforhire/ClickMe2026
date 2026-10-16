//
//  CancellationBookingSummary.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Mini booking summary card (inside confirmation step)

struct CancellationBookingSummary: View {
    let booking: CancellationBooking

    var body: some View {
        VStack(spacing: 0) {
            expertRow

            Rectangle()
                .fill(CancellationBrand.outlineVar.opacity(0.40))
                .frame(height: 1)
                .padding(.vertical, 14)

            dateRefundRows
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(CancellationBrand.innerBg)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(CancellationBrand.innerBorder, lineWidth: 1))
        )
    }

    private var expertRow: some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: booking.imageURL)) { phase in
                switch phase {
                case let .success(img): img.resizable().scaledToFill()
                default:
                    ZStack {
                        Color(red: 0.12, green: 0.18, blue: 0.14)
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(Circle())
            .overlay(Circle().stroke(CancellationBrand.brandGreen.opacity(0.50), lineWidth: 1.5)
                .shadow(color: CancellationBrand.brandGreen.opacity(0.35), radius: 4))

            VStack(alignment: .leading, spacing: 4) {
                Text(booking.expertName)
                    .font(.brand(.body, weight: .bold))
                    .foregroundColor(CancellationBrand.onSurface)
                Text(booking.expertTitle)
                    .font(.brand(.caption, weight: .semibold))
                    .foregroundColor(CancellationBrand.brandGreen)
            }
            Spacer()
        }
    }

    private var dateRefundRows: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.subheadline)
                    .foregroundColor(CancellationBrand.onSurfaceVar)
                    .frame(width: 18)
                Text(booking.dateString)
                    .font(.brand(.subheadline, weight: .regular))
                    .foregroundColor(CancellationBrand.onSurface)
            }

            if let refundAmount = booking.refundAmount {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "creditcard")
                        .font(.subheadline)
                        .foregroundColor(CancellationBrand.onSurfaceVar)
                        .frame(width: 18)
                    Text(refundAmount)
                        .font(.brand(.subheadline, weight: .semibold))
                        .foregroundColor(CancellationBrand.brandGreen)
                        + Text(" will be refunded according to our policy.")
                        .font(.brand(.subheadline, weight: .regular))
                        .foregroundColor(CancellationBrand.onSurfaceVar)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
