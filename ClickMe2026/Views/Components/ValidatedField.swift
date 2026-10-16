//
//  ValidatedField.swift
//  ClickMe2026
//

import SwiftUI

/// Input row with a leading SF Symbol icon, red border on error, and an error
/// message below. Secure fields (`isSecure: true`) get a trailing eye toggle
/// that switches between masked (`SecureField`) and plain-text (`TextField`)
/// rendering — handy for confirming a typed password without re-typing.
struct ValidatedField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    let error: String?

    /// Drives the eye-toggle for `isSecure` fields. When true, we switch
    /// to a plain `TextField` so the user can read what they've typed.
    /// Local `@State` so each field manages its own visibility — nothing
    /// to plumb from callers.
    @State private var isPasswordVisible: Bool = false

    var body: some View {
        let hasError = error != nil
        let borderColor = hasError ? Brand.destructive : Brand.outlineVariant
        let borderWidth: CGFloat = hasError ? 1.8 : 1.2

        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Brand.surfaceContainer)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .frame(height: 54)
                    .animation(.easeInOut(duration: 0.2), value: hasError)

                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.callout.weight(.regular))
                        .foregroundColor(hasError ? Brand.destructive : Color.white.opacity(0.40))
                        .frame(width: 20)

                    Group {
                        if isSecure && !isPasswordVisible {
                            SecureField("", text: $text)
                                .textContentType(.password)
                        } else if isSecure {
                            // Plain TextField for the "visible" branch of a
                            // secure field. `textContentType(.password)`
                            // keeps password autofill / keychain integration
                            // working the same as SecureField; explicit
                            // capitalization + autocorrect off so the
                            // password doesn't get "helpfully" mangled.
                            TextField("", text: $text)
                                .textContentType(.password)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            TextField("", text: $text)
                                .keyboardType(keyboardType)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                    }
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(Color.white.opacity(0.30))
                            .font(.brand(.callout))
                    }
                    .foregroundColor(.white)
                    .font(.brand(.callout))

                    if isSecure {
                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .font(.callout.weight(.regular))
                                .foregroundColor(Color.white.opacity(0.40))
                                .frame(width: 24, height: 24)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                    }
                }
                .padding(.horizontal, 18)
            }

            if let msg = error {
                Text(msg)
                    .font(.brand(.caption, weight: .medium))
                    .foregroundColor(Brand.destructive)
                    .padding(.leading, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.bottom, 16)
        .animation(.easeInOut(duration: 0.2), value: error)
    }
}
