//
//  IncomingRequestsTheme.swift
//  ClickMe2026
//
//  Screen-specific extras. Standard palette tokens live in Brand.
//

import SwiftUI

enum IncomingRequestsTheme {
    static let amberColor = Color(red: 1.000, green: 0.720, blue: 0.200)

    static let irisBorder = LinearGradient(
        colors: [
            Color(red: 0.55, green: 0.45, blue: 0.92).opacity(0.60),
            Color(red: 0.28, green: 0.50, blue: 0.90).opacity(0.40),
            Color(red: 0.18, green: 0.75, blue: 0.50).opacity(0.45),
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}
