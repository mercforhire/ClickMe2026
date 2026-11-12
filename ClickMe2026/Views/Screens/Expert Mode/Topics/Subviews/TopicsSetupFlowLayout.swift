//
//  TopicsSetupFlowLayout.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Left-to-right flow layout that wraps onto a new row when the next subview
/// does not fit. Shared by expert topic setup, Favorites cards and the search
/// result tag pills.
///
/// A subview is measured at its ideal size (`.unspecified`) and placed with that
/// same proposal. Only a subview whose ideal width is wider than the row is
/// proposed the row width instead (EXPL-04), so a long pill wraps its own text
/// inside the pill rather than overflowing. Subviews that fit are measured and
/// placed exactly as before.
struct TopicsSetupFlowLayout: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let sizes = subviews.map { subview -> CGSize in
            let ideal = subview.sizeThatFits(.unspecified)
            let rowProposal = Self.proposal(forIdealWidth: ideal.width, maxWidth: maxWidth)
            return rowProposal.width == nil ? ideal : subview.sizeThatFits(rowProposal)
        }
        let frames = Self.frames(for: sizes, maxWidth: maxWidth, horizontalSpacing: horizontalSpacing, verticalSpacing: verticalSpacing)
        return Self.fittingSize(of: frames)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let maxWidth = bounds.width
        var proposals: [ProposedViewSize] = []
        var sizes: [CGSize] = []
        for subview in subviews {
            let ideal = subview.sizeThatFits(.unspecified)
            let rowProposal = Self.proposal(forIdealWidth: ideal.width, maxWidth: maxWidth)
            proposals.append(rowProposal)
            sizes.append(rowProposal.width == nil ? ideal : subview.sizeThatFits(rowProposal))
        }
        let frames = Self.frames(for: sizes, maxWidth: maxWidth, horizontalSpacing: horizontalSpacing, verticalSpacing: verticalSpacing)
        for (index, subview) in subviews.enumerated() {
            let origin = CGPoint(x: bounds.minX + frames[index].minX, y: bounds.minY + frames[index].minY)
            subview.place(at: origin, anchor: .topLeading, proposal: proposals[index])
        }
    }

    // MARK: - Pure helpers

    /// The proposal for a subview whose ideal (single-line) width is `idealWidth`.
    ///
    /// - Parameters:
    ///   - idealWidth: The subview's width when proposed `.unspecified`.
    ///   - maxWidth: The row width. `.infinity` when the parent proposed no width.
    /// - Returns: `.unspecified` when the subview fits or the row has no finite
    ///   width, so it is measured and placed as before; otherwise the row width,
    ///   so the subview wraps inside it.
    static func proposal(forIdealWidth idealWidth: CGFloat, maxWidth: CGFloat) -> ProposedViewSize {
        guard maxWidth.isFinite, idealWidth > maxWidth else { return .unspecified }
        return ProposedViewSize(width: maxWidth, height: nil)
    }

    /// Where each subview goes, relative to (0, 0).
    ///
    /// A subview starts a new row when it would pass `maxWidth` and is not the
    /// first on its row, so a subview wider than the row sits alone at the start
    /// of its row and never leaves an empty row behind. A row is as tall as its
    /// tallest subview, and rows are `verticalSpacing` apart.
    ///
    /// - Parameters:
    ///   - sizes: The measured size of each subview, in order.
    ///   - maxWidth: The row width.
    ///   - horizontalSpacing: Gap between subviews on a row.
    ///   - verticalSpacing: Gap between rows.
    static func frames(for sizes: [CGSize], maxWidth: CGFloat, horizontalSpacing: CGFloat, verticalSpacing: CGFloat) -> [CGRect] {
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for size in sizes {
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
        return frames
    }

    /// The size that holds every frame: the largest right and bottom edge, or
    /// zero when there are none.
    static func fittingSize(of frames: [CGRect]) -> CGSize {
        CGSize(
            width: frames.map(\.maxX).max() ?? 0,
            height: frames.map(\.maxY).max() ?? 0
        )
    }
}
