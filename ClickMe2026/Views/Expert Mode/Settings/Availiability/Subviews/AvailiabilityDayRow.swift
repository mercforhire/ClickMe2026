//
//  AvailiabilityDayRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct AvailiabilityDayRow: View {
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
                            .fill(day.isEnabled ? AvailiabilityTheme.brandGreen : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(day.isEnabled
                                        ? AvailiabilityTheme.brandGreen
                                        : AvailiabilityTheme.onSurfaceVar.opacity(0.45),
                                        lineWidth: 2)
                            )
                            .frame(width: 22, height: 22)
                        if day.isEnabled {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AvailiabilityTheme.onPrimary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Text(day.shortDay)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(day.isEnabled ? AvailiabilityTheme.onSurface : AvailiabilityTheme.onSurfaceVar)
                    .frame(width: 36, alignment: .leading)

                Spacer()

                if !day.isEnabled {
                    Text("Unavailable")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(AvailiabilityTheme.onSurfaceVar.opacity(0.60))
                }
            }

            // Time slots (only when enabled)
            if day.isEnabled {
                ForEach(day.slots.indices, id: \.self) { si in
                    HStack(spacing: 10) {
                        // Start time button
                        timeButton(label: minutesToString(day.slots[si].start)) {
                            onEditSlot(si)
                        }

                        Text("-")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AvailiabilityTheme.onSurfaceVar)

                        // End time button
                        timeButton(label: minutesToString(day.slots[si].end)) {
                            onEditSlot(si)
                        }

                        Spacer()

                        // Add slot
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                let newStart = day.slots[si].end + 30
                                let newEnd = min(newStart + 60, 24 * 60)
                                day.slots.append(AvailabilityTimeSlot(start: newStart, end: newEnd))
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AvailiabilityTheme.brandGreen)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // "Add hours" link when there's already at least one slot
                if !day.slots.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            let last = day.slots.last!
                            let newStart = last.end + 30
                            let newEnd = min(newStart + 60, 24 * 60)
                            day.slots.append(AvailabilityTimeSlot(start: newStart, end: newEnd))
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("Add hours")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(AvailiabilityTheme.brandGreen)
                        .padding(.leading, 32)
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
                .foregroundColor(AvailiabilityTheme.onSurface)
                .frame(width: 88, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AvailiabilityTheme.surfaceField)
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(AvailiabilityTheme.outlineVar.opacity(0.50), lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
    }
}
