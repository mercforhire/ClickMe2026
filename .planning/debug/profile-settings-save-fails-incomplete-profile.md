---
status: diagnosed
trigger: "22 fail Because the profile has not been completed yet, all saving actions fail on the screen."
created: 2026-11-14T23:00:00Z
updated: 2026-11-14T23:30:00Z
goal: find_root_cause_only
gap_id: G-05-6
---

## Current Focus

hypothesis: CONFIRMED. iOS profile settings (client and expert) auto-save one whole-form PATCH /user/profile that always carries basic.first_name and basic.last_name as trimmed local strings, so "" when the profile has no name. The backend zod schema enforces min(1) on both, so every save from an empty-name profile gets a 422 VALIDATION_ERROR before the controller runs. The raw Zod messages are replaced by the generic sentence, and iOS shows only the top-level message, so the alert names no field.
test: done (local schema repro, 5 cases)
expecting: n/a
next_action: Return ROOT CAUSE FOUND to the orchestrator (goal find_root_cause_only); a gap-closure plan applies the fix.
bug_class: Bohrbug (deterministic: same empty-field state, same failure; complete profile always succeeds)
known_pattern_candidate: none (no knowledge-base.md exists)

reasoning_checkpoint:
  hypothesis: "Any Profile Settings save on a profile with an empty first or last name fails, because makeProfileUpdateBody (client :308-331, expert :314-337) always sends basic.first_name/last_name, and the backend's updateUserProfileSchema rejects \"\" with min(1), returning 422 whose message is GENERIC_VALIDATION_MESSAGE because the Zod default is filtered as raw."
  confirming_evidence:
    - "Local run of the production-identical schema + errorHandler on the iOS body returns exactly 422 message 'Please check the information you entered and try again.' with errors basic.first_name and basic.last_name"
    - "The same body with the empty names omitted validates; a complete profile with province cleared validates (matches the UAT retest PASS)"
    - "The alert's message string exists only in backend src/utils/errors.js:5; iOS shows it via Error.userMessage → StandardErrorResponse.message"
    - "28da165 (production) and master are byte-identical for every involved backend file"
  falsification_test: "A device save on an empty-name profile that (a) returns 2xx, or (b) shows a different server message, or (c) a body without first_name/last_name still returns 422, would disprove it. Repro case 5 tested (c) and it passed validation."
  fix_rationale: "The defect is sending fields the user did not edit, in a value (\"\") the server forbids. Omitting untouched or empty name keys (and/or sending only changed groups) removes the invalid input at its source; surfacing errors[] fixes the nameless message."
  blind_spots: "No live request was sent (production, write-forbidden), so the device response body was not captured directly; inferred from a byte-identical local run. Production data not read, so the number of live accounts with last_name '' is unknown (code says every iOS signup)."
  candidate_causes:
    - "code (iOS): whole-form PATCH always sends basic group incl. empty names; userMessage ignores errors[]"
    - "code/contract (backend): zod min(1) on first_name/last_name contradicts the OpenAPI (no minLength) and the '' that signup stores"
    - "data: signup inserts last_name '' and no setup step ever writes a last name, so empty names are the norm for iOS-created accounts"
  and_gate: "yes. The failure needs BOTH (a) iOS sending \"\" for a name it did not edit AND (b) the backend rejecting \"\". Removing either removes the symptom. The data condition (signup '' default, setup never writes last_name) is what makes (a) carry \"\" on every iOS-created account. The nameless alert is a separate contributing UX defect: iOS ignores errors[] and the backend has no hand-written message."

## Symptoms

expected: Profile settings saves an edit (including clearing State/Province) and it persists after reopening, with no error, even when the profile is not yet complete.
actual: "22 fail Because the profile has not been completed yet, all saving actions fail on the screen." Client Profile Settings for a fresh, unfinished expert signup (First Name, Last Name, Bio, Job Title, City empty; State/Province "Ontario"; Country "Select"; Spoken Languages "Add languages"). Any save shows alert "Couldn't save changes" / "Please check the information you entered and try again." with OK; no field named. On a complete profile the same edits save fine.
errors: Alert "Couldn't save changes" / "Please check the information you entered and try again."; no server message surfaced.
reproduction: Test 6 / checklist item 22 in .planning/phases/05-signup-mode-switch-and-account/05-UAT.md and 05-DEVICE-UAT-CHECKLIST.md. Open Client mode > Profile tab > Profile settings on an unfinished expert signup, edit any field, Save.
started: Discovered during Phase 5 UAT 2026-11-14. Phase 5 plans 05-04 and 05-09 changed this screen's save (province "" never null, D-07; LanguageSelectionView; A9 never save empty language list).

