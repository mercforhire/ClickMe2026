//
//  TopicsSetupTopicsSection.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct TopicsSetupTopicsSection: View {
    @Bindable var viewModel: TopicsSetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Topics & Pricing")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(TopicsSetupTheme.onSurface)
                Spacer()
                HStack(spacing: 8) {
                    Text("Global Free Consult")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(TopicsSetupTheme.onSurfaceVariant)
                    Toggle("", isOn: $viewModel.globalFreeConsult)
                        .labelsHidden()
                        .tint(TopicsSetupTheme.primaryContainer)
                        .scaleEffect(0.85)
                }
            }

            VStack(spacing: 14) {
                ForEach(viewModel.topics) { topic in
                    TopicsSetupTopicCard(topic: topic, viewModel: viewModel)
                }
                addTopicButton
            }
        }
    }

    private var addTopicButton: some View {
        Button { viewModel.newTopic() } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 16, weight: .medium))
                Text("Add New Topic")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(TopicsSetupTheme.onSurfaceVariant)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                    .foregroundColor(TopicsSetupTheme.outlineVariant)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.expertiseAreas.isEmpty)
        .opacity(viewModel.expertiseAreas.isEmpty ? 0.45 : 1)
    }
}
