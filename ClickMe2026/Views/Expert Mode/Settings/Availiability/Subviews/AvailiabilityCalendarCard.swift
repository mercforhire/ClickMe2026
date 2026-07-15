//
//  AvailiabilityCalendarCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct AvailiabilityCalendarCard: View {
    @Binding var selectedDate: Date
    @Binding var displayedMonth: Date

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
            // Month nav header
            HStack {
                Text(monthYearString(displayedMonth))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AvailiabilityTheme.onSurface)

                Spacer()

                Button {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AvailiabilityTheme.onSurfaceVar)
                        .frame(width: 32, height: 32)
                }
                Button {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AvailiabilityTheme.onSurfaceVar)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            // Day headers
            HStack(spacing: 0) {
                ForEach(AvailiabilityTheme.dayHeaders, id: \.self) { d in
                    Text(d)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AvailiabilityTheme.onSurfaceVar)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 6)

            // Date grid
            let days = generateCalendarDays(displayedMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 2) {
                ForEach(days.indices, id: \.self) { i in
                    calendarCell(days[i])
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AvailiabilityTheme.surfaceCard)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AvailiabilityTheme.outlineVar.opacity(0.50), lineWidth: 1))
        )
    }

    private func calendarCell(_ item: CalendarDayItem) -> some View {
        let isSelected = item.date.map { calendar.isDate($0, inSameDayAs: selectedDate) } ?? false
        let isToday = item.date.map { calendar.isDateInToday($0) } ?? false

        return Button {
            if let d = item.date, item.isCurrentMonth { selectedDate = d }
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(AvailiabilityTheme.brandGreen)
                        .shadow(color: AvailiabilityTheme.brandGreen.opacity(0.55), radius: 6)
                } else if isToday {
                    Circle()
                        .stroke(AvailiabilityTheme.brandGreen.opacity(0.55), lineWidth: 1.5)
                }

                Text(item.label)
                    .font(.system(size: 14, weight: isSelected ? .bold : .regular, design: .rounded))
                    .foregroundColor(
                        isSelected ? AvailiabilityTheme.onPrimary :
                            !item.isCurrentMonth ? AvailiabilityTheme.onSurfaceVar.opacity(0.30) :
                            isToday ? AvailiabilityTheme.brandGreen : AvailiabilityTheme.onSurface
                    )
            }
            .frame(height: 38)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(!item.isCurrentMonth)
    }

    // MARK: - Calendar helpers

    struct CalendarDayItem {
        let label: String
        let date: Date?
        let isCurrentMonth: Bool
    }

    private func generateCalendarDays(_ month: Date) -> [CalendarDayItem] {
        let comps = calendar.dateComponents([.year, .month], from: month)
        guard let first = calendar.date(from: comps) else { return [] }
        let weekday = calendar.component(.weekday, from: first) - 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: first)?.count ?? 30
        var days: [CalendarDayItem] = []

        // Leading blanks
        if let prev = calendar.date(byAdding: .month, value: -1, to: first),
           let range = calendar.range(of: .day, in: .month, for: prev)
        {
            for d in (range.count - weekday + 1) ... range.count {
                days.append(CalendarDayItem(label: "\(d)", date: nil, isCurrentMonth: false))
            }
        }

        // Current month
        for d in 1 ... daysInMonth {
            var c = comps; c.day = d
            days.append(CalendarDayItem(label: "\(d)", date: calendar.date(from: c), isCurrentMonth: true))
        }

        // Trailing
        let trailing = (7 - days.count % 7) % 7
        for d in 1 ... max(1, trailing) {
            days.append(CalendarDayItem(label: "\(d)", date: nil, isCurrentMonth: false))
        }
        return days
    }

    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: date)
    }
}
