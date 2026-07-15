//
//  ReadyToStartCallLinkCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Skype-link card with a Copy / Copied pill button

struct ReadyToStartCallLinkCard: View {
    let skypeLink: String
    let didCopy: Bool
    let opacity: Double
    let yOffset: CGFloat
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Skype link:")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(ReadyToStartCallBrand.onSurfaceVar)
                Text(skypeLink)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(ReadyToStartCallBrand.onSurface)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button(action: onCopy) {
                HStack(spacing: 6) {
                    Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 14, weight: .semibold))
                    Text(didCopy ? "Copied" : "Copy")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(ReadyToStartCallBrand.onPrimary)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(
                    Capsule()
                        .fill(ReadyToStartCallBrand.brandGreen)
                        .shadow(color: ReadyToStartCallBrand.brandGreen.opacity(0.40), radius: 8, x: 0, y: 2)
                )
            }
            .buttonStyle(SkypeScaleStyle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ReadyToStartCallBrand.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(ReadyToStartCallBrand.cardBorder, lineWidth: 1)
                )
        )
        .opacity(opacity)
        .offset(y: yOffset)
    }
}
