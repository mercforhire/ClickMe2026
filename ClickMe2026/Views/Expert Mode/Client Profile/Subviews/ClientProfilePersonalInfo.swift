//
//  ClientProfilePersonalInfo.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - "Personal Information" section: name + email + bio fields

struct ClientProfilePersonalInfo: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var bio: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Information")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(ClientProfileBrand.onSurface)

            ClientProfileEditableField(label: "Name", text: $name, isMultiline: false)
            ClientProfileEditableField(label: "Email", text: $email, isMultiline: false, keyboard: .emailAddress)
            ClientProfileEditableField(label: "Bio", text: $bio, isMultiline: true)
        }
    }
}
