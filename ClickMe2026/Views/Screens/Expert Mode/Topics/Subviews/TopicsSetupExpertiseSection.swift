//
//  TopicsSetupExpertiseSection.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Multi-select expertise picker sourced from `GET /meta/expertise-tags`.
/// Persisted via `PATCH /expert/profile.expertiseTags` when the outer
/// "Save Changes" button fires.
struct TopicsSetupExpertiseSection: View {
    @ObservedObject var viewModel: TopicsSetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Expertise Areas")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Brand.onSurface)
                Spacer()
                Text("Select up to \(viewModel.maxTagSelection)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Brand.onSurfaceVariant)
            }

            if viewModel.availableTags.isEmpty {
                Text("No expertise tags available.")
                    .font(.system(size: 13))
                    .foregroundColor(Brand.onSurfaceVariant)
            } else {
                TopicsSetupFlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                    ForEach(viewModel.availableTags) { tag in
                        pill(for: tag)
                    }
                }
            }
        }
    }

    private func pill(for tag: ExpertiseTagItem) -> some View {
        let isSelected = viewModel.isSelected(tag)
        let atCap = viewModel.selectedTagIds.count >= viewModel.maxTagSelection && !isSelected

        return Button {
            viewModel.toggleTag(tag)
        } label: {
            Text(tag.label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? Brand.primary : Brand.onSurfaceVariant)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Brand.primary.opacity(0.08) : Color.clear)
                        .overlay(
                            Capsule().stroke(
                                isSelected ? Brand.primary : Brand.outlineVariant,
                                lineWidth: isSelected ? 1.2 : 1
                            )
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(atCap)
        .opacity(atCap ? 0.45 : 1)
    }
}
