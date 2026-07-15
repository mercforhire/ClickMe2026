//
//  FeedbackTypeItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// A static feedback category available for submission.
struct FeedbackTypeItem: Decodable, Identifiable, Hashable {
    let id: String
    let label: String
    let description: String
}
