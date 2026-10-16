//
//  MakeABookingTopicPicker.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

struct MakeABookingTopicPicker: View {
    @ObservedObject var viewModel: MakeABookingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MakeABookingSectionHeader(title: "Topic of Discussion")

            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.topicsState {
        case .idle, .loading:
            skeletonRow
        case .failed(let message):
            errorRow(message: message)
        case .loaded:
            loadedButton
        }
    }

    private var loadedButton: some View {
        Button { viewModel.showTopicPicker = true } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.selectedTopic?.title ?? "Select a topic")
                        .font(.brand(.subheadline, weight: .semibold))
                        .foregroundColor(MakeABookingBrand.onSurface)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let topic = viewModel.selectedTopic {
                        HStack(spacing: 8) {
                            Text(topic.durationLabel)
                                .font(.brand(.caption, weight: .medium))
                                .foregroundColor(MakeABookingBrand.onSurfaceVar)
                            Text("·")
                                .foregroundColor(MakeABookingBrand.onSurfaceVar)
                            Text(topic.priceLabel)
                                .font(.brand(.caption, weight: .semibold))
                                .foregroundColor(topic.isFree ? MakeABookingBrand.brandGreen : MakeABookingBrand.onSurface)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(MakeABookingBrand.onSurfaceVar)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(cardBg)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.topics.isEmpty)
        // Full-height sheet replaces the previous `.confirmationDialog`
        // — the old menu couldn't show descriptions or a rich per-row
        // layout, which experts started asking for once topic count
        // started varying meaningfully per profile. The sheet is
        // tap-to-select and self-dismisses.
        .sheet(isPresented: $viewModel.showTopicPicker) {
            MakeABookingTopicSheet(viewModel: viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(MakeABookingBrand.bg)
        }
    }

    private var skeletonRow: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(MakeABookingBrand.surfaceHigh)
                .frame(height: 16)
            Spacer(minLength: 32)
            RoundedRectangle(cornerRadius: 4)
                .fill(MakeABookingBrand.surfaceHigh)
                .frame(width: 60, height: 16)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(cardBg)
        .redacted(reason: .placeholder)
    }

    private func errorRow(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(MakeABookingBrand.onSurfaceVar)
            Text(message)
                .font(.brand(.caption))
                .foregroundColor(MakeABookingBrand.onSurfaceVar)
                .lineLimit(2)
            Spacer()
            Button("Retry") { Task { await viewModel.loadTopics() } }
                .font(.brand(.caption, weight: .semibold))
                .foregroundColor(MakeABookingBrand.brandGreen)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(cardBg)
    }

    private var cardBg: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(MakeABookingBrand.surface)
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(MakeABookingBrand.outlineVar, lineWidth: 1))
    }
}
