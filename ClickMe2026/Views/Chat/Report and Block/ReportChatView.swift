//
//  ReportChatView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Block & Report View

struct ReportChatView: View {

    @StateObject private var viewModel: ReportChatViewModel

    var onBlock: (String) -> Void
    var onReport: (String, String) -> Void
    var onDismiss: () -> Void

    @FocusState private var descFocused: Bool

    // MARK: Init

    init(
        viewModel: ReportChatViewModel = ReportChatViewModel(),
        onBlock: @escaping (String) -> Void = { _ in },
        onReport: @escaping (String, String) -> Void = { _, _ in },
        onDismiss: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onBlock = onBlock
        self.onReport = onReport
        self.onDismiss = onDismiss
    }

    /// Convenience init mirroring the prior signature so existing call sites
    /// that pass a userName keep compiling.
    init(
        userName: String,
        onBlock: @escaping (String) -> Void = { _ in },
        onReport: @escaping (String, String) -> Void = { _, _ in },
        onDismiss: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: ReportChatViewModel(userName: userName),
            onBlock: onBlock,
            onReport: onReport,
            onDismiss: onDismiss
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ReportChatBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ReportChatBlockCard(
                        onBlockTap: { viewModel.showBlockConfirm = true }
                    )

                    ReportChatReportCard(
                        reasons: viewModel.reasons,
                        selectedReason: viewModel.selectedReason,
                        showReasonError: viewModel.showReasonError,
                        description: $viewModel.description,
                        descFocused: $descFocused,
                        isSubmitting: viewModel.isSubmitting,
                        didSubmit: viewModel.didSubmit,
                        onSelectReason: { viewModel.selectReason($0) },
                        onSubmit: { viewModel.submitReport(onReport: onReport) }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Block & Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ReportChatBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .confirmationDialog(
            "Block \(viewModel.userName)?",
            isPresented: $viewModel.showBlockConfirm,
            titleVisibility: .visible
        ) {
            Button("Block User", role: .destructive) {
                onBlock(viewModel.userName)
                onDismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They won't be able to contact you or see your profile. They won't be notified.")
        }
    }
}

// MARK: - Preview harness

private enum ReportChatPreviewRoute: Hashable {
    case blockReport
    case errorState
}

/// Wraps the block/report screen inside a NavigationStack with a dummy
/// "Chat" parent already pushed, so the system back chevron renders in
/// the canvas.
private struct ReportChatPreviewHarness: View {
    let route: ReportChatPreviewRoute
    @State private var path: [ReportChatPreviewRoute]

    init(route: ReportChatPreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Chat details")
                NavigationLink("Block or report", value: route)
            }
            .navigationTitle("Chat")
            .navigationDestination(for: ReportChatPreviewRoute.self) { dest in
                switch dest {
                case .blockReport:
                    ReportChatView()
                case .errorState:
                    ReportChatView(userName: "Dr. Olivia Bennett")
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Block & Report") {
    ReportChatPreviewHarness(route: .blockReport)
        .preferredColorScheme(.dark)
}

#Preview("Reason Error State") {
    ReportChatPreviewHarness(route: .errorState)
        .preferredColorScheme(.dark)
}
