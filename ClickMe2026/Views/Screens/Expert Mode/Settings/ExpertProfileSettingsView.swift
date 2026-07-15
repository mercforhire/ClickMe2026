//
//  ExpertProfileSettingsView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct ExpertiseTagChip: Identifiable {
    let id = UUID()
    var name: String
}

struct HourlyRateItem: Identifiable {
    let id = UUID()
    var topic: String
    var rate: Int
}

struct AvailabilitySlot: Identifiable {
    let id = UUID()
    let day: String
    var columns: [Bool] // Mon,Tue,Wed,Thu,Fri checkboxes
    var timeRange: String
}

// MARK: - Expert Profile Management View

struct ExpertProfileSettingsView: View {
    @State private var viewModel: ExpertProfileSettingsViewModel

    init(viewModel: ExpertProfileSettingsViewModel = ExpertProfileSettingsViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        // Inline @Bindable so we can hand `Binding<...>` down to the
        // shared `ProfileLabeledField`/`ProfileBioField`/... subviews.
        @Bindable var vm = viewModel

        ZStack {
            Brand.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ExpertProfileSettingsAvatar(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 24)

                    clientFieldsStack(vm: vm)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    ExpertProfileSettingsExpertise(viewModel: viewModel)
                        .padding(.horizontal, 20).padding(.bottom, 24)

                    ExpertProfileSettingsRates(viewModel: viewModel)
                        .padding(.horizontal, 20).padding(.bottom, 24)

                    ExpertProfileSettingsAvailability(viewModel: viewModel)
                        .padding(.horizontal, 20).padding(.bottom, 24)

                    ExpertProfileSettingsSaveButton(viewModel: viewModel)
                        .padding(.horizontal, 20).padding(.bottom, 40)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Expert Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                autoSaveStatusIcon
            }
        }
        .onChange(of: autoSaveSnapshot) { _ in
            viewModel.scheduleAutoSave()
        }
        .onChange(of: viewModel.selectedPhoto) { _ in
            Task { await viewModel.loadSelectedPhoto() }
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
        .sheet(isPresented: $vm.showProfSheet) {
            ProfessionalDetailsSheet(
                jobTitle: $vm.jobTitle,
                company: $vm.company
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(ProfileSettingsBrand.sheetBg)
        }
        .sheet(isPresented: $vm.showLangSheet) {
            LanguageEditorSheet(languages: $vm.languages)
                .presentationDetents([.fraction(0.72)])
                .presentationDragIndicator(.visible)
                .presentationBackground(ProfileSettingsBrand.sheetBg)
        }
    }

    // MARK: - Client-side fields stack

    /// Mirrors `ClientProfileSettingsView.fieldsStack` — first/last name,
    /// phone, bio, professional card, city+state, country, and languages.
    /// Email is intentionally omitted per product spec.
    private func clientFieldsStack(vm: Bindable<ExpertProfileSettingsViewModel>) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ProfileLabeledField(label: "First Name", text: vm.firstName)
                ProfileLabeledField(label: "Last Name", text: vm.lastName)
            }
            ProfileLabeledField(label: "Phone", text: vm.phone, keyboard: .phonePad)

            ProfileBioField(text: vm.bio)

            ProfileProfessionalCard(
                jobTitle: vm.wrappedValue.jobTitle,
                company: vm.wrappedValue.company,
                action: { vm.wrappedValue.showProfSheet = true }
            )

            HStack(spacing: 8) {
                ProfileLabeledField(label: "City", text: vm.city)
                    .frame(maxWidth: .infinity)
                ProfileLabeledField(label: "State/Province", text: vm.state)
                    .frame(maxWidth: 120)
            }

            ProfileCountryField(country: vm.country)

            ProfileLanguageField(
                languages: vm.wrappedValue.languages,
                action: { vm.wrappedValue.showLangSheet = true }
            )
        }
    }

    // MARK: - Auto-save chrome

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

    /// Trailing-nav-bar spinner while saving, checkmark right after a
    /// successful save. Empty in all other states so the bar stays clean.
    @ViewBuilder
    private var autoSaveStatusIcon: some View {
        if viewModel.isAutoSaving {
            ProgressView()
                .controlSize(.small)
                .tint(Brand.onSurface)
        } else if viewModel.didAutoSave {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Brand.primary)
                .transition(.opacity)
        }
    }
}

// MARK: - Preview harness

private enum ExpertProfileSettingsPreviewRoute: Hashable { case settings }

/// Wraps the screen in a NavigationStack with a dummy "Expert" parent
/// already pushed, so the system back chevron renders in the canvas —
/// matches how the profile hub pushes this screen in production.
private struct ExpertProfileSettingsPreviewHarness: View {
    @State private var path: [ExpertProfileSettingsPreviewRoute] = [.settings]

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Profile Hub")
                NavigationLink("Edit Profile", value: ExpertProfileSettingsPreviewRoute.settings)
            }
            .navigationTitle("Expert")
            .navigationDestination(for: ExpertProfileSettingsPreviewRoute.self) { _ in
                ExpertProfileSettingsView()
            }
        }
    }
}

// MARK: - Previews

#Preview("Expert Profile") {
    ExpertProfileSettingsPreviewHarness()
        .preferredColorScheme(.dark)
}
