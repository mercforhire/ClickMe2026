//
//  DeleteAccountFarewell.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Farewell screen — icon + "We're sorry to see you go" + Back to Login

struct DeleteAccountFarewell: View {
    let onBackToLogin: () -> Void

    @State private var iconScale: CGFloat = 0.70
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 16

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(DeleteAccountBrand.farewellIconBg)
                            .frame(width: 100, height: 100)

                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 46, weight: .regular))
                            .foregroundColor(DeleteAccountBrand.errorRed)
                    }
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                    VStack(spacing: 12) {
                        Text("We're sorry to see\nyou go!")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(DeleteAccountBrand.onSurface)
                            .multilineTextAlignment(.center)

                        Text("Your account has been successfully deleted.\nWe hope to see you again soon.")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(DeleteAccountBrand.onSurfaceVar)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .opacity(textOpacity)
                    .offset(y: textOffset)
                }
                .padding(.horizontal, 32)

                Spacer()
                Spacer()
            }
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.15)) {
                    iconScale = 1.0
                    iconOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.45).delay(0.40)) {
                    textOpacity = 1
                    textOffset = 0
                }
            }

            Button(action: onBackToLogin) {
                Text("Back to Login")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(DeleteAccountBrand.errorRed)
                    )
            }
            .buttonStyle(DeleteScaleStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}
