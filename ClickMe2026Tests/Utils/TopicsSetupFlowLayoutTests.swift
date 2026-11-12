//
//  TopicsSetupFlowLayoutTests.swift
//  ClickMe2026Tests
//
//  EXPL-04: search tag pills wrap inside `TopicsSetupFlowLayout`. The layout is
//  shared with Favorites cards and expert topic setup, so subviews that fit
//  must be placed exactly as they were before the change. The line-breaking
//  math lives in pure static helpers so both rules can be checked without a
//  SwiftUI host.
//

import CoreGraphics
import SwiftUI
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Topics setup flow layout")
struct TopicsSetupFlowLayoutTests {

    private typealias Flow = TopicsSetupFlowLayout

    // MARK: - HEAD reference

    /// The two loops of `TopicsSetupFlowLayout` as they were before EXPL-04
    /// (`sizeThatFits` and `placeSubviews`), run over plain sizes with every
    /// subview measured at its ideal size. Copied from the file as read before
    /// editing, so the comparison rows fail if the line-breaking rule drifts.
    private func headLayout(
        _ sizes: [CGSize],
        maxWidth: CGFloat,
        horizontalSpacing: CGFloat,
        verticalSpacing: CGFloat
    ) -> (size: CGSize, origins: [CGPoint]) {
        // sizeThatFits
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        for size in sizes {
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x + size.width)
            x += size.width + horizontalSpacing
        }
        let fitted = CGSize(width: totalWidth, height: y + rowHeight)

