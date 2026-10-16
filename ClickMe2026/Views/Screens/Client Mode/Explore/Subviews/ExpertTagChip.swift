//
//  ExpertTagChip.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

struct ExpertTagChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.brand(.caption2, weight: .medium))
            .foregroundColor(Color.white.opacity(0.70))
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color(red: 0.16, green: 0.20, blue: 0.18))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
    }
}
