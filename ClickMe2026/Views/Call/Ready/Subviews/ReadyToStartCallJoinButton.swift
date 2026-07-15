//
//  ReadyToStartCallJoinButton.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Primary "Join Call" pill button with green glow

struct ReadyToStartCallJoinButton: View {
    let opacity: Double
    let yOffset: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text("Join Call")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Image(systemName: "video.fill")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(ReadyToStartCallBrand.onPrimary)
            .frame(width: 200, height: 54)
            .background(
                Capsule()
                    .fill(ReadyToStartCallBrand.brandGreen)
                    .shadow(color: ReadyToStartCallBrand.brandGreen.opacity(0.55), radius: 20, x: 0, y: 6)
            )
        }
        .buttonStyle(SkypeScaleStyle())
        .opacity(opacity)
        .offset(y: yOffset)
    }
}
