//
//  SignupBasicInfoView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-26.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Personal Details Onboarding View

struct SignupBasicInfoView: View {

    @StateObject private var viewModel: SignupBasicInfoViewModel

    // UI-only state
    @State private var showLanguagePicker = false

    // MARK: Callbacks

    var onBack: () -> Void
    var onSkip: () -> Void
    var onContinue: (PersonalDetailsPayload) -> Void

    // MARK: Init

    init(
        viewModel: SignupBasicInfoViewModel = SignupBasicInfoViewModel(),
        onBack: @escaping () -> Void = {},
        onSkip: @escaping () -> Void = {},
        onContinue: @escaping (PersonalDetailsPayload) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onBack = onBack
        self.onSkip = onSkip
        self.onContinue = onContinue
    }

    /// Runtime init — binds directly to the shared `SignupAccumulator`.
    init(
        accumulator: SignupAccumulator,
        onBack: @escaping () -> Void = {},
        onSkip: @escaping () -> Void = {},
        onContinue: @escaping (PersonalDetailsPayload) -> Void = { _ in }
    ) {
        self.init(
            viewModel: SignupBasicInfoViewModel(accumulator: accumulator),
            onBack: onBack,
            onSkip: onSkip,
            onContinue: onContinue
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            BasicInfoBrand.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        BasicInfoHeader()
                            .padding(.top, 20)
                            .padding(.bottom, 28)

                        VStack(spacing: 24) {
                            BasicInfoTextField(
                                placeholder: "First Name",
                                text: $viewModel.firstName
                            )

                            VStack(spacing: 12) {
                                BasicInfoIconField(
                                    systemImage: "building.2",
                                    placeholder: "City",
                                    text: $viewModel.city
                                )
                                HStack(spacing: 12) {
                                    BasicInfoTextField(
                                        placeholder: "Province/State",
                                        text: $viewModel.province
                                    )
                                    BasicInfoCountryPicker(
                                        countryCode: $viewModel.countryCode
                                    )
                                }
                            }

                            languagesField
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                    }
                }
            }

            BasicInfoContinueButton {
                onContinue(viewModel.payload)
            }
        }
        .navigationTitle("Personal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BasicInfoBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Spoken Languages field

    private var languagesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spoken Languages")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(BasicInfoBrand.onSurfaceVar)

            VStack(alignment: .leading, spacing: 8) {
                if !viewModel.languages.isEmpty {
                    FlowLayoutOnboarding(spacing: 8) {
                        ForEach(viewModel.languages, id: \.id) { lang in
                            LanguageChip(language: lang.label) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.removeLanguage(lang)
                                }
                            }
                        }
                    }
                }

                AddLanguageButton { showLanguagePicker = true }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(BasicInfoBrand.fieldBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(BasicInfoBrand.fieldBorder, lineWidth: 1)
                    )
            )
        }
        .sheet(isPresented: $showLanguagePicker) {
            LanguageSelectionView(
                initialSelection: viewModel.languages,
                onDone: { picked in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        viewModel.setLanguages(picked)
                    }
                }
            )
        }
    }
}

// MARK: - Payload

struct PersonalDetailsPayload {
    let firstName: String
    let city: String
    let province: String
    let country: String
    let languages: [LanguageItem]
}

// MARK: - Previews

#Preview("Personal Details — Onboarding") {
    PreviewNavHarness(parentText: "Create account", navTitle: "Signup", rowTitle: "Personal details") {
        SignupBasicInfoView()
    }
    .preferredColorScheme(.dark)
}
