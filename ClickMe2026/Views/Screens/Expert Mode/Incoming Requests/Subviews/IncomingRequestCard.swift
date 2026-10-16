//
//  IncomingRequestCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

struct IncomingRequestCard: View {
    let request: BookingRequest
    var onTap: (BookingRequest) -> Void

    var body: some View {
        Button { onTap(request) } label: {
            VStack(spacing: 0) {
                // ── Client row ──
                HStack(alignment: .center, spacing: 14) {
                    IncomingRequestAvatar(request: request)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.clientName)
                            .font(.brand(.title3, weight: .bold))
                            .foregroundColor(Brand.onSurface)
                        Text(request.topic)
                            .font(.brand(.subheadline, weight: .regular))
                            .foregroundColor(Brand.onSurfaceVariant)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Earnings")
                            .font(.brand(.caption, weight: .regular))
                            .foregroundColor(Brand.onSurfaceVariant)
                        Text(request.earnings)
                            .font(.brand(.title3, weight: .bold))
                            .foregroundColor(Brand.onSurface)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 14)

                // ── Divider ──
                Rectangle()
                    .fill(Brand.outlineVariant.opacity(0.50))
                    .frame(height: 1)
                    .padding(.horizontal, 18)

                // ── Date + expiry ──
                VStack(spacing: 6) {
                    Text(request.dateTime)
                        .font(.brand(.callout, weight: .regular))
                        .foregroundColor(Brand.onSurface)

                    if request.isExpired {
                        Text("EXPIRED")
                            .font(.brand(.subheadline, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(Brand.onSurfaceVariant)
                    } else {
                        HStack(spacing: 0) {
                            Text("Expires in: ")
                                .font(.brand(.subheadline, weight: .regular))
                                .foregroundColor(IncomingRequestsTheme.amberColor)
                            Text("\(request.expiresInHours)h")
                                .font(.brand(.title2, weight: .bold))
                                .foregroundColor(IncomingRequestsTheme.amberColor)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Brand.surfaceContainerLow)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(IncomingRequestsTheme.irisBorder, lineWidth: 1.5)
                    )
            )
            // Fully-past requests are visually dimmed but still tappable
            // — tap opens a read-only decision screen so the expert can
            // review the client info and message them if they want to.
            .opacity(request.isExpired ? 0.55 : 1.0)
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}
