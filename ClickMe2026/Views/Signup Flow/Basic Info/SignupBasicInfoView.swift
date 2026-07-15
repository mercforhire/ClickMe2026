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
                                    BasicInfoTextField(
                                        placeholder: "Country",
                                        text: $viewModel.country
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
        .navigationBarHidden(true)
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
                        ForEach(viewModel.languages, id: \.self) { lang in
                            LanguageChip(language: lang) {
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
    let languages: [String]
}

// MARK: - Preview

#Preview("Personal Details — Onboarding") {
    SignupBasicInfoView()
        .preferredColorScheme(.dark)
}
