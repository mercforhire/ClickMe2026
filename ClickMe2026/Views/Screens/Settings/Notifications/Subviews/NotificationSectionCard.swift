//
//  NotificationSectionCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Outer glass card containing a group of toggle rows

struct NotificationSectionCard: View {
    let title: String
    @Binding var settings: [NotificationSetting]

    var body: some View {
        VStack(spacing: 0) {
            NotificationCardTitle(title)

            VStack(spacing: 0) {
                ForEach(settings.indices, id: \.self) { ri in
                    NotificationToggleRow(
                        title: settings[ri].title,
                        subtitle: settings[ri].subtitle,
                        isOn: $settings[ri].isOn
                    )
                    if ri < settings.count - 1 {
                        Divider().background(NotificationSettingsBrand.rowDivider)
                    }
                }
            }
            .background(NotificationRowGroupBackground())
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
        .background(NotificationGlassCard())
    }
}
