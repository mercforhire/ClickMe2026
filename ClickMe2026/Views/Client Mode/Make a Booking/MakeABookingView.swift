//
//  BookingView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct BookingTopic: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let price: Int
}

enum MeetingType: String, CaseIterable {
    case inAppVoice  = "In-app Voice Call"
    case skypeZoom   = "Skype/Zoom Call"
}

// MARK: - Book Session View

struct BookingView: View {

    // MARK: Expert info
    let expertName:     String
    let expertTitle:    String
    let expertImageURL: String

    // MARK: Topics
    let topics: [BookingTopic]

    var onBook: (BookingTopic, Date, String, MeetingType) -> Void

    // MARK: State — selections
    @State private var selectedTopic:    BookingTopic
    @State private var selectedDate:     Date = Date()
    @State private var displayedMonth:   Date = Date()
    @State private var selectedTimeSlot: String = "10:30 AM"
    @State private var meetingType:      MeetingType = .inAppVoice
    @State private var showTopicPicker:  Bool = false
    @State private var isBooking:        Bool = false

    // MARK: Design tokens — Luminous Dark
    private let bg             = Color(red: 0.075, green: 0.075, blue: 0.075) // #131313
    private let surface        = Color(red: 0.125, green: 0.125, blue: 0.125) // #201f1f
    private let surfaceHigh    = Color(red: 0.165, green: 0.165, blue: 0.165) // #2a2a2a
    private let outlineVar     = Color(red: 0.235, green: 0.290, blue: 0.247) // #3c4a3f
    private let brandGreen     = Color(red: 0.267, green: 0.965, blue: 0.592) // #44f697
    private let onSurface      = Color(red: 0.898, green: 0.886, blue: 0.882) // #e5e2e1
    private let onSurfaceVar   = Color(red: 0.729, green: 0.796, blue: 0.737) // #bacbbc
    private let onPrimary      = Color(red: 0.000, green: 0.224, blue: 0.114) // #003920

    // MARK: Calendar helpers
    private let calendar   = Calendar.current
    private let dayHeaders = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    private let timeSlots  = ["09:00 AM", "10:30 AM", "11:00 AM", "12:00 PM", "2:00 PM", "3:30 PM"]

    // MARK: Inits

    init(
        expertName:     String = "Sophia Carter",
        expertTitle:    String = "Marketing Expert",
        expertImageURL: String = "https://randomuser.me/api/portraits/women/44.jpg",
        topics: [BookingTopic] = [
            BookingTopic(name: "Digital Marketing Strategy", price: 50),
            BookingTopic(name: "Brand Growth",               price: 75),
            BookingTopic(name: "SEO & Content",              price: 60),
        ],
        onBook: @escaping (BookingTopic, Date, String, MeetingType) -> Void = { _, _, _, _ in }
    ) {
        self.expertName     = expertName
        self.expertTitle    = expertTitle
        self.expertImageURL = expertImageURL
        self.topics         = topics
        self.onBook         = onBook
        _selectedTopic      = State(initialValue: topics.first ?? BookingTopic(name: "General", price: 50))
    }

    // MARK: Body

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    expertSection
                    topicSection
                    timeSection
                    timeSlotsSection
                    meetingTypeSection
                    summarySection
                    bookButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Expert section

    private var expertSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Expert")

