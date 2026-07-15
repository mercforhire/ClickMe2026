//
//  CategoryIconMap.swift
//  ClickMe2026
//
//  Maps `GET /categories` slug IDs (e.g. "ai", "real-estate") to SF Symbol
//  names for the client-side UI. The backend returns Lucide icon names, but
//  the app currently renders via `Image(systemName:)`, so we don't consume
//  the server's `icon_name` field.
//
//  When a slug isn't in the table (e.g. the backend adds a new category
//  before we ship a fresh mapping), the fallback icon is used.
//

import Foundation

enum CategoryIconMap {

    /// Fallback SF Symbol for unknown category slugs. Chosen to read as a
    /// generic taxonomy tile so an unknown row still looks intentional.
    static let fallbackSymbol = "square.grid.2x2"

    /// Returns an SF Symbol name for the given category slug.
    static func sfSymbol(forSlug slug: String) -> String {
        table[slug.lowercased()] ?? fallbackSymbol
    }

    private static let table: [String: String] = [
        "ai":             "cpu",
        "business":       "briefcase",
        "consulting":     "lightbulb",
        "career":         "person.badge.plus",
        "coaching":       "person.wave.2",
        "design":         "pencil.and.ruler",
        "education":      "book",
        "engineering":    "gearshape",
        "finance":        "chart.line.uptrend.xyaxis",
        "fitness":        "figure.walk",
        "food":           "fork.knife",
        "gaming":         "gamecontroller",
        "healthcare":     "stethoscope",
        "health":         "stethoscope",
        "language":       "character.book.closed",
        "languages":      "character.book.closed",
        "legal":          "scalemass",
        "marketing":      "megaphone.fill",
        "music":          "music.note",
        "photography":    "camera",
        "productivity":   "speedometer",
        "psychology":     "brain",
        "real-estate":    "house",
        "science":        "atom",
        "sports":         "sportscourt",
        "startup":        "sparkles",
        "tech":           "chevron.left.forwardslash.chevron.right",
        "technology":     "chevron.left.forwardslash.chevron.right",
        "travel":         "airplane",
        "wellness":       "heart.text.square",
        "writing":        "pencil"
    ]
}
