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
                .foregroundColor(RequestDecisionTheme.onSurface)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(RequestDecisionTheme.messageBg))
            }
            .buttonStyle(RequestDecisionActionStyle())

            HStack(spacing: 12) {
                Button(action: onDeclineTap) {
                    Text(isDeclined ? "Declined" : "Decline")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(isDeclined ? RequestDecisionTheme.onSurfaceVar : RequestDecisionTheme.onSurface)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(RequestDecisionTheme.declineBg))
                }
                .buttonStyle(RequestDecisionActionStyle())
                .disabled(isDeclined || isAccepted)

                Button(action: onAcceptTap) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isAccepted ? RequestDecisionTheme.brandGreen.opacity(0.55) : RequestDecisionTheme.brandGreen)
                            .shadow(color: RequestDecisionTheme.brandGreen.opacity(0.38), radius: 8, x: 0, y: 2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)

                        if isAccepted {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Accepted!")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(RequestDecisionTheme.onPrimary)
                        } else {
                            Text("Accept")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(RequestDecisionTheme.onPrimary)
                        }
                    }
                }
                .buttonStyle(RequestDecisionActionStyle())
                .disabled(isAccepted || isDeclined)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 32)
        .background(RequestDecisionTheme.bg.opacity(0.92).ignoresSafeArea(edges: .bottom))
    }
}
