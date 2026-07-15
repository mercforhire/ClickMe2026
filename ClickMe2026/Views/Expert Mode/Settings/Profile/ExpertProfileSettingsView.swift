//
//  ExpertProfileSettingsView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct ExpertiseTagChip: Identifiable {
    let id = UUID()
    var name: String
}

struct HourlyRateItem: Identifiable {
    let id = UUID()
    var topic: String
    var rate: Int
}

struct AvailabilitySlot: Identifiable {
    let id = UUID()
    let day: String
    var columns: [Bool] // Mon,Tue,Wed,Thu,Fri checkboxes
    var timeRange: String
}

// MARK: - Expert Profile Management View

struct ExpertProfileSettingsView: View {
    @State private var viewModel: ExpertProfileSettingsViewModel

    init(viewModel: ExpertProfileSettingsViewModel = ExpertProfileSettingsViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            ExpertProfileSettingsTheme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Text("Expert Settings")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(ExpertProfileSettingsTheme.onSurface)
                        .padding(.top, 52)
                        .padding(.bottom, 20)

                    ExpertProfileSettingsAvatar(viewModel: viewModel)
                        .padding(.bottom, 28)

                    ExpertProfileSettingsBasicInfo(viewModel: viewModel)
                        .padding(.horizontal, 20).padding(.bottom, 24)

                    ExpertProfileSettingsExpertise(viewModel: viewModel)
                        .padding(.horizontal, 20).padding(.bottom, 24)

                    ExpertProfileSettingsRates(viewModel: viewModel)
                        .padding(.horizontal, 20).padding(.bottom, 24)

                    ExpertProfileSettingsAvailability(viewModel: viewModel)
                        .padding(.horizontal, 20).padding(.bottom, 24)

                    ExpertProfileSettingsAdditionalInfo(viewModel: viewModel)
                        .padding(.horizontal, 20).padding(.bottom, 28)

                    ExpertProfileSettingsSaveButton(viewModel: viewModel)
                        .padding(.horizontal, 20).padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Expert Profile") {
    NavigationStack {
        ExpertProfileSettingsView()
    }
    .preferredColorScheme(.dark)
}
