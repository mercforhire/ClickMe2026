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

    /// Observed so the avatar refreshes reactively when
    /// `UserManager.refreshProfile` returns a new photo URL (or when the
    /// user uploads a new one from the signup flow / another device).
    @ObservedObject private var userManager = UserManager.shared

    /// Tracks taps on the version footer. Reaching 5 consecutive taps clears
    /// the onboarding-shown flag (debug affordance for QA / demos).
    @State private var versionTapCount: Int = 0
    @State private var showOnboardingResetAlert: Bool = false

    init(viewModel: ClientProfileSettingsViewModel = ClientProfileSettingsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            ProfileSettingsBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ProfileAvatarSection(
                        profileImage: viewModel.profileImage,
                        remoteAvatarURL: userManager.profile?.personalDetails.avatarUrl,
                        selectedPhoto: $viewModel.selectedPhoto
                    )
                    .padding(.top, 12)
                    .padding(.bottom, 24)

                    fieldsStack
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    versionFooter
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Profile Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ProfileSettingsBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                autoSaveStatusIcon
            }
        }
        .onChange(of: autoSaveSnapshot) {
            viewModel.scheduleAutoSave()
        }
        .alert("Onboarding reset", isPresented: $showOnboardingResetAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The welcome flow will show again the next time you open the app.")
        }
        .alert(
            "Couldn't upload avatar",
            isPresented: Binding(
                get: { viewModel.avatarUploadError != nil },
                set: { if !$0 { viewModel.avatarUploadError = nil } }
            ),
            presenting: viewModel.avatarUploadError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .alert(
            "Couldn't save changes",
            isPresented: Binding(
                get: { viewModel.autoSaveError != nil },
                set: { if !$0 { viewModel.autoSaveError = nil } }
            ),
            presenting: viewModel.autoSaveError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
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
        .onChange(of: viewModel.selectedPhoto) {
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
            ProfileLabeledField(label: "Phone", text: $viewModel.phone, keyboard: .phonePad)

            ProfileBioField(text: $viewModel.bio)

            ProfileProfessionalCard(
                jobTitle: viewModel.jobTitle,
                company: viewModel.company,
                action: { viewModel.showProfSheet = true }
            )

            HStack(spacing: 8) {
                ProfileLabeledField(label: "City", text: $viewModel.city)
                    .frame(maxWidth: .infinity)
                ProfileLabeledField(label: "State/Province", text: $viewModel.state)
                    .frame(maxWidth: 120)
            }

            ProfileCountryField(country: $viewModel.country)

            ProfileLanguageField(
                languages: viewModel.languages,
                action: { viewModel.showLangSheet = true }
            )
        }
    }

    // MARK: Auto-save chrome

    /// Trailing-nav-bar spinner while saving, checkmark right after a
    /// successful save. Empty in all other states so the bar stays clean.
    @ViewBuilder
    private var autoSaveStatusIcon: some View {
        if viewModel.isAutoSaving {
            ProgressView()
                .controlSize(.small)
                .tint(ProfileSettingsBrand.onSurface)
        } else if viewModel.didAutoSave {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(ProfileSettingsBrand.brandGreen)
                .transition(.opacity)
        }
    }

    /// Compact string that changes whenever any auto-save-triggering field
    /// changes. A single `.onChange` on this drives the debounced save
    /// scheduler — cleaner than an `.onChange` per field.
    private var autoSaveSnapshot: String {
        [
            viewModel.firstName, viewModel.lastName, viewModel.phone, viewModel.bio,
            viewModel.jobTitle, viewModel.company,
            viewModel.city, viewModel.state, viewModel.country
        ].joined(separator: "|")
    }

    // MARK: Version footer + hidden reset

    /// Muted app version label. Five taps in succession clears
    /// `UserManager.hasSeenOnboarding`, matching the classic iOS
    /// "tap the version to unlock developer mode" pattern.
    private var versionFooter: some View {
        Text(Self.versionString)
            .font(.system(size: 12, weight: .regular, design: .rounded))
            .foregroundColor(ProfileSettingsBrand.onSurface.opacity(0.35))
            .contentShape(Rectangle())
            .onTapGesture {
                versionTapCount += 1
                if versionTapCount >= 5 {
                    versionTapCount = 0
                    UserManager.shared.resetOnboardingShown()
                    showOnboardingResetAlert = true
                }
            }
    }

    private static var versionString: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(short) (\(build))"
    }
}

// MARK: - Previews

#Preview("Profile Settings") {
    PreviewNavHarness(parentText: "Account", navTitle: "Profile", rowTitle: "Personal Information") {
        ClientProfileSettingsView()
    }
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