## Eliminated

- hypothesis: The iOS A9 local guard (applyLanguageSelection, "never save an empty language list") raises the alert without any request.
  evidence: That guard sets autoSaveError = "Keep at least one language." (ClientProfileSettingsViewModel.swift:295), which differs from the reported message, and it fires only from the language picker's Done with zero languages while languages already exist. The reported text is the backend's GENERIC_VALIDATION_MESSAGE, so a server response was involved.
  timestamp: 2026-11-14T23:15:00Z

- hypothesis: An empty country_code ("Select") fails alpha3Schema (length 3 / ^[A-Z]{3}$).
  evidence: Countries.normalize("") returns nil (Countries.swift:73), so the key is omitted (synthesized Encodable uses encodeIfPresent). The local repro with country_code omitted still failed, and errors[] named only basic.first_name and basic.last_name.
  timestamp: 2026-11-14T23:18:00Z

- hypothesis: Empty city / state_province / bio / job_title / company are rejected.
  evidence: The schema allows empty strings for all of them (plain z.string() or max-only). The repro with every one empty and the names omitted returned 200 (case 5).
  timestamp: 2026-11-14T23:18:00Z

- hypothesis: The D-07 province "" change (05-04/05-09) caused the regression.
  evidence: state_province "" passes validation (repro cases 4 and 5). The always-sent basic group with trimmed names dates from the app baseline df8d99e (2026-07-14), per `git log -S 'firstName: firstName.trimmingCharacters'`. b956838 (05-09) touched only languages and the province test. This is a pre-existing defect that also ships in App Store build 6; Phase 5 UAT was the first test run on an empty-name account.
  timestamp: 2026-11-14T23:20:00Z

- hypothesis: The backend controller (not the schema) rejects partial profiles.
  evidence: The controller's only 422 is unknown language_id, and its hand-written message would be shown verbatim. Validation fails in the validate() middleware before the controller runs.
  timestamp: 2026-11-14T23:13:00Z

## Evidence

- timestamp: 2026-11-14T23:05:00Z
  checked: Phase 0 knowledge base (.planning/debug/knowledge-base.md) and MemPalace
  found: No knowledge-base.md exists; no prior resolved sessions. No known-pattern candidate.
  implication: Open-ended investigation.

- timestamp: 2026-11-14T23:06:00Z
  checked: iOS alert source (grep "Couldn't save changes")
  found: ClientProfileSettingsView.swift:86-97 shows the alert titled "Couldn't save changes" with message = viewModel.autoSaveError. autoSaveError is set at ClientProfileSettingsViewModel.swift:350 (`autoSaveError = error.userMessage`) after `api.updateUserProfile(body)` throws, and at :295 ("Keep at least one language." local A9 guard). The message text "Please check the information you entered and try again." is NOT in iOS sources. It is the backend's GENERIC_VALIDATION_MESSAGE (backend src/utils/errors.js:5).
  implication: The alert is a server 422 passed through Error.userMessage (Error+UserMessage.swift:22-30, which returns StandardErrorResponse.message). The local A9 guard cannot be the source: its text differs, and it only fires from the language picker's Done.

- timestamp: 2026-11-14T23:08:00Z
  checked: ClientProfileSettingsViewModel.makeProfileUpdateBody (lines 308-331) and performAutoSave (333-352); the view's autoSaveSnapshot .onChange (ClientProfileSettingsView.swift:66-68, 178-185)
  found: Every auto-save (any field change, debounced 1.2 s) sends ONE whole-form PATCH /user/profile. It always includes basic{first_name, last_name, bio}, location{city, state_province, country_code}, professional{job_title, company}, each the trimmed local string. Empty local strings go out as "" (non-nil Swift String, so the synthesized Encodable emits the key). Only country_code can be omitted: Countries.normalize("") returns nil (Constants/Countries.swift:71-73), so the key is dropped by encodeIfPresent. The languages group is sent only when the ids changed. For the UAT account the body is {"basic":{"first_name":"","last_name":"","bio":""},"location":{"city":"","state_province":"<edited>"},"professional":{"job_title":"","company":""}}.
  implication: Every edit carries empty first_name and last_name, so one invalid field blocks all unrelated edits.

