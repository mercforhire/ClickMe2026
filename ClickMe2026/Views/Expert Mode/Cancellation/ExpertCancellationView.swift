//
//  ExpertCancellationView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-27.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Cancellation Reason

enum CancellationReason: String, CaseIterable, Identifiable {
    case none = "Select a reason..."
    case personalEmergency = "Personal Emergency"
    case schedulingConflict = "Scheduling Conflict"
    case technicalIssues = "Technical Issues"
    case other = "Other"

    var id: String {
        rawValue
    }
}

// MARK: - Expert Cancellation View

struct ExpertCancellationView: View {

    @StateObject private var viewModel: ExpertCancellationViewModel

    // MARK: Callbacks

    var onKeepBooking: () -> Void
    var onConfirm: (CancellationReason) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: Init

    init(
        viewModel: ExpertCancellationViewModel = ExpertCancellationViewModel(),
        onKeepBooking: @escaping () -> Void = {},
        onConfirm: @escaping (CancellationReason) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onKeepBooking = onKeepBooking
        self.onConfirm = onConfirm
    }

    /// Convenience init mirroring the prior signature so existing call sites
    /// that pass individual content fields keep compiling.
    init(
        clientName: String = "Marcus Chen",
        clientImageURL: String = ExpertCancellationViewModel.sampleImageURL,
        sessionTopic: String = "Advanced UX Mentorship",
        dateTime: String = "Wed, Oct 25 • 2:00 PM - 3:00 PM",
        refundType: String = "full refund",
        onKeepBooking: @escaping () -> Void = {},
        onConfirm: @escaping (CancellationReason) -> Void = { _ in }
    ) {
        self.init(
            viewModel: ExpertCancellationViewModel(
                clientName: clientName,
                clientImageURL: clientImageURL,
                sessionTopic: sessionTopic,
                dateTime: dateTime,
                refundType: refundType
            ),
            onKeepBooking: onKeepBooking,
            onConfirm: onConfirm
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ExpertCancellationBrand.bg.ignoresSafeArea()
            ExpertCancellationAmbientGlow().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    ExpertCancellationMainCard(
                        clientName: viewModel.clientName,
                        clientImageURL: viewModel.clientImageURL,
                        sessionTopic: viewModel.sessionTopic,
                        dateTime: viewModel.dateTime,
                        refundType: viewModel.refundType,
                        selectedReason: viewModel.selectedReason,
                        onTapReasonPicker: { viewModel.showReasonPicker = true }
                    )

                    ExpertCancellationActions(
                        isCancelling: viewModel.isCancelling,
                        onKeepBooking: { onKeepBooking(); dismiss() },
                        onConfirm: { viewModel.confirmCancellation(onConfirm: onConfirm) }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Confirm Cancellation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ExpertCancellationBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $viewModel.showReasonPicker) {
            ExpertCancellationReasonSheet(
                selectedReason: viewModel.selectedReason,
                onSelect: { viewModel.selectReason($0) }
            )
            .presentationDetents([.fraction(0.45)])
            .presentationDragIndicator(.visible)
            .presentationBackground(ExpertCancellationBrand.reasonSheetBg)
        }
    }
}

// MARK: - Preview harness

private enum ExpertCancellationPreviewRoute: Hashable {
    case fullRefund
    case partialRefund
}

/// Wraps the expert-cancellation screen inside a NavigationStack with a
/// dummy "Upcoming session" parent already pushed, so the system back
/// chevron renders in the canvas.
private struct ExpertCancellationPreviewHarness: View {
    let route: ExpertCancellationPreviewRoute
    @State private var path: [ExpertCancellationPreviewRoute]

    init(route: ExpertCancellationPreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Booking details")
                NavigationLink("Cancel session", value: route)
            }
            .navigationTitle("Upcoming session")
            .navigationDestination(for: ExpertCancellationPreviewRoute.self) { dest in
                switch dest {
                case .fullRefund:
                    ExpertCancellationView()
                case .partialRefund:
                    ExpertCancellationView(refundType: "partial refund")
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Expert Cancellation") {
    ExpertCancellationPreviewHarness(route: .fullRefund)
        .preferredColorScheme(.dark)
}

#Preview("Partial Refund") {
    ExpertCancellationPreviewHarness(route: .partialRefund)
        .preferredColorScheme(.dark)
}
