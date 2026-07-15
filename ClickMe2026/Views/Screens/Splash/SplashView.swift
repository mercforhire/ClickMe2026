//
//  SplashScreenView.swift
//  ClickMe
//
//  A dark splash screen with a glowing green "heart + cursor" mark,
//  the ClickMe wordmark, and a tagline. Fades/scales in on appear and
//  calls `onFinished` after a short delay so you can route to your
//  first real screen.
//
//  Deployment target: iOS 16+
//

import SwiftUI

// MARK: - Splash Screen

struct SplashScreenView: View {

    /// Called once the splash animation + auto-login check have resolved,
    /// with the destination the app should route to.
    var onFinished: (SplashDestination) -> Void

    @State private var viewModel: SplashViewModel
    @State private var logoOpacity = 0.0
    @State private var logoScale   = 0.82
    @State private var glowPulse   = false
    @State private var textOpacity = 0.0

    init(
        viewModel: SplashViewModel = SplashViewModel(),
        onFinished: @escaping (SplashDestination) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onFinished = onFinished
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 30) {
                logo

                VStack(spacing: 12) {
                    Text("ClickMe")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(.white)
                        .kerning(0.5)

                    Text("Book time with the best minds.")
                        .font(.system(size: 19, weight: .regular))
                        .foregroundColor(Brand.onSurfaceMuted)
                }
                .opacity(textOpacity)
            }
            .offset(y: -20) // sit slightly above true center, like the mock
        }
        .ignoresSafeArea()
        .onAppear(perform: playAnimations)
        .task {
            await viewModel.start()
        }
        .onChange(of: viewModel.destination) { _, destination in
            if let destination { onFinished(destination) }
        }
    }

    // MARK: Background

    private var background: some View {
        RadialGradient(
            colors: [Color(white: 0.09), Color(white: 0.035)],
            center: .center,
            startRadius: 8,
            endRadius: 520
        )
    }

    // MARK: Logo (glow + mark)

    private var logo: some View {
        ZStack {
            // Soft pulsing halo behind the mark.
            Circle()
                .fill(Brand.primary)
                .frame(width: 190, height: 190)
                .blur(radius: 65)
                .opacity(glowPulse ? 0.45 : 0.28)
                .scaleEffect(glowPulse ? 1.05 : 0.95)

            ClickMeMark()
                .frame(width: 148, height: 148)
        }
        .opacity(logoOpacity)
        .scaleEffect(logoScale)
    }

    // MARK: Animation

    private func playAnimations() {
        withAnimation(.easeOut(duration: 0.7)) {
            logoOpacity = 1
            logoScale = 1
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.35)) {
            textOpacity = 1
        }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
    }
}

// MARK: - Preview

#Preview {
    SplashScreenView()
}
