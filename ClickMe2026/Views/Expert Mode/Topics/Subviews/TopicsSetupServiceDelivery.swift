//
//  TopicsSetupServiceDelivery.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct TopicsSetupServiceDelivery: View {
    @Bindable var viewModel: TopicsSetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Service Delivery")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(TopicsSetupTheme.onSurface)

            VStack(spacing: 0) {
                serviceRow(
                    icon: "phone.fill",
                    title: "In-app Voice Call",
                    subtitle: "Encrypted high-fidelity audio",
                    isOn: $viewModel.inAppVoiceEnabled
                )
                Divider().background(TopicsSetupTheme.outlineVariant.opacity(0.5))
                serviceRow(
                    icon: "video",
                    title: "Skype/Zoom Call",
                    subtitle: "Requires external link",
                    isOn: $viewModel.skypeZoomEnabled
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(TopicsSetupTheme.cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(TopicsSetupTheme.outlineVariant.opacity(0.5), lineWidth: 1))
            )
        }
    }

    private func serviceRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(TopicsSetupTheme.primary.opacity(isOn.wrappedValue ? 0.18 : 0.08))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(TopicsSetupTheme.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(TopicsSetupTheme.onSurface)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(TopicsSetupTheme.onSurfaceVariant)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(TopicsSetupTheme.primaryContainer)
        }
        .padding(16)
    }
}
