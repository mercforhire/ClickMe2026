//
//  FavoritesProTipCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Pro tip card

struct FavoritesProTipCard: View {
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 0.10, green: 0.12, blue: 0.15))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(FavoritesBrand.tipBorder, lineWidth: 1))
                    .frame(width: 44, height: 44)
                Image(systemName: "lightbulb")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(FavoritesBrand.brandGreen)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Pro Tip:")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(FavoritesBrand.onSurface)
                Text("Tap the star icon on any expert's profile to add them to this list instantly.")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(FavoritesBrand.onSurfaceVar)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(FavoritesBrand.tipBg)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(FavoritesBrand.tipBorder, lineWidth: 1))
        )
    }
}
