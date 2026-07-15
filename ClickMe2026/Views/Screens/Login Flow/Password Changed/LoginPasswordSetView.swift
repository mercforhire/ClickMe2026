//
//  LoginPasswordSetView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-14.
//  Copyright © 2026 Q42. All rights reserved.
//
import SwiftUI

// MARK: - Password Updated View

struct LoginPasswordSetView: View {
    var onGoToLogin: () -> Void

    // MARK: Entry animation state

    @State private var checkScale: CGFloat = 0.40
    @State private var checkOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var btnOpacity: Double = 0
    @State private var btnOffset: CGFloat = 16

    // MARK: Init

    init(onGoToLogin: @escaping () -> Void = {}) {
        self.onGoToLogin = onGoToLogin
    }

    var body: some View {
        ZStack {
            PasswordUpdatedBrand.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    GlowingCheckmark(
                        scale: checkScale,
                        opacity: checkOpacity,
                        glowRadius: glowRadius
                    )
                    PasswordUpdatedHeadline(
                        opacity: textOpacity,
                        offset: textOffset
                    )
                }

                Spacer()

                GoToLoginButton(action: onGoToLogin)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                    .opacity(btnOpacity)
                    .offset(y: btnOffset)
            }
        }
        .onAppear { runEntryAnimation() }
    }

    // MARK: - Entry animation

    private func runEntryAnimation() {
        // 1. Checkmark springs in
        withAnimation(.spring(response: 0.55, dampingFraction: 0.58).delay(0.15)) {
            checkScale = 1.0
            checkOpacity = 1.0
        }
        // 2. Glow pulses open
        withAnimation(.easeOut(duration: 0.55).delay(0.30)) {
            glowRadius = 12
        }
        // 3. Text slides up
        withAnimation(.easeOut(duration: 0.45).delay(0.52)) {
            textOpacity = 1.0
            textOffset = 0
        }
        // 4. Button fades in
        withAnimation(.easeOut(duration: 0.40).delay(0.70)) {
            btnOpacity = 1.0
            btnOffset = 0
        }
    }
}

// MARK: - Preview

#Preview("Password Updated") {
    LoginPasswordSetView()
        .preferredColorScheme(.dark)
}
