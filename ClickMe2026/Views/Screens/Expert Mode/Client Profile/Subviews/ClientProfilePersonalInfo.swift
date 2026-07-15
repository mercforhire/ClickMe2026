//
//  ClientProfilePersonalInfo.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Read-only "About" section: bio, location, languages, member-since.

/// Renders the client's public profile fields the expert is allowed to
/// see. All rows are read-only — the expert can't edit another user's
/// personal information.
struct ClientProfilePersonalInfo: View {
    let bio: String?
    let city: String?
    let stateProvince: String?
    let country: String?
    let timezone: String?
    let languages: [String]
    let memberSince: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("About")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(ClientProfileBrand.onSurface)

            VStack(spacing: 10) {
                if let bio, !bio.isEmpty {
                    bioRow(bio: bio)
                }
                if let locationLabel {
                    infoRow(icon: "mappin.and.ellipse", label: "Location", value: locationLabel)
                }
                if let timezone, !timezone.isEmpty {
                    infoRow(icon: "clock", label: "Timezone", value: timezone)
                }
                if !languages.isEmpty {
                    infoRow(icon: "character.bubble", label: "Languages", value: languages.joined(separator: ", "))
                }
                if let memberSinceLabel {
                    infoRow(icon: "person.badge.clock", label: "Member since", value: memberSinceLabel)
                }
            }
        }
    }

    // MARK: - Derived labels

    private var locationLabel: String? {
        let parts = [city, stateProvince, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private var memberSinceLabel: String? {
        guard let memberSince else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: memberSince)
    }

    // MARK: - Rows

    private func bioRow(bio: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "text.quote")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ClientProfileBrand.brandGreen)
                Text("Bio")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(ClientProfileBrand.onSurfaceVar)
            }
            Text(bio)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(ClientProfileBrand.onSurface)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardBackground)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(ClientProfileBrand.brandGreen)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(ClientProfileBrand.onSurfaceVar)
                Text(value)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(ClientProfileBrand.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(ClientProfileBrand.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(ClientProfileBrand.outlineVar, lineWidth: 1)
            )
    }
}
