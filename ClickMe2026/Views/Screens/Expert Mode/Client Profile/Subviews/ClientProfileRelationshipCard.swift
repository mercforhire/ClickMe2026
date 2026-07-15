//
//  ClientProfileRelationshipCard.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Aggregate stats about the expert's shared history with this client —
/// total number of sessions and the first / last session dates. Populated
/// server-side so the mobile client doesn't paginate through all bookings
/// just to compute it.
struct ClientProfileRelationshipCard: View {
    let totalSessions: Int
    let firstSessionDate: Date?
    let lastSessionDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Sessions Together")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(ClientProfileBrand.onSurface)

            HStack(spacing: 12) {
                statCell(
                    value: "\(totalSessions)",
                    label: totalSessions == 1 ? "Session" : "Sessions"
                )
                statCell(
                    value: firstSessionLabel ?? "—",
                    label: "Client since"
                )
                statCell(
                    value: lastSessionLabel ?? "—",
                    label: "Last session"
                )
            }
        }
    }

    private var firstSessionLabel: String? {
        guard let firstSessionDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: firstSessionDate)
    }

    private var lastSessionLabel: String? {
        guard let lastSessionDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: lastSessionDate)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(ClientProfileBrand.brandGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(ClientProfileBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ClientProfileBrand.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(ClientProfileBrand.outlineVar, lineWidth: 1)
                )
        )
    }
}
