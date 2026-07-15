//
//  TagsSearchBar.swift
//  ClickMe2026
//

import SwiftUI

/// Rounded pill search field with a magnifier icon and an optional clear button.
struct TagsSearchBar: View {
    @Binding var text: String
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Color.white.opacity(0.38))

            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text("Search for tags")
                        .foregroundColor(Color.white.opacity(0.30))
                        .font(.system(size: 16, design: .rounded))
                }
                .foregroundColor(.white)
                .font(.system(size: 16, design: .rounded))
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if !text.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color.white.opacity(0.35))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(TagsBrand.fieldBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(TagsBrand.fieldBorder, lineWidth: 1)
                )
        )
    }
}
