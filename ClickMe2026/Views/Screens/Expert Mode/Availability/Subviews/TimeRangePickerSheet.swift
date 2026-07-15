//
//  TimeRangePickerSheet.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct TimeRangePickerSheet: View {
    @Binding var slot: AvailabilityTimeSlot

    let brandGreen: Color
    let bg: Color
    let onSurface: Color
    let onSurfaceVar: Color
    let onPrimary: Color
    let onDone: () -> Void
    let onCancel: () -> Void

    private let step = 30 // minutes
    private var times: [Int] {
        stride(from: 0, through: 24 * 60 - step, by: step).map { $0 }
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Select Time Range")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(onSurface)
                .padding(.top, 8)

            HStack(spacing: 24) {
                // Start time picker
                timePicker(
                    label: "Start Time",
                    selectedMinutes: $slot.start,
                    otherMinutes: slot.end,
                    isStart: true
                )

                Text("-")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(onSurfaceVar)
                    .padding(.top, 24)

                // End time picker
                timePicker(
                    label: "End Time",
                    selectedMinutes: $slot.end,
                    otherMinutes: slot.start,
                    isStart: false
                )
            }
            .padding(.horizontal, 20)

            // Buttons
            HStack(spacing: 12) {
                Button { onCancel() } label: {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(onSurface)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.10))
                        )
                }

                Button { onDone() } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
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
        otherMinutes: Int,
        isStart: Bool
    ) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(onSurfaceVar)

            let validTimes = isStart
                ? times.filter { $0 < otherMinutes }
                : times.filter { $0 > otherMinutes }

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(validTimes, id: \.self) { t in
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
                                        .font(.system(size: 16, weight: isSelected ? .bold : .regular, design: .rounded))
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        proxy.scrollTo(selectedMinutes.wrappedValue, anchor: .center)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
