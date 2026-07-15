//
//  RescheduleCalendarCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Month picker + day grid with green selected-day ring

struct RescheduleCalendarCard: View {
    let monthLabel: String
    let cells: [Date?]
    let calendar: Calendar
    let isSelected: (Date) -> Bool
    let isBookable: (Date) -> Bool
    let onPrevMonth: () -> Void
    let onNextMonth: () -> Void
    let onSelectDay: (Date) -> Void

    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: 12) {
            monthHeader
            weekdayHeader
            dayGrid
        }
        .padding(14)
        .background(RescheduleCardBackground())
    }

    // MARK: Header

    private var monthHeader: some View {
        HStack {
            Button(action: onPrevMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(RescheduleBrand.onSurfaceVar)
                    .frame(width: 32, height: 32)
            }

            Spacer()

            Text(monthLabel)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(RescheduleBrand.onSurface)

            Spacer()

            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(RescheduleBrand.onSurfaceVar)
                    .frame(width: 32, height: 32)
            }
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { sym in
                Text(sym)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(RescheduleBrand.onSurfaceVar)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Day grid

    private var dayGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
            ForEach(0 ..< cells.count, id: \.self) { idx in
                if let day = cells[idx] {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 36)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let selected = isSelected(day)
        let bookable = isBookable(day)
        let dayNumber = calendar.component(.day, from: day)

        return Button {
            guard bookable else { return }
            onSelectDay(day)
        } label: {
            ZStack {
                if selected {
                    Circle()
                        .stroke(RescheduleBrand.brandGreen, lineWidth: 1.6)
                        .shadow(color: RescheduleBrand.brandGreen.opacity(0.50), radius: 4)
                        .frame(width: 32, height: 32)
                }
                Text("\(dayNumber)")
                    .font(.system(size: 14, weight: selected ? .bold : .regular, design: .rounded))
                    .foregroundColor(
                        !bookable
                            ? RescheduleBrand.onSurfaceVar.opacity(0.30)
                            : (selected ? RescheduleBrand.brandGreen : RescheduleBrand.onSurface)
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!bookable)
    }
}
