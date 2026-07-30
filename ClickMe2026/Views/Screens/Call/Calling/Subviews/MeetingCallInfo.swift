//
//  MeetingCallInfo.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Peer name + topic + scheduled range + elapsed timer + status label

struct MeetingCallInfo: View {
    let expertName: String
    let topic: String
    let scheduledRangeLabel: String?
    let timerString: String
    let statusLabel: String
    /// Time-remaining chip, e.g. `"5:00 left"`. Nil when we're not
    /// inside the final-stretch window; view hides the chip.
    let remainingLabel: String?
    /// Tints the timer + surfaces a scheduled-end context. Amber
    /// during the last 5 min and after scheduled end so the user
    /// notices without being alarmed.
    let isNearOrPastEnd: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text(expertName)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(MeetingCallBrand.onSurface)

            if !topic.isEmpty {
                Text(topic)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(MeetingCallBrand.onSurfaceVar)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let scheduledRangeLabel {
                Text(scheduledRangeLabel)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(MeetingCallBrand.onSurfaceVar.opacity(0.75))
            }

            Text(timerString)
                .font(.system(size: 22, weight: .regular, design: .monospaced))
                .foregroundColor(isNearOrPastEnd ? .orange : MeetingCallBrand.onSurfaceVar)
                .padding(.top, 4)

            if let remainingLabel {
                Text(remainingLabel)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.12))
                            .overlay(Capsule().stroke(Color.orange.opacity(0.45), lineWidth: 1))
                    )
            }

            Text(statusLabel)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(MeetingCallBrand.onSurfaceVar)
        }
    }
}
