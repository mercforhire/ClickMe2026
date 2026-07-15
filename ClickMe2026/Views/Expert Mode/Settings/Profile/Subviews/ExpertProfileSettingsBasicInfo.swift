//
//  ExpertProfileSettingsBasicInfo.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ExpertProfileSettingsBasicInfo: View {
    @Bindable var viewModel: ExpertProfileSettingsViewModel

    var body: some View {
        HStack(spacing: 12) {
            labeledField(label: "Name", text: $viewModel.name, keyboard: .default)
            labeledField(label: "Email", text: $viewModel.email, keyboard: .emailAddress)
        }
    }

    private func labeledField(label: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ExpertProfileSettingsTheme.fieldBg)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(ExpertProfileSettingsTheme.fieldBorder, lineWidth: 1))
                .frame(minHeight: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(ExpertProfileSettingsTheme.onSurfaceVar)
                TextField("", text: text)
                    .keyboardType(keyboard)
                    .autocapitalization(keyboard == .emailAddress ? .none : .words)
                    .disableAutocorrection(true)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(ExpertProfileSettingsTheme.onSurface)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }
}