- timestamp: 2026-11-14T23:10:00Z
  checked: Backend route src/routes/userProfile.js:54 (`router.patch('/user/profile', validate(updateUserProfileSchema), updateUserProfile)`) and src/schemas/userProfile.schema.js
  found: basic.first_name = z.string().min(1).max(100).optional(); basic.last_name = z.string().min(1).max(100).optional(); bio max(500); city/state_province plain z.string() (empty OK); job_title/company max(200) (empty OK); country_code = alpha3Schema.optional() (length 3 + /^[A-Z]{3}$/; omitted by iOS when empty, so OK). validate() (src/middleware/validate.js) uses code VALIDATION_ERROR and status 422. parseOrThrowValidation (src/utils/validation.js) maps Zod issues to {field: path.join('.'), message}.
  implication: "" for first_name or last_name fails schema validation before the controller runs. No other field in the iOS body can fail when empty.

- timestamp: 2026-11-14T23:11:00Z
  checked: Backend errorHandler + validationSummaryMessage (src/utils/errors.js)
  found: For a ValidationError the top-level message is the first errors[] entry whose message is hand-written. Raw Zod defaults (regex RAW_ZOD_MESSAGE, which includes "Too small:") are skipped, and when every entry is raw the message is GENERIC_VALIDATION_MESSAGE, "Please check the information you entered and try again.". min(1) on first_name/last_name has no custom message, so Zod's default "Too small: expected string to have >=1 characters" is raw, giving the generic sentence. The field names appear only in errors[].field, which iOS never reads on this screen.
  implication: Explains exactly why the alert names no field.

- timestamp: 2026-11-14T23:12:00Z
  checked: Production backend version vs local files
  found: origin/main HEAD = 28da165 (matches STATE.md production /health). `git diff 28da165 master` is empty for userProfile.schema.js, onboarding.schema.js, errors.js, validation.js, userProfile.controller.js and routes/userProfile.js. userProfile.schema.js last changed at 44d5b56 (2026-10-17).
  implication: The schema read locally is the schema production runs; no live request needed.

- timestamp: 2026-11-14T23:13:00Z
  checked: Backend controller updateUserProfile (src/controllers/userProfile.controller.js:145-219)
  found: Its only 422 is unknown language_id, with the hand-written message "One or more language_ids do not exist.", which would be shown verbatim, not the generic sentence. The 403 for email is not triggered (iOS never sends email).
  implication: The controller is ruled out as the source of the generic-message 422.

- timestamp: 2026-11-14T23:14:00Z
  checked: ExpertProfileSettingsViewModel.makeProfileUpdateBody (lines 314-337) and performAutoSave (339-384)
  found: Identical body construction (always sends trimmed first_name/last_name, possibly ""). The same alert title is used in ExpertProfileSettingsView.swift:60. The comment at :345-351 records an earlier, identical class of bug (meeting_url "" got a 422 and was fixed by omitting the empty key) that was never applied to first_name/last_name.
  implication: The expert screen has the same defect for any expert whose first or last name is empty.

- timestamp: 2026-11-14T23:17:00Z
  checked: Deterministic local repro. /tmp/gsd-debug-g056-scripts/repro.js runs the backend's real validate(updateUserProfileSchema) + errorHandler (required by absolute path, no network, no production request) on the exact iOS bodies.
  found: |
    1. Incomplete profile, province cleared: 422 {"status":"error","message":"Please check the information you entered and try again.","errors":[{"field":"basic.first_name","message":"Too small: expected string to have >=1 characters"},{"field":"basic.last_name","message":"Too small: expected string to have >=1 characters"}],"code":"VALIDATION_ERROR"}
    2. Incomplete profile, bio edited: the same 422.
    3. First name filled, last name empty: 422, errors=[basic.last_name] only.
    4. Complete profile, province cleared: passes validation (matches the UAT retest PASS).
    5. Incomplete profile, empty names OMITTED: passes validation.
  implication: Confirms the hypothesis exactly, including the alert text and that no field is named. Omitting empty name keys is sufficient for the request to validate.

- timestamp: 2026-11-14T23:21:00Z
  checked: Where profile names come from. Backend signup (auth.controller.js:595-607), auth.schema signupSchema, onboarding.schema/onboarding.controller, iOS SignupInitialViewModel.swift:118-122, SetupExpertProfileRequest.swift, grep of every iOS lastName writer.
  found: Signup inserts profiles.first_name = '' and last_name = '' for every account. signupSchema takes no names. iOS signup always uses role .expert. The setup flow (PATCH /expert/profile/setup, SetupExpertProfileRequest) carries firstName but has NO lastName key, and publish completeness (computeOnboardingStatus) checks first_name only. The only iOS writers of last_name are the two profile settings screens (ClientProfileSettingsViewModel.swift:312, ExpertProfileSettingsViewModel.swift:318).
  implication: Wider blast radius than "incomplete profile". Every iOS-created account, published experts included, has last_name '' until the user types one in Profile Settings, so ANY first edit of another field on either settings screen fails (repro case 3). The UAT "complete profile" account must already have had a last name. Blind spot: production data not read (no live queries).

