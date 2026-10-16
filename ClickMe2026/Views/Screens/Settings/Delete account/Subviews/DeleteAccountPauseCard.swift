//
//  DeleteAccountPauseCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - "Pause Account" alternative card

struct DeleteAccountPauseCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(DeleteAccountBrand.pauseIconBg)
                        .frame(width: 50, height: 50)
                    Image(systemName: "pause.fill")
                        .font(.title2.weight(.regular))
                        .foregroundColor(DeleteAccountBrand.errorRed)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Pause Account")
                        .font(.brand(.callout, weight: .bold))
                        .foregroundColor(DeleteAccountBrand.onSurface)
                    Text("Temporarily hide your profile\nand services.")
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(DeleteAccountBrand.onSurfaceVar)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.medium))
                    .foregroundColor(DeleteAccountBrand.onSurfaceVar)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(DeleteAccountBrand.cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(DeleteAccountBrand.errorRed.opacity(0.25), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}
