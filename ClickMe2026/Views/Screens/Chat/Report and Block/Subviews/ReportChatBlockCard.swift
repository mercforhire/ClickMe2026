//
//  ReportChatBlockCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Block User card: warning copy + destructive outline button

struct ReportChatBlockCard: View {
    let onBlockTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Block User")
                    .font(.brand(.title2, weight: .bold))
                    .foregroundColor(ReportChatBrand.onSurface)

                Text("Blocking this user will prevent them from seeing your profile, sending you messages, or booking appointments with you. They will not be notified that you have blocked them.")
                    .font(.brand(.subheadline, weight: .regular))
                    .foregroundColor(ReportChatBrand.onSurfaceVar)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Spacer()
                Button(action: onBlockTap) {
                    Text("Block User")
                        .font(.brand(.subheadline, weight: .bold))
                        .foregroundColor(ReportChatBrand.errorRed)
                        .padding(.horizontal, 20)
                        .frame(height: 42)
                        .overlay(
                            Capsule().stroke(ReportChatBrand.errorBorder, lineWidth: 1.5)
                        )
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
        .padding(20)
        .background(ReportChatGlassCard())
    }
}
