//
//  MessageStatus.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Chat message delivery status. Default `sent`; `read` requires explicit signal.
enum MessageStatus: String, Decodable {
    case sent
    case delivered
    case read
}
