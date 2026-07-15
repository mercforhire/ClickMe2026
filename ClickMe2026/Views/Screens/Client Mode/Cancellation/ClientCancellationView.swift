//
//  ClientCancellationView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct CancellationBooking {
    let expertName: String
    let expertTitle: String
    let dateString: String
    let imageURL: String
    let refundType: String // "full refund", "partial refund", "no refund"
}

enum CancelStep { case reason, confirmation }

// MARK: - Cancellation Flow View

struct ClientCancellationView: View {

    @StateObject private var viewModel: ClientCancellationViewModel

    var onKeepBooking: () -> Void
    var onConfirmCancellation: (String, String) -> Void // (reason, comment)

    @FocusState private var commentFocused: Bool

    // MARK: Init

    init(
        viewModel: ClientCancellationViewModel = ClientCancellationViewModel(),
        onKeepBooking: @escaping () -> Void = {},
        onConfirmCancellation: @escaping (String, String) -> Void = { _, _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onKeepBooking = onKeepBooking
        self.onConfirmCancellation = onConfirmCancellation
    }

    /// Convenience init mirroring the prior signature so existing call sites
    /// that pass a booking + initial step keep working.
    init(
        booking: CancellationBooking = ClientCancellationViewModel.sampleBooking,
        initialStep: CancelStep = .reason,
        onKeepBooking: @escaping () -> Void = {},
        onConfirmCancellation: @escaping (String, String) -> Void = { _, _ in }
    ) {
        self.init(
            viewModel: ClientCancellationViewModel(
                booking: booking,
                step: initialStep
            ),
            onKeepBooking: onKeepBooking,
            onConfirmCancellation: onConfirmCancellation
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            CancellationBrand.bg.ignoresSafeArea()
            GreenGlowBlobLayer().ignoresSafeArea()

            switch viewModel.step {
            case .reason:
                reasonStep
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .confirmation:
                confirmStep
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.28), value: viewModel.step)
    }

    // MARK: - Step 1 — Reason

    private var reasonStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                CancellationReasonHeadline()
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                CancellationReasonCard(
                    reasons: viewModel.reasons,
                    selectedReason: $viewModel.selectedReason
                )

                CancellationCommentField(
                    comment: $viewModel.comment,
                    commentFocused: $commentFocused
                )
                .padding(.horizontal, 20)

                CancellationContinueButton(action: viewModel.advanceToConfirmation)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Step 2 — Confirm

    private var confirmStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                CancellationConfirmCard(booking: viewModel.booking)
                    .padding(.horizontal, 20)

                CancellationActionButtons(
                    isConfirming: viewModel.isConfirming,
                    onKeepBooking: onKeepBooking,
                    onConfirmCancellation: {
                        viewModel.confirmCancellation(onConfirm: onConfirmCancellation)
                    }
                )
                .padding(.horizontal, 20)
            }

            Spacer()
        }
    }
}

// MARK: - Preview harness

private enum ClientCancellationPreviewRoute: Hashable {
    case reason
    case confirmation
}

/// Wraps the cancellation flow inside a NavigationStack with a dummy
/// "My Bookings" parent already pushed, so the system back chevron
/// renders in the canvas.
private struct ClientCancellationPreviewHarness: View {
    let route: ClientCancellationPreviewRoute
    @State private var path: [ClientCancellationPreviewRoute]

    init(route: ClientCancellationPreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Upcoming sessions")
                NavigationLink("Cancel booking", value: route)
            }
            .navigationTitle("My Bookings")
            .navigationDestination(for: ClientCancellationPreviewRoute.self) { dest in
                switch dest {
                case .reason:
                    ClientCancellationView()
                case .confirmation:
                    ClientCancellationView(initialStep: .confirmation)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Step 1 — Reason") {
    ClientCancellationPreviewHarness(route: .reason)
        .preferredColorScheme(.dark)
}

#Preview("Step 2 — Confirm") {
    ClientCancellationPreviewHarness(route: .confirmation)
        .preferredColorScheme(.dark)
}
