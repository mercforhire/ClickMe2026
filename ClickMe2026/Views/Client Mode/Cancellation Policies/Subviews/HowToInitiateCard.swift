//
//  HowToInitiateCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Card 3 — How to Initiate a Cancellation

struct HowToInitiateCard: View {
    private let steps = [
        "Go to the 'Bookings' section of the app.",
        "Find the booking you wish to cancel.",
        "Click on the 'Cancel Booking' button.",
        "Follow the on-screen instructions.",
    ]

    var body: some View {
        PolicyCard(border: CancellationPoliciesBrand.blueGreenBorder) {
            VStack(alignment: .leading, spacing: 16) {
                header
                stepsList
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            PolicyCardTitle("How to Initiate a Cancellation")

            Text("To cancel a booking, follow the steps below. You can initiate a cancellation directly from the Bookings tab at any time before the session starts.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(CancellationPoliciesBrand.onSurfaceVar)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var stepsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(steps.indices, id: \.self) { i in
                stepRow(index: i + 1, text: steps[i])
            }
        }
    }

    private func stepRow(index: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .stroke(CancellationPoliciesBrand.brandGreen, lineWidth: 1.5)
                    .shadow(color: CancellationPoliciesBrand.brandGreen.opacity(0.35), radius: 4)
                    .frame(width: 28, height: 28)
                Text("\(index)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(CancellationPoliciesBrand.brandGreen)
            }

            Text(text)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(CancellationPoliciesBrand.onSurface)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
    }
}
