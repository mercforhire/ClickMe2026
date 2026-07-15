//
//  TopicsSetupExpertiseSection.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct TopicsSetupExpertiseSection: View {
    @Bindable var viewModel: TopicsSetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Expertise Areas")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(TopicsSetupTheme.onSurface)
                Spacer()
                Text("Select up to 5")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(TopicsSetupTheme.onSurfaceVariant)
            }

            TopicsSetupFlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(viewModel.expertiseAreas, id: \.self) { area in
                    expertisePill(area)
                }
                addExpertisePill
            }
        }
    }

    private func expertisePill(_ name: String) -> some View {
        HStack(spacing: 8) {
            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(TopicsSetupTheme.primary)
            Button { viewModel.removeExpertiseArea(name) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(TopicsSetupTheme.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(TopicsSetupTheme.primary.opacity(0.08))
                .overlay(Capsule().stroke(TopicsSetupTheme.primary, lineWidth: 1.2))
        )
    }

    private var addExpertisePill: some View {
        Button { viewModel.openAddExpertise() } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                Text("Add Expertise")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(TopicsSetupTheme.onSurfaceVariant)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundColor(TopicsSetupTheme.outlineVariant)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.expertiseAreas.count >= 5)
        .opacity(viewModel.expertiseAreas.count >= 5 ? 0.45 : 1)
    }
}