        // placeSubviews, with bounds at the origin
        let bounds = CGRect(x: 0, y: 0, width: maxWidth, height: fitted.height)
        var px = bounds.minX
        var py = bounds.minY
        var placedRowHeight: CGFloat = 0
        var origins: [CGPoint] = []
        for size in sizes {
            if px + size.width > bounds.maxX && px > bounds.minX {
                px = bounds.minX
                py += placedRowHeight + verticalSpacing
                placedRowHeight = 0
            }
            origins.append(CGPoint(x: px, y: py))
            px += size.width + horizontalSpacing
            placedRowHeight = max(placedRowHeight, size.height)
        }
        return (fitted, origins)
    }

    // MARK: - Fixed rows

    @Test("three 50 by 20 subviews share one row")
    func threeFitOnOneRow() {
        let sizes = [CGSize(width: 50, height: 20), CGSize(width: 50, height: 20), CGSize(width: 50, height: 20)]

        let frames = Flow.frames(for: sizes, maxWidth: 200, horizontalSpacing: 8, verticalSpacing: 4)

        #expect(frames.map(\.origin) == [CGPoint(x: 0, y: 0), CGPoint(x: 58, y: 0), CGPoint(x: 116, y: 0)])
        #expect(Flow.fittingSize(of: frames) == CGSize(width: 166, height: 20))
    }

    @Test("a subview that does not fit starts a new row below the tallest one")
    func overflowStartsNewRow() {
        let sizes = [CGSize(width: 120, height: 20), CGSize(width: 100, height: 30)]

        let frames = Flow.frames(for: sizes, maxWidth: 200, horizontalSpacing: 8, verticalSpacing: 4)

        #expect(frames.map(\.origin) == [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 24)])
        #expect(Flow.fittingSize(of: frames) == CGSize(width: 120, height: 54))
    }

    @Test("a single subview wider than the row stays at the origin with no empty first row")
    func singleWideSubview() {
        let frames = Flow.frames(
            for: [CGSize(width: 250, height: 40)],
            maxWidth: 200,
            horizontalSpacing: 8,
            verticalSpacing: 4
        )

        #expect(frames == [CGRect(x: 0, y: 0, width: 250, height: 40)])
    }

    @Test("after a full-width subview the next one starts a new row")
    func afterFullWidthSubview() {
        let sizes = [CGSize(width: 60, height: 20), CGSize(width: 200, height: 40), CGSize(width: 60, height: 20)]

        let frames = Flow.frames(for: sizes, maxWidth: 200, horizontalSpacing: 8, verticalSpacing: 4)

        #expect(frames.map(\.origin) == [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 24), CGPoint(x: 0, y: 68)])
        #expect(Flow.fittingSize(of: frames) == CGSize(width: 200, height: 88))
    }

    @Test("no subviews give no frames and a zero size")
    func emptyLayout() {
        let frames = Flow.frames(for: [], maxWidth: 200, horizontalSpacing: 8, verticalSpacing: 4)

        #expect(frames.isEmpty)
        #expect(Flow.fittingSize(of: []) == .zero)
    }

    // MARK: - Fitting subviews are unchanged

    nonisolated private static let fittingLists: [[CGSize]] = [
        [CGSize(width: 50, height: 20)],
        [CGSize(width: 90, height: 28), CGSize(width: 110, height: 28), CGSize(width: 70, height: 28)],
        [CGSize(width: 150, height: 30), CGSize(width: 150, height: 24), CGSize(width: 80, height: 40), CGSize(width: 60, height: 20)],
        [CGSize(width: 320, height: 32), CGSize(width: 12, height: 32), CGSize(width: 300, height: 18)],
        [
            CGSize(width: 64, height: 26), CGSize(width: 88, height: 26), CGSize(width: 101, height: 30),
            CGSize(width: 73, height: 26), CGSize(width: 140, height: 26), CGSize(width: 52, height: 22),
            CGSize(width: 99, height: 26),
        ],
    ]

    @Test(
        "subviews that all fit get the same frames and size as the layout had before",
        arguments: fittingLists, [CGSize(width: 8, height: 4), CGSize(width: 8, height: 8)]
    )
    func fittingSubviewsMatchHead(sizes: [CGSize], spacing: CGSize) {
        let maxWidth: CGFloat = 320
        // Every subview's ideal width fits, so every proposal is `.unspecified`.
        for size in sizes {
            let proposal = Flow.proposal(forIdealWidth: size.width, maxWidth: maxWidth)
            #expect(proposal.width == nil && proposal.height == nil)
        }

        let head = headLayout(sizes, maxWidth: maxWidth, horizontalSpacing: spacing.width, verticalSpacing: spacing.height)
        let frames = Flow.frames(
            for: sizes,
            maxWidth: maxWidth,
            horizontalSpacing: spacing.width,
            verticalSpacing: spacing.height
        )

        #expect(frames.map(\.origin) == head.origins)
        #expect(frames.map(\.size) == sizes)
        #expect(Flow.fittingSize(of: frames) == head.size)
    }

    // MARK: - Overflowing subviews wrap

    @Test("a subview wider than the row is proposed the row width; one that fits is not")
    func proposalForIdealWidth() {
        let fits = Flow.proposal(forIdealWidth: 150, maxWidth: 200)
        #expect(fits.width == nil && fits.height == nil)

        let exact = Flow.proposal(forIdealWidth: 200, maxWidth: 200)
        #expect(exact.width == nil && exact.height == nil)

        let wide = Flow.proposal(forIdealWidth: 250, maxWidth: 200)
        #expect(wide.width == 200)
        #expect(wide.height == nil)

        let unbounded = Flow.proposal(forIdealWidth: 250, maxWidth: .infinity)
        #expect(unbounded.width == nil && unbounded.height == nil)
    }

    @Test("an overflowing pill re-measured at the row width starts its own row")
    func overflowingPillWrapsInsideItsPill() {
        // The long pill's ideal width is 400; at the 200 pt row width its text
        // wraps to 200 by 60. The short pill before it keeps its own row.
        let rowWidth: CGFloat = 200
        let shortPill = CGSize(width: 40, height: 20)
        let longPillIdeal = CGSize(width: 400, height: 20)
        let proposal = Flow.proposal(forIdealWidth: longPillIdeal.width, maxWidth: rowWidth)
        let longPillWrapped = CGSize(width: proposal.width ?? longPillIdeal.width, height: 60)

        let frames = Flow.frames(
            for: [shortPill, longPillWrapped],
            maxWidth: rowWidth,
            horizontalSpacing: 8,
            verticalSpacing: 4
        )

        #expect(longPillWrapped.width == rowWidth)
        #expect(frames[1].origin == CGPoint(x: 0, y: 24))
        #expect(Flow.fittingSize(of: frames) == CGSize(width: rowWidth, height: 84))
    }
}
