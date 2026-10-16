//
//  RequestDecisionDetailsCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

struct RequestDecisionDetailsCard: View {
    let request: IncomingRequest

    var body: some View {
        VStack(spacing: 0) {
            detailRow(label: "Date & Time") {
                Text("\(request.date),\n\(request.timeRange)")
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(Brand.onSurface)
                    .multilineTextAlignment(.trailing)
            }
            rowDivider
            detailRow(label: "Topic") {
                Text(request.topic)
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(Brand.onSurface)
            }
            rowDivider
            detailRow(label: "Meeting Type") {
                HStack(spacing: 6) {
                    Image(systemName: request.meetingTypeIcon)
                        .font(.subheadline)
                        .foregroundColor(Brand.onSurface)
                    Text(request.meetingTypeLabel)
                        .font(.brand(.subheadline, weight: .semibold))
                        .foregroundColor(Brand.onSurface)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Brand.overlayWhite05))
    }

    private func detailRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(Brand.overlayWhite60)
            Spacer()
            content()
        }
        .padding(.vertical, 12)
    }

    private var rowDivider: some View {
        Rectangle().fill(Brand.overlayWhite10).frame(height: 1)
    }
}
