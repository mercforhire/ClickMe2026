//
//  MakeABookingTopicPicker.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
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
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(MakeABookingBrand.onSurface)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let topic = viewModel.selectedTopic {
                        HStack(spacing: 8) {
                            Text(topic.durationLabel)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(MakeABookingBrand.onSurfaceVar)
                            Text("·")
                                .foregroundColor(MakeABookingBrand.onSurfaceVar)
                            Text(topic.priceLabel)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(topic.isFree ? MakeABookingBrand.brandGreen : MakeABookingBrand.onSurface)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MakeABookingBrand.onSurfaceVar)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(cardBg)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.topics.isEmpty)
        .confirmationDialog("Topic of Discussion", isPresented: $viewModel.showTopicPicker, titleVisibility: .visible) {
            ForEach(viewModel.topics) { topic in
                Button("\(topic.title) — \(topic.priceLabel)") { viewModel.selectedTopic = topic }
            }
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
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(MakeABookingBrand.onSurfaceVar)
                .lineLimit(2)
            Spacer()
            Button("Retry") { Task { await viewModel.loadTopics() } }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
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
