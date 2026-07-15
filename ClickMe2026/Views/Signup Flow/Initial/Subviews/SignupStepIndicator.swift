//
//  SignupStepIndicator.swift
//  ClickMe2026
//

import SwiftUI

/// Dots-and-connectors progress indicator for multi-step signup flows.
struct SignupStepIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        VStack(spacing: 10) {
            Text("\(currentStep) of \(totalSteps)")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.45))

            HStack(spacing: 0) {
                ForEach(1 ... totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? SignupBrand.green : Color.white.opacity(0.25))
                        .frame(width: 8, height: 8)

                    if step < totalSteps {
                        Rectangle()
                            .fill(step < currentStep ? SignupBrand.green : Color.white.opacity(0.18))
                            .frame(height: 1.5)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 32)
        }
    }
}
