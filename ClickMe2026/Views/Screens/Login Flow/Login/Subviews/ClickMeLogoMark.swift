//
//  ClickMeLogoMark.swift
//  ClickMe2026
//

import SwiftUI

struct ClickMeLogoMark: View {
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.20, green: 0.85, blue: 0.45).opacity(0.30),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: size * 0.10)

            Image("SplashLogo")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }
}
