//
//  AllCategoriesSearchBar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Categories search bar

struct AllCategoriesSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(AllCategoriesBrand.brandGreen)

            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text("Search categories...")
                        .foregroundColor(AllCategoriesBrand.onSurfaceVar)
                        .font(.system(size: 15, design: .rounded))
                }
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(AllCategoriesBrand.onSurface)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .tint(AllCategoriesBrand.brandGreen)

            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AllCategoriesBrand.onSurfaceVar.opacity(0.60))
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AllCategoriesBrand.fieldBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AllCategoriesBrand.brandGreen.opacity(0.50), lineWidth: 1.2)
                )
        )
    }
}
