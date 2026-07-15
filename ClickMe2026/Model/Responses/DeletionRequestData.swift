//
//  DeletionRequestData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// `POST /user/account/delete-request` — single-use 15-minute deletion token
/// returned to the authenticated caller for use as Step 2 input
/// (`DELETE /user/account`). The server stores only the sha256 hash.
struct DeletionRequestData: Decodable {
    let deletionToken: String
}
