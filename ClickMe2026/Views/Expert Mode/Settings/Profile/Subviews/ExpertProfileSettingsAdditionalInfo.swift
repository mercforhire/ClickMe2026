//
//  ExpertProfileSettingsAdditionalInfo.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ExpertProfileSettingsAdditionalInfo: View {
    @Bindable var viewModel: ExpertProfileSettingsViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                viewModel.toggleAdditional()
            } label: {
                HStack {
                    Text("Additional Info")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(ExpertProfileSettingsTheme.onSurface)
                    Spacer()
                    Image(systemName: viewModel.additionalExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ExpertProfileSettingsTheme.onSurfaceVar)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if viewModel.additionalExpanded {
                Divider().background(ExpertProfileSettingsTheme.cardBorder)

                VStack(spacing: 0) {
                    row(label: "Bio", value: $viewModel.bio)
                    Divider().background(ExpertProfileSettingsTheme.cardBorder).padding(.horizontal, 16)
                    row(label: "Location", value: $viewModel.location)
                    Divider().background(ExpertProfileSettingsTheme.cardBorder).padding(.horizontal, 16)
                    row(label: "Languages Spoken", value: $viewModel.languages)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ExpertProfileSettingsTheme.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ExpertProfileSettingsTheme.cardBorder, lineWidth: 1))
        )
    }

    private func row(label: String, value: Binding<String>) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(ExpertProfileSettingsTheme.onSurface)
                Text(value.wrappedValue)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(ExpertProfileSettingsTheme.onSurfaceVar)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button {} label: {
                Image(systemName: "pencil")
                    .font(.system(size: 15))
                    .foregroundColor(ExpertProfileSettingsTheme.brandGreen)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
