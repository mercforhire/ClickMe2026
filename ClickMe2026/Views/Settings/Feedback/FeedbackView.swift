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
        .confirmationDialog("Feedback Type", isPresented: $viewModel.showTypePicker, titleVisibility: .visible) {
            ForEach(viewModel.feedbackTypes, id: \.self) { type in
                Button(type) { viewModel.selectType(type) }
            }
        }
    }

    // MARK: - Form card

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            FeedbackTypePicker(
                feedbackType: viewModel.feedbackType,
                onTap: { viewModel.showTypePicker = true }
            )

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
                action: { viewModel.submit() }
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
}

// MARK: - Preview harness

private enum FeedbackPreviewRoute: Hashable {
    case `default`
    case validationError
}

/// Wraps the feedback screen inside a NavigationStack with a dummy
/// "Settings" parent already pushed, so the system back chevron renders
/// in the canvas.
private struct FeedbackPreviewHarness: View {
    let route: FeedbackPreviewRoute
    @State private var path: [FeedbackPreviewRoute]

    init(route: FeedbackPreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Support")
                NavigationLink("Send feedback", value: route)
            }
            .navigationTitle("Settings")
            .navigationDestination(for: FeedbackPreviewRoute.self) { dest in
                switch dest {
                case .default:
                    FeedbackView()
                case .validationError:
                    FeedbackView(viewModel: FeedbackViewModel(showDetailsError: true))
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Default") {
    FeedbackPreviewHarness(route: .default)
        .preferredColorScheme(.dark)
}

#Preview("Validation Error") {
    FeedbackPreviewHarness(route: .validationError)
        .preferredColorScheme(.dark)
}
