//
//  UpdatePasswordRequest.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Body for `PATCH /user/password`.
///
/// The confirm field is client-side only and is intentionally omitted here —
/// the server enforces "≥8 chars + must include a number" plus "must differ
/// from current password" against `new_password` alone.
struct UpdatePasswordRequest: Encodable {
    let currentPassword: String
    let newPassword: String
}
