//
//  ClientProfileEditableField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - Floating-label field with a single-line or multiline text input

struct ClientProfileEditableField: View {
    let label: String
    @Binding var text: String
    let isMultiline: Bool
    var keyboard: UIKeyboardType = .default

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ClientProfileBrand.fieldBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(ClientProfileBrand.fieldBorder, lineWidth: 1)
                )
                .frame(minHeight: isMultiline ? 110 : 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(ClientProfileBrand.onSurfaceVar)

                if isMultiline {
                    TextEditor(text: $text)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .foregroundColor(ClientProfileBrand.onSurface)
                        .font(.system(size: 16, design: .rounded))
                        .frame(minHeight: 72)
                        .tint(ClientProfileBrand.brandGreen)
                } else {
                    TextField("", text: $text)
                        .keyboardType(keyboard)
                        .autocapitalization(keyboard == .emailAddress ? .none : .words)
                        .disableAutocorrection(keyboard == .emailAddress)
                        .foregroundColor(ClientProfileBrand.onSurface)
                        .font(.system(size: 16, design: .rounded))
                        .tint(ClientProfileBrand.brandGreen)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }
}
