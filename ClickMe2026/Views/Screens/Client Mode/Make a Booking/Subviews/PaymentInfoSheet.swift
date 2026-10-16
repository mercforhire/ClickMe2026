//
//  PaymentInfoSheet.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Pre-payment info bottom sheet — opened by the "How does payment work?"
/// affordance on `MakeABookingView`. Deliberately non-intrusive: the user
/// still sees the "Book Now" button; this sheet only appears when they
/// explicitly ask.
///
/// Reuses `PaymentLifecycleCard` in `.upcoming` state so pre- and
/// post-payment screens describe the same flow with consistent copy.
/// Product direction is that the client pays exactly the session price
/// (no platform fee layered on top), so the sheet doesn't discuss fees
/// — the only thing users are confused about is timing, so that's all
/// this answers.
struct PaymentInfoSheet: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.surface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("How does payment work?")
                                .font(.brand(.title3, weight: .bold))
                                .foregroundColor(Brand.onSurface)
                            Text("You pay exactly the session price — no additional fees. Here's when your card is charged.")
                                .font(.brand(.subheadline, weight: .regular))
                                .foregroundColor(Brand.overlayWhite80)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        PaymentLifecycleCard(currentStep: .upcoming)

                        Button {
                            dismiss()
                        } label: {
                            Text("Got it")
                                .font(.brand(.subheadline, weight: .bold))
                                .foregroundColor(Brand.onPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Brand.primary)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Brand.onSurface)
                    }
                }
            }
            .toolbarBackground(Brand.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            PaymentInfoSheet()
        }
        .preferredColorScheme(.dark)
}
