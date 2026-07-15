//
//  PasswordStrengthMeter.swift
//  ClickMe2026
//

import SwiftUI

/// 3-segment strength bar with a "Strength: <label>" caption.
struct PasswordStrengthMeter: View {
    let strength: PasswordStrength

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(1 ... 3, id: \.self) { segment in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(segmentColor(for: segment))
                        .frame(height: 5)
                        .animation(.easeInOut(duration: 0.3), value: strength)
                }
            }

            HStack(spacing: 4) {
                Text("Strength:")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.45))
                Text(strength.label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(strength.color)
                    .animation(.easeInOut(duration: 0.2), value: strength)
            }
        }
    }

    private func segmentColor(for segment: Int) -> Color {
        switch strength {
        case .empty: return Color.white.opacity(0.15)
        case .weak: return segment == 1 ? PasswordStrength.weak.color : Color.white.opacity(0.15)
        case .fair: return segment <= 2 ? PasswordStrength.fair.color : Color.white.opacity(0.15)
        case .strong: return PasswordStrength.strong.color
        }
    }
}
