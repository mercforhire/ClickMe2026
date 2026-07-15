//
//  TopicsSetupTopicsSection.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct TopicsSetupTopicsSection: View {
    @ObservedObject var viewModel: TopicsSetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Topics & Pricing")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Brand.onSurface)

            VStack(spacing: 14) {
                ForEach(viewModel.topics, id: \.id) { topic in
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
            .foregroundColor(Brand.onSurfaceVariant)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                    .foregroundColor(Brand.outlineVariant)
            )
        }
        .buttonStyle(.plain)
    }
}
