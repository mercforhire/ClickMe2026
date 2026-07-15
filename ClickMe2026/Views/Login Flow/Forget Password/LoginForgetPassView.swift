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

    // UI-only animation state
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 16

    // MARK: Inits

    init(viewModel: LoginForgetPassViewModel = LoginForgetPassViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ForgetPassBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForgetPassLogoRow()
                        .padding(.top, 48)
                        .padding(.bottom, 36)

                    ForgetPassTitleSection()
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)

                    ForgetPassEmailField(
                        email: $viewModel.email,
                        error: viewModel.emailError,
                        onChange: { viewModel.emailDidChange() }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                    ForgetPassSendButton(
                        isLoading: viewModel.isLoading,
                        isSent: viewModel.isSent
                    ) {
                        Task { await viewModel.attemptSend() }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    ForgetPassInfoText()
                        .padding(.horizontal, 32)

                    Spacer().frame(height: 60)
                }
            }
        }
        .toolbarBackground(ForgetPassBrand.bg, for: .navigationBar)
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
        .alert(
            "Check your email",
            isPresented: presenting(\.successMessage),
            presenting: viewModel.successMessage
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
}

// MARK: - Previews

#Preview("Default") {
    LoginForgetPassView()
        .preferredColorScheme(.dark)
}

#Preview("Email Error") {
    LoginForgetPassView(viewModel: LoginForgetPassViewModel(
        email: "john.doe@notanemail",
        emailError: "Invalid email format",
        didAttemptSend: true
    ))
    .preferredColorScheme(.dark)
}

#Preview("Empty Field Error") {
    LoginForgetPassView(viewModel: LoginForgetPassViewModel(
        email: "",
        emailError: "Please enter your email or username",
        didAttemptSend: true
    ))
    .preferredColorScheme(.dark)
}

#Preview("Link Sent") {
    LoginForgetPassView(viewModel: LoginForgetPassViewModel(
        email: "john.doe@example.com",
        isSent: true
    ))
    .preferredColorScheme(.dark)
}
