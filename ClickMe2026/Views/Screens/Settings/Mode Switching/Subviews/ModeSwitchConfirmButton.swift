//
//  ModeSwitchConfirmButton.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-16.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - "Continue as ..." primary button

struct ModeSwitchConfirmButton: View {
    let selectedMode: AppMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ModeSwitchBrand.brandGreen)
                    .shadow(color: ModeSwitchBrand.brandGreen.opacity(0.35), radius: 14, x: 0, y: 4)
                    .frame(height: 54)

                Text("Continue as \(selectedMode == .client ? "Client" : "Expert")")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(ModeSwitchBrand.onPrimary)
                    .animation(.none, value: selectedMode)
            }
        }
        .frame(height: 54)
        .buttonStyle(PressScaleButtonStyle())
    }
}
