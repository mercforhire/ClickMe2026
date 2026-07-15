//
//  RequestDecisionDetailsCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct RequestDecisionDetailsCard: View {
    let request: IncomingRequest

    var body: some View {
        VStack(spacing: 0) {
            detailRow(label: "Date & Time") {
                Text("\(request.date),\n\(request.timeRange)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(RequestDecisionTheme.onSurface)
                    .multilineTextAlignment(.trailing)
            }
            rowDivider
            detailRow(label: "Topic") {
                Text(request.topic)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(RequestDecisionTheme.onSurface)
            }
            rowDivider
            detailRow(label: "Meeting Type") {
                HStack(spacing: 6) {
                    Image(systemName: request.isVirtual ? "video" : "person.2")
                        .font(.system(size: 14))
                        .foregroundColor(RequestDecisionTheme.onSurface)
                    Text(request.isVirtual ? "Virtual" : "Face-to-Face")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(RequestDecisionTheme.onSurface)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(RequestDecisionTheme.cardBg))
    }

    private func detailRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(RequestDecisionTheme.onSurfaceVar)
            Spacer()
            content()
        }
        .padding(.vertical, 12)
    }

    private var rowDivider: some View {
        Rectangle().fill(RequestDecisionTheme.divider).frame(height: 1)
    }
}
