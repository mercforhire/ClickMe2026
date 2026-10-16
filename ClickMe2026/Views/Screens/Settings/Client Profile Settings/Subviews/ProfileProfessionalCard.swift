//
//  ProfileProfessionalCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Professional details summary card (tappable)

struct ProfileProfessionalCard: View {
    let jobTitle: String
    let company: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(ProfileSettingsBrand.fieldBg)
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(ProfileSettingsBrand.fieldBorder, lineWidth: 1))
                VStack(alignment: .leading, spacing: 10) {
                    Text("Professional Details")
                        .font(.brand(.caption, weight: .semibold))
                        .foregroundColor(ProfileSettingsBrand.onSurfaceVar)
                    HStack(spacing: 10) {
                        column(label: "Job Title", value: jobTitle)
                        column(label: "Company", value: company)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .frame(minHeight: 80)
        }
        .buttonStyle(.plain)
    }

    private func column(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.brand(.caption2, weight: .semibold))
                .foregroundColor(ProfileSettingsBrand.labelColor)
            Text(value)
                .font(.brand(.subheadline))
                .foregroundColor(ProfileSettingsBrand.onSurface)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
