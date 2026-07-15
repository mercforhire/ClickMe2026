//
//  ExpertProfileSettingsExpertise.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ExpertProfileSettingsExpertise: View {
    @Bindable var viewModel: ExpertProfileSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expertise")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(Brand.onSurface)

            // Existing tags
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach($viewModel.expertiseTags) { $tag in
                    tagView($tag)
                }
            }

            // Add topic field
            HStack {
                TextField("Add Discussion Topic", text: $viewModel.newTopic)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Brand.onSurfaceVariant)
                    .submitLabel(.done)
                    .onSubmit { viewModel.addTopic() }

                Button { viewModel.addTopic() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Brand.primary)
                }
                .disabled(viewModel.newTopic.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Brand.surfaceContainer)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Brand.primary.opacity(0.30), lineWidth: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                                    .foregroundColor(Brand.primary.opacity(0.25))
                            )
                    )
            )
        }
    }

    private func tagView(_ tag: Binding<ExpertiseTagChip>) -> some View {
        HStack {
            Text(tag.wrappedValue.name)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Brand.onSurface)
                .lineLimit(1)
            Spacer()
            Button {} label: {
                Image(systemName: "pencil")
                    .font(.system(size: 13))
                    .foregroundColor(Brand.primary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ExpertProfileSettingsTheme.tagBg)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(ExpertProfileSettingsTheme.tagBorder, lineWidth: 1))
        )
    }
}
