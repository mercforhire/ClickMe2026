//
//  HomeNavigationPathTests.swift
//  ClickMe2026Tests
//
//  BOOK-12 / BOOK-16: a confirmed cancel opened from a HomeRoute pops two
//  levels, and a pop that asks for more than the stack holds must stop at the
//  tab root instead of crashing.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Home navigation path")
struct HomeNavigationPathTests {

    private func path(holding count: Int) -> HomeNavigationPath {
        let nav = HomeNavigationPath()
        for value in 0..<count { nav.push(value) }
        return nav
    }

    @Test("pop(2) on three entries leaves one")
    func popTwoOfThree() {
        let nav = path(holding: 3)
        nav.pop(2)
        #expect(nav.path.count == 1)
    }

    @Test("pop(5) on one entry empties the path without crashing")
    func popPastRoot() {
        let nav = path(holding: 1)
        nav.pop(5)
        #expect(nav.path.isEmpty)
    }

    @Test("pop(0) leaves the path unchanged")
    func popZero() {
        let nav = path(holding: 2)
        nav.pop(0)
        #expect(nav.path.count == 2)
    }

    @Test("pop(1) on an empty path is a no-op")
    func popEmpty() {
        let nav = path(holding: 0)
        nav.pop(1)
        #expect(nav.path.isEmpty)
    }
}
