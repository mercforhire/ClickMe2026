//
//  DeleteAccountBottomButtons.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Pinned bottom Delete + Cancel buttons

struct DeleteAccountBottomButtons: View {
    let primaryLabel: String
    let primaryEnabled: Bool
    let isDeleting: Bool
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider().background(Color.white.opacity(0.08))

            VStack(spacing: 10) {
                Button(action: primaryAction) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(primaryEnabled ? DeleteAccountBrand.errorRed : DeleteAccountBrand.deleteBtnDim)
                            .frame(height: 56)
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(primaryLabel)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(!primaryEnabled || isDeleting)
                .buttonStyle(DeleteScaleStyle())

                Button(action: secondaryAction) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(DeleteAccountBrand.onSurfaceVar)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 36)
            .background(DeleteAccountBrand.bg)
        }
    }
}
