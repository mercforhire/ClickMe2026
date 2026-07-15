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

    // MARK: Inits

    init(viewModel: LoginForgetPassViewModel = LoginForgetPassViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
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

                    fieldLabel("Email or Username")
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
                        Task { await viewModel.attemptSend() }
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

    // MARK: Inline helpers

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
    }
}

// MARK: - Preview harness

private enum ForgetPassPreviewRoute: Hashable {
    case `default`
    case emailError
    case emptyFieldError
    case linkSent
}

/// Wraps the forget-password view inside a NavigationStack with a dummy
/// "Login" parent already pushed, so the system back chevron renders in
/// the canvas.
private struct ForgetPassPreviewHarness: View {
    let route: ForgetPassPreviewRoute
    @State private var path: [ForgetPassPreviewRoute]

    init(route: ForgetPassPreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Login")
                NavigationLink("Forgot password", value: route)
            }
            .navigationTitle("Sign in")
            .navigationDestination(for: ForgetPassPreviewRoute.self) { dest in
                switch dest {
                case .default:
                    LoginForgetPassView()
                case .emailError:
                    LoginForgetPassView(viewModel: LoginForgetPassViewModel(
                        email: "john.doe@notanemail",
                        emailError: "Invalid email format",
                        didAttemptSend: true
                    ))
                case .emptyFieldError:
                    LoginForgetPassView(viewModel: LoginForgetPassViewModel(
                        email: "",
                        emailError: "Please enter your email or username",
                        didAttemptSend: true
                    ))
                case .linkSent:
                    LoginForgetPassView(viewModel: LoginForgetPassViewModel(
                        email: "john.doe@example.com",
                        isSent: true
                    ))
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Default") {
    ForgetPassPreviewHarness(route: .default)
        .preferredColorScheme(.dark)
}

#Preview("Email Error") {
    ForgetPassPreviewHarness(route: .emailError)
        .preferredColorScheme(.dark)
}

#Preview("Empty Field Error") {
    ForgetPassPreviewHarness(route: .emptyFieldError)
        .preferredColorScheme(.dark)
}

#Preview("Code Sent") {
    ForgetPassPreviewHarness(route: .linkSent)
        .preferredColorScheme(.dark)
}
