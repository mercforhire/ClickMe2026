//
//  MakeABookingNotesCard.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Optional free-form note that goes to the expert with the booking request
/// (`client_notes` on `POST /bookings/request` and `/bookings/confirm`).
struct MakeABookingNotesCard: View {
    @Binding var clientNotes: String

    private let maxLength = 500

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MakeABookingSectionHeader(title: "Message (optional)")

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(MakeABookingBrand.surface)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(MakeABookingBrand.outlineVar, lineWidth: 1))

                if clientNotes.isEmpty {
                    Text("Add context for the expert — what you'd like to focus on, questions you have, etc.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(MakeABookingBrand.onSurfaceVar.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $clientNotes)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(MakeABookingBrand.onSurface)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .frame(minHeight: 100)
                    .onChange(of: clientNotes) { newValue in
                        if newValue.count > maxLength {
                            clientNotes = String(newValue.prefix(maxLength))
                        }
                    }
            }
            .frame(minHeight: 100)

            HStack {
                Spacer()
                Text("\(clientNotes.count)/\(maxLength)")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(MakeABookingBrand.onSurfaceVar)
            }
        }
    }
}
