---
created: 2026-11-15T05:05:56.000Z
title: "Backend: PATCH /user/profile name validation (min(1) copy, contract drift, empty last name decision)"
area: api
severity: medium
files:
  - ClickMe2026 Backend/src/schemas/userProfile.schema.js
  - ClickMe2026 Backend/openapi/clickme-api.yaml
  - ClickMe2026 Backend/src/controllers/auth.controller.js
  - ClickMe2026/Model/Requests/SetupExpertProfileRequest.swift
---

## Problem

Found by UAT gap G-05-6 and traced in `.planning/debug/profile-settings-save-fails-incomplete-profile.md`.

- `basic.first_name` and `basic.last_name` carry `min(1)` in `userProfile.schema.js` with no hand-written message, so a rejected name gives the generic 422 sentence "Please check the information you entered and try again." and a raw validator line ("Too small: ...") per field.
- The OpenAPI (`openapi/clickme-api.yaml`) has no minLength on either name, and signup stores `''` for both (`auth.controller.js` L604-605). A profile created by signup therefore cannot round-trip through this PATCH.
- No iOS setup step writes a last name, so every iOS-created account keeps `last_name ''`.
- App Store build 6 still fails every Profile Settings save for those accounts, because it sends the whole form. Current Android fails on any basic-group edit, because it sends a changed group whole with `last_name ""` (see the Android todo `2026-11-14-android-profile-settings-empty-name-save.md`).
- The new iOS build (plans 05-19 and 05-20) no longer sends empty names and needs no backend change.

## Decisions for the user (not made in Phase 5)

- A: accept an empty `last_name` (and maybe `first_name`) on PATCH. That would fix build 6 and Android with no client release. Whether an empty last name is valid is a product question; publish completeness checks `first_name` only.
- B: whether signup or setup should collect a last name.

## Safe additive change if approved

- Add hand-written messages on the name rules. Only the top-level message text changes; field paths and the `VALIDATION_ERROR` code stay the same, so build 6 and Android stay safe.
- Make the OpenAPI match whichever rule is chosen.
- Add backend tests: the `errors.test.js` parity rows and a schema row for the round-trip of signup's `''`.
- Precondition: backend `master` must MERGE origin/main first (todo `2026-11-11-merge-d12-into-backend-master.md`).
- One commit in the backend repo. The user deploys, because production is live and serves build 6.
- Log an Android follow-up if the backend changes.
