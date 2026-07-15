//
//  MakeABookingView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

/// Client-side view model of an expert's topic of discussion. Backed by the
/// server-side `PublicProfileDetailsData.TopicOfDiscussion` — `id` is the
/// authoritative server UUID, needed when firing booking requests.
struct BookingTopic: Identifiable, Hashable {
    let id: UUID
    let title: String
    let durationMinutes: Int
    /// Price in minor units (cents). `nil` when the topic is free or price
    /// isn't set on the server.
    let priceAmount: Int?
    let currency: String?
    let isFree: Bool

    /// Human-readable price label. "Free", "USD 50", or "—" when unknown.
    var priceLabel: String {
        if isFree { return "Free" }
        if let priceAmount, let currency {
            return "\(currency) \(priceAmount / 100)"
        }
        return "—"
    }

    /// Duration label used in the topic picker + summary.
    var durationLabel: String { "\(durationMinutes) min" }
}

/// A single availability slot resolved from `ExpertAvailabilityData`.
struct BookingTimeSlot: Identifiable, Hashable {
    var id: Date { startTime }
    let startTime: Date
    let endTime: Date?
    let isAvailable: Bool

    var displayLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        return f.string(from: startTime)
    }
}

extension MeetingType {
    /// Human-readable label used in the meeting-type picker.
    var displayName: String {
        switch self {
        case .inAppVoice: return "In-app Voice Call"
        case .skypeZoom:  return "Skype/Zoom Call"
        }
    }

    /// All cases, ordered for the picker.
    static var pickerCases: [MeetingType] { [.inAppVoice, .skypeZoom] }
}

// MARK: - Book Session View

struct MakeABooking: View {

    @StateObject private var viewModel: MakeABookingViewModel

    // MARK: Inits

    /// Runtime init. The caller supplies expert seed data; topics + slots
    /// are fetched on appear.
    init(
        expertId: UUID,
        expertName: String,
        expertTitle: String,
        expertImageURL: String
    ) {
        _viewModel = StateObject(
            wrappedValue: MakeABookingViewModel(
                expertId: expertId,
                expertName: expertName,
                expertTitle: expertTitle,
                expertImageURL: expertImageURL
            )
        )
    }

    /// Preview / test seam — inject a pre-configured view model.
    init(viewModel: MakeABookingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            MakeABookingBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    MakeABookingExpertCard(
                        expertName: viewModel.expertName,
                        expertTitle: viewModel.expertTitle,
                        expertImageURL: viewModel.expertImageURL
                    )

                    MakeABookingTopicPicker(viewModel: viewModel)

                    MakeABookingCalendarCard(viewModel: viewModel)

                    MakeABookingTimeSlotsCard(viewModel: viewModel)

                    MakeABookingMeetingTypeCard(meetingType: $viewModel.meetingType)

                    MakeABookingNotesCard(clientNotes: $viewModel.clientNotes)

                    MakeABookingSummarySection(
                        topicLabel: viewModel.selectedTopic?.title ?? "—",
                        dateTimeLabel: summaryDateTimeLabel,
                        durationLabel: viewModel.selectedTopic?.durationLabel ?? "—",
                        meetingTypeLabel: viewModel.meetingType.displayName,
                        priceLabel: viewModel.selectedTopic?.priceLabel ?? "—"
                    )

                    MakeABookingBookButton(
                        isBooking: viewModel.isBooking,
                        isEnabled: canBook,
                        action: viewModel.book
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Book a Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MakeABookingBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.onAppear() }
        .alert("Paid bookings coming soon",
               isPresented: $viewModel.showPaidUnsupportedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Payment support isn't available in this build yet. Please pick a free topic to book right now.")
        }
        .alert("Booking sent",
               isPresented: presenting(\.bookingSuccessMessage),
               presenting: viewModel.bookingSuccessMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { text in
            Text(text)
        }
        .alert("Couldn't book",
               isPresented: presenting(\.bookingError),
               presenting: viewModel.bookingError) { _ in
            Button("OK", role: .cancel) {}
        } message: { text in
            Text(text)
        }
    }

    // MARK: Derived

    private var canBook: Bool {
        viewModel.selectedTopic != nil && viewModel.selectedTimeSlot != nil && !viewModel.isBooking
    }

    private var summaryDateTimeLabel: String {
        guard let slot = viewModel.selectedTimeSlot else {
            return "\(viewModel.shortDate(viewModel.selectedDate))"
        }
        return "\(viewModel.shortDate(viewModel.selectedDate)), \(slot.displayLabel)"
    }

    /// Binding that's `true` while `keyPath` is non-nil; setting it to
    /// `false` clears the underlying value.
    private func presenting(_ keyPath: ReferenceWritableKeyPath<MakeABookingViewModel, String?>) -> Binding<Bool> {
        Binding(
            get: { viewModel[keyPath: keyPath] != nil },
            set: { if !$0 { viewModel[keyPath: keyPath] = nil } }
        )
    }
}

// MARK: - Preview harness

private enum MakeABookingPreviewRoute: Hashable {
    case free
    case paid
}

private struct MakeABookingPreviewHarness: View {
    let route: MakeABookingPreviewRoute
    @State private var path: [MakeABookingPreviewRoute]

    init(route: MakeABookingPreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("About")
                NavigationLink("Book a session", value: route)
            }
            .navigationTitle("Expert profile")
            .navigationDestination(for: MakeABookingPreviewRoute.self) { route in
                MakeABooking(viewModel: Self.previewViewModel(for: route))
            }
        }
    }

    private static func previewViewModel(for route: MakeABookingPreviewRoute) -> MakeABookingViewModel {
        let isFree = route == .free
        let topics: [BookingTopic] = [
            BookingTopic(
                id: UUID(),
                title: isFree ? "Intro Session" : "Marketing Strategy Deep Dive",
                durationMinutes: 30,
                priceAmount: isFree ? nil : 5000,
                currency: isFree ? nil : "USD",
                isFree: isFree
            ),
            BookingTopic(
                id: UUID(),
                title: "Brand Growth",
                durationMinutes: 45,
                priceAmount: 7500,
                currency: "USD",
                isFree: false
            ),
        ]
        let today = Calendar.current.startOfDay(for: Date())
        let sampleSlots: [BookingTimeSlot] = (9...15).map { hour in
            let start = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: today) ?? today
            return BookingTimeSlot(startTime: start, endTime: nil, isAvailable: true)
        }
        let key: String = {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: today)
        }()

        return MakeABookingViewModel(
            expertName: "Marcus Chen",
            expertTitle: "Growth Hacker & Analyst",
            expertImageURL: "https://randomuser.me/api/portraits/men/32.jpg",
            topics: topics,
            availabilityByDate: [key: sampleSlots],
            expertTimezone: "America/Toronto"
        )
    }
}

// MARK: - Previews

#Preview("Free Topic") {
    MakeABookingPreviewHarness(route: .free)
        .preferredColorScheme(.dark)
}

#Preview("Paid Topic") {
    MakeABookingPreviewHarness(route: .paid)
        .preferredColorScheme(.dark)
}
