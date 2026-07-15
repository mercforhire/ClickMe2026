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

    /// Runtime init — hits `POST /chats/:id/actions` with `action=block`
    /// / `action=report`.
    init(
        threadId: UUID,
        userName: String,
        onBlock: @escaping (String) -> Void = { _ in },
        onReport: @escaping (String, String) -> Void = { _, _ in },
        onDismiss: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: ReportChatViewModel(
            threadId: threadId,
            userName: userName
        ))
        self.onBlock = onBlock
        self.onReport = onReport
        self.onDismiss = onDismiss
    }

    /// Preview / test seam.
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
                viewModel.blockUser { name in
                    onBlock(name)
                    onDismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They won't be able to contact you or see your profile. They won't be notified.")
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { viewModel.apiError != nil },
                set: { if !$0 { viewModel.apiError = nil } }
            ),
            presenting: viewModel.apiError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
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
                    ReportChatView(viewModel: ReportChatViewModel(userName: "Dr. Olivia Bennett"))
                }
            }
        }
    }
}

/// Resolves a real `threadId` (and partner name) from `GET /chats`, then
/// pushes `ReportChatView` with it — so tapping Block / Submit actually
/// POSTs `/chats/:id/actions` against the live server.
///
/// Tapping Block for real WILL block the counterparty in the dev DB.
/// Use with care.
private struct LiveFetchReportChatHarness: View {
    @State private var resolved: (id: UUID, name: String)?
    @State private var errorMessage: String?
    @State private var path: [ReportChatPreviewRoute] = [.blockReport]

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Chat details")
                NavigationLink("Block or report", value: ReportChatPreviewRoute.blockReport)
            }
            .navigationTitle("Chat")
            .navigationDestination(for: ReportChatPreviewRoute.self) { _ in
                if let r = resolved {
                    ReportChatView(threadId: r.id, userName: r.name)
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                } else {
                    ProgressView("Resolving thread…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                        .task { await resolveThread() }
                }
            }
        }
    }

    private func resolveThread() async {
        do {
            let response = try await ClickMeAPI.shared.getChats(page: 1, limit: 1)
            guard let first = response.data.threads.first else {
                errorMessage = "No conversations on this account."
                return
            }
            resolved = (first.threadId, first.partner.name ?? "Chat partner")
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
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

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return LiveFetchReportChatHarness()
        .preferredColorScheme(.dark)
}
