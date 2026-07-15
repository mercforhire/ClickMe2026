//
//  ClientProfileHomeBrand.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Design tokens for the profile-home hub screen. Sourced from the shipped
/// "Luminous Dark" palette in DESIGN.md so the screen matches the design
/// system exactly.
enum ClientProfileHomeBrand {
    /// #131313 — page background.
    static let bg = Brand.surface
    /// #1c1b1b — card / list-row background.
    static let cardBg = Color(red: 0.110, green: 0.106, blue: 0.106)
    /// #2a2a2a — icon badge background.
    static let iconBg = Brand.surfaceContainerHigh
    /// #3c4a3f — subtle card border.
    static let outlineVar = Brand.outlineVariant
    /// #44f697 — primary brand accent (icons, edit button, chevron highlight).
    static let primary = Brand.primary
    /// #22e286 — section headers (green, all-caps, tracked).
    static let sectionHeader = Color(red: 0.133, green: 0.886, blue: 0.525)
    /// #e5e2e1 — primary text.
    static let onSurface = Brand.onSurface
    /// #bacbbc — secondary text + chevron.
    static let onSurfaceVar = Brand.onSurfaceVariant
    /// #ffb4ab — destructive (Log Out).
    static let error = Brand.error
    /// #93000a with 20% alpha — Log Out icon badge tint.
    static let errorBg = Color(red: 0.576, green: 0.000, blue: 0.039).opacity(0.20)
}
