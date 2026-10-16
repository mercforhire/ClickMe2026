//
//  OrDivider.swift
//  ClickMe2026
//

import SwiftUI

struct OrDivider: View {
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)

            Text("OR")
                .font(.brand(.caption, weight: .medium))
                .foregroundColor(Color.white.opacity(0.40))
                .fixedSize()

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)
        }
    }
}
