//
//  PaginationMeta.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Pagination envelope returned by paginated list endpoints. Different
/// endpoints include different subsets of fields — `/client/bookings` puts
/// `total_count` inside pagination and omits `has_more`, while other
/// endpoints do the opposite. Everything except `currentPage` /
/// `totalPages` is optional so this DTO decodes across all shapes.
struct PaginationMeta: Decodable {
    let currentPage: Int
    let totalPages: Int
    let totalCount: Int?
    let hasMore: Bool?

    /// Prefer the server-provided flag when present; otherwise derive from
    /// page counts. Safe fallback for endpoints that omit `has_more`.
    var hasMoreOrDerived: Bool {
        hasMore ?? (currentPage < totalPages)
    }
}
