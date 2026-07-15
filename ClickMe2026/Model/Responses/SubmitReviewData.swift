//
//  SubmitReviewData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Result of review submission. Upsert-on-resubmit semantics: re-submission silently
/// overwrites and always returns 201 with status `published`.
struct SubmitReviewData: Decodable {
    let reviewId: UUID
    let status: ReviewStatus
    let message: String
}
