//
//  ForgetPassSendButton.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-13.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ForgetPassSendButton: View {
    let isLoading: Bool
    let isSent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(ForgetPassBrand.green)
                    .shadow(color: ForgetPassBrand.green.opacity(0.40), radius: 12, x: 0, y: 5)
                    .frame(height: 56)

                if isSent {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Link Sent!")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                } else if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Send Reset Link")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 56)
        .disabled(isLoading || isSent)
    }
}
