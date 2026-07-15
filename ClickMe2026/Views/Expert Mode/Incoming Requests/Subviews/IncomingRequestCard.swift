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
                            .foregroundColor(IncomingRequestsTheme.onSurface)
                        Text(request.topic)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(IncomingRequestsTheme.onSurfaceVar)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Earnings")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(IncomingRequestsTheme.onSurfaceVar)
                        Text(request.earnings)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(IncomingRequestsTheme.onSurface)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 14)

                // ── Divider ──
                Rectangle()
                    .fill(IncomingRequestsTheme.divider.opacity(0.50))
                    .frame(height: 1)
                    .padding(.horizontal, 18)

                // ── Date + expiry ──
                VStack(spacing: 6) {
                    Text(request.dateTime)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(IncomingRequestsTheme.onSurface)

                    HStack(spacing: 0) {
                        Text("Expires in: ")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(IncomingRequestsTheme.amberColor)
                        Text("\(request.expiresInHours)h")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(IncomingRequestsTheme.amberColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(IncomingRequestsTheme.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(IncomingRequestsTheme.irisBorder, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(BookingRequestScale())
    }
}

private struct BookingRequestScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.13), value: configuration.isPressed)
    }
}
