//
//  NotificationToggleRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Single setting row with title/subtitle + green toggle

struct NotificationToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(NotificationSettingsBrand.onSurface)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(NotificationSettingsBrand.onSurfaceVar)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(NotificationSettingsBrand.brandGreen)
                .scaleEffect(CGSize(width: 0.85, height: 0.85))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
