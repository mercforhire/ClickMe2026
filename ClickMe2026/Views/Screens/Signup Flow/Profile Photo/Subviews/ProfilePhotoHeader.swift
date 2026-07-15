//
//  ProfilePhotoHeader.swift
//  ClickMe2026
//

import SwiftUI

struct ProfilePhotoHeader: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Add a Profile Photo")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Choose a clear photo so clients can recognize you.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(Color.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}
