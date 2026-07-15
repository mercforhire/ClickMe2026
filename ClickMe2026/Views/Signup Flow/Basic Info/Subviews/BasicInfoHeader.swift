//
//  BasicInfoHeader.swift
//  ClickMe2026
//

import SwiftUI

struct BasicInfoHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Personal Details")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(BasicInfoBrand.onSurface)
            Text("Tell us a bit about yourself.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(BasicInfoBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
