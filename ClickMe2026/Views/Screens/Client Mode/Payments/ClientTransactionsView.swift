//
//  ClientTransactionsView.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Full-screen paginated payment history for the client — mirrors the
/// expert-side `TransactionsView` in shape and interaction, but uses
/// the 11-value client payment vocabulary (spec §3) and follows the
/// pagination-500-as-end rule (spec §7 — see the ViewModel).
///
/// Row tap deep-links to `UpcomingBookingView` (in-flight bookings) or
/// `BookingSummaryView` (terminal bookings) — for now we route
/// everything to `UpcomingBookingView`, which itself handles the
/// "already past" case internally.
struct ClientTransactionsView: View {

    @StateObject private var viewModel: ClientTransactionsViewModel

    // MARK: Design tokens — matches Payouts screen palette
    private let bg = Brand.surface
    private let cardBg = Color(red: 0.110, green: 0.110, blue: 0.115)
    private let cardBorder = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let brandGreen = Brand.primary
    private let onSurface = Brand.onSurface
    private let onSurfaceVar = Color(red: 0.580, green: 0.640, blue: 0.610)

    init(viewModel: ClientTransactionsViewModel = ClientTransactionsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            content
        }
        .navigationTitle("Payments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.loadFirstPageIfNeeded() }
        .refreshable { await viewModel.reload() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            loadingContent
        case .failed(let message):
            errorContent(message: message)
        case .loaded:
            if viewModel.isEmptyResult {
                emptyContent
            } else {
                loadedList
            }
        }
    }

    // MARK: - Loaded list

    private var loadedList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                    NavigationLink {
                        UpcomingBookingView(bookingId: item.bookingId)
                    } label: {
                        ClientTransactionRow(item: item)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.loadNextPageIfNeeded(currentItem: item)
                    }

                    if index < viewModel.items.count - 1 {
                        Rectangle()
                            .fill(cardBorder)
                            .frame(height: 1)
                            .padding(.horizontal, 14)
                    }
                }

                if viewModel.isLoadingMore {
                    HStack(spacing: 8) {
                        ProgressView().tint(onSurfaceVar)
                        Text("Loading more…")
                            .font(.brand(.caption, weight: .regular))
                            .foregroundColor(onSurfaceVar)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }

                if let error = viewModel.pageError {
                    // Only reached for non-500 errors — 500 on page > 1
                    // is silently treated as end-of-list per spec §7.
                    VStack(spacing: 6) {
                        Text(error)
                            .font(.brand(.caption, weight: .regular))
                            .foregroundColor(onSurfaceVar)
                            .multilineTextAlignment(.center)
                        Button {
                            Task {
                                if let last = viewModel.items.last {
                                    await viewModel.loadNextPageIfNeeded(currentItem: last)
                                }
                            }
                        } label: {
                            Text("Retry")
                                .font(.brand(.caption, weight: .semibold))
                                .foregroundColor(brandGreen)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(cardBorder, lineWidth: 1))
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
    }

    // MARK: - States

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(onSurface)
            Text("Loading payments…")
                .font(.brand(.caption))
                .foregroundColor(onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.title.weight(.light))
                .foregroundColor(onSurfaceVar)
            Text("No payments yet")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(onSurface)
            Text("Your paid sessions will appear here once you've booked with an expert.")
                .font(.brand(.caption))
                .foregroundColor(onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title.weight(.light))
                .foregroundColor(onSurfaceVar)
            Text("Couldn't load payments")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(onSurface)
            Text(message)
                .font(.brand(.caption))
                .foregroundColor(onSurfaceVar)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(brandGreen))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview("Payments — populated") {
    PreviewNavHarness(parentText: "Profile", navTitle: "Client", rowTitle: "Payments") {
        ClientTransactionsView(viewModel: .previewSeed(
            items: ClientTransactionsView.sampleItems,
            totalCount: ClientTransactionsView.sampleItems.count,
            hasMore: false
        ))
    }
    .preferredColorScheme(.dark)
}

#Preview("Payments — empty") {
    PreviewNavHarness(parentText: "Profile", navTitle: "Client", rowTitle: "Payments") {
        ClientTransactionsView(viewModel: .previewSeed(items: []))
    }
    .preferredColorScheme(.dark)
}

