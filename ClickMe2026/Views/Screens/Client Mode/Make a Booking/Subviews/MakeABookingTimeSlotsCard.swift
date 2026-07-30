//
//  MakeABookingTimeSlotsCard.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct MakeABookingTimeSlotsCard: View {
    @ObservedObject var viewModel: MakeABookingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Available Time Slots")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(MakeABookingBrand.onSurface)
                Spacer()
                if let tz = viewModel.expertTimezone {
                    Text(tz)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(MakeABookingBrand.onSurfaceVar)
                }
            }

            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(MakeABookingBrand.surface)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(MakeABookingBrand.outlineVar, lineWidth: 1))
        )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.availabilityState {
        case .idle, .loading:
            skeletonRow
        case .failed(let message):
            errorRow(message: message)
        case .loaded:
            loadedRow
        }
    }

    @ViewBuilder
    private var loadedRow: some View {
        let slots = viewModel.slotsForSelectedDate
        if slots.isEmpty {
            Text("No available slots on this day.")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(MakeABookingBrand.onSurfaceVar)
                .padding(.vertical, 4)
        } else {
            // ScrollViewReader lets us jump straight to the first
            // still-bookable slot on first appear (and again whenever
            // the user picks a different date) so they don't have to
            // scroll past sold-out / past slots to see what's actually
            // available.
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(slots) { slot in
                            chip(for: slot)
                                .id(slot.id)
                        }
                    }
                }
                .onAppear { scrollToFirstAvailable(with: proxy) }
                .onChange(of: viewModel.selectedDate) { _, _ in
                    scrollToFirstAvailable(with: proxy)
                }
            }
        }
    }

    /// Jump the horizontal slot list to the first slot that's still
    /// bookable — i.e. flagged available AND not already past. Silent
    /// no-op if no slot qualifies (leaves the list wherever it was).
    /// A short delay lets the layout finish before we scroll, otherwise
    /// on cold appear the proxy target hasn't been measured yet and the
    /// call is dropped.
    private func scrollToFirstAvailable(with proxy: ScrollViewProxy) {
        let slots = viewModel.slotsForSelectedDate
        let now = Date()
        guard let target = slots.first(where: { $0.isAvailable && $0.startTime >= now }) else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(target.id, anchor: .leading)
            }
        }
    }

    private var skeletonRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(0 ..< 4, id: \.self) { _ in
                    Capsule()
                        .fill(MakeABookingBrand.surfaceHigh)
                        .frame(width: 84, height: 36)
                }
            }
        }
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
            Button("Retry") {
                Task { await viewModel.loadAvailability(for: viewModel.displayedMonth) }
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(MakeABookingBrand.brandGreen)
        }
    }

    private func chip(for slot: BookingTimeSlot) -> some View {
        let isSelected = viewModel.selectedTimeSlot == slot
        let isPast = viewModel.isPastDate(slot.startTime) || slot.startTime < Date()
        let isDisabled = !slot.isAvailable || isPast

        return Button {
            if !isDisabled { viewModel.selectedTimeSlot = slot }
        } label: {
            Text(slot.displayLabel)
                .font(.system(size: 14, weight: isSelected ? .bold : .regular, design: .rounded))
                .foregroundColor(
                    isSelected ? MakeABookingBrand.onPrimary :
                        isDisabled ? MakeABookingBrand.onSurfaceVar.opacity(0.35) :
                        MakeABookingBrand.onSurface
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? MakeABookingBrand.brandGreen : Color.clear)
                        .overlay(
                            Capsule()
                                .stroke(
                                    isSelected ? MakeABookingBrand.brandGreen :
                                        isDisabled ? MakeABookingBrand.outlineVar.opacity(0.40) :
                                        MakeABookingBrand.outlineVar,
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: isSelected ? MakeABookingBrand.brandGreen.opacity(0.40) : .clear,
                                radius: 6, x: 0, y: 0)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
