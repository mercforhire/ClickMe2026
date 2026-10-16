//
//  ClientProfileNameBadge.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Centered name + "Client" pill badge

struct ClientProfileNameBadge: View {
    let name: String

    var body: some View {
        VStack(spacing: 10) {
            Text(name)
                .font(.brand(.title, weight: .bold))
                .foregroundColor(ClientProfileBrand.onSurface)

            Text("Client")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(ClientProfileBrand.onSurfaceVar)
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(ClientProfileBrand.chipBg)
                        .overlay(Capsule().stroke(ClientProfileBrand.outlineVar, lineWidth: 1))
                )
        }
    }
}
