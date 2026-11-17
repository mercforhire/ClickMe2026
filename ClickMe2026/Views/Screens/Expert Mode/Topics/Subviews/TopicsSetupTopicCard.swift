//
//  TopicsSetupTopicCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

struct TopicsSetupTopicCard: View {
    let topic: ExpertTopicItem
    @ObservedObject var viewModel: TopicsSetupViewModel

    /// Suffix the server's own label carries (`CA$50 / session`), kept so the
    /// card reads as before apart from the cents.
    static let perSessionSuffix = " / session"

    /// Symbol the card shows before the digits. USD keeps `US$`, what the card
    /// showed through the server label and what the editor's `currencySymbol`
    /// shows, until the open todo `2026-11-16-usd-symbol-us-dollar-prefix.md`
    /// decides how USD renders; this rule, and the `US$` rows in
    /// `TopicsSetupTopicCardLabelTests`, change with that decision. Every other
    /// code takes the `Money` prefix, so CAD stays `CA$`.
    static func cardSymbol(for currency: String) -> String {
        currency == "USD" ? "US$" : Money.prefix(for: currency)
    }

    /// Per-session price display (the amount the client pays per booking).
    /// The server label trims cents (`formatPrice.js`), so the card formats the
    /// stored minor amount itself: the digits come from `Money` (BOOK-10), full
    /// minor digits, in the currency the Topic Editor opens the topic in (its
    /// own valid currency, plan 06-11, else the editor's account default), so
    /// card and editor agree. Keeps the ` / session` suffix, reads `Free` for a
    /// free topic, and uses the server label only when no usable amount
    /// exists (missing or negative). The wire key `hourly_rate` is per-session
    /// too; see project memory `topic_price_semantics.md` (G-06-1-card-cents).
    static func priceLabel(for topic: ExpertTopicItem, defaultCurrency: String) -> String {
        if topic.price.isFree { return "Free" }
        guard let amount = topic.hourlyRate?.amount ?? topic.price.amount, amount >= 0 else {
            return topic.price.label ?? ""
        }
        let currency = TopicEditorViewModel.resolveInitialCurrency(topic: topic, defaultCurrency: defaultCurrency)
        let formatted = Money.format(minorUnits: amount, currency: currency)
        let digits = String(formatted.dropFirst(Money.prefix(for: currency).count))
        return cardSymbol(for: currency) + digits + perSessionSuffix
    }

    private var priceLabel: String {
        Self.priceLabel(
            for: topic,
            defaultCurrency: TopicEditorViewModel.newTopicDefaultCurrency(in: UserManager.shared.me)
        )
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
                        .font(.body.weight(.semibold))
                        .foregroundColor(Brand.primary)
                }
                Spacer()
                Menu {
                    Button("Edit") { viewModel.editTopic(topic) }
                    Button("Delete", role: .destructive) {
                        viewModel.requestDelete(topic)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.callout.weight(.semibold))
                        .foregroundColor(Brand.onSurfaceVariant)
                        .frame(width: 32, height: 32)
                }
            }

            // Topic + rate
            HStack(alignment: .top) {
                Text(topic.title)
                    .font(.callout.weight(.semibold))
                    .foregroundColor(Brand.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Per Session")
                        .font(.caption.weight(.medium))
                        .foregroundColor(Brand.onSurfaceVariant)
                    Text(priceLabel)
                        .font(.title2.weight(.bold))
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
