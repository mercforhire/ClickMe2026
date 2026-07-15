//
//  RescheduleTimeSlotsCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - 4-column grid of pill-shaped time-slot chips

struct RescheduleTimeSlotsCard: View {
    let slots: [BookingTimeSlot]
    let selectedTime: BookingTimeSlot?
    let onSelect: (BookingTimeSlot) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Slots")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(RescheduleBrand.onSurface)

            if slots.isEmpty {
                Text("No available slots for the selected day.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
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
        let isSelected = selectedTime == slot
        let isDisabled = !slot.isAvailable
        return Button {
            guard !isDisabled else { return }
            onSelect(slot)
        } label: {
            Text(slot.displayLabel)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(
                    isDisabled
                        ? RescheduleBrand.onSurfaceVar.opacity(0.35)
                        : (isSelected ? RescheduleBrand.brandGreen : RescheduleBrand.onSurface)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(RescheduleBrand.chipBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    isSelected
                                        ? RescheduleBrand.brandGreen
                                        : RescheduleBrand.chipBorder,
                                    lineWidth: isSelected ? 1.5 : 1
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
}
