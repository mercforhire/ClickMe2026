//
//  ReportChatView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Block & Report View

struct ReportChatView: View {

    @StateObject private var viewModel: ReportChatViewModel

    var onBlock: (String) -> Void
    var onReport: (String, String) -> Void
    /// Fired after a successful `unblock`. Callers typically re-fetch
    /// their chat list and either dismiss or update the thread row.
    var onUnblock: (String) -> Void
    var onDismiss: () -> Void

    @FocusState private var descFocused: Bool

    // MARK: Init

    /// Runtime init — hits `POST /chats/:id/actions` with
    /// `action=block` / `action=unblock` / `action=report`. Fetches the
    /// thread's `is_blocked` + `blocked_by_me` on appear so the Block
    /// card lands in the correct state (Block vs Unblock vs "blocked
    /// by them"). Pass `initialIsBlocked` / `initialBlockedByMe` when
    /// the caller already knows (saves one `GET /chats`).
    init(
        threadId: UUID,
        userName: String,
        initialIsBlocked: Bool = false,
        initialBlockedByMe: Bool = false,
        onBlock: @escaping (String) -> Void = { _ in },
        onReport: @escaping (String, String) -> Void = { _, _ in },
        onUnblock: @escaping (String) -> Void = { _ in },
        onDismiss: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: ReportChatViewModel(
            threadId: threadId,
            userName: userName,
            isBlocked: initialIsBlocked,
            blockedByMe: initialBlockedByMe
        ))
        self.onBlock = onBlock
        self.onReport = onReport
        self.onUnblock = onUnblock
        self.onDismiss = onDismiss
    }

    /// Preview / test seam.
    init(
        viewModel: ReportChatViewModel = ReportChatViewModel(),
        onBlock: @escaping (String) -> Void = { _ in },
        onReport: @escaping (String, String) -> Void = { _, _ in },
        onUnblock: @escaping (String) -> Void = { _ in },
        onDismiss: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onBlock = onBlock
        self.onReport = onReport
        self.onUnblock = onUnblock
        self.onDismiss = onDismiss
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ReportChatBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ReportChatBlockCard(
                        isBlocked: viewModel.isBlocked,
                        blockedByMe: viewModel.blockedByMe,
                        isWorking: viewModel.isBlocking,
                        unblockDenied: viewModel.unblockDenied,
                        onBlockTap: { viewModel.showBlockConfirm = true },
                        onUnblockTap: {
                            viewModel.unblockUser { name in
                                onUnblock(name)
                            }
                        }
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
        .task { await viewModel.loadBlockState() }
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

// MARK: - Live-fetch bootstrap

/// Resolves a real `threadId` (and partner name) from `GET /chats`, then
/// hands off to `ReportChatView` — so tapping Block / Submit actually
/// POSTs `/chats/:id/actions` against the live server.
///
/// Tapping Block for real WILL block the counterparty in the dev DB.
/// Use with care.
private struct LiveFetchReportChatBootstrap: View {
    @State private var resolved: (id: UUID, name: String)?
    @State private var errorMessage: String?

    var body: some View {
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

    private func resolveThread() async {
        do {
            let response = try await ClickMeAPI.shared.getChats(page: 1, limit: 1)
            guard let first = response.data.threads.first else {
                errorMessage = "No conversations on this account."
                return
            }
            resolved = (first.threadId, first.partner.name ?? "Chat partner")
        } catch {
            errorMessage = error.userMessage
        }
    }
}

// MARK: - Previews

#Preview("Block & Report") {
    PreviewNavHarness(parentText: "Chat details", navTitle: "Chat", rowTitle: "Block or report") {
        ReportChatView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Reason Error State") {
    PreviewNavHarness(parentText: "Chat details", navTitle: "Chat", rowTitle: "Block or report") {
        ReportChatView(viewModel: ReportChatViewModel(userName: "Dr. Olivia Bennett"))
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return PreviewNavHarness(parentText: "Chat details", navTitle: "Chat", rowTitle: "Block or report") {
        LiveFetchReportChatBootstrap()
    }
    .preferredColorScheme(.dark)
}