extension ClientTransactionsView {
    /// Sample rows for previews — covers every meaningful payment
    /// status branch including the null-fielded orphan row (which
    /// per spec §"Rendering rule" still renders, not hides).
    static var sampleItems: [ClientTransactionItem] {
        [
            ClientTransactionItem(
                bookingId: UUID(),
                sessionDate: ISO8601DateFormatter().date(from: "2026-08-15T14:00:00Z"),
                topicTitle: "Backend code & API design review",
                expertName: "Sarah Chen",
                expertAvatarUrl: nil,
                amount: 7500,
                currency: "CAD",
                paymentStatus: "captured",
                refundedAmount: 0,
                paidAt: ISO8601DateFormatter().date(from: "2026-08-15T15:45:02Z"),
                refundedAt: nil,
                createdAt: ISO8601DateFormatter().date(from: "2026-08-15T14:23:14Z") ?? Date()
            ),
            ClientTransactionItem(
                bookingId: UUID(),
                sessionDate: ISO8601DateFormatter().date(from: "2026-08-20T10:30:00Z"),
                topicTitle: "Career Advice",
                expertName: "Liam Carter",
                expertAvatarUrl: nil,
                amount: 5000,
                currency: "USD",
                paymentStatus: "requires_capture",
                refundedAmount: 0,
                paidAt: nil,
                refundedAt: nil,
                createdAt: ISO8601DateFormatter().date(from: "2026-08-18T09:00:00Z") ?? Date()
            ),
            ClientTransactionItem(
                bookingId: UUID(),
                sessionDate: ISO8601DateFormatter().date(from: "2026-08-10T16:00:00Z"),
                topicTitle: "Product Strategy Deep Dive",
                expertName: "Priya Nair",
                expertAvatarUrl: nil,
                amount: 15000,
                currency: "USD",
                paymentStatus: "partially_refunded",
                refundedAmount: 5000,
                paidAt: ISO8601DateFormatter().date(from: "2026-08-10T16:45:00Z"),
                refundedAt: nil,
                createdAt: ISO8601DateFormatter().date(from: "2026-08-10T15:30:00Z") ?? Date()
            ),
            ClientTransactionItem(
                bookingId: UUID(),
                sessionDate: ISO8601DateFormatter().date(from: "2026-08-05T09:00:00Z"),
                topicTitle: "Design Portfolio Review",
                expertName: "Sam",
                expertAvatarUrl: nil,
                amount: 3000,
                currency: "USD",
                paymentStatus: "refunded",
                refundedAmount: 3000,
                paidAt: ISO8601DateFormatter().date(from: "2026-08-05T09:45:00Z"),
                refundedAt: nil,
                createdAt: ISO8601DateFormatter().date(from: "2026-08-05T08:30:00Z") ?? Date()
            ),
            ClientTransactionItem(
                bookingId: UUID(),
                sessionDate: ISO8601DateFormatter().date(from: "2026-08-01T11:00:00Z"),
                topicTitle: "UX Audit",
                expertName: "Chen Wei",
                expertAvatarUrl: nil,
                amount: 12000,
                currency: "USD",
                paymentStatus: "failed",
                refundedAmount: 0,
                paidAt: nil,
                refundedAt: nil,
                createdAt: ISO8601DateFormatter().date(from: "2026-08-01T10:30:00Z") ?? Date()
            ),
            ClientTransactionItem(
                bookingId: UUID(),
                sessionDate: nil,
                topicTitle: nil,
                expertName: nil,
                expertAvatarUrl: nil,
                amount: 5000,
                currency: "USD",
                paymentStatus: "none",  // legacy row with real amount — should render "Processed"
                refundedAmount: 0,
                paidAt: nil,
                refundedAt: nil,
                createdAt: ISO8601DateFormatter().date(from: "2026-07-28T00:00:00Z") ?? Date()
            ),
        ]
    }
}
