//
//  ReadyToStartCallHeadline.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - "Ready to join your call" headline + subtext

struct ReadyToStartCallHeadline: View {
    let opacity: Double
    let yOffset: CGFloat

    var body: some View {
        VStack(spacing: 10) {
            Text("Ready to join your call")
                .font(.brand(.title, weight: .bold))
                .foregroundColor(ReadyToStartCallBrand.onSurface)
                .multilineTextAlignment(.center)

            Text("Click the button below to open Skype.")
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(ReadyToStartCallBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
        }
        .opacity(opacity)
        .offset(y: yOffset)
    }
}
