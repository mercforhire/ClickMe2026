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
    var category: String
    var skills: [String]
}

// MARK: - Profile Review & Publish View

struct SignupReviewView: View {

    @StateObject private var viewModel: SignupReviewViewModel

    var onEdit: (ProfileSection) -> Void
    var onPublish: (ProfileReviewData) -> Void

    enum ProfileSection { case personalDetails, profilePhoto, expertise }

    // MARK: Inits

    init(
        viewModel: SignupReviewViewModel = SignupReviewViewModel(),
        onEdit: @escaping (ProfileSection) -> Void = { _ in },
        onPublish: @escaping (ProfileReviewData) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onEdit = onEdit
        self.onPublish = onPublish
    }

    /// Convenience: build the VM directly from an initial profile.
    init(
        profile: ProfileReviewData,
        onEdit: @escaping (ProfileSection) -> Void = { _ in },
        onPublish: @escaping (ProfileReviewData) -> Void = { _ in }
    ) {
        self.init(
            viewModel: SignupReviewViewModel(profile: profile),
            onEdit: onEdit,
            onPublish: onPublish
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ReviewTheme.bgBase.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    ReviewHeader()
                        .padding(.top, 8)

                    ReviewTitle()

                    VStack(spacing: 18) {
                        personalDetailsCard
                        profilePhotoCard
                        expertiseCard
                    }

                    PublishProfileButton {
                        onPublish(viewModel.profile)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
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
                Text("$\(viewModel.profile.hourlyRate) / hour")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(ReviewTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var expertiseCard: some View {
        ReviewCard(
            title: "Expertise",
            onEdit: { onEdit(.expertise) }
        ) {
            VStack(alignment: .leading, spacing: 8) {
                ReviewLabeledRow(label: "Category", value: viewModel.profile.category)
                ReviewLabeledRow(label: "Skills", value: viewModel.profile.skills.joined(separator: ", "))
            }
        }
    }
}

// MARK: - Previews

#Preview("Default") {
    SignupReviewView()
        .preferredColorScheme(.dark)
}

#Preview("Many skills") {
    SignupReviewView(profile: ProfileReviewData(
        firstName: "Lucas",
        location: "Berlin, Germany",
        spokenLanguages: "English, German, French",
        avatarURL: "https://i.pravatar.cc/240?img=12",
        hourlyRate: 120,
        category: "Software Engineering",
        skills: ["Swift", "iOS", "SwiftUI", "Combine", "Concurrency"]
    ))
    .preferredColorScheme(.dark)
}
