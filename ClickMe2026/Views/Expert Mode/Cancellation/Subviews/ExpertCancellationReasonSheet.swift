//
//  ExpertCancellationReasonSheet.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-27.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Bottom-sheet reason picker with checkmark on selected row

struct ExpertCancellationReasonSheet: View {
    let selectedReason: CancellationReason
    let onSelect: (CancellationReason) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Reason for Cancellation")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(ExpertCancellationBrand.onSurface)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider().background(ExpertCancellationBrand.cardBorder)

            VStack(spacing: 0) {
                ForEach(CancellationReason.allCases.filter { $0 != .none }) { reason in
                    Button {
                        onSelect(reason)
                    } label: {
                        HStack {
                            Text(reason.rawValue)
                                .font(.system(size: 15,
                                              weight: selectedReason == reason ? .semibold : .regular,
                                              design: .rounded))
                                .foregroundColor(
                                    selectedReason == reason
                                        ? ExpertCancellationBrand.brandGreen
                                        : ExpertCancellationBrand.onSurface
                                )
                            Spacer()
                            if selectedReason == reason {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(ExpertCancellationBrand.brandGreen)
                            }
                        }
                        .padding(.horizontal, 24)
                        .frame(height: 52)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider()
                        .background(ExpertCancellationBrand.cardBorder.opacity(0.50))
                        .padding(.horizontal, 24)
                }
            }
        }
        .foregroundColor(ExpertCancellationBrand.onSurface)
    }
}
