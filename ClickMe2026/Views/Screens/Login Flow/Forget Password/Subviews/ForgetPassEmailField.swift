//
//  ForgetPassEmailField.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-13.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ForgetPassEmailField: View {
    @Binding var email: String
    var error: String?
    var onChange: () -> Void

    var body: some View {
        let hasError = error != nil
        let border = hasError ? ForgetPassBrand.errorRed : ForgetPassBrand.fieldBorder
        let width: CGFloat = hasError ? 1.8 : 0

        return VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ForgetPassBrand.fieldBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(border, lineWidth: width)
                    )
                    .frame(height: 56)
                    .animation(.easeInOut(duration: 0.2), value: hasError)

                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .font(.system(size: 16))
                        .foregroundColor(hasError ? ForgetPassBrand.errorRed : Color.white.opacity(0.40))
                        .frame(width: 20)

                    TextField("", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .placeholder(when: email.isEmpty) {
                            Text("Email")
                                .foregroundColor(Color.white.opacity(0.30))
                                .font(.system(size: 16, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .font(.system(size: 16, design: .rounded))
                        .onChange(of: email) { onChange() }
                }
                .padding(.horizontal, 18)
            }

            if let msg = error {
                Text(msg)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(ForgetPassBrand.errorRed)
                    .padding(.leading, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: error)
    }
}
