//
//  Bundle+Fixtures.swift
//  ClickMe2026Tests
//
//  Loads JSON fixtures bundled with the test target.
//

import Foundation

extension Bundle {

    /// Bundle for the currently-executing test target. Prefer this over
    /// `Bundle.main` when loading test resources.
    static var tests: Bundle {
        Bundle(for: TestBundleAnchor.self)
    }

    /// Loads a JSON fixture from `Fixtures/<subdirectory>/<name>.json`.
    func jsonData(named name: String, subdirectory: String? = nil) -> Data {
        let candidate = subdirectory.map { "Fixtures/\($0)" } ?? "Fixtures"
        guard let url = self.url(forResource: name, withExtension: "json", subdirectory: candidate)
              ?? self.url(forResource: name, withExtension: "json")
        else {
            fatalError("Missing fixture: \(candidate)/\(name).json")
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            fatalError("Failed to read fixture \(name).json: \(error)")
        }
    }
}

/// Anchor class used only to locate the test target bundle.
private final class TestBundleAnchor {}
