//
//  TopicsSetupTopicCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct TopicsSetupTopicCard: View {
    let topic: ExpertTopic
    let viewModel: TopicsSetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text(topic.expertiseArea.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(TopicsSetupTheme.primary)
                Spacer()
                Menu {
                    Button("Edit") { viewModel.editTopic(topic) }
                    Button("Delete", role: .destructive) { viewModel.deleteTopic(topic) }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(TopicsSetupTheme.onSurfaceVariant)
                        .frame(width: 32, height: 32)
                }
            }

            // Topic + rate
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Topic Title")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(TopicsSetupTheme.onSurfaceVariant)
                    Text(topic.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(TopicsSetupTheme.onSurface)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Hourly Rate")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(TopicsSetupTheme.onSurfaceVariant)
                    Text("$\(topic.hourlyRate)/hr")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(TopicsSetupTheme.primary)
                }
            }

            Divider().background(TopicsSetupTheme.outlineVariant.opacity(0.6))

            // Free consultation row
            HStack(spacing: 10) {
                if let minutes = topic.freeConsultationMinutes {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(TopicsSetupTheme.primary)
                    Text("\(minutes)m Free Consultation")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(TopicsSetupTheme.onSurface)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 18))
                        .foregroundColor(TopicsSetupTheme.onSurfaceVariant)
                    Text("No Free Consultation")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(TopicsSetupTheme.onSurfaceVariant)
                }
                Spacer()
                Button { viewModel.deleteTopic(topic) } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15))
                        .foregroundColor(TopicsSetupTheme.onSurfaceVariant)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(TopicsSetupTheme.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(TopicsSetupTheme.outlineVariant.opacity(0.5), lineWidth: 1))
        )
    }
}
