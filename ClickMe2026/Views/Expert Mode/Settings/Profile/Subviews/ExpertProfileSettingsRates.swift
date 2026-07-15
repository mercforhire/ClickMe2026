//
//  ExpertProfileSettingsRates.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ExpertProfileSettingsRates: View {
    @Bindable var viewModel: ExpertProfileSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hourly Rates")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(ExpertProfileSettingsTheme.onSurface)

            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(viewModel.rates) { rate in
                    rateCard(rate)
                }
                freeConsultationCard
            }
        }
    }

    private func rateCard(_ rate: HourlyRateItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(rate.topic)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ExpertProfileSettingsTheme.onSurface)
                .lineLimit(2)
            Text("($\(rate.rate)/hr)")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(ExpertProfileSettingsTheme.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ExpertProfileSettingsTheme.tagBg)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(ExpertProfileSettingsTheme.tagBorder, lineWidth: 1))
        )
    }

    private var freeConsultationCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Free")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(ExpertProfileSettingsTheme.onSurface)
                Text("Consultation")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(ExpertProfileSettingsTheme.onSurface)
            }
            Spacer()
            Toggle("", isOn: $viewModel.freeConsultation)
                .labelsHidden()
                .tint(ExpertProfileSettingsTheme.brandGreen)
                .scaleEffect(0.85)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ExpertProfileSettingsTheme.tagBg)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(ExpertProfileSettingsTheme.tagBorder, lineWidth: 1))
        )
    }
}
