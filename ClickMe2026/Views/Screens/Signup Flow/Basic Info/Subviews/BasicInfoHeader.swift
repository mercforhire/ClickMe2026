//
//  BasicInfoHeader.swift
//  ClickMe2026
//

import SwiftUI

struct BasicInfoHeader: View {
    var body: some View {
        Text("Tell us a bit about yourself.")
            .font(.brand(.subheadline, weight: .regular))
            .foregroundColor(BasicInfoBrand.onSurfaceVar)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
