//
//  MessageType.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Chat message type — from the `messages.type` CHECK constraint.
/// `event` rows are system-injected booking lifecycle events.
enum MessageType: String, Decodable {
    case text
    case image
    case file
    case event
}
