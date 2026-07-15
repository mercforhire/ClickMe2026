//
//  MakeABookingView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

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
                        isBooking: viewModel.isSubmitting,
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
        .bookingPaymentSheet(viewModel: viewModel)
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
        viewModel.selectedTopic != nil
            && viewModel.selectedTimeSlot != nil
            && !viewModel.isSubmitting
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

// MARK: - Preview helpers

#if DEBUG
private func makeABookingPreviewViewModel(isFree: Bool) -> MakeABookingViewModel {
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
#endif

// MARK: - Live-fetch bootstrap

/// Bootstraps by calling `/client/home` to grab a real expert, then pushes
/// `MakeABooking` which loads topics + availability against the live
/// backend. Requires `PreviewSecrets.clientBearerToken` to hold a valid
/// client-role JWT.
private struct LiveFetchBookingBootstrap: View {
    @State private var seed: Seed?
    @State private var errorMessage: String?

    private struct Seed {
        let expertId: UUID
        let name: String
        let title: String
        let imageURL: String
    }

    var body: some View {
        if let seed {
            MakeABooking(
                expertId: seed.expertId,
                expertName: seed.name,
                expertTitle: seed.title,
                expertImageURL: seed.imageURL
            )
        } else if let errorMessage {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.white.opacity(0.6))
                Text("Preview bootstrap failed")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(errorMessage)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MakeABookingBrand.bg.ignoresSafeArea())
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(MakeABookingBrand.bg.ignoresSafeArea())
                .task { await bootstrap() }
        }
    }

    private func bootstrap() async {
        ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
        do {
            let home = try await ClickMeAPI.shared.getClientHome()
            guard let re = home.data.recommendedExperts.first else {
                errorMessage = "No recommended experts in the home feed to preview."
                return
            }
            seed = Seed(
                expertId: re.expertId,
                name: re.fullName ?? "Expert",
                title: re.title ?? "",
                imageURL: re.profileImageUrl ?? ""
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Previews

#Preview("Free Topic") {
    PreviewNavHarness(parentText: "About", navTitle: "Expert profile", rowTitle: "Book a session") {
        MakeABooking(viewModel: makeABookingPreviewViewModel(isFree: true))
    }
    .preferredColorScheme(.dark)
}

#Preview("Paid Topic") {
    PreviewNavHarness(parentText: "About", navTitle: "Expert profile", rowTitle: "Book a session") {
        MakeABooking(viewModel: makeABookingPreviewViewModel(isFree: false))
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    PreviewNavHarness(parentText: "About", navTitle: "Expert profile", rowTitle: "Book a session") {
        LiveFetchBookingBootstrap()
    }
    .preferredColorScheme(.dark)
}
