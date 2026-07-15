//
//  ProfileLabeledField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
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
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(ProfileSettingsBrand.labelColor)
                TextField("", text: $text)
                    .keyboardType(keyboard)
                    .autocapitalization(keyboard == .emailAddress ? .none : .words)
                    .disableAutocorrection(keyboard == .emailAddress)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(ProfileSettingsBrand.onSurface)
                    .tint(ProfileSettingsBrand.brandGreen)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(minHeight: 60)
    }
}