- timestamp: 2026-11-14T23:22:00Z
  checked: GET /user/profile serializer (userProfile.controller.js:59-60) and the OpenAPI contract for PATCH /user/profile (openapi/clickme-api.yaml ~5348-5356)
  found: GET returns first_name/last_name straight from the row ('' for new accounts; iOS hydrates '' or nil to ""). The OpenAPI basic.first_name / last_name are `type: string, maxLength: 100` with NO minLength, but the zod implementation adds .min(1).
  implication: Backend contract drift. The documented contract allows "", the implementation rejects it, and the server's own stored default ('') cannot be round-tripped through its PATCH.

- timestamp: 2026-11-14T23:24:00Z
  checked: Android port (ClickMe_Android .../clientprofilesettings/ProfileSnapshot.kt buildProfilePatch; ClientProfileSettingsViewModel.kt onSaveFailed / fieldForServerName)
  found: Android sends ONLY the groups that changed vs the baseline snapshot (each changed group whole, trimmed, "" for cleared). So a province-only edit sends only `location` and succeeds on an incomplete profile. A basic-group edit (e.g. bio) with an empty name still sends last_name "" and gets the same 422. Android has no local blank-name guard either, but on a 422 it maps errors[].field (basic.first_name, basic.last_name, ...) to per-field messages under the fields. It shows the raw Zod text "Too small: ...". It does not use a nameless dialog.
  implication: iOS diverges from Android in two ways: whole-form instead of changed-groups PATCH, and ignoring errors[]. Android also has a residual bug (a basic edit with an empty name returns 422) plus raw Zod copy. A shared backend fix would cover both clients.

- timestamp: 2026-11-14T23:25:00Z
  checked: Why tests missed it (ClickMe2026Tests/Settings/ProfileLanguagesSaveTests.swift fixtures)
  found: Every fixture profile has first_name "Ada" and last_name "Lovelace", and MockURLProtocol answers every PATCH with 200, so the backend min(1) never runs. No test covers an empty-name profile or a 422 on this screen. No backend test pins the round-trip of the signup default.
  implication: No gate existed for this class (client and server validation rules out of sync, plus a server default that can't round-trip).

## Resolution

root_cause: >
  AND-gate, two code causes plus one data condition.
  (1) iOS: ClientProfileSettingsViewModel.makeProfileUpdateBody (ClientProfileSettingsViewModel.swift:308-331) and
  ExpertProfileSettingsViewModel.makeProfileUpdateBody (:314-337) build ONE whole-form PATCH /user/profile on every
  debounced edit. It always includes basic{first_name,last_name,bio} as trimmed local strings, so "" for a name the
  profile never had, even when the user only edited State/Province.
  (2) Backend: src/schemas/userProfile.schema.js basic.first_name / last_name = z.string().min(1).max(100).optional()
  rejects "", which contradicts openapi/clickme-api.yaml (type string, maxLength 100, no minLength) and the '' that
  signup itself stores (auth.controller.js:604-605). The result is 422 {status:error, code:VALIDATION_ERROR,
  message:"Please check the information you entered and try again.", errors:[{field:"basic.first_name",message:"Too small: expected string to have >=1 characters"},{field:"basic.last_name",...}]}.
  The generic message comes from validationSummaryMessage (src/utils/errors.js), which drops raw Zod defaults.
  (3) Data: every account starts with first_name '' and last_name ''. The iOS setup flow (SetupExpertProfileRequest) writes first_name but never last_name,
  so empty last names are normal even on PUBLISHED iOS experts, not only unfinished setups.
  Contributing UX defect: iOS Error.userMessage (Error+UserMessage.swift:22-30) shows only the top-level message
  and never reads errors[] (FieldValidationErrorResponse exists but is unused on this screen), so the alert names no field.
  Pre-existing since app baseline df8d99e (2026-07-14), also in App Store build 6; not introduced by 05-04/05-09.
fix: (not in scope: goal find_root_cause_only)
verification: Root cause verified by a deterministic local repro of the production-identical backend schema + error handler (/tmp/gsd-debug-g056-scripts/repro.js), 5 cases; no production request sent.
files_changed: []
specialist_hint: swift (primary fix in iOS view models); backend JS optional/additive