            HStack(spacing: 14) {
                AsyncImage(url: URL(string: expertImageURL)) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default:
                        ZStack {
                            Color(red: 0.14, green: 0.18, blue: 0.15)
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.15))
                        }
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(expertName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(onSurface)
                    Text(expertTitle)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(onSurfaceVar)
                }
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(surface)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(outlineVar, lineWidth: 1))
            )
        }
    }

    // MARK: - Topic picker

    private var topicSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Topic of Discussion")

            Button { showTopicPicker = true } label: {
                HStack {
                    Text("\(selectedTopic.name) - $\(selectedTopic.price)")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(onSurface)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(onSurfaceVar)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(surface)
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(outlineVar, lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
            .confirmationDialog("Topic of Discussion", isPresented: $showTopicPicker, titleVisibility: .visible) {
                ForEach(topics) { topic in
                    Button("\(topic.name) — $\(topic.price)") { selectedTopic = topic }
                }
            }
        }
    }

    // MARK: - Calendar

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Select a Time")

            VStack(spacing: 0) {
                // Month nav
                HStack {
                    Button {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(brandGreen)
                            .frame(width: 32, height: 32)
                    }

                    Spacer()

                    Text(monthYearString(displayedMonth))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(onSurface)

                    Spacer()

                    Button {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(brandGreen)
                            .frame(width: 32, height: 32)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 14)
                .padding(.bottom, 12)

                // Day headers
                HStack(spacing: 0) {
                    ForEach(dayHeaders, id: \.self) { d in
                        Text(d)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(onSurfaceVar)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 8)

                // Date grid
                let days = generateDays(for: displayedMonth)
                let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(days.indices, id: \.self) { i in
                        let item = days[i]
                        calendarCell(item: item)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(surface)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(outlineVar, lineWidth: 1))
            )
        }
    }

    private func calendarCell(item: CalendarDay) -> some View {
        let isSelected = item.date.map { calendar.isDate($0, inSameDayAs: selectedDate) } ?? false
        let isToday    = item.date.map { calendar.isDateInToday($0) } ?? false
        let isCurrentMonth = item.isCurrentMonth

        return Button {
            if let d = item.date, isCurrentMonth { selectedDate = d }
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(brandGreen)
                        .shadow(color: brandGreen.opacity(0.50), radius: 6, x: 0, y: 0)
                }

                Text(item.label)
                    .font(.system(size: 14, weight: isSelected ? .bold : .regular, design: .rounded))
                    .foregroundColor(
                        isSelected ? onPrimary :
                        !isCurrentMonth ? onSurfaceVar.opacity(0.35) :
                        isToday ? brandGreen : onSurface
                    )
            }
            .frame(height: 36)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(!isCurrentMonth || item.date == nil)
    }

    // MARK: - Time slots

    private var timeSlotsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Embedded inside a card
            VStack(alignment: .leading, spacing: 12) {
                Text("Available Time Slots")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(onSurface)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(timeSlots, id: \.self) { slot in
                            let isSelected = selectedTimeSlot == slot
                            Button { selectedTimeSlot = slot } label: {
                                Text(slot)
                                    .font(.system(size: 14, weight: isSelected ? .bold : .regular, design: .rounded))
                                    .foregroundColor(isSelected ? onPrimary : onSurface)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? brandGreen : Color.clear)
                                            .overlay(
                                                Capsule()
                                                    .stroke(isSelected ? brandGreen : outlineVar, lineWidth: 1)
                                            )
                                            .shadow(color: isSelected ? brandGreen.opacity(0.40) : .clear,
                                                    radius: 6, x: 0, y: 0)
                                    )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.2), value: isSelected)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(surface)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(outlineVar, lineWidth: 1))
            )
        }
    }

    // MARK: - Meeting type

    private var meetingTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Meeting Type")

            VStack(spacing: 0) {
                ForEach(Array(MeetingType.allCases.enumerated()), id: \.offset) { idx, type in
                    Button { withAnimation(.easeInOut(duration: 0.2)) { meetingType = type } } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .stroke(meetingType == type ? brandGreen : onSurfaceVar.opacity(0.40), lineWidth: 2)
                                    .frame(width: 22, height: 22)
                                if meetingType == type {
                                    Circle()
                                        .fill(brandGreen)
                                        .frame(width: 12, height: 12)
                                }
                            }

                            Text(type.rawValue)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(onSurface)

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)

                    if idx < MeetingType.allCases.count - 1 {
                        Divider().background(outlineVar).padding(.horizontal, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(surface)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(outlineVar, lineWidth: 1))
            )
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Summary")

            VStack(spacing: 8) {
                summaryRow(label: "Topic:",       value: selectedTopic.name)
                summaryRow(label: "Date & Time:", value: "\(shortDate(selectedDate)), \(selectedTimeSlot) (30 min)")
                summaryRow(label: "Meeting Type:", value: meetingType.rawValue)
            }
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(onSurfaceVar)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(onSurface)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // MARK: - Book button

    private var bookButton: some View {
        Button {
            guard !isBooking else { return }
            withAnimation { isBooking = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                onBook(selectedTopic, selectedDate, selectedTimeSlot, meetingType)
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(brandGreen)
                    .shadow(color: brandGreen.opacity(0.45), radius: 16, x: 0, y: 4)
                    .frame(height: 56)

                if isBooking {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: onPrimary))
                } else {
                    Text("Book Now")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(onPrimary)
                }
            }
        }
        .frame(height: 56)
        .disabled(isBooking)
        .buttonStyle(BookScaleStyle())
    }

    // MARK: - Section header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(onSurface)
    }

    // MARK: - Calendar helpers

    struct CalendarDay {
        let label:          String
        let date:           Date?
        let isCurrentMonth: Bool
    }

    private func generateDays(for month: Date) -> [CalendarDay] {
        let comps       = calendar.dateComponents([.year, .month], from: month)
        guard let first = calendar.date(from: comps) else { return [] }

        let weekday     = calendar.component(.weekday, from: first) - 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: first)?.count ?? 30

        var days: [CalendarDay] = []

        // Leading blanks (previous month)
        if let prevMonth = calendar.date(byAdding: .month, value: -1, to: first),
           let prevRange = calendar.range(of: .day, in: .month, for: prevMonth) {
            let prevCount = prevRange.count
            for i in stride(from: prevCount - weekday + 1, through: prevCount, by: 1) {
                days.append(CalendarDay(label: "\(i)", date: nil, isCurrentMonth: false))
            }
        }

        // Current month
        for day in 1...daysInMonth {
            var c = comps; c.day = day
            let date = calendar.date(from: c)
            days.append(CalendarDay(label: "\(day)", date: date, isCurrentMonth: true))
        }

        // Trailing blanks
        let total = days.count
        let trailing = (7 - total % 7) % 7
        for i in 1...max(1, trailing) {
            days.append(CalendarDay(label: "\(i)", date: nil, isCurrentMonth: false))
        }

        return days
    }

    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

// MARK: - Button style

private struct BookScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Book Session") {
    BookingView()
        .preferredColorScheme(.dark)
}

#Preview("Multiple Topics") {
    BookingView(
        expertName:     "Marcus Chen",
        expertTitle:    "Growth Hacker & Analyst",
        expertImageURL: "https://randomuser.me/api/portraits/men/32.jpg",
        topics: [
            BookingTopic(name: "SEO Strategy",        price: 80),
            BookingTopic(name: "PPC Campaign Review", price: 100),
            BookingTopic(name: "Analytics Deep Dive", price: 120),
        ]
    )
    .preferredColorScheme(.dark)
}
