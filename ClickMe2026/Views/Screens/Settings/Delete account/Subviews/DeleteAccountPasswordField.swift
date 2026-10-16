//
//  DeleteAccountPasswordField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-10.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Password re-entry field

/// Confirms the caller's password before the delete-request token is minted
/// (`POST /user/account/delete-request`). Inline error is used to surface a
/// 401/403 "wrong password" response from the server without leaving the
/// screen.
struct DeleteAccountPasswordField: View {
    @Binding var text: String
    var errorMessage: String?

    @State private var isVisible: Bool = false
    @FocusState private var isFocused: Bool

    private var borderColor: Color {
        if errorMessage != nil { return DeleteAccountBrand.errorRed }
        if isFocused { return DeleteAccountBrand.errorRed.opacity(0.55) }
        return DeleteAccountBrand.fieldBorder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Confirm your password")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(DeleteAccountBrand.onSurface)

            HStack(spacing: 0) {
                Group {
                    if isVisible {
                        TextField("Enter your password", text: $text)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    } else {
                        SecureField("Enter your password", text: $text)
                    }
                }
                .focused($isFocused)
                .font(.brand(.subheadline))
                .foregroundColor(DeleteAccountBrand.onSurface)
                .tint(DeleteAccountBrand.errorRed)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .font(.callout.weight(.regular))
                        .foregroundColor(DeleteAccountBrand.onSurfaceVar)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 2)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DeleteAccountBrand.fieldBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: errorMessage == nil ? 1 : 1.5)
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(.brand(.caption, weight: .medium))
                    .foregroundColor(DeleteAccountBrand.errorRed)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
