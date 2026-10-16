//
//  TransactionsView.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Full paginated earnings ledger, pushed from the "See all activity"
/// row on the Payouts screen. Rendered as a plain list with a
/// tail-visibility trigger driving the next-page fetch — no manual
/// "Load more" button, no floor-mounted spinner.
struct TransactionsView: View {

    @StateObject private var viewModel: TransactionsViewModel

    // MARK: Design tokens — matches Payouts screen
    private let bg = Brand.surface
    private let cardBg = Color(red: 0.110, green: 0.110, blue: 0.115)
    private let cardBorder = Color(red: 0.173, green: 0.173, blue: 0.173)
    private let brandGreen = Brand.primary
    private let onSurface = Brand.onSurface
    private let onSurfaceVar = Color(red: 0.580, green: 0.640, blue: 0.610)

    init(viewModel: TransactionsViewModel = TransactionsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            content
        }
        .navigationTitle("Activity")
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
                    EarningsTransactionRow(item: item)
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
                    VStack(spacing: 6) {
                        Text(error)
                            .font(.brand(.caption, weight: .regular))
                            .foregroundColor(onSurfaceVar)
                            .multilineTextAlignment(.center)
                        Button {
                            Task {
                                // Re-trigger by pretending the last row
                                // was just seen — the guard passes
                                // because `pageError` doesn't gate the
                                // fetch (only `isLoadingMore` + `hasMore`).
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
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - States

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(onSurface)
            Text("Loading activity…")
                .font(.brand(.caption))
                .foregroundColor(onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle")
                .font(.title.weight(.light))
                .foregroundColor(onSurfaceVar)
            Text("No activity yet")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(onSurface)
            Text("Your completed sessions will appear here as they're processed.")
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
            Text("Couldn't load activity")
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

#Preview("Transactions — populated") {
    PreviewNavHarness(parentText: "Payouts", navTitle: "Expert", rowTitle: "Activity") {
        TransactionsView(viewModel: .previewSeed(
            items: TransactionsView.sampleItems,
            hasMore: false
        ))
    }
    .preferredColorScheme(.dark)
}

#Preview("Transactions — empty") {
    PreviewNavHarness(parentText: "Payouts", navTitle: "Expert", rowTitle: "Activity") {
        TransactionsView(viewModel: .previewSeed(items: []))
    }
    .preferredColorScheme(.dark)
}

extension TransactionsView {
    /// Sample rows for previews — covers the three payout_status
    /// branches plus a fully-null row (per spec, orphaned rows still
    /// appear with `—` placeholders).
    static var sampleItems: [EarningsTransactionItem] {
        [
            EarningsTransactionItem(
                id: UUID(),
                bookingId: UUID(),
                sessionDate: ISO8601DateFormatter().date(from: "2026-08-05T14:00:00Z"),
                topicTitle: "Career Advice",
                clientName: "Liam Carter",
                grossAmount: 7500,
                commissionAmount: 1125,
                netAmount: 6375,
                currency: "USD",
                payoutStatus: .paid,
                processedAt: ISO8601DateFormatter().date(from: "2026-08-06T12:00:00Z"),
                createdAt: ISO8601DateFormatter().date(from: "2026-08-05T14:30:00Z") ?? Date()
            ),
            EarningsTransactionItem(
                id: UUID(),
                bookingId: UUID(),
                sessionDate: ISO8601DateFormatter().date(from: "2026-08-03T10:30:00Z"),
                topicTitle: "Product Strategy",
                clientName: "Priya Nair",
                grossAmount: 15000,
                commissionAmount: 2250,
                netAmount: 12750,
                currency: "USD",
                payoutStatus: .processing,
                processedAt: nil,
                createdAt: ISO8601DateFormatter().date(from: "2026-08-03T11:00:00Z") ?? Date()
            ),
            EarningsTransactionItem(
                id: UUID(),
                bookingId: UUID(),
                sessionDate: ISO8601DateFormatter().date(from: "2026-08-01T09:00:00Z"),
                topicTitle: "Design Portfolio Review",
                clientName: "Sam",
                grossAmount: 5000,
                commissionAmount: 750,
                netAmount: 4250,
                currency: "USD",
                payoutStatus: .pending,
                processedAt: nil,
                createdAt: ISO8601DateFormatter().date(from: "2026-08-01T09:30:00Z") ?? Date()
            ),
            EarningsTransactionItem(
                id: UUID(),
                bookingId: nil,
                sessionDate: nil,
                topicTitle: nil,
                clientName: nil,
                grossAmount: 3000,
                commissionAmount: 450,
                netAmount: 2550,
                currency: "USD",
                payoutStatus: .failed,
                processedAt: nil,
                createdAt: ISO8601DateFormatter().date(from: "2026-07-28T00:00:00Z") ?? Date()
            ),
        ]
    }
}
