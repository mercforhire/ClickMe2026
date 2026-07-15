//
//  ExpertiseTagItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// A single expertise tag from the seeded `expertise_tags` table.
/// `categoryId` is the stable text slug from `/categories` (e.g. `"business"`,
/// `"technology"`) — NOT a UUID. `id` is a real UUID used as the value for
/// `/experts/search?category=<uuid>`.
struct ExpertiseTagItem: Decodable, Hashable, Identifiable {
    let id: UUID
    let label: String
    let categoryId: String
}
