//
//  MakeABookingTopicSheet.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Full-height sheet that replaces the old `.confirmationDialog` topic
/// menu on the "Book a Session" screen. Each topic renders as a rich
/// card (title, duration, price, description) — the previous menu only
/// showed the title and the price string, which wasn't enough info for
/// clients choosing between multiple topics from the same expert.
///
/// Interaction is tap-to-select: tapping a card writes to
/// `viewModel.selectedTopic` and dismisses via
/// `viewModel.showTopicPicker = false`. The book screen's summary row
/// updates in place.
struct MakeABookingTopicSheet: View {
    @ObservedObject var viewModel: MakeABookingViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                MakeABookingBrand.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.topics) { topic in
                            topicCard(topic)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Choose a Topic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MakeABookingBrand.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        viewModel.showTopicPicker = false
                    }
                    .foregroundColor(MakeABookingBrand.brandGreen)
                }
            }
        }
    }

    // MARK: - Card

    private func topicCard(_ topic: BookingTopic) -> some View {
        let isSelected = viewModel.selectedTopic?.id == topic.id

        return Button {
            // Tap-to-select: assign then dismiss. Guarded on a real
            // change so tapping the current selection just closes
            // without re-firing `didSet` (which would reset the
            // idempotency key on the paid booking attempt).
            if viewModel.selectedTopic?.id != topic.id {
                viewModel.selectedTopic = topic
            }
            viewModel.showTopicPicker = false
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Selection dot — same footprint whether selected or
                // not so the row height stays constant.
                selectionMark(isSelected: isSelected)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(topic.title)
                            .font(.brand(.callout, weight: .semibold))
                            .foregroundColor(MakeABookingBrand.onSurface)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        Text(topic.priceLabel)
                            .font(.brand(.subheadline, weight: .bold))
                            .foregroundColor(
                                topic.isFree
                                    ? MakeABookingBrand.brandGreen
                                    : MakeABookingBrand.onSurface
                            )
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption2.weight(.semibold))
                        Text(topic.durationLabel)
                            .font(.brand(.caption, weight: .medium))
                    }
                    .foregroundColor(MakeABookingBrand.onSurfaceVar)

                    if let description = topic.description, !description.isEmpty {
                        Text(description)
                            .font(.brand(.caption))
                            .foregroundColor(MakeABookingBrand.onSurfaceVar)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 2)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground(isSelected: isSelected))
        }
        .buttonStyle(.plain)
    }

    private func selectionMark(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(
                    isSelected
                        ? MakeABookingBrand.brandGreen
                        : MakeABookingBrand.outlineVar,
                    lineWidth: 1.5
                )
                .frame(width: 22, height: 22)
            if isSelected {
                Circle()
                    .fill(MakeABookingBrand.brandGreen)
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.top, 2) // Vertical align with the title's cap height.
    }

    private func cardBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                isSelected
                    ? MakeABookingBrand.brandGreen.opacity(0.08)
                    : MakeABookingBrand.surface
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected
                            ? MakeABookingBrand.brandGreen
                            : MakeABookingBrand.outlineVar,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
    }
}
