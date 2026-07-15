//
//  LoginForgetPassView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-13.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Reset Password Screen

struct LoginForgetPassView: View {

    @StateObject private var viewModel: LoginForgetPassViewModel
    @Environment(\.dismiss) private var dismiss

    // UI-only animation state
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 16

    /// Invoked once the backend accepts the reset request. Delivers the
    /// trimmed email so the next screen can prefill it for `/auth/password/reset`.
    var onCodeSent: (String) -> Void

    // MARK: Inits

    init(
        viewModel: LoginForgetPassViewModel = LoginForgetPassViewModel(),
        onCodeSent: @escaping (String) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onCodeSent = onCodeSent
    }

    // MARK: Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ForgetPassBrand.bgTop, ForgetPassBrand.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Enter your email to receive a password reset code")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.55))
                        .padding(.top, 28)
                        .padding(.horizontal, 24)

                    fieldLabel("Email")
                        .padding(.top, 32)
                        .padding(.horizontal, 24)

                    ForgetPassEmailField(
                        email: $viewModel.email,
                        error: viewModel.emailError,
                        onChange: { viewModel.emailDidChange() }
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    ForgetPassSendButton(
                        isLoading: viewModel.isLoading,
                        isSent: viewModel.isSent
                    ) {
                        Task {
                            if let email = await viewModel.attemptSend() {
                                onCodeSent(email)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

                    ForgetPassInfoText()
                        .padding(.horizontal, 32)
                        .padding(.top, 24)
                        .frame(maxWidth: .infinity)

                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back to Login")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(ForgetPassBrand.green)
                    }
                    .padding(.top, 32)
                    .frame(maxWidth: .infinity)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ForgetPassBrand.bgTop, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .opacity(contentOpacity)
        .offset(y: contentOffset)
        .onAppear {
            withAnimation(.easeOut(duration: 0.45).delay(0.1)) {
                contentOpacity = 1
                contentOffset = 0
            }
        }
        .alert(
            "Something went wrong",
            isPresented: presenting(\.apiError),
            presenting: viewModel.apiError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    /// Binding that's `true` while the given optional property is non-nil, and
    /// clears it when the alert dismisses.
    private func presenting(_ keyPath: ReferenceWritableKeyPath<LoginForgetPassViewModel, String?>) -> Binding<Bool> {
        Binding(
            get: { viewModel[keyPath: keyPath] != nil },
            set: { if !$0 { viewModel[keyPath: keyPath] = nil } }
        )
    }

    // MARK: Inline helpers

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
    }
}

// MARK: - Previews

#if DEBUG
private func forgetPassPreview<Content: View>(@ViewBuilder _ content: @escaping () -> Content) -> some View {
    PreviewNavHarness(parentText: "Login", navTitle: "Sign in", rowTitle: "Forgot password") {
        content()
    }
    .preferredColorScheme(.dark)
}
#endif

#Preview("Default") {
    forgetPassPreview { LoginForgetPassView() }
}

#Preview("Email Error") {
    forgetPassPreview {
        LoginForgetPassView(viewModel: LoginForgetPassViewModel(
            email: "john.doe@notanemail",
            emailError: "Invalid email format",
            didAttemptSend: true
        ))
    }
}

#Preview("Empty Field Error") {
    forgetPassPreview {
        LoginForgetPassView(viewModel: LoginForgetPassViewModel(
            email: "",
            emailError: "Please enter your email",
            didAttemptSend: true
        ))
    }
}

#Preview("Code Sent") {
    forgetPassPreview {
        LoginForgetPassView(viewModel: LoginForgetPassViewModel(
            email: "john.doe@example.com",
            isSent: true
        ))
    }
}
