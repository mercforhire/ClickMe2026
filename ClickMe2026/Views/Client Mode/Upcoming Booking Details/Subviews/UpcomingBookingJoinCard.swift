//
//  UpcomingBookingJoinCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - "How to Join" link row + JOIN CALL primary button

struct UpcomingBookingJoinCard: View {
    let joinLink: String
    let onJoinCall: () -> Void
    let onCopyLink: () -> Void

    @State private var didCopyLink = false

    var body: some View {
        VStack(spacing: 14) {
            linkRow
            joinButton
        }
        .padding(16)
        .background(UpcomingBookingGlassCard())
    }

    // MARK: Link row

    private var linkRow: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(UpcomingBookingBrand.videoBg)
                    .frame(width: 42, height: 42)
                Image(systemName: "video")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(UpcomingBookingBrand.blueAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("How to Join")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(UpcomingBookingBrand.onSurface)
                Text("Link: \(joinLink)")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button {
                UIPasteboard.general.string = joinLink
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { didCopyLink = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation { didCopyLink = false }
                }
                onCopyLink()
            } label: {
                Image(systemName: didCopyLink ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(UpcomingBookingBrand.brandGreen)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: JOIN CALL button

    private var joinButton: some View {
        Button(action: onJoinCall) {
            HStack(spacing: 8) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("JOIN CALL")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .tracking(0.5)
            }
            .foregroundColor(UpcomingBookingBrand.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(UpcomingBookingBrand.brandGreen)
                    .shadow(color: UpcomingBookingBrand.brandGreen.opacity(0.45), radius: 14, x: 0, y: 4)
            )
        }
        .buttonStyle(DetailsScaleStyle())
    }
}
