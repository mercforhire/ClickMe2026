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
/// AND (via its ViewModel's `save()`) PATCHes just that step's slice to
/// `/expert/profile/setup` before advancing — so a mid-flow quit leaves
/// authoritative state on the server.
///
/// The final `SignupReviewView` calls `PATCH /expert/profile/setup` one
/// more time with `setup_completed: true` to flip the server's completion
/// flag and unlock the expert dashboard.
///
/// When the app auto-resumes a mid-setup expert (see `AppRoute.signupSetup`),
/// `hydrate(from:)` seeds this instance from `GET /expert/profile` so any
/// step that already saved pre-fills instead of forcing re-entry.
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
    ///
    /// Pre-seeded with English so the Basic Info step doesn't force the
    /// user through a language picker if they only speak English. `id`
    /// and `label` mirror the canonical entries in
    /// `LanguageSelectionViewModel.masterList`.
    var languages: [LanguageItem] = [LanguageItem(id: "en", label: "English")]

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
    /// element is treated as the primary tag by the server. On hydration
    /// from `/expert/profile` the `categoryId` field is set to `""` — the
    /// tag-picker view only needs `categoryId` for the master catalog
    /// (which it re-fetches on load), so an empty value here is fine.
    var expertiseTags: [ExpertiseTagItem] = []

    // MARK: - Derived

    /// True once every field required for `PATCH /expert/profile/setup`
    /// with `setup_completed: true` is present. Drives the "Publish
    /// Profile" button on the review screen.
    ///
    /// Hourly rate is intentionally NOT part of setup — clients aren't
    /// experts yet, and any per-topic pricing is captured later on the
    /// expert-side Topics screen.
    var isReadyToPublish: Bool {
        !firstName.isEmpty
            && !city.isEmpty
            && !provinceState.isEmpty
            && !countryCode.isEmpty
            && !timezone.isEmpty
            && !languages.isEmpty
            && !expertiseTags.isEmpty
    }

    // MARK: - Checklist state

    /// Signals for the Overview screen's checklist — each entry is
    /// derived from whether the corresponding field(s) have been filled
    /// in. Kept as a computed property so the checklist stays in sync
    /// as the user moves between steps.
    ///
    /// Basic Info requires every identity field (first name, city,
    /// province/state, country, languages) — anything less and the
    /// server can't render a useful expert card. Timezone always has
    /// a value (auto-seeded from `TimeZone.current`), so its row is
    /// considered complete as long as the string is non-empty.
    var checklist: SignupChecklist {
        SignupChecklist(
            basicInfo: !firstName.isEmpty
                && !city.isEmpty
                && !provinceState.isEmpty
                && !countryCode.isEmpty
                && !languages.isEmpty,
            timezone: !timezone.isEmpty,
            profilePhoto: avatarUrl != nil,
            emailVerified: emailVerified,
            expertise: !expertiseTags.isEmpty
        )
    }

    // MARK: - Hydration

    /// Seeds fields from a server `ExpertProfileData` snapshot returned by
    /// `GET /expert/profile`. Covers every step of the signup flow —
    /// basic info, avatar, location, timezone, languages, hourly rate,
    /// expertise tags. Non-empty local values are preserved where the
    /// server has nothing to say (e.g. the English default for
    /// `languages` survives if the profile has an empty list).
    ///
    /// Note the input's `location_details` uses `stateProvince` (GET key
    /// `state_province`), while the PATCH schema uses `province_state`.
    /// The client normalizes to `provinceState` internally.
    func hydrate(from profile: ExpertProfileData) {
        if let name = profile.personalInfo.firstName, !name.isEmpty {
            firstName = name
        }
        if let email = profile.personalInfo.email, !email.isEmpty {
            self.email = email
        }
        if let avatar = profile.avatarUrl, !avatar.isEmpty {
            avatarUrl = avatar
        }
        if let cityValue = profile.locationDetails.city, !cityValue.isEmpty {
            city = cityValue
        }
        if let stateValue = profile.locationDetails.stateProvince, !stateValue.isEmpty {
            provinceState = stateValue
        }
        if let country = profile.locationDetails.countryCode, !country.isEmpty {
            countryCode = country
        }
        if let tz = profile.locationDetails.timezone, !tz.isEmpty {
            timezone = tz
        }
        let hydratedLanguages: [LanguageItem] = profile.languages.compactMap { entry in
            guard let id = entry.id, let label = entry.label else { return nil }
            return LanguageItem(id: id, label: label)
        }
        if !hydratedLanguages.isEmpty {
            languages = hydratedLanguages
        }
        if !profile.expertiseTags.isEmpty {
            // Primary tag first — matches the server's `is_primary`
            // ordering and mirrors how the review + publish payload
            // treats element 0 as primary.
            let sorted = profile.expertiseTags.sorted { lhs, rhs in
                if lhs.isPrimary != rhs.isPrimary { return lhs.isPrimary }
                return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
            }
            expertiseTags = sorted.map {
                ExpertiseTagItem(id: $0.id, label: $0.label, categoryId: "")
            }
        }
    }

    // MARK: - Request builders

    /// Assembles the full payload for the final "publish" call — all
    /// required fields plus `setup_completed: true`. Callers must guard
    /// on `isReadyToPublish`; returns nil when any required field is
    /// empty so the caller can route the user back.
    func buildPublishRequest() -> SetupExpertProfileRequest? {
        guard isReadyToPublish else { return nil }
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
            setupCompleted: true
        )
    }
}

// MARK: - Checklist

/// Bool flags mirrored to the Overview screen's checklist rows.
/// Order here mirrors the order in the UI: identity → settings → polish.
struct SignupChecklist {
    let basicInfo: Bool
    let timezone: Bool
    let profilePhoto: Bool
    let emailVerified: Bool
    let expertise: Bool
}
