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

    /// Per-session price display (the amount the client pays per booking).
    /// Server sends `amount` in minor units (cents) — divide by 100 as a
    /// Double so amounts like $180.50 aren't dropped by integer division.
    /// The wire key is `hourly_rate` but the semantics are per-session; see
    /// project memory `topic_price_semantics.md`.
    private var priceLabel: String {
        guard let rate = topic.hourlyRate else { return topic.price.label ?? "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = rate.currency
        formatter.maximumFractionDigits = Double(rate.amount).truncatingRemainder(dividingBy: 100) == 0 ? 0 : 2
        let value = Double(rate.amount) / 100.0
        return formatter.string(from: NSNumber(value: value))
            ?? "\(rate.currency) \(String(format: "%.0f", value))"
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
                    Text("Per Session")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Brand.onSurfaceVariant)
                    Text(priceLabel)
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
        // Whole-card tap opens the editor. The ellipsis Menu above still
        // wins its own hit area for Delete, since SwiftUI's Menu consumes
        // taps within its own bounds before the parent gesture runs.
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture { viewModel.editTopic(topic) }
    }
}
