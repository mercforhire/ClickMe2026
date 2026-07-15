//
//  SignupAccumulator.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import Observation

/// Shared state model owned by the signup orchestrator (currently
/// `LoginView`). Each signup step reads/writes fields on this instance
/// instead of firing callbacks up to the parent — cleaner than
/// initializer-chaining slices of payload from screen to screen.
///
/// The final `SignupReviewView` calls `buildSetupExpertProfileRequest()`
/// and POSTs the result to `PATCH /expert/profile/setup`.
///
/// TODO: persist to `UserDefaults` on every mutation so a mid-signup
/// app close doesn't wipe progress. Deferred until MVP feedback confirms
/// that's a real user-facing problem.
@Observable
@MainActor
final class SignupAccumulator {

    // MARK: Initial (account creation)

    /// Handles both @username and full-name conventions — the field is
    /// labelled "Username" in the UI but the server accepts either.
    var username: String = ""
    var email: String = ""
    var password: String = ""

    // MARK: Email verification

    /// Flipped to `true` by `SignupVerifyEmailViewModel` when its poll of
    /// `GET /auth/email/status` returns `verified=true`. Drives the
    /// Overview checklist row.
    var emailVerified: Bool = false

    // MARK: Basic info

    var firstName: String = ""
    var city: String = ""
    var provinceState: String = ""
    /// ISO-3166-1 alpha-3. Populated via the country picker.
    var countryCode: String = ""

    // MARK: Languages

    /// Language records picked from `GET /meta/languages`. First element
    /// is treated as the primary language by the server. Store the full
    /// `LanguageItem` (id + label) so the review screen can render
    /// labels without a second lookup and the request builder can extract
    /// ids without a lookup either.
    var languages: [LanguageItem] = []

    // MARK: Timezone

    /// IANA identifier (e.g. `"America/Los_Angeles"`). Auto-detected on
    /// entry via `TimeZone.current.identifier`; user may override via
    /// the timezone picker step.
    var timezone: String = TimeZone.current.identifier

    // MARK: Profile photo

    /// URL returned by `POST /user/profile/avatar` once the photo is
    /// uploaded. Nil until the photo step is completed.
    var avatarUrl: String?

    // MARK: Expertise tags

    /// Full tag records picked from `GET /meta/expertise-tags`. First
    /// element is treated as the primary tag by the server. Storing the
    /// items (id + label) avoids parallel-array drift and lets the
    /// review screen render labels without re-looking-up.
    var expertiseTags: [ExpertiseTagItem] = []

    // MARK: Hourly rate

    /// Minor units (cents). `nil` = not set. `0` is a valid "free
    /// consultation" value once the user has explicitly chosen it, so
    /// we can't use `0` as the sentinel.
    var hourlyRateAmount: Int?
    /// ISO 3-letter uppercase.
    var hourlyRateCurrency: String = "USD"

    // MARK: - Derived

    /// True once every field required for `PATCH /expert/profile/setup`
    /// is present. Drives the "Publish Profile" button on the review
    /// screen.
    var isReadyToPublish: Bool {
        !firstName.isEmpty
            && !city.isEmpty
            && !provinceState.isEmpty
            && !countryCode.isEmpty
            && !timezone.isEmpty
            && !languages.isEmpty
            && !expertiseTags.isEmpty
            && hourlyRateAmount != nil
            && !hourlyRateCurrency.isEmpty
    }

    // MARK: - Checklist state

    /// Signals for the Overview screen's checklist — each entry is
    /// derived from whether the corresponding field(s) have been filled
    /// in. Kept as a computed property so the checklist stays in sync
    /// as the user moves between steps.
    var checklist: SignupChecklist {
        SignupChecklist(
            profilePhoto: avatarUrl != nil,
            emailVerified: emailVerified,
            hourlyRate: hourlyRateAmount != nil,
            expertise: !expertiseTags.isEmpty
        )
    }

    // MARK: - Request builder

    /// Assembles the payload for `PATCH /expert/profile/setup`. Requires
    /// `isReadyToPublish` — callers guard on that before invoking. If
    /// any required field is empty this returns nil so the caller can
    /// route the user back to the appropriate step.
    func buildSetupExpertProfileRequest() -> SetupExpertProfileRequest? {
        guard isReadyToPublish, let amount = hourlyRateAmount else { return nil }
        return SetupExpertProfileRequest(
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            location: .init(
                city: city.trimmingCharacters(in: .whitespaces),
                provinceState: provinceState.trimmingCharacters(in: .whitespaces),
                countryCode: countryCode
            ),
            timezone: timezone,
            languages: languages.map(\.id),
            expertiseTags: expertiseTags.map { $0.id.uuidString },
            hourlyRate: .init(amount: amount, currency: hourlyRateCurrency)
        )
    }
}

// MARK: - Checklist

/// Bool flags mirrored to the Overview screen's checklist rows.
struct SignupChecklist {
    let profilePhoto: Bool
    let emailVerified: Bool
    let hourlyRate: Bool
    let expertise: Bool
}
