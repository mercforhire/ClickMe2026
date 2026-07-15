//
//  FeedbackView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Feedback View

struct FeedbackView: View {

    @StateObject private var viewModel: FeedbackViewModel
    @FocusState private var detailsFocused: Bool
    @FocusState private var emailFocused: Bool

    init(viewModel: FeedbackViewModel = FeedbackViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            FeedbackBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                formCard
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle("Send Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FeedbackBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
        .confirmationDialog("Feedback Type", isPresented: $viewModel.showTypePicker, titleVisibility: .visible) {
            ForEach(viewModel.feedbackTypes) { type in
                Button(type.label) { viewModel.selectType(type) }
            }
        }
        .alert(
            "Couldn't send feedback",
            isPresented: Binding(
                get: { viewModel.apiError != nil },
                set: { if !$0 { viewModel.apiError = nil } }
            ),
            presenting: viewModel.apiError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Form card

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            FeedbackTypePicker(
                feedbackType: pickerLabel,
                onTap: { if canOpenTypePicker { viewModel.showTypePicker = true } }
            )
            .disabled(!canOpenTypePicker)

            FeedbackDetailsField(
                text: $viewModel.details,
                showError: viewModel.showDetailsError,
                isFocused: $detailsFocused,
                onTextChange: { viewModel.detailsDidChange() }
            )

            FeedbackEmailField(
                email: $viewModel.email,
                isFocused: $emailFocused
            )

            FeedbackSubmitButton(
                isSubmitting: viewModel.isSubmitting,
                didSubmit: viewModel.didSubmit,
                action: { Task { await viewModel.submit() } }
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(FeedbackBrand.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(FeedbackBrand.iridBorder, lineWidth: 1.5)
                )
        )
    }

    // MARK: - Picker state

    /// Copy shown in the type picker chip while the initial `getFeedbackTypes`
    /// call is in flight or has failed. Falls back to the selected item's
    /// label once loaded.
    private var pickerLabel: String {
        if let selected = viewModel.selectedType { return selected.label }
        switch viewModel.loadState {
        case .idle, .loading: return "Loading categories…"
        case .failed:         return "Categories unavailable"
        case .loaded:         return "Choose a category"
        }
    }

    /// The picker only opens once we have real categories to show. Prevents
    /// the confirmation dialog from surfacing with an empty button list.
    private var canOpenTypePicker: Bool {
        !viewModel.feedbackTypes.isEmpty
    }
}

// MARK: - Previews

#Preview("Default") {
    PreviewNavHarness(parentText: "Support", navTitle: "Settings", rowTitle: "Send feedback") {
        FeedbackView(viewModel: .previewSeed())
    }
    .preferredColorScheme(.dark)
}

#Preview("Validation Error") {
    PreviewNavHarness(parentText: "Support", navTitle: "Settings", rowTitle: "Send feedback") {
        FeedbackView(viewModel: .previewSeed(showDetailsError: true))
    }
    .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
    return PreviewNavHarness(parentText: "Support", navTitle: "Settings", rowTitle: "Send feedback") {
        FeedbackView()
    }
    .preferredColorScheme(.dark)
}
