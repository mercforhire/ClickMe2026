//
//  ClientProfileSettingsView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - User Profile Edit View

struct ClientProfileSettingsView: View {

    @StateObject private var viewModel: ClientProfileSettingsViewModel

    init(viewModel: ClientProfileSettingsViewModel = ClientProfileSettingsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            ProfileSettingsBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Text("ClickMe")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(ProfileSettingsBrand.onSurface)
                        .padding(.top, 52)
                        .padding(.bottom, 20)

                    ProfileAvatarSection(
                        profileImage: viewModel.profileImage,
                        selectedPhoto: $viewModel.selectedPhoto
                    )
                    .padding(.bottom, 24)

                    fieldsStack
                        .padding(.horizontal, 20)

                    ProfileAccountSettingsRow()
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    ProfileSaveButton(
                        isSaving: viewModel.isSaving,
                        didSave: viewModel.didSave,
                        action: viewModel.save
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 48)
                }
            }
        }
        .sheet(isPresented: $viewModel.showProfSheet) {
            ProfessionalDetailsSheet(
                jobTitle: $viewModel.jobTitle,
                company: $viewModel.company
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(ProfileSettingsBrand.sheetBg)
        }
        .sheet(isPresented: $viewModel.showLangSheet) {
            LanguageEditorSheet(languages: $viewModel.languages)
                .presentationDetents([.fraction(0.72)])
                .presentationDragIndicator(.visible)
                .presentationBackground(ProfileSettingsBrand.sheetBg)
        }
        .onChange(of: viewModel.selectedPhoto) { _ in
            Task { await viewModel.loadSelectedPhoto() }
        }
    }

    // MARK: Form fields

    private var fieldsStack: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ProfileLabeledField(label: "First Name", text: $viewModel.firstName)
                ProfileLabeledField(label: "Last Name", text: $viewModel.lastName)
            }
            HStack(spacing: 10) {
                ProfileLabeledField(label: "Email", text: $viewModel.email, keyboard: .emailAddress)
                ProfileLabeledField(label: "Phone", text: $viewModel.phone, keyboard: .phonePad)
            }

            ProfileBioField(text: $viewModel.bio)

            ProfileProfessionalCard(
                jobTitle: viewModel.jobTitle,
                company: viewModel.company,
                action: { viewModel.showProfSheet = true }
            )

            HStack(spacing: 10) {
                ProfileLabeledField(label: "Location", text: $viewModel.location)
                ProfileLabeledField(label: "Company", text: $viewModel.location2)
            }

            HStack(spacing: 8) {
                ProfileLabeledField(label: "City", text: $viewModel.city)
                    .frame(maxWidth: .infinity)
                ProfileLabeledField(label: "State/Province", text: $viewModel.state)
                    .frame(maxWidth: 90)
                ProfileCountryField(country: $viewModel.country)
            }

            ProfileLabeledField(label: "Education", text: $viewModel.education)

            ProfileLanguageField(
                languages: viewModel.languages,
                action: { viewModel.showLangSheet = true }
            )
        }
    }
}

// MARK: - Previews

#Preview("Edit Profile") {
    ClientProfileSettingsView()
        .preferredColorScheme(.dark)
}

#Preview("Professional Details Sheet") {
    ProfSheetPreview().preferredColorScheme(.dark)
}

#Preview("Language Editor Sheet") {
    LangSheetPreview().preferredColorScheme(.dark)
}

private struct ProfSheetPreview: View {
    @State private var jt = "Digital Marketing Expert"
    @State private var co = "Self-Employed"
    var body: some View {
        ZStack {
            ProfileSettingsBrand.sheetBg.ignoresSafeArea()
            ProfessionalDetailsSheet(jobTitle: $jt, company: $co)
        }
    }
}

private struct LangSheetPreview: View {
    @State private var langs = ["English", "Spanish"]
    var body: some View {
        ZStack {
            ProfileSettingsBrand.sheetBg.ignoresSafeArea()
            LanguageEditorSheet(languages: $langs)
        }
    }
}
