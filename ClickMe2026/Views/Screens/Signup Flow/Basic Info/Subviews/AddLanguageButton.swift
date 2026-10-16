//
//  AddLanguageButton.swift
//  ClickMe2026
//

import SwiftUI

/// Tappable "Add language..." row that opens the language selection sheet.
struct AddLanguageButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("Add language...")
                    .foregroundColor(BasicInfoBrand.onSurfaceVar.opacity(0.60))
                    .font(.brand(.subheadline))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(BasicInfoBrand.onSurfaceVar.opacity(0.60))
            }
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
