//
//  ReadyToStartCallSupportRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Fallback copy + "Having trouble? Contact support." row

struct ReadyToStartCallSupportRow: View {
    let opacity: Double
    let yOffset: CGFloat
    let onContactSupport: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Text("If you don't have Skype installed, you can join from your browser. Clicking the link will give you this option.")
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(ReadyToStartCallBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            HStack(spacing: 4) {
                Text("Having trouble?")
                    .font(.brand(.subheadline, weight: .regular))
                    .foregroundColor(ReadyToStartCallBrand.onSurfaceVar)
                Button(action: onContactSupport) {
                    Text("Contact support.")
                        .font(.brand(.subheadline, weight: .semibold))
                        .foregroundColor(ReadyToStartCallBrand.brandGreen)
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(opacity)
        .offset(y: yOffset)
    }
}
