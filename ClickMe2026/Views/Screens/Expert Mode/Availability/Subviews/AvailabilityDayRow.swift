//
//  AvailabilityDayRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct AvailabilityDayRow: View {
    @Binding var day: DaySchedule
    var onEditSlot: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day header row
            HStack {
                // Checkbox
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        day.isEnabled.toggle()
                        if day.isEnabled && day.slots.isEmpty {
                            day.slots.append(AvailabilityTimeSlot(start: 9 * 60, end: 17 * 60))
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(day.isEnabled ? Brand.primary : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(day.isEnabled
                                        ? Brand.primary
                                        : Brand.onSurfaceVariant.opacity(0.45),
                                        lineWidth: 2)
                            )
                            .frame(width: 22, height: 22)
                        if day.isEnabled {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Brand.onPrimary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Text(day.shortDay)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(day.isEnabled ? Brand.onSurface : Brand.onSurfaceVariant)
                    .frame(width: 36, alignment: .leading)

                Spacer()

                if !day.isEnabled {
                    Text("Unavailable")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(Brand.onSurfaceVariant.opacity(0.60))
                }
            }

            // Time slots (only when enabled)
            if day.isEnabled {
                ForEach(day.slots.indices, id: \.self) { si in
                    HStack(spacing: 10) {
                        timeButton(label: minutesToString(day.slots[si].start)) {
                            onEditSlot(si)
                        }

                        Text("-")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Brand.onSurfaceVariant)

                        timeButton(label: minutesToString(day.slots[si].end)) {
                            onEditSlot(si)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // "Add hours" link when there's already at least one slot
                if !day.slots.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            // Anchor to the latest end across ALL slots,
                            // not just `last` — the user may have edited
                            // an earlier slot to run later, so `last`
                            // isn't necessarily the max. Prevents the
                            // fresh add from overlapping.
                            let maxEnd = day.slots.map(\.end).max() ?? 0
                            let newStart = min(maxEnd + 30, 23 * 60)
                            let newEnd = min(newStart + 60, 24 * 60)
                            day.slots.append(AvailabilityTimeSlot(start: newStart, end: newEnd))
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                            Text("Add hours")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(Brand.primary)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func timeButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .regular, design: .monospaced))
                .foregroundColor(Brand.onSurface)
                .frame(width: 88, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Brand.surfaceContainerHigh)
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Brand.outlineVariant.opacity(0.50), lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
    }
}
