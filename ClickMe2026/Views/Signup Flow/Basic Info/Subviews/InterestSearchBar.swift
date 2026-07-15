//
//  InterestSearchBar.swift
//  ClickMe2026
//

import SwiftUI

/// Pill-shaped search field used to filter the interests grid.
struct InterestSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(BasicInfoBrand.onSurfaceVar)

            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text("Search interests...")
                        .foregroundColor(BasicInfoBrand.onSurfaceVar)
                        .font(.system(size: 14, design: .rounded))
                }
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(BasicInfoBrand.onSurface)
                .tint(BasicInfoBrand.brandGreen)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(
            Capsule()
                .fill(BasicInfoBrand.fieldBg)
                .overlay(Capsule().stroke(BasicInfoBrand.fieldBorder, lineWidth: 1))
        )
    }
}
