//
//  ProfileLabeledField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Single rounded labeled text field

struct ProfileLabeledField: View {
    let label: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ProfileSettingsBrand.fieldBg)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(ProfileSettingsBrand.fieldBorder, lineWidth: 1))
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.brand(.caption2, weight: .semibold))
                    .foregroundColor(ProfileSettingsBrand.labelColor)
                TextField("", text: $text)
                    .keyboardType(keyboard)
                    .autocapitalization(Self.suppressesCase(for: keyboard) ? .none : .words)
                    .disableAutocorrection(Self.suppressesCase(for: keyboard))
                    .font(.brand(.subheadline))
                    .foregroundColor(ProfileSettingsBrand.onSurface)
                    .tint(ProfileSettingsBrand.brandGreen)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(minHeight: 60)
    }

    /// Keyboards that should never auto-capitalize the first letter or
    /// run autocorrect (emails and URLs both look wrong when Swiftified).
    private static func suppressesCase(for keyboard: UIKeyboardType) -> Bool {
        switch keyboard {
        case .emailAddress, .URL: return true
        default:                  return false
        }
    }
}
