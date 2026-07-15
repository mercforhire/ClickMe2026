//
//  ExpertProfileSettingsAvailability.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ExpertProfileSettingsAvailability: View {
    @Bindable var viewModel: ExpertProfileSettingsViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                viewModel.toggleAvailability()
            } label: {
                HStack {
                    Text("Availability")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Brand.onSurface)
                    Spacer()
                    Image(systemName: viewModel.availabilityExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Brand.onSurfaceVariant)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if viewModel.availabilityExpanded {
                VStack(spacing: 0) {
                    Divider().background(Brand.outlineVariant)

                    // Calendar sub-header
                    HStack {
                        Text("Calendar")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Brand.onSurface)
                        Spacer()
                        Button("Edit") {}
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Brand.onPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Brand.primary))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    // Column headers
                    HStack(spacing: 0) {
                        Text("").frame(width: 40) // row label spacer
                        ForEach(WeekdayHeaders.weekdays, id: \.self) { d in
                            Text(d)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(Brand.onSurfaceVariant)
                                .frame(maxWidth: .infinity)
                        }
                        Text("").frame(width: 120) // time range spacer
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)

                    // Rows
                    ForEach($viewModel.availability) { $slot in
                        row($slot)
                    }

                    // Expand hint
                    Button {} label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(Brand.onSurfaceVariant)
                    }
                    .padding(.vertical, 10)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Brand.surfaceContainerLow)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Brand.outlineVariant, lineWidth: 1))
        )
    }

    private func row(_ slot: Binding<AvailabilitySlot>) -> some View {
        HStack(spacing: 0) {
            // Day label
            Text(slot.wrappedValue.day)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Brand.onSurface)
                .frame(width: 40, alignment: .leading)
                .padding(.leading, 12)

            // Checkbox columns (Mon–Fri)
            ForEach(0 ..< 5) { col in
                let checked = slot.wrappedValue.columns[col]
                Button {
                    slot.wrappedValue.columns[col].toggle()
                } label: {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(checked
                            ? Brand.primary.opacity(0.30)
                            : Color(red: 0.12, green: 0.16, blue: 0.13))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(checked
                                    ? Brand.primary.opacity(0.70)
                                    : Brand.outlineVariant, lineWidth: 1)
                        )
                        .frame(width: 26, height: 24)
                }
                .frame(maxWidth: .infinity)
            }

            // Time range
            Text(slot.wrappedValue.timeRange)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(Brand.onSurfaceVariant)
                .frame(width: 112, alignment: .trailing)
                .padding(.trailing, 12)
        }
        .padding(.vertical, 6)
    }
}
