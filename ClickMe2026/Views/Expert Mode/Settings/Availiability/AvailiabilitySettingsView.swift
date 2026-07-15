//
//  AvailiabilitySettingsView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct DaySchedule: Identifiable {
    let id = UUID()
    let day: String
    let shortDay: String
    var isEnabled: Bool
    var slots: [AvailabilityTimeSlot]
}

struct AvailabilityTimeSlot: Identifiable {
    let id = UUID()
    var start: Int // minutes from midnight
    var end: Int // minutes from midnight
}

// MARK: - Helpers

func minutesToString(_ minutes: Int) -> String {
    let h = minutes / 60
    let m = minutes % 60
    return String(format: "%02d:%02d", h, m)
}

func minutesToAMPM(_ minutes: Int) -> String {
    let h = minutes / 60
    let m = minutes % 60
    let period = h < 12 ? "AM" : "PM"
    let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
    return String(format: "%d:%02d %@", h12, m, period)
}

// MARK: - Availability Settings View

struct AvailiabilitySettingsView: View {
    @State private var viewModel: AvailiabilitySettingsViewModel

    init(viewModel: AvailiabilitySettingsViewModel = AvailiabilitySettingsViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack(alignment: .bottom) {
            AvailiabilityTheme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    AvailiabilityCalendarCard(
                        selectedDate: $viewModel.selectedDate,
                        displayedMonth: $viewModel.displayedMonth
                    )
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)

                    AvailiabilityTimezoneRow(selectedTimezone: viewModel.selectedTimezone) {
                        viewModel.showTimezonePicker = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                    VStack(spacing: 16) {
                        ForEach($viewModel.schedule.indices, id: \.self) { i in
                            AvailiabilityDayRow(day: $viewModel.schedule[i]) { slotIndex in
                                viewModel.beginEditingSlot(dayIndex: i, slotIndex: slotIndex)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // space for pinned button
                }
            }

            AvailiabilitySaveButton(isSaving: viewModel.isSaving, didSave: viewModel.didSave) {
                viewModel.save()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        // Time picker sheet
        .sheet(isPresented: $viewModel.showTimePicker) {
            if let di = viewModel.editingDayIndex, let si = viewModel.editingSlotIndex {
                TimeRangePickerSheet(
                    slot: $viewModel.schedule[di].slots[si],
                    brandGreen: AvailiabilityTheme.brandGreen,
                    bg: AvailiabilityTheme.surfaceCard,
                    onSurface: AvailiabilityTheme.onSurface,
                    onSurfaceVar: AvailiabilityTheme.onSurfaceVar,
                    onPrimary: AvailiabilityTheme.onPrimary,
                    onDone: { viewModel.dismissTimePicker() },
                    onCancel: { viewModel.dismissTimePicker() }
                )
                .presentationDetents([.fraction(0.55)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(red: 0.10, green: 0.12, blue: 0.11).opacity(0.97))
            }
        }
        .confirmationDialog("Select Timezone", isPresented: $viewModel.showTimezonePicker, titleVisibility: .visible) {
            ForEach(AvailiabilityTheme.timezones, id: \.self) { tz in
                Button(tz) { viewModel.selectedTimezone = tz }
            }
        }
        .navigationTitle("Availability")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

private struct AvailiabilitySettingsPreviewHost: View {
    @State private var path: [Int] = [0]

    var body: some View {
        NavigationStack(path: $path) {
            Color.clear
                .navigationDestination(for: Int.self) { _ in
                    AvailiabilitySettingsView()
                }
        }
    }
}

#Preview("Availability Settings") {
    AvailiabilitySettingsPreviewHost()
        .preferredColorScheme(.dark)
}

#Preview("Time Range Picker") {
    TimeRangePickerSheetPreview()
        .preferredColorScheme(.dark)
}

private struct TimeRangePickerSheetPreview: View {
    @State private var slot = AvailabilityTimeSlot(start: 9 * 60, end: 9 * 60 + 15)
    var body: some View {
        ZStack {
            AvailiabilityTheme.bg.ignoresSafeArea()
            TimeRangePickerSheet(
                slot: $slot,
                brandGreen: AvailiabilityTheme.brandGreen,
                bg: AvailiabilityTheme.surfaceCard,
                onSurface: AvailiabilityTheme.onSurface,
                onSurfaceVar: AvailiabilityTheme.onSurfaceVar,
                onPrimary: AvailiabilityTheme.onPrimary,
                onDone: {},
                onCancel: {}
            )
        }
    }
}
