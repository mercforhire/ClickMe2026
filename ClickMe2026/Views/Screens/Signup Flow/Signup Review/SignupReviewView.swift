//
//  SignupReviewView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-16.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Model

struct ProfileReviewData {
    var firstName: String
    var location: String
    var spokenLanguages: String
    var avatarURL: String
    var hourlyRate: Int
    var hourlyRateCurrency: String
    var skills: [String]
}

// MARK: - Profile Review & Publish View

struct SignupReviewView: View {

    @StateObject private var viewModel: SignupReviewViewModel

    var onEdit: (ProfileSection) -> Void
    var onPublish: () -> Void

    enum ProfileSection { case personalDetails, profilePhoto, expertise }

    // MARK: Inits

    init(
        viewModel: SignupReviewViewModel = SignupReviewViewModel(),
        onEdit: @escaping (ProfileSection) -> Void = { _ in },
        onPublish: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onEdit = onEdit
        self.onPublish = onPublish
    }

    /// Convenience: build the VM directly from an initial profile (previews only).
    init(
        profile: ProfileReviewData,
        onEdit: @escaping (ProfileSection) -> Void = { _ in },
        onPublish: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: SignupReviewViewModel(profile: profile),
            onEdit: onEdit,
            onPublish: onPublish
        )
    }

    /// Runtime init — binds directly to the shared `SignupAccumulator`.
    init(
        accumulator: SignupAccumulator,
        onEdit: @escaping (ProfileSection) -> Void = { _ in },
        onPublish: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: SignupReviewViewModel(accumulator: accumulator),
            onEdit: onEdit,
            onPublish: onPublish
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Brand.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 18) {
                        personalDetailsCard
                        profilePhotoCard
                        expertiseCard
                    }
                    .padding(.top, 8)

                    PublishProfileButton(isLoading: viewModel.isPublishing) {
                        Task {
                            if await viewModel.publish() {
                                onPublish()
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Profile Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert(
            "Couldn't publish profile",
            isPresented: Binding(
                get: { viewModel.publishError != nil },
                set: { if !$0 { viewModel.publishError = nil } }
            ),
            presenting: viewModel.publishError
        ) { _ in
            Button("OK", role: .cancel) { viewModel.publishError = nil }
        } message: { message in
            Text(message)
        }
    }

    // MARK: Cards

    private var personalDetailsCard: some View {
        ReviewCard(
            title: "Personal Details",
            onEdit: { onEdit(.personalDetails) }
        ) {
            VStack(alignment: .leading, spacing: 8) {
                ReviewLabeledRow(label: "First Name", value: viewModel.profile.firstName)
                ReviewLabeledRow(label: "Location", value: viewModel.profile.location)
                ReviewLabeledRow(label: "Spoken Languages", value: viewModel.profile.spokenLanguages)
            }
        }
    }

    private var profilePhotoCard: some View {
        ReviewCard(
            title: "Profile Photo",
            onEdit: { onEdit(.profilePhoto) }
        ) {
            VStack(spacing: 10) {
                ReviewAvatar(url: viewModel.profile.avatarURL)
                Text(formattedHourlyRate)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Brand.onSurface)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var expertiseCard: some View {
        ReviewCard(
            title: "Expertise",
            onEdit: { onEdit(.expertise) }
        ) {
            ReviewLabeledRow(
                label: "Skills",
                value: viewModel.profile.skills.joined(separator: ", ")
            )
        }
    }

    // MARK: Formatting

    /// `$80 USD / hour`. Currency code is appended verbatim because we don't
    /// have the symbol at this point in the flow — the hourly-rate step only
    /// commits the ISO code onto the accumulator, not the CurrencyItem.
    private var formattedHourlyRate: String {
        let rate = viewModel.profile.hourlyRate
        let currency = viewModel.profile.hourlyRateCurrency
        return "$\(rate) \(currency) / hour"
    }
}

// MARK: - Previews

#Preview("Default") {
    PreviewNavHarness(parentText: "Complete your profile", navTitle: "Profile setup", rowTitle: "Review profile") {
        SignupReviewView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Many skills") {
    PreviewNavHarness(parentText: "Complete your profile", navTitle: "Profile setup", rowTitle: "Review profile") {
        SignupReviewView(profile: ProfileReviewData(
            firstName: "Lucas",
            location: "Berlin, Germany",
            spokenLanguages: "English, German, French",
            avatarURL: "https://i.pravatar.cc/240?img=12",
            hourlyRate: 120,
            hourlyRateCurrency: "EUR",
            skills: ["Swift", "iOS", "SwiftUI", "Combine", "Concurrency"]
        ))
    }
    .preferredColorScheme(.dark)
}
