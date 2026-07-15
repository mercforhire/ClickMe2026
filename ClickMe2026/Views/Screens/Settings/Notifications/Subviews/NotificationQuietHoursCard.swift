//
//  NotificationQuietHoursCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Quiet Hours card — enable toggle + start/end pickers

struct NotificationQuietHoursCard: View {
    @Binding var isEnabled: Bool
    let startValue: String
    let endValue: String
    let onTapStart: () -> Void
    let onTapEnd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            NotificationCardTitle("Quiet Hours")

            VStack(spacing: 0) {
                NotificationToggleRow(
                    title: "Enable Quiet Hours",
                    subtitle: "",
                    isOn: $isEnabled
                )

                Divider().background(NotificationSettingsBrand.rowDivider)

                NotificationTimePickerRow(
                    title: "Start Time",
                    subtitle: "Start Time on the start time",
                    value: startValue,
                    isEnabled: isEnabled,
                    onTap: onTapStart
                )

                Divider().background(NotificationSettingsBrand.rowDivider)

                NotificationTimePickerRow(
                    title: "End Time",
                    subtitle: "End Time on the end time",
                    value: endValue,
                    isEnabled: isEnabled,
                    onTap: onTapEnd
                )
            }
            .background(NotificationRowGroupBackground())
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
        }
        .background(NotificationGlassCard())
    }
}
