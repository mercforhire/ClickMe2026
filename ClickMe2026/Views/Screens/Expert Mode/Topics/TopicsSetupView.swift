//
//  TopicsSetupView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Manage Expertise View

struct TopicsSetupView: View {
    @StateObject private var viewModel: TopicsSetupViewModel

    init(viewModel: TopicsSetupViewModel = TopicsSetupViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Brand.surface.ignoresSafeArea()
            content
        }
        .navigationTitle("Manage Expertise")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(isPresented: $viewModel.showTopicEditor) {
            TopicsSetupTopicEditorSheet(
                topic: viewModel.editingTopic,
                onSave: { title, description, durationMins, hourlyRateAmount, currency, freeConsultMins in
                    Task {
                        await viewModel.saveTopic(
                            title: title,
                            description: description,
                            durationMins: durationMins,
                            hourlyRateAmount: hourlyRateAmount,
                            currency: currency,
                            freeConsultationMinutes: freeConsultMins
                        )
                    }
                },
                onDismiss: { viewModel.dismissTopicEditor() }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert(
            "Something went wrong",
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

    // MARK: - Content router

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            loadingContent
        case .failed(let message):
            errorContent(message: message)
        case .loaded:
            loadedContent
        }
    }

    private var loadedContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                TopicsSetupExpertiseSection(viewModel: viewModel)
                TopicsSetupTopicsSection(viewModel: viewModel)
                TopicsSetupSaveButton(viewModel: viewModel)
            }
            .padding(20)
            .padding(.bottom, 32)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Brand.onSurface)
            Text("Loading expertise…")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(Brand.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(Brand.onSurfaceVariant)
            Text("Couldn't load expertise")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Brand.onSurface)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Brand.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task { await viewModel.reload() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Brand.onPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Brand.primary))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview harness

private struct TopicsSetupPreviewHost: View {
    let viewModel: TopicsSetupViewModel
    @State private var path: [Int] = [0]

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Profile")
                Text("Availability")
                NavigationLink("Manage Expertise", value: 0)
                Text("Payouts")
                Text("Notifications")
            }
            .navigationTitle("Expert Settings")
            .navigationDestination(for: Int.self) { _ in
                TopicsSetupView(viewModel: viewModel)
            }
        }
    }
}

/// Live-fetch harness — installs the expert bearer token and lets the
/// screen fetch its own state via `GET /meta/expertise-tags` +
/// `GET /expert/topics`.
private struct LiveFetchTopicsSetupHarness: View {
    @State private var path: [Int] = [0]

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Profile")
                NavigationLink("Manage Expertise", value: 0)
            }
            .navigationTitle("Expert Settings")
            .navigationDestination(for: Int.self) { _ in
                TopicsSetupView()
            }
        }
    }
}

// MARK: - Previews

#Preview("Manage Expertise") {
    TopicsSetupPreviewHost(viewModel: .previewSeed())
        .preferredColorScheme(.dark)
}

#Preview("Live Fetch") {
    ClickMeAPI.shared.bearerToken = PreviewSecrets.expertBearerToken
    return LiveFetchTopicsSetupHarness()
        .preferredColorScheme(.dark)
}
