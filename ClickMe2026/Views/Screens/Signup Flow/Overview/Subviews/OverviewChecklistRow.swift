//
//  OverviewChecklistRow.swift
//  ClickMe2026
//

import SwiftUI

/// A single row in the "Complete Your Profile" checklist.
struct OverviewChecklistRow: View {
    let item: ChecklistItem
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                icon
                Text(item.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Brand.onSurface)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Brand.onSurfaceFaint)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Brand.surfaceContainer)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Brand.overlayWhite06, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var icon: some View {
        if item.isComplete {
            ZStack {
                Circle().fill(Brand.primary)
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Brand.surface)
            }
            .frame(width: 44, height: 44)
        } else {
            ZStack {
                Circle().stroke(Brand.onSurfaceFaint, lineWidth: 1.5)
                Image(systemName: "star")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Brand.onSurfaceFaint)
            }
            .frame(width: 44, height: 44)
        }
    }
}
