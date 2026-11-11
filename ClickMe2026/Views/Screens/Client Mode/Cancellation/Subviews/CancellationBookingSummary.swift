//
//  CancellationBookingSummary.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Mini booking summary card (inside confirmation step)

struct CancellationBookingSummary: View {
    let booking: CancellationBooking

    var body: some View {
        VStack(spacing: 0) {
            expertRow

            Rectangle()
                .fill(CancellationBrand.outlineVar.opacity(0.40))
                .frame(height: 1)
                .padding(.vertical, 14)

            dateRefundRows
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(CancellationBrand.innerBg)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(CancellationBrand.innerBorder, lineWidth: 1))
        )
    }

    private var expertRow: some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: booking.imageURL)) { phase in
                switch phase {
                case let .success(img): img.resizable().scaledToFill()
                default:
                    ZStack {
                        Color(red: 0.12, green: 0.18, blue: 0.14)
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(Circle())
            .overlay(Circle().stroke(CancellationBrand.brandGreen.opacity(0.50), lineWidth: 1.5)
                .shadow(color: CancellationBrand.brandGreen.opacity(0.35), radius: 4))

            VStack(alignment: .leading, spacing: 4) {
                Text(booking.expertName)
                    .font(.brand(.body, weight: .bold))
                    .foregroundColor(CancellationBrand.onSurface)
                Text(booking.expertTitle)
                    .font(.brand(.caption, weight: .semibold))
                    .foregroundColor(CancellationBrand.brandGreen)
            }
            Spacer()
        }
    }

    private var dateRefundRows: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.subheadline)
                    .foregroundColor(CancellationBrand.onSurfaceVar)
                    .frame(width: 18)
                Text(booking.dateString)
                    .font(.brand(.subheadline, weight: .regular))
                    .foregroundColor(CancellationBrand.onSurface)
            }

            if let refundCase = booking.refundCase {
                moneyLine(for: refundCase)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Money line

    @ViewBuilder
    private func moneyLine(for refundCase: CancelRefundPreview.Case) -> some View {
        if case let .chargedNotRefundable(zero) = refundCase {
            warningBlock(zero: zero, sentence: CancelRefundPreview.text(for: refundCase) ?? "")
        } else if let sentence = CancelRefundPreview.text(for: refundCase) {
            HStack(alignment: .top, spacing: 10) {
                if let icon = CancelRefundPreview.iconName(for: refundCase) {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundColor(CancellationBrand.onSurfaceVar)
                        .frame(width: 18)
                }
                emphasizedText(
                    sentence,
                    emphasis: CancelRefundPreview.emphasis(for: refundCase)
                )
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// The sentence with the amount set semibold in `onSurface`, never accent.
    private func emphasizedText(_ sentence: String, emphasis: String?) -> Text {
        let regular = Font.brand(.subheadline, weight: .regular)
        let semibold = Font.brand(.subheadline, weight: .semibold)
        guard let emphasis, let range = sentence.range(of: emphasis) else {
            return Text(sentence).font(regular).foregroundColor(CancellationBrand.onSurface)
        }
        let head = String(sentence[..<range.lowerBound])
        let tail = String(sentence[range.upperBound...])
        return Text(head).font(regular).foregroundColor(CancellationBrand.onSurface)
            + Text(emphasis).font(semibold).foregroundColor(CancellationBrand.onSurface)
            + Text(tail).font(regular).foregroundColor(CancellationBrand.onSurface)
    }

    /// Case D (D-05): a charged booking inside 24 hours gets nothing back.
    /// The block is one accessibility element read as the full sentence.
    private func warningBlock(zero: String, sentence: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundColor(Color.orange)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 4) {
                Text("Refund: \(zero)")
                    .font(.brand(.callout, weight: .semibold))
                    .foregroundColor(CancellationBrand.onSurface)
                Text(CancelRefundPreview.withinWindowDetail)
                    .font(.brand(.subheadline, weight: .regular))
                    .foregroundColor(CancellationBrand.onSurfaceVar)
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.orange.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.orange.opacity(0.45), lineWidth: 1))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sentence)
    }
}
