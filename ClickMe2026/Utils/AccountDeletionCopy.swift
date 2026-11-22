//
//  AccountDeletionCopy.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The Delete Account disclosure (SET-06, D-08 to D-11).
///
/// Each group reflects what `accountCascade.purgeAndLockAccount` does on the backend:
/// - Deleted: F1 profile tombstone (name, photo, bio, location), F6 devices,
///   F7 notifications, F8 preferences and step I uploaded profile photos.
/// - Kept without your personal details: bookings stay, shown against the tombstoned
///   "Deleted user" profile; F3 and F4 erase the private notes on them. Unanswered
///   client requests are cancelled and their card holds voided before the purge.
/// - Kept: reviews, messages and payment records (no DML on those tables).
///
/// Saved cards: the cascade does not detach them, so they stay with the payment
/// provider. `savedCardsNote` discloses that (D-23) and never claims removal.
///
/// Plan 05-13 copies these strings word for word into the Android todo (D-11), and
/// plan 08-13 does the same for `savedCardsNote` (D-23, Android port in plan 08-17),
/// so change them here and there together.
nonisolated enum AccountDeletionCopy {
    static let permanence = "Deleting your account is permanent and can't be undone."
    static let bookingsFirst = "Before you delete, cancel or finish any upcoming sessions. Requests you've sent that haven't been answered yet are cancelled for you, and any hold on your card is released."

    static let deletedTitle = "Deleted"
    static let deletedBody = "Your name, photo, bio and location, your devices, your notifications and preferences, and your uploaded profile photos."

    static let keptAnonymizedTitle = "Kept without your personal details"
    static let keptAnonymizedBody = "Your past bookings stay on record, shown as from \"Deleted user\". Your private notes on them are erased."

    static let keptTitle = "Kept"
    static let keptBody = "Messages and reviews you've written stay visible to the other person, shown as from \"Deleted user\". Payment records are kept."

    /// Shown on the confirmation step only, after the three groups (D-23).
    static let savedCardsNote = "Cards you added to pay for sessions are not deleted with your account."
}
