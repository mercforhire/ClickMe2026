//
//  ReadyToStartCallSupportRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
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
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(ReadyToStartCallBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            HStack(spacing: 4) {
                Text("Having trouble?")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(ReadyToStartCallBrand.onSurfaceVar)
                Button(action: onContactSupport) {
                    Text("Contact support.")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(ReadyToStartCallBrand.brandGreen)
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(opacity)
        .offset(y: yOffset)
    }
}
