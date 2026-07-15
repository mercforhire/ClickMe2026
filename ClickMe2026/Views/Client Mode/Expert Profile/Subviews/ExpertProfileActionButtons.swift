//
//  ExpertProfileActionButtons.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Book Session + Message buttons

struct ExpertProfileActionButtons: View {
    let onBookSession: () -> Void
    let onMessage: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            bookSessionButton
            messageButton
        }
    }

    private var bookSessionButton: some View {
        Button(action: onBookSession) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 17, weight: .medium))
                Text("Book Session")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(ExpertProfileBrand.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ExpertProfileBrand.brandGreen)
                    .shadow(color: ExpertProfileBrand.brandGreen.opacity(0.40), radius: 14, x: 0, y: 4)
            )
        }
        .buttonStyle(ProfileActionStyle())
    }

    private var messageButton: some View {
        Button(action: onMessage) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 17, weight: .medium))
                Text("Message")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(ExpertProfileBrand.brandGreen)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(ExpertProfileBrand.brandGreen, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(ProfileActionStyle())
    }
}
