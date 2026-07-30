//
//  AvailabilitySettingsView.swift
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

struct AvailabilitySettingsView: View {
    @State private var viewModel: AvailabilitySettingsViewModel

    init(viewModel: AvailabilitySettingsViewModel = AvailabilitySettingsViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            Brand.surface.ignoresSafeArea()
            content
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                saveToolbarButton
            }
        }
        // Time picker sheet
        .sheet(isPresented: $viewModel.showTimePicker) {
            if let di = viewModel.editingDayIndex, let si = viewModel.editingSlotIndex {
                TimeRangePickerSheet(
                    slot: $viewModel.schedule[di].slots[si],
                    brandGreen: Brand.primary,
                    bg: Brand.surfaceContainerLow,
                    onSurface: Brand.onSurface,
                    onSurfaceVar: Brand.onSurfaceVariant,
                    onPrimary: Brand.onPrimary,
                    onDone: { viewModel.dismissTimePicker() },
                    onCancel: { viewModel.dismissTimePicker() }
                )
                .presentationDetents([.fraction(0.55)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(red: 0.10, green: 0.12, blue: 0.11).opacity(0.97))
            }
        }
        .confirmationDialog("Select Timezone", isPresented: $viewModel.showTimezonePicker, titleVisibility: .visible) {
            ForEach(Timezones.all) { entry in
                Button(entry.label) { viewModel.selectTimezone(entry) }
            }
        }
        .alert(
            "Couldn't save availability",
            isPresented: Binding(
                get: { viewModel.saveError != nil },
                set: { if !$0 { viewModel.saveError = nil } }
            ),
            presenting: viewModel.saveError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .navigationTitle("Availability")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Content router

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            loadingContent
        case .failed(let message):
            errorContent(message: message)
        case .loaded:
            loadedContent
        }
    }

    private var loadedContent: some View {
        @Bindable var viewModel = viewModel

        return ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    AvailabilityTimezoneRow(selectedTimezone: viewModel.selectedTimezone) {
                        viewModel.showTimezonePicker = true
                    }

                    Button {
                        viewModel.autoDetectTimezone()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Auto-detect from device")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(Brand.primary)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                if viewModel.hasOverlaps {
                    overlapBanner
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }

                VStack(spacing: 16) {
                    ForEach($viewModel.schedule.indices, id: \.self) { i in
                        AvailabilityDayRow(day: $viewModel.schedule[i]) { slotIndex in
                            viewModel.beginEditingSlot(dayIndex: i, slotIndex: slotIndex)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    /// Inline warning shown while any enabled day has overlapping slots.
    /// Names the offending day(s) so the user can jump straight to the
    /// fix rather than hunting for the source.
    private var overlapBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Brand.error)
            VStack(alignment: .leading, spacing: 2) {
                Text("Overlapping time slots")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Brand.onSurface)
                Text(overlapCopy)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Brand.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Brand.error.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Brand.error.opacity(0.35), lineWidth: 1))
        )
    }

    private var overlapCopy: String {
        let days = viewModel.overlappingDayNames
        if days.count == 1 {
            return "\(days[0]) has overlapping slots. Adjust them to save."
        }
        let joined = ListFormatter.localizedString(byJoining: days)
        return "\(joined) have overlapping slots. Adjust them to save."
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(Brand.onSurface)
            Text("Loading availability…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(Brand.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(Brand.onSurfaceVariant)
            Text("Couldn't load availability")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Brand.onSurface)
            Text(message)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(Brand.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Brand.onPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Brand.primary))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Compact nav-bar save affordance — spinner while saving, checkmark
    /// briefly after success, plain "Save" otherwise.
    @ViewBuilder
    private var saveToolbarButton: some View {
        if viewModel.isSaving {
            ProgressView()
                .controlSize(.small)
                .tint(Brand.onSurface)
        } else if viewModel.didSave {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Brand.primary)
                .transition(.opacity)
        } else {
            Button {
                guard CallCenter.shared.attempt("edit your availability") else { return }
                viewModel.save()
            } label: {
                Text("Save")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(viewModel.hasOverlaps
                        ? Brand.onSurfaceVariant.opacity(0.55)
                        : Brand.primary)
            }
            .disabled(viewModel.hasOverlaps)
        }
    }
}

// MARK: - Previews

#Preview("Availability Settings") {
    PreviewNavHarness(parentText: "Profile Hub", navTitle: "Expert", rowTitle: "Availability") {
        AvailabilitySettingsView(viewModel: .previewSeed())
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return PreviewNavHarness(parentText: "Profile Hub", navTitle: "Expert", rowTitle: "Availability") {
        AvailabilitySettingsView()
    }
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
            Brand.surface.ignoresSafeArea()
            TimeRangePickerSheet(
                slot: $slot,
                brandGreen: Brand.primary,
                bg: Brand.surfaceContainerLow,
                onSurface: Brand.onSurface,
                onSurfaceVar: Brand.onSurfaceVariant,
                onPrimary: Brand.onPrimary,
                onDone: {},
                onCancel: {}
            )
        }
    }
}
