//
//  LanguageItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// A single language entry from the seeded `languages` table.
/// `id` is the ISO 639-1 two-letter code (`"en"`, `"es"`, `"zh"`) —
/// server-controlled short slug, not a UUID.
struct LanguageItem: Decodable, Hashable, Identifiable {
    let id: String
    let label: String
}
