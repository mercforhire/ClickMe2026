//
//  CancellationReasonCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Reason radio list card

struct CancellationReasonCard: View {
    let reasons: [String]
    @Binding var selectedReason: String

    var body: some View {
        VStack(spacing: 0) {
            ForEach(reasons.indices, id: \.self) { i in
                let reason = reasons[i]
                let isSelected = selectedReason == reason

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedReason = reason }
                } label: {
                    HStack {
                        Text(reason)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(CancellationBrand.onSurface)
                        Spacer()
                        radio(isSelected: isSelected)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if i < reasons.count - 1 {
                    Rectangle()
                        .fill(CancellationBrand.outlineVar.opacity(0.30))
                        .frame(height: 1)
                        .padding(.horizontal, 18)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(CancellationBrand.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(CancellationBrand.cardBorder, lineWidth: 1))
        )
        .padding(.horizontal, 20)
    }

    private func radio(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(isSelected ? CancellationBrand.brandGreen : CancellationBrand.outlineVar, lineWidth: 2)
                .frame(width: 24, height: 24)
                .shadow(color: isSelected ? CancellationBrand.brandGreen.opacity(0.50) : .clear, radius: 5)

            if isSelected {
                Circle()
                    .fill(CancellationBrand.brandGreen)
                    .frame(width: 11, height: 11)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
