//
//  ChattingEmptyState.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Empty conversation state

struct ChattingEmptyState: View {
    let onSendMessage: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ChattingGlowingBubbles()

            VStack(spacing: 8) {
                Text("Start your conversation here.")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(ChattingBrand.onSurface)
                    .multilineTextAlignment(.center)

                Text("Say hello!")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(ChattingBrand.onSurfaceVar)
            }

            Button(action: onSendMessage) {
                Text("Send a message")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(ChattingBrand.myText)
                    .frame(width: 220, height: 52)
                    .background(
                        Capsule()
                            .fill(ChattingBrand.brandGreen)
                            .shadow(color: ChattingBrand.brandGreen.opacity(0.50), radius: 16, x: 0, y: 5)
                    )
            }
            .buttonStyle(PressScaleButtonStyle())

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
