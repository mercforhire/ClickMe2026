//
//  UserLanguageEntity.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

struct UserLanguageEntity: Codable {
    let id: UUID
    let userId: UUID
    let languageId: String?
    let customLabel: String?
}
