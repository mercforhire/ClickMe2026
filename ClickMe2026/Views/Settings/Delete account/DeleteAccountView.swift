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

struct ClickMeDeleteAccountView: View {
    @State private var step: DeleteAccountStep = .confirmation
    @Environment(\.dismiss) private var dismiss

    var onBackToLogin: () -> Void
    var onPauseAccount: () -> Void

    // MARK: Step 2 form state

    @State private var selectedReason: String = ""
    @State private var additionalComments: String = ""
    @State private var isDeleting = false
    @FocusState private var commentsFocused: Bool

    private let reasons = [
        "Too expensive",
        "Found an alternative",
        "Privacy concerns",
        "Other",
    ]

    // MARK: Init

    init(
        onBackToLogin: @escaping () -> Void = {},
        onPauseAccount: @escaping () -> Void = {}
    ) {
        self.onBackToLogin = onBackToLogin
        self.onPauseAccount = onPauseAccount
    }

    // MARK: Body

    var body: some View {
        ZStack {
            (step == .deleted ? DeleteAccountBrand.bgDeleted : DeleteAccountBrand.bg)
                .ignoresSafeArea()

            switch step {
            case .confirmation:
                confirmationView.transition(.opacity)
            case .feedback:
                feedbackView.transition(.opacity)
            case .deleted:
                DeleteAccountFarewell(onBackToLogin: onBackToLogin)
                    .transition(.opacity)
            }
        }
        .navigationTitle(step == .deleted ? "" : "Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(step == .deleted ? .hidden : .visible, for: .navigationBar)
        .toolbarBackground(step == .deleted ? DeleteAccountBrand.bgDeleted : DeleteAccountBrand.bg,
                           for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .animation(.easeInOut(duration: 0.30), value: step)
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
                isDeleting: isDeleting,
                primaryAction: {
                    withAnimation { step = .feedback }
                },
                secondaryAction: { dismiss() }
            )
        }
    }

    // MARK: ── Step 2: Feedback / Reason ───────────────────────────────────

    private var feedbackView: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        DeleteAccountWarningHeader()

                        VStack(alignment: .leading, spacing: 16) {
                            Text("Help us improve")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(DeleteAccountBrand.onSurface)

                            DeleteAccountReasonSection(
                                reasons: reasons,
                                selectedReason: $selectedReason
                            )

                            DeleteAccountCommentsField(
                                text: $additionalComments,
                                isFocused: $commentsFocused
                            )
                        }

                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }

            DeleteAccountBottomButtons(
                primaryLabel: "Delete Account",
                primaryEnabled: true,
                isDeleting: isDeleting,
                primaryAction: {
                    withAnimation { isDeleting = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                        withAnimation { step = .deleted }
                    }
                },
                secondaryAction: { dismiss() }
            )
        }
    }
}

// MARK: - Preview harness

private enum DeleteAccountPreviewRoute: Hashable {
    case confirmation
    case feedback
    case deleted
}

/// Wraps the delete-account screen inside a NavigationStack with a dummy
/// "Settings" parent already pushed, so the system back chevron renders
/// in the canvas.
private struct DeleteAccountPreviewHarness: View {
    let route: DeleteAccountPreviewRoute
    @State private var path: [DeleteAccountPreviewRoute]

    init(route: DeleteAccountPreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Account")
                NavigationLink("Delete account", value: route)
            }
            .navigationTitle("Settings")
            .navigationDestination(for: DeleteAccountPreviewRoute.self) { dest in
                switch dest {
                case .confirmation, .feedback:
                    // Step 2 in the canvas: tap "Delete Account" on step 1 to advance.
                    ClickMeDeleteAccountView()
                case .deleted:
                    ZStack {
                        DeleteAccountBrand.bgDeleted.ignoresSafeArea()
                        DeleteAccountFarewell(onBackToLogin: {})
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Step 1 — Confirmation") {
    DeleteAccountPreviewHarness(route: .confirmation)
        .preferredColorScheme(.dark)
}

#Preview("Step 2 — Feedback") {
    DeleteAccountPreviewHarness(route: .feedback)
        .preferredColorScheme(.dark)
}

#Preview("Step 3 — Deleted") {
    DeleteAccountPreviewHarness(route: .deleted)
        .preferredColorScheme(.dark)
}
