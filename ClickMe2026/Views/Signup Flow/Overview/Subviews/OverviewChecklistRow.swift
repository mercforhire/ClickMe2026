//
//  OverviewChecklistRow.swift
//  ClickMe2026
//

import SwiftUI

/// A single row in the "Complete Your Profile" checklist.
struct OverviewChecklistRow: View {
    let item: ChecklistItem

    var body: some View {
        HStack(spacing: 16) {
            icon
            Text(item.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(OverviewTheme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(OverviewTheme.textTertiary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(OverviewTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(OverviewTheme.cardStroke, lineWidth: 1)
                )
        )
    }

    @ViewBuilder private var icon: some View {
        if item.isComplete {
            ZStack {
                Circle().fill(OverviewTheme.green)
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(OverviewTheme.bg)
            }
            .frame(width: 44, height: 44)
        } else {
            ZStack {
                Circle().stroke(OverviewTheme.textTertiary, lineWidth: 1.5)
                Image(systemName: "star")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(OverviewTheme.textTertiary)
            }
            .frame(width: 44, height: 44)
        }
    }
}
