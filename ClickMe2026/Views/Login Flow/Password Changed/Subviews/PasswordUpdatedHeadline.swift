//
//  PasswordUpdatedHeadline.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-14.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Headline block

struct PasswordUpdatedHeadline: View {
    var opacity: Double
    var offset: CGFloat

    var body: some View {
        VStack(spacing: 16) {
            Text("Password\nUpdated!")
                .font(.system(size: 40, weight: .bold, design: .serif))
                .foregroundColor(PasswordUpdatedBrand.onSurface)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text("Your password has been successfully updated. You can now use your new password to log in.")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(PasswordUpdatedBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
        }
        .opacity(opacity)
        .offset(y: offset)
    }
}
