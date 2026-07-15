//
//  DeleteAccountBrand.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Design tokens — red-tinted dark

enum DeleteAccountBrand {
    static let bg = Color(red: 0.055, green: 0.035, blue: 0.035)
    static let bgDeleted = Color(red: 0.065, green: 0.030, blue: 0.030)
    static let onSurface = Color(red: 0.920, green: 0.910, blue: 0.910)
    static let onSurfaceVar = Color(red: 0.600, green: 0.580, blue: 0.580)
    static let errorRed = Color(red: 0.929, green: 0.196, blue: 0.196) // #ED3232
    static let errorRedBg = Color(red: 0.929, green: 0.196, blue: 0.196).opacity(0.15)
    static let cardBg = Color(red: 0.110, green: 0.070, blue: 0.070)
    static let rowBg = Color(red: 0.130, green: 0.095, blue: 0.095)
    static let fieldBg = Color(red: 0.125, green: 0.085, blue: 0.085)
    static let fieldBorder = Color(red: 0.240, green: 0.160, blue: 0.160)
    static let pauseIconBg = Color(red: 0.929, green: 0.196, blue: 0.196).opacity(0.25)
    static let deleteBtnDim = Color(red: 0.200, green: 0.150, blue: 0.160)
    static let farewellIconBg = Color(red: 0.35, green: 0.06, blue: 0.06)
}

// MARK: - Button style

struct DeleteScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
