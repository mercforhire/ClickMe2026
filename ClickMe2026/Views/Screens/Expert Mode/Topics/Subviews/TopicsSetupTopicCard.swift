//
//  TopicsSetupTopicCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct TopicsSetupTopicCard: View {
    let topic: ExpertTopicItem
    @ObservedObject var viewModel: TopicsSetupViewModel

    /// Rounded whole-dollar amount for display. Server sends `amount` in
    /// minor units (cents), so we divide by 100 to a Double so cents like
    /// $180.50 aren't dropped by integer division.
    private var rateLabel: String {
        guard let rate = topic.hourlyRate else { return topic.price.label ?? "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = rate.currency
        formatter.maximumFractionDigits = Double(rate.amount).truncatingRemainder(dividingBy: 100) == 0 ? 0 : 2
        let value = Double(rate.amount) / 100.0
        let formatted = formatter.string(from: NSNumber(value: value))
            ?? "\(rate.currency) \(String(format: "%.0f", value))"
        return "\(formatted)/hr"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header — topic icon (left) + three-dot edit/delete menu (right)
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Brand.primary.opacity(0.12))
                        .frame(width: 38, height: 38)
                    // Resolve server slug → SF Symbol via CategoryIconMap.
                    // Falls back to `sparkles` when nil or the slug isn't
                    // in the table yet.
                    Image(systemName: topic.iconSlug.map { CategoryIconMap.sfSymbol(forSlug: $0) } ?? "sparkles")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Brand.primary)
                }
                Spacer()
                Menu {
                    Button("Edit") { viewModel.editTopic(topic) }
                    Button("Delete", role: .destructive) {
                        Task { await viewModel.deleteTopic(topic) }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Brand.onSurfaceVariant)
                        .frame(width: 32, height: 32)
                }
            }

            // Topic + rate
            HStack(alignment: .top) {
                Text(topic.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Brand.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Hourly Rate")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Brand.onSurfaceVariant)
                    Text(rateLabel)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Brand.primary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Brand.surfaceContainerLow)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Brand.outlineVariant.opacity(0.5), lineWidth: 1))
        )
    }
}
