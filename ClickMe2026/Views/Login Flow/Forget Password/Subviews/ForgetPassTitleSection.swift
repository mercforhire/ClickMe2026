//
//  ForgetPassTitleSection.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-13.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ForgetPassTitleSection: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Reset Password")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("Enter your email to receive a\npassword reset link.")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(Color.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }
}
