//
//  SearchExpertSearchBar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Search field with clear button

struct SearchExpertSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(SearchExpertBrand.onSurfaceVar)

            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text("Search for experts")
                        .foregroundColor(SearchExpertBrand.onSurfaceVar)
                        .font(.system(size: 16, design: .rounded))
                }
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(SearchExpertBrand.onSurface)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .tint(SearchExpertBrand.brandGreen)

            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(SearchExpertBrand.onSurfaceVar.opacity(0.60))
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(SearchExpertBrand.fieldBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(SearchExpertBrand.brandGreen.opacity(0.55), lineWidth: 1.2)
                        .shadow(color: SearchExpertBrand.brandGreen.opacity(0.15), radius: 6)
                )
        )
    }
}
