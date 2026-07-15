//
//  NotificationTimePickerRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Tappable time-picker row for Quiet Hours

struct NotificationTimePickerRow: View {
    let title: String
    let subtitle: String
    let value: String
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(isEnabled
                                         ? NotificationSettingsBrand.onSurface
                                         : NotificationSettingsBrand.onSurfaceVar)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(NotificationSettingsBrand.onSurfaceVar.opacity(0.60))
                }
                Spacer()
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isEnabled
                                     ? NotificationSettingsBrand.brandGreen
                                     : NotificationSettingsBrand.onSurfaceVar)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
