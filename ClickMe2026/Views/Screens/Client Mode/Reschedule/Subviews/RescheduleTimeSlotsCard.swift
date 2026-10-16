//
//  RescheduleTimeSlotsCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - 4-column grid of pill-shaped time-slot chips

struct RescheduleTimeSlotsCard: View {
    let slots: [BookingTimeSlot]
    let selectedTime: BookingTimeSlot?
    /// Whether a given slot corresponds to the booking's current start
    /// time. Renders it disabled with a "Current" label so the user
    /// can't reschedule to the same slot they're rescheduling from.
    var isCurrent: (BookingTimeSlot) -> Bool = { _ in false }
    let onSelect: (BookingTimeSlot) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Slots")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(RescheduleBrand.onSurface)

            if slots.isEmpty {
                Text("No available slots for the selected day.")
                    .font(.brand(.caption, weight: .regular))
                    .foregroundColor(RescheduleBrand.onSurfaceVar)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    ForEach(slots) { slot in
                        timeChip(slot)
                    }
                }
            }
        }
        .padding(14)
        .background(RescheduleCardBackground())
    }

    private func timeChip(_ slot: BookingTimeSlot) -> some View {
        let isCurrentSlot = isCurrent(slot)
        let isSelected = selectedTime == slot
        // Current slots are always disabled — user can't reschedule to
        // the same time. Rendered with an orange border + "Current"
        // caption so they're distinguishable from generic unavailable
        // (grey) slots.
        let isDisabled = !slot.isAvailable || isCurrentSlot
        return Button {
            guard !isDisabled else { return }
            onSelect(slot)
        } label: {
            VStack(spacing: 1) {
                Text(slot.displayLabel)
                    .font(.system(.caption, design: .rounded).weight(isSelected ? .bold : .medium))
                    .foregroundColor(chipTextColor(
                        isSelected: isSelected,
                        isDisabled: isDisabled,
                        isCurrent: isCurrentSlot
                    ))
                if isCurrentSlot {
                    Text("Current")
                        .font(.brand(.caption2, weight: .semibold))
                        .tracking(0.4)
                        .foregroundColor(.orange.opacity(0.85))
                }
            }
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(RescheduleBrand.chipBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    chipBorderColor(
                                        isSelected: isSelected,
                                        isCurrent: isCurrentSlot
                                    ),
                                    lineWidth: isSelected || isCurrentSlot ? 1.5 : 1
                                )
                                .shadow(
                                    color: isSelected
                                        ? RescheduleBrand.brandGreen.opacity(0.25)
                                        : .clear,
                                    radius: 6
                                )
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private func chipTextColor(isSelected: Bool, isDisabled: Bool, isCurrent: Bool) -> Color {
        if isCurrent { return RescheduleBrand.onSurface.opacity(0.7) }
        if isDisabled { return RescheduleBrand.onSurfaceVar.opacity(0.35) }
        return isSelected ? RescheduleBrand.brandGreen : RescheduleBrand.onSurface
    }

    private func chipBorderColor(isSelected: Bool, isCurrent: Bool) -> Color {
        if isCurrent { return .orange.opacity(0.55) }
        return isSelected ? RescheduleBrand.brandGreen : RescheduleBrand.chipBorder
    }
}
