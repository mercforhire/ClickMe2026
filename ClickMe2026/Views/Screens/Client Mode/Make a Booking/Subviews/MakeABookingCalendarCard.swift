//
//  MakeABookingCalendarCard.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct MakeABookingCalendarCard: View {
    @ObservedObject var viewModel: MakeABookingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MakeABookingSectionHeader(title: "Select a Time")

            VStack(spacing: 0) {
                monthNav
                dayHeadersRow
                dateGrid
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(MakeABookingBrand.surface)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(MakeABookingBrand.outlineVar, lineWidth: 1))
            )
        }
    }

    private var monthNav: some View {
        HStack {
            Button {
                viewModel.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MakeABookingBrand.brandGreen)
                    .frame(width: 32, height: 32)
            }

            Spacer()

            Text(viewModel.monthYearString(viewModel.displayedMonth))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(MakeABookingBrand.onSurface)

            Spacer()

            Button {
                viewModel.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MakeABookingBrand.brandGreen)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var dayHeadersRow: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.dayHeaders, id: \.self) { d in
                Text(d)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(MakeABookingBrand.onSurfaceVar)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 8)
    }

    private var dateGrid: some View {
        let days = viewModel.generateDays(for: viewModel.displayedMonth)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days.indices, id: \.self) { i in
                calendarCell(item: days[i])
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 12)
    }

    private func calendarCell(item: MakeABookingViewModel.CalendarDay) -> some View {
        let isSelected = item.date.map { viewModel.calendar.isDate($0, inSameDayAs: viewModel.selectedDate) } ?? false
        let isToday = item.date.map { viewModel.calendar.isDateInToday($0) } ?? false
        let isCurrentMonth = item.isCurrentMonth

        return Button {
            if let d = item.date, isCurrentMonth { viewModel.selectedDate = d }
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(MakeABookingBrand.brandGreen)
                        .shadow(color: MakeABookingBrand.brandGreen.opacity(0.50), radius: 6, x: 0, y: 0)
                }

                Text(item.label)
                    .font(.system(size: 14, weight: isSelected ? .bold : .regular, design: .rounded))
                    .foregroundColor(
                        isSelected ? MakeABookingBrand.onPrimary :
                            !isCurrentMonth ? MakeABookingBrand.onSurfaceVar.opacity(0.35) :
                            isToday ? MakeABookingBrand.brandGreen : MakeABookingBrand.onSurface
                    )
            }
            .frame(height: 36)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(!isCurrentMonth || item.date == nil)
    }
}
