//
//  MakeABookingMeetingTypeCard.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct MakeABookingMeetingTypeCard: View {
    @Binding var meetingType: MeetingType

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MakeABookingSectionHeader(title: "Meeting Type")

            VStack(spacing: 0) {
                ForEach(Array(MeetingType.pickerCases.enumerated()), id: \.offset) { idx, type in
                    row(for: type)

                    if idx < MeetingType.pickerCases.count - 1 {
                        Divider().background(MakeABookingBrand.outlineVar).padding(.horizontal, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(MakeABookingBrand.surface)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(MakeABookingBrand.outlineVar, lineWidth: 1))
            )
        }
    }

    private func row(for type: MeetingType) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { meetingType = type }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(meetingType == type ? MakeABookingBrand.brandGreen : MakeABookingBrand.onSurfaceVar.opacity(0.40), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if meetingType == type {
                        Circle()
                            .fill(MakeABookingBrand.brandGreen)
                            .frame(width: 12, height: 12)
                    }
                }

                Text(type.displayName)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(MakeABookingBrand.onSurface)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
}
