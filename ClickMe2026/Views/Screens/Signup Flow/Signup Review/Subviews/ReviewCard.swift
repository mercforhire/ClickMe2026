//
//  ReviewCard.swift
//  ClickMe2026
//

import SwiftUI

/// Rounded card with a bold title, a green-bordered pencil edit button on the
/// trailing edge, and a custom content body below.
struct ReviewCard<Content: View>: View {
    let title: String
    let onEdit: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Brand.onSurface)

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Brand.primary)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Brand.primary.opacity(0.55), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.surfaceContainer)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Brand.primary.opacity(0.55), lineWidth: 1)
                )
        )
    }
}
