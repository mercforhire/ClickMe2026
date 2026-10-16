//
//  ForgetPassSendButton.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-13.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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
                            .font(.title3.weight(.semibold))
                        Text("Code Sent!")
                            .font(.brand(.title3, weight: .semibold))
                    }
                    .foregroundColor(.white)
                } else if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Send Reset Code")
                        .font(.brand(.title3, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 56)
        .disabled(isLoading || isSent)
    }
}
