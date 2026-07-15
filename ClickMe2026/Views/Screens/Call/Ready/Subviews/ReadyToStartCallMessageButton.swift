//
//  ReadyToStartCallMessageButton.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Secondary "Message Participant" outline button

struct ReadyToStartCallMessageButton: View {
    let opacity: Double
    let yOffset: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 17, weight: .regular))
                Text("Message Participant")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(ReadyToStartCallBrand.onSurface)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Capsule()
                    .fill(Color.clear)
                    .overlay(Capsule().stroke(ReadyToStartCallBrand.outlineVar, lineWidth: 1.5))
            )
        }
        .buttonStyle(PressScaleButtonStyle())
        .opacity(opacity)
        .offset(y: yOffset)
    }
}
