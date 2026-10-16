//
//  BrandFont.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Dynamic-Type-aware system fonts using rounded design — the app's
/// standard. Prefer these over `.system(size:weight:design:)` so text
/// respects the user's Content Size preference in iOS Settings and
/// grows for users who need larger text.
///
/// **Mapping** (chosen to match the app's existing fixed sizes at the
/// default Content Size Category):
///
/// | Original size | Semantic style |
/// |---------------|----------------|
/// | 9, 10, 11     | `.caption2`    |
/// | 12, 13        | `.caption`     |
/// | 14, 15        | `.subheadline` |
/// | 16, 17        | `.body`        |
/// | 18, 20        | `.title3`      |
/// | 22, 24        | `.title2`      |
/// | 26–32         | `.title`       |
///
/// Hero/splash sizes (34pt+) stay as fixed sizes because they're
/// display graphics, not readable content.
extension Font {
    /// Rounded-design system font at a semantic text style. Preserves
    /// the app's rounded aesthetic while letting iOS scale the size.
    ///
    /// - Parameters:
    ///   - style: iOS text style (`.body`, `.callout`, …).
    ///   - weight: Font weight (`.regular` default).
    static func brand(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
}
