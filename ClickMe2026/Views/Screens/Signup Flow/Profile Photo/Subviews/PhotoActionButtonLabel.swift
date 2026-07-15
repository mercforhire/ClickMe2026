//
//  PhotoActionButtonLabel.swift
//  ClickMe2026
//

import SwiftUI

/// Rounded outlined label used by the Upload and Remove photo actions.
struct PhotoActionButtonLabel: View {
    let icon: String
    let title: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(ProfilePhotoBrand.fieldBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(ProfilePhotoBrand.fieldBorder, lineWidth: 1.2)
                )
                .frame(height: 54)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.75))
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
}
