//
//  TimeRangePickerSheet.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Edits a copy of a slot. Only Done hands the draft back (`onDone`), so
/// Cancel, swipe-down and tap-outside leave the stored slot untouched (EXP-05,
/// D-09). `original` is the slot as the sheet opened: its start and end stay
/// rows in their lists, so an off-grid or 24:00 stored time shows as selected
/// and is only replaced when the expert taps another row (EXP-07, D-08).
struct TimeRangePickerSheet: View {
    let original: AvailabilityTimeSlot
    @State private var draft: AvailabilityTimeSlot

    let brandGreen: Color
    let bg: Color
    let onSurface: Color
    let onSurfaceVar: Color
    let onPrimary: Color
    let onDone: (AvailabilityTimeSlot) -> Void
    let onCancel: () -> Void

    init(
        slot: AvailabilityTimeSlot,
        brandGreen: Color,
        bg: Color,
        onSurface: Color,
        onSurfaceVar: Color,
        onPrimary: Color,
        onDone: @escaping (AvailabilityTimeSlot) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.original = slot
        _draft = State(initialValue: slot)
        self.brandGreen = brandGreen
        self.bg = bg
        self.onSurface = onSurface
        self.onSurfaceVar = onSurfaceVar
        self.onPrimary = onPrimary
        self.onDone = onDone
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Select Time Range")
                .font(.brand(.title3, weight: .bold))
                .foregroundColor(onSurface)
                .padding(.top, 8)

            HStack(spacing: 24) {
                // Start time picker
                timePicker(
                    label: "Start Time",
                    selectedMinutes: $draft.start,
                    rows: AvailabilitySlotRules.pickerRows(
                        isStart: true,
                        draftStart: draft.start,
                        draftEnd: draft.end,
                        storedValue: original.start
                    )
                )

                Text("-")
                    .font(.title3.weight(.bold))
                    .foregroundColor(onSurfaceVar)
                    .padding(.top, 24)

                // End time picker
                timePicker(
                    label: "End Time",
                    selectedMinutes: $draft.end,
                    rows: AvailabilitySlotRules.pickerRows(
                        isStart: false,
                        draftStart: draft.start,
                        draftEnd: draft.end,
                        storedValue: original.end
                    )
                )
            }
            .padding(.horizontal, 20)

            // Buttons
            HStack(spacing: 12) {
                Button { onCancel() } label: {
                    Text("Cancel")
                        .font(.brand(.callout, weight: .semibold))
                        .foregroundColor(onSurface)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.10))
                        )
                }

                Button { onDone(draft) } label: {
                    Text("Done")
                        .font(.brand(.callout, weight: .bold))
                        .foregroundColor(onPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(brandGreen)
                                .shadow(color: brandGreen.opacity(0.40), radius: 8, x: 0, y: 2)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    private func timePicker(
        label: String,
        selectedMinutes: Binding<Int>,
        rows: [Int]
    ) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.brand(.caption, weight: .medium))
                .foregroundColor(onSurfaceVar)

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(rows, id: \.self) { t in
                            let isSelected = selectedMinutes.wrappedValue == t

                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedMinutes.wrappedValue = t
                                }
                            } label: {
                                ZStack {
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(brandGreen, lineWidth: 1.5)
                                            .shadow(color: brandGreen.opacity(0.45), radius: 5)
                                    }
                                    Text(minutesToAMPM(t))
                                        .font(.system(.body, design: .rounded).weight(isSelected ? .bold : .regular))
                                        .foregroundColor(isSelected ? brandGreen : onSurface)
                                }
                                .frame(height: 44)
                                .frame(maxWidth: .infinity)
                            }
                            .id(t)
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: 180)
                .onAppear {
                    // Two-shot fire: the first pass covers the fast
                    // case (sheet already stable); the deferred pass
                    // covers the slide-in-animation case, where the
                    // ScrollView's geometry finalizes ~350ms after
                    // `.onAppear` and any earlier scrollTo silently
                    // targets stale offsets.
                    let target = selectedMinutes.wrappedValue
                    DispatchQueue.main.async {
                        proxy.scrollTo(target, anchor: .center)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        proxy.scrollTo(target, anchor: .center)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
