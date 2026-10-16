//
//  EarningsTransactionsData.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Response payload for `GET /expert/earnings/transactions`.
///
/// Newest-first list of the caller's per-session earnings ledger
/// (`expert_earnings` rows). Scope is always the caller's own JWT
/// identity — any client-supplied `expert_id` query param is silently
/// ignored by the server.
///
/// Pagination is server-driven: caller passes `page` + `limit`
/// (1-based, max 100), server returns `pagination.hasMore` /
/// `currentPage` / `totalPages` / `totalCount`. Use the shared
/// `PaginationMeta` helper on the child.
struct EarningsTransactionsData: Decodable {
    let transactions: [EarningsTransactionItem]
    let pagination: PaginationMeta
}
