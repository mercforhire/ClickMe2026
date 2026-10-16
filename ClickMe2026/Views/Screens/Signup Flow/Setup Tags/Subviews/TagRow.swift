//
//  TagRow.swift
//  ClickMe2026
//

import SwiftUI

/// Row in the suggested-tags list with a tappable add/remove circle icon.
struct TagRow: View {
    let tag: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(tag)
                    .font(.brand(.body, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title2.weight(.regular))
                    .foregroundColor(isSelected ? TagsBrand.green : TagsBrand.green.opacity(0.60))
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
