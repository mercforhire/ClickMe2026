//
//  RequestDecisionActionFooter.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct RequestDecisionActionFooter: View {
    let isAccepted: Bool
    let isDeclined: Bool
    var onMessage: () -> Void
    var onDeclineTap: () -> Void
    var onAcceptTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onMessage) {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 15, weight: .medium))
                    Text("Message User")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundColor(Brand.onSurface)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Brand.overlayWhite10))
            }
            .buttonStyle(PressScaleButtonStyle())

            HStack(spacing: 12) {
                Button(action: onDeclineTap) {
                    Text(isDeclined ? "Declined" : "Decline")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(isDeclined ? Brand.overlayWhite60 : Brand.onSurface)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Brand.overlayWhite22))
                }
                .buttonStyle(PressScaleButtonStyle())
                .disabled(isDeclined || isAccepted)

                Button(action: onAcceptTap) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isAccepted ? Brand.primary.opacity(0.55) : Brand.primary)
                            .shadow(color: Brand.primary.opacity(0.38), radius: 8, x: 0, y: 2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)

                        if isAccepted {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Accepted!")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(Brand.onPrimary)
                        } else {
                            Text("Accept")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Brand.onPrimary)
                        }
                    }
                }
                .buttonStyle(PressScaleButtonStyle())
                .disabled(isAccepted || isDeclined)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 32)
        .background(Brand.surface.opacity(0.92).ignoresSafeArea(edges: .bottom))
    }
}
