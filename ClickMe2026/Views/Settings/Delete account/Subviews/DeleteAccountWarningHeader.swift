//
//  DeleteAccountWarningHeader.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - "Are you sure..." warning headline + body

struct DeleteAccountWarningHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Are you sure you want to\ndelete your account?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(DeleteAccountBrand.onSurface)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("Deleting your account is permanent and cannot be undone. All your data, including bookings, profile information, and payment details, will be permanently removed.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(DeleteAccountBrand.onSurfaceVar)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
