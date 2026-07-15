//
//  TopicsSetupView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct ExpertTopic: Identifiable, Equatable {
    let id: UUID
    var expertiseArea: String
    var title: String
    var hourlyRate: Int
    var freeConsultationMinutes: Int? // nil = no free consultation

    init(
        id: UUID = UUID(),
        expertiseArea: String,
        title: String,
        hourlyRate: Int,
        freeConsultationMinutes: Int? = nil
    ) {
        self.id = id
        self.expertiseArea = expertiseArea
        self.title = title
        self.hourlyRate = hourlyRate
        self.freeConsultationMinutes = freeConsultationMinutes
    }
}

// MARK: - Manage Expertise View

struct TopicsSetupView: View {
    @State private var viewModel: TopicsSetupViewModel

    init(viewModel: TopicsSetupViewModel = TopicsSetupViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            TopicsSetupTheme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    TopicsSetupExpertiseSection(viewModel: viewModel)
                    TopicsSetupTopicsSection(viewModel: viewModel)
                    TopicsSetupServiceDelivery(viewModel: viewModel)
                    TopicsSetupSaveButton(viewModel: viewModel)
                }
                .padding(20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Manage Expertise")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showTopicEditor) {
            TopicsSetupTopicEditorSheet(
                topic: viewModel.editingTopic,
                availableAreas: viewModel.expertiseAreas,
                onSave: { viewModel.saveTopic($0) },
                onDismiss: { viewModel.dismissTopicEditor() }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showAddExpertise) {
            TopicsSetupAddExpertiseSheet(
                onAdd: { viewModel.addExpertiseArea($0) },
                onDismiss: { viewModel.dismissAddExpertise() }
            )
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Previews

/// Wraps the manage-expertise screen inside a NavigationStack with a
/// dummy "Expert Settings" parent already pushed, so the system back
/// chevron renders in the canvas.
private struct TopicsSetupPreviewHost: View {
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
                TopicsSetupView()
            }
        }
    }
}

#Preview("Manage Expertise") {
    TopicsSetupPreviewHost()
        .preferredColorScheme(.dark)
}
