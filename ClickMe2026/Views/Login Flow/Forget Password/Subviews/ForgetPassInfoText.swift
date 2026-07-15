//
//  ForgetPassInfoText.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-13.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ForgetPassInfoText: View {
    var body: some View {
        Text(
            "The reset link will be sent to the email associated with your account. " +
                "Check your inbox and follow the instructions to reset your password."
        )
        .font(.system(size: 14, weight: .regular, design: .rounded))
        .foregroundColor(Color.white.opacity(0.40))
        .multilineTextAlignment(.center)
        .lineSpacing(4)
    }
}
