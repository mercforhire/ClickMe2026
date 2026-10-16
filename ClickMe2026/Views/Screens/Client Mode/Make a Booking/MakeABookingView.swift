//
//  MakeABookingView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Book Session View

struct MakeABooking: View {

    @StateObject private var viewModel: MakeABookingViewModel
    @State private var showPaymentInfo: Bool = false
    @State private var showPaymentMethods: Bool = false

    /// Shell-injected shortcuts consumed by the post-booking
    /// `BookingRequestSentView`. Nil in previews / isolated tests —
    /// `BookingRequestSentView` treats the underlying closures as
    /// optional no-ops in that case.
    @Environment(\.showMyBookings) private var showMyBookings
    @Environment(\.returnToHome) private var returnToHome

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

                    // Non-intrusive info affordance — only surfaced for
                    // paid topics; free bookings don't need a payment
                    // explainer. Deliberately placed above the primary
                    // CTA so users curious about timing can find it
                    // without decoration cluttering the button itself.
                    if shouldShowPaymentInfoLink {
                        Button {
                            showPaymentInfo = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .font(.footnote.weight(.semibold))
                                Text("How does payment work?")
                                    .font(.brand(.caption, weight: .semibold))
                            }
                            .foregroundColor(Brand.primary)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    MakeABookingBookButton(
                        title: bookButtonTitle,
                        isBooking: viewModel.isSubmitting,
                        isEnabled: canBook,
                        action: bookButtonAction
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
        // Post-success navigation. `navigationDestination(item:)` takes
        // a `Binding<Optional<Hashable>>`; UUID is Hashable so we don't
        // need a wrapper. Fires for both free (`performFreeBooking`) and
        // paid (`completePaidBooking`) paths — the destination view
        // conditionally hides the payment-lifecycle card for free
        // bookings.
        .navigationDestination(item: $viewModel.completedBookingId) { bookingId in
            BookingRequestSentView(
                bookingId: bookingId,
                onViewBookings: { showMyBookings?() },
                onBackToHome: { returnToHome?() }
            )
        }
        // Routes the client to Payment Methods when they try to book a
        // paid topic without a saved card. Refreshes the availability
        // flag on return so a newly-added card immediately re-enables
        // the "Book Now" CTA.
        .navigationDestination(isPresented: $showPaymentMethods) {
            PaymentMethodsView()
        }
        .onChange(of: showPaymentMethods) { _, isShowing in
            if !isShowing {
                Task { await viewModel.loadPaymentMethods() }
            }
        }
        .sheet(isPresented: $showPaymentInfo) {
            PaymentInfoSheet()
        }
        .alert("Couldn't book",
               isPresented: presenting(\.bookingError),
               presenting: viewModel.bookingError) { _ in
            Button("OK", role: .cancel) {}
        } message: { text in
            Text(text)
        }
        // App-root keyboard toolbar doesn't reliably reach this deep
        // through the tab shell + booking-tab NavigationStack, so
        // re-attach locally to guarantee the message `TextEditor` has
        // a Done button.
        .keyboardDismissToolbar()
    }

    // MARK: Derived

    private var canBook: Bool {
        guard let topic = viewModel.selectedTopic else { return false }
        if viewModel.isSubmitting { return false }

        // Paid topics gate the CTA on the payment-methods check. While
        // the check is still in flight (`.unknown`) we keep the button
        // disabled so a tap can't slip through into the paid flow —
        // which would let the user add a card mid-checkout and bypass
        // the "save first" rule.
        if !topic.isFree {
            switch viewModel.paymentMethodsAvailability {
            case .unknown:
                return false
            case .none:
                // "Add a Payment Method" branch — just needs a topic
                // selected; a slot isn't required to route the user
                // into settings.
                return true
            case .available:
                break
            }
        }

        return viewModel.selectedTimeSlot != nil
    }

    private var bookButtonTitle: String {
        viewModel.requiresPaymentMethodSetup ? "Add a Payment Method" : "Book Now"
    }

    private var bookButtonAction: () -> Void {
        if viewModel.requiresPaymentMethodSetup {
            return { showPaymentMethods = true }
        }
        return viewModel.book
    }

    /// The "How does payment work?" affordance only makes sense for paid
    /// sessions. Free topics don't authorize a card — the sheet would
    /// describe a flow that doesn't apply.
    private var shouldShowPaymentInfoLink: Bool {
        guard let topic = viewModel.selectedTopic else { return false }
        return !topic.isFree
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

private func makeABookingPreviewViewModel(isFree: Bool) -> MakeABookingViewModel {
    let topics: [BookingTopic] = [
        BookingTopic(
            id: UUID(),
            title: isFree ? "Intro Session" : "Marketing Strategy Deep Dive",
            durationMinutes: 30,
            description: isFree
                ? "A quick 30-minute intro chat to see if we're a good fit — no agenda required."
                : "Deep dive on positioning, ICP, channel mix, and 90-day GTM execution priorities.",
            priceAmount: isFree ? nil : 5000,
            currency: isFree ? nil : "USD",
            isFree: isFree
        ),
        BookingTopic(
            id: UUID(),
            title: "Brand Growth",
            durationMinutes: 45,
            description: "Positioning workshop for early-stage founders — narrative, audience, and messaging tests.",
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
                    .font(.title.weight(.light))
                    .foregroundColor(.white.opacity(0.6))
                Text("Preview bootstrap failed")
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(.white)
                Text(errorMessage)
                    .font(.brand(.caption))
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
