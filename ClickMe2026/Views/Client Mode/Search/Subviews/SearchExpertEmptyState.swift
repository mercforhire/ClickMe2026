//
//  SearchExpertEmptyState.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - "No experts found" empty state with Refresh + Browse All

struct SearchExpertEmptyState: View {
    let glowPulse: Bool
    let onBrowseAll: () -> Void
    @State private var isRefreshing = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            SearchExpertGlowingIllustration(glowPulse: glowPulse)

            VStack(spacing: 12) {
                Text("No Experts Found")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(SearchExpertBrand.onSurface)

                Text("We couldn't find any experts based on your current preferences. Try adjusting your interests or refreshing.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(SearchExpertBrand.onSurfaceVar)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 12) {
                refreshButton
                browseAllButton
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    private var refreshButton: some View {
        Button {
            guard !isRefreshing else { return }
            withAnimation(.easeInOut(duration: 0.2)) { isRefreshing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { isRefreshing = false }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(isRefreshing
                        ? Animation.linear(duration: 0.8).repeatForever(autoreverses: false)
                        : .default,
                        value: isRefreshing)
                Text("Refresh")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(SearchExpertBrand.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Capsule()
                    .fill(SearchExpertBrand.brandGreen)
                    .shadow(color: SearchExpertBrand.brandGreen.opacity(0.50), radius: 16, x: 0, y: 5)
            )
        }
        .buttonStyle(SearchScaleStyle())
        .disabled(isRefreshing)
    }

    private var browseAllButton: some View {
        Button(action: onBrowseAll) {
            Text("Browse All")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(SearchExpertBrand.onSurface)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    Capsule()
                        .fill(Color(red: 0.14, green: 0.18, blue: 0.15))
                        .overlay(Capsule().stroke(SearchExpertBrand.cardBorder, lineWidth: 1))
                )
        }
        .buttonStyle(SearchScaleStyle())
    }
}
