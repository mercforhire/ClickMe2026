//
//  BasicInfoContinueButton.swift
//  ClickMe2026
//

import SwiftUI

/// Sticky-bottom "Continue" CTA — green pill with a gradient fade above so the
/// underlying scroll content visually fades into the button area.
struct BasicInfoContinueButton: View {
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [BasicInfoBrand.bg.opacity(0), BasicInfoBrand.bg],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 28)

            Button(action: action) {
                Group {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(BasicInfoBrand.onPrimary)
                    } else {
                        Text("Continue")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(BasicInfoBrand.onPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(BasicInfoBrand.brandGreen)
                        .shadow(color: BasicInfoBrand.brandGreen.opacity(0.50), radius: 18, x: 0, y: 5)
                )
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(isLoading)
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
            .background(BasicInfoBrand.bg)
        }
    }
}
