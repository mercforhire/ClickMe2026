//
//  ClientTransactionsData.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Response payload for `GET /client/transactions` — the client-side
/// payment history ledger.
///
/// Newest-first (server orders `created_at DESC, id DESC` per spec §2).
/// Scoping is entirely by the caller's JWT — any client-supplied
/// `client_id` is silently ignored. Empty list (`transactions: []` with
/// `total_count: 0`) is a normal, non-error response for a client who's
/// never paid for a session.
struct ClientTransactionsData: Decodable {
    let transactions: [ClientTransactionItem]
    let pagination: PaginationMeta
}
