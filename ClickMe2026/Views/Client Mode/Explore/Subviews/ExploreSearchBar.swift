//
//  ExploreSearchBar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ExploreSearchBar: View {
    @Binding var text: String
    var onFilter: () -> Void = {}

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(Color.white.opacity(0.38))

            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text("Search for experts, skills, or topics")
                        .foregroundColor(Color.white.opacity(0.28))
                        .font(.system(size: 14, design: .rounded))
                        .lineLimit(1)
                }
                .foregroundColor(.white)
                .font(.system(size: 14, design: .rounded))
                .autocapitalization(.none)
                .disableAutocorrection(true)

            Spacer()

            Button(action: onFilter) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.55))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ExploreBrand.fieldBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ExploreBrand.fieldBorder, lineWidth: 1)
                )
        )
    }
}
