//
//  DeleteAccountReasonSection.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Reason radio list

struct DeleteAccountReasonSection: View {
    let reasons: [DeleteAccountReason]
    @Binding var selectedReason: DeleteAccountReason?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What is your primary reason for leaving?")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(DeleteAccountBrand.onSurface)

            VStack(spacing: 8) {
                ForEach(reasons) { reason in
                    row(reason)
                }
            }
        }
    }

    private func row(_ reason: DeleteAccountReason) -> some View {
        let isSelected = selectedReason == reason
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { selectedReason = reason }
        } label: {
            HStack {
                Text(reason.label)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(DeleteAccountBrand.onSurface)
                Spacer()
                ZStack {
                    Circle()
                        .stroke(isSelected ? DeleteAccountBrand.errorRed : DeleteAccountBrand.onSurfaceVar.opacity(0.55), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(DeleteAccountBrand.errorRed)
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DeleteAccountBrand.rowBg)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? DeleteAccountBrand.errorRed.opacity(0.40) : DeleteAccountBrand.fieldBorder, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}
