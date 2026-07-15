//
//  ClientProfileNameBadge.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Centered name + "Client" pill badge

struct ClientProfileNameBadge: View {
    let name: String

    var body: some View {
        VStack(spacing: 10) {
            Text(name)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(ClientProfileBrand.onSurface)

            Text("Client")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
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
