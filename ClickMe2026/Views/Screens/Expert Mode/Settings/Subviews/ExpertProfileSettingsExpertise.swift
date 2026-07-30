//
//  ExpertProfileSettingsExpertise.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Read-only expertise strip in the expert profile settings screen —
/// shows the currently-picked tags and an "Edit" button that opens
/// `ExpertiseEditorSheet` for catalog-backed picking.
///
/// The strip shows the primary tag first (it's inserted at index 0 by
/// `applyExpertiseEdits`). An empty state ("No expertise yet") nudges
/// the expert into the editor.
struct ExpertProfileSettingsExpertise: View {
    @Bindable var viewModel: ExpertProfileSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Expertise")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Brand.onSurface)

                Spacer()

                Button {
                    viewModel.showExpertiseSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                        Text(viewModel.expertiseEntries.isEmpty ? "Add" : "Edit")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Brand.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(Brand.primary.opacity(0.5), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            if viewModel.expertiseEntries.isEmpty {
                emptyState
            } else {
                chipsFlow
            }
        }
    }

    // MARK: - Chip strip

    private var chipsFlow: some View {
        let columns = [GridItem(.adaptive(minimum: 120), spacing: 8)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(viewModel.expertiseEntries, id: \.id) { entry in
                tagChip(entry)
            }
        }
    }

    private func tagChip(_ entry: ExpertProfileData.ExpertiseTagEntry) -> some View {
        HStack(spacing: 6) {
            if entry.isPrimary {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Brand.primary)
            }
            Text(entry.label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Brand.onSurface)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ExpertProfileSettingsTheme.tagBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            entry.isPrimary
                                ? Brand.primary.opacity(0.55)
                                : ExpertProfileSettingsTheme.tagBorder,
                            lineWidth: 1
                        )
                )
        )
    }

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14))
                .foregroundColor(Brand.primary.opacity(0.7))
            Text("Pick expertise so clients can find you.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(Brand.onSurfaceVariant)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Brand.surfaceContainer)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                        .foregroundColor(Brand.primary.opacity(0.25))
                )
        )
    }
}
