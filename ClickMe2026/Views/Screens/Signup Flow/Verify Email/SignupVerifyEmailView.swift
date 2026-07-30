//
//  SignupVerifyEmailView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-14.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Email Verification Screen

struct SignupVerifyEmailView: View {

    @StateObject private var viewModel: SignupVerifyEmailViewModel

    // UI-only state
    @State private var glowPulse: Bool = false
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 18

    var onChangeEmail: () -> Void
    var onVerified: () -> Void

    // MARK: Init

    init(
        viewModel: SignupVerifyEmailViewModel = SignupVerifyEmailViewModel(),
        onChangeEmail: @escaping () -> Void = {},
        onVerified: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onChangeEmail = onChangeEmail
        self.onVerified = onVerified
    }

    /// Runtime init — reads the email from the accumulator and enables
    /// the real `POST /auth/email/resend` + `POST /auth/email/verify`
    /// calls.
    init(
        accumulator: SignupAccumulator,
        onChangeEmail: @escaping () -> Void = {},
        onVerified: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: SignupVerifyEmailViewModel(accumulator: accumulator))
        self.onChangeEmail = onChangeEmail
        self.onVerified = onVerified
    }

    // MARK: Body

    var body: some View {
        ZStack {
            VerifyEmailBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VerifyEmailHeader()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 52)
                        .padding(.bottom, 36)

                    Text("Email Verification")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 36)

                    EnvelopeGlowBubble(glowPulse: glowPulse)
                        .padding(.bottom, 36)

                    VerifyEmailMessageSection(
                        email: viewModel.email,
                        didSend: viewModel.didResend
                    )
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)

                    // Code entry appears only after the user has actually
                    // requested a code — no point letting them type into a
                    // field before they've triggered the send.
                    if viewModel.didResend {
                        VerifyEmailCodeField(
                            text: $viewModel.code,
                            error: viewModel.codeError
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        .onChange(of: viewModel.code) { viewModel.codeDidChange() }

                        VerifyCodeButton(
                            isLoading: viewModel.isVerifying,
                            isEnabled: viewModel.code.count == 6
                        ) {
                            Task { await viewModel.verify() }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }

                    VStack(spacing: 14) {
                        ResendEmailButton(
                            isResending: viewModel.isResending,
                            resendCooldown: viewModel.resendCooldown,
                            didResend: viewModel.didResend
                        ) {
                            Task { await viewModel.resend() }
                        }

                        ChangeEmailButton(action: onChangeEmail)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            // Fade/slide the content only — background stays opaque so
            // the push transition doesn't briefly reveal white.
            .opacity(contentOpacity)
            .offset(y: contentOffset)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45).delay(0.1)) {
                contentOpacity = 1
                contentOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                glowPulse = true
            }
        }
        .onChange(of: viewModel.isVerified) { _, newValue in
            if newValue { onVerified() }
        }
        .alert(
            "Couldn't send code",
            isPresented: Binding(
                get: { viewModel.resendError != nil },
                set: { if !$0 { viewModel.resendError = nil } }
            ),
            presenting: viewModel.resendError
        ) { _ in
            Button("OK", role: .cancel) { viewModel.resendError = nil }
        } message: { message in
            Text(message)
        }
    }
}

// MARK: - Previews

#Preview("Default — no send yet") {
    SignupVerifyEmailView(viewModel: SignupVerifyEmailViewModel(
        email: "lucas.anderson@example.com"
    ))
    .preferredColorScheme(.dark)
}

#Preview("After Send — code field visible") {
    SignupVerifyEmailView(viewModel: SignupVerifyEmailViewModel(
        email: "lucas.anderson@example.com",
        didResend: true,
        resendCooldown: 27
    ))
    .preferredColorScheme(.dark)
}

#Preview("Bad Code") {
    SignupVerifyEmailView(viewModel: SignupVerifyEmailViewModel(
        email: "lucas.anderson@example.com",
        code: "999999",
        codeError: "Invalid or expired code. Please request a new one.",
        didResend: true,
        resendCooldown: 12
    ))
    .preferredColorScheme(.dark)
}
