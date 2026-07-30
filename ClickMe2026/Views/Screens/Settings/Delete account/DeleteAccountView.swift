//
//  DeleteAccountView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Delete Account Flow State

enum DeleteAccountStep {
    case confirmation // Image 3: warning + Pause Account card
    case feedback // Image 2: reason selection + comments
    case deleted // Image 1: "We're sorry to see you go"
}

// MARK: - Delete Account View

struct DeleteAccountView: View {
    @StateObject private var viewModel: DeleteAccountViewModel
    @Environment(\.dismiss) private var dismiss

    var onBackToLogin: () -> Void
    var onPauseAccount: () -> Void

    @FocusState private var commentsFocused: Bool

    // MARK: Init

    init(
        viewModel: DeleteAccountViewModel = DeleteAccountViewModel(),
        onBackToLogin: @escaping () -> Void = {},
        onPauseAccount: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onBackToLogin = onBackToLogin
        self.onPauseAccount = onPauseAccount
    }

    // MARK: Body

    var body: some View {
        ZStack {
            (viewModel.step == .deleted ? DeleteAccountBrand.bgDeleted : DeleteAccountBrand.bg)
                .ignoresSafeArea()

            switch viewModel.step {
            case .confirmation:
                confirmationView.transition(.opacity)
            case .feedback:
                feedbackView.transition(.opacity)
            case .deleted:
                DeleteAccountFarewell(onBackToLogin: onBackToLogin)
                    .transition(.opacity)
            }
        }
        .navigationTitle(viewModel.step == .deleted ? "" : "Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(viewModel.step == .deleted ? .hidden : .visible, for: .navigationBar)
        .toolbarBackground(viewModel.step == .deleted ? DeleteAccountBrand.bgDeleted : DeleteAccountBrand.bg,
                           for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .animation(.easeInOut(duration: 0.30), value: viewModel.step)
        .alert(
            "Couldn't delete account",
            isPresented: Binding(
                get: { viewModel.deletionError != nil },
                set: { if !$0 { viewModel.deletionError = nil } }
            ),
            presenting: viewModel.deletionError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    // MARK: ── Step 1: Confirmation ─────────────────────────────────────────

    private var confirmationView: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        DeleteAccountWarningHeader()

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Before you go...")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(DeleteAccountBrand.onSurface)

                            DeleteAccountPauseCard(action: onPauseAccount)
                        }

                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }

            DeleteAccountBottomButtons(
                primaryLabel: "Delete Account",
                primaryEnabled: true,
                isDeleting: viewModel.isDeleting,
                primaryAction: {
                    guard CallCenter.shared.attempt("delete your account") else { return }
                    viewModel.advanceToFeedback()
                },
                secondaryAction: { dismiss() }
            )
        }
    }

    // MARK: ── Step 2: Feedback / Reason ───────────────────────────────────

    private var feedbackView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 28) {
                    DeleteAccountWarningHeader()

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Help us improve")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(DeleteAccountBrand.onSurface)

                        DeleteAccountReasonSection(
                            reasons: viewModel.reasons,
                            selectedReason: $viewModel.selectedReason
                        )

                        DeleteAccountCommentsField(
                            text: $viewModel.additionalComments,
                            isFocused: $commentsFocused
                        )

                        DeleteAccountPasswordField(
                            text: $viewModel.password,
                            errorMessage: viewModel.passwordError
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 24)

                // Bottom buttons sit inline at the end of the form now instead
                // of floating over it. Their component owns its own horizontal
                // padding + top divider + bottom safe-area padding, so it
                // spans the ScrollView edge-to-edge.
                DeleteAccountBottomButtons(
                    primaryLabel: "Delete Account",
                    primaryEnabled: viewModel.canConfirmDeletion,
                    isDeleting: viewModel.isDeleting,
                    primaryAction: {
                        guard CallCenter.shared.attempt("delete your account") else { return }
                        Task { await viewModel.confirmDeletion() }
                    },
                    secondaryAction: { dismiss() }
                )
            }
        }
    }
}

// MARK: - Previews

#Preview("Step 1 — Confirmation") {
    PreviewNavHarness(parentText: "Account", navTitle: "Settings", rowTitle: "Delete account") {
        // Tap "Delete Account" on step 1 to advance in the canvas.
        DeleteAccountView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Step 2 — Feedback") {
    PreviewNavHarness(parentText: "Account", navTitle: "Settings", rowTitle: "Delete account") {
        DeleteAccountView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Step 3 — Deleted") {
    PreviewNavHarness(parentText: "Account", navTitle: "Settings", rowTitle: "Delete account") {
        ZStack {
            DeleteAccountBrand.bgDeleted.ignoresSafeArea()
            DeleteAccountFarewell(onBackToLogin: {})
        }
    }
    .preferredColorScheme(.dark)
}
