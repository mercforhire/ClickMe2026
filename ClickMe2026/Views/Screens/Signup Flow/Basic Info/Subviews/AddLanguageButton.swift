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
                    .font(.system(size: 14, design: .rounded))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(BasicInfoBrand.onSurfaceVar.opacity(0.60))
            }
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
