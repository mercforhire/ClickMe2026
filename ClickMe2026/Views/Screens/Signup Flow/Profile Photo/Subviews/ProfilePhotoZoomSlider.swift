//
//  ProfilePhotoZoomSlider.swift
//  ClickMe2026
//

import SwiftUI

/// Slider with tappable +/- chips for adjusting the avatar zoom.
struct ProfilePhotoZoomSlider: View {
    @Binding var zoomScale: CGFloat
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "minus")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.white.opacity(0.45))
                .onTapGesture { zoomScale = max(0, zoomScale - 0.1) }

            Slider(value: $zoomScale, in: 0 ... 1)
                .tint(ProfilePhotoBrand.green)
                .disabled(!isEnabled)
                .opacity(isEnabled ? 1 : 0.35)

            Image(systemName: "plus")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.white.opacity(0.45))
                .onTapGesture { zoomScale = min(1, zoomScale + 0.1) }
        }
    }
}
