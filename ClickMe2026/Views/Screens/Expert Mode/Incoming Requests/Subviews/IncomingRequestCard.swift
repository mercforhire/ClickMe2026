//
//  IncomingRequestCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
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
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Brand.onSurface)
                        Text(request.topic)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(Brand.onSurfaceVariant)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Earnings")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(Brand.onSurfaceVariant)
                        Text(request.earnings)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
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
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(Brand.onSurface)

                    if request.isExpired {
                        Text("EXPIRED")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .tracking(1.2)
                            .foregroundColor(Brand.onSurfaceVariant)
                    } else {
                        HStack(spacing: 0) {
                            Text("Expires in: ")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(IncomingRequestsTheme.amberColor)
                            Text("\(request.expiresInHours)h")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
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
            // Fully-past requests are visually dimmed and non-interactive.
            .opacity(request.isExpired ? 0.55 : 1.0)
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(request.isExpired)
    }
}
