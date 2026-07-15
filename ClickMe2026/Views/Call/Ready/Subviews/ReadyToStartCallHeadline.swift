//
//  ReadyToStartCallHeadline.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - "Ready to join your call" headline + subtext

struct ReadyToStartCallHeadline: View {
    let opacity: Double
    let yOffset: CGFloat

    var body: some View {
        VStack(spacing: 10) {
            Text("Ready to join your call")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(ReadyToStartCallBrand.onSurface)
                .multilineTextAlignment(.center)

            Text("Click the button below to open Skype.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(ReadyToStartCallBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
        }
        .opacity(opacity)
        .offset(y: yOffset)
    }
}
