---
phase: 06-expert-mode
reviewed: 2026-11-17T13:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - ClickMe2026/Utils/BookingCalendarEventContent.swift
  - ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift
  - ClickMe2026Tests/ExpertMode/TopicsSetupMutationTests.swift
  - ClickMe2026Tests/ExpertMode/TopicsSetupTopicCardLabelTests.swift
  - ClickMe2026Tests/Model/TopicCurrencyTests.swift
  - ClickMe2026Tests/Support/MeDataFixtures.swift
findings:
  critical: 0
  warning: 0
  info: 1
  total: 1
status: issues_found
---

# Phase 06: Code Review Report (quick task 261117-1le)

**Reviewed:** 2026-11-17T13:00:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

This report supersedes the earlier phase-06 review for the diff `a8f0531..HEAD` over the six files above. It covers quick task 261117-1le, which fixed WR-01, IN-03 and IN-07.

## Summary

All three targeted findings are fixed. I found no bugs, concurrency errors or behaviour changes for real callers. One small residual test-isolation gap remains (IN-08).

What I checked:

- **WR-01 (seed and selection agree).** `init` now calls `resolveInitialCurrency(topic:defaultCurrency: newTopicDefaultCurrency(in: me))` once. The price seed (`editableAmount`) and `self.currency` both use `resolvedCurrency`. The `defaultCurrency` property now returns `newTopicDefaultCurrency(in: currentMe)`, the same rule the init and the Topics tab card use, so the property, the init and the test assertions cannot drift. The new `TopicCurrencyTests` rows cover the JPY-default account for a blank-currency topic, a new topic, and a stored USD topic, which still keeps USD, its `125.50` seed and its lock (D-18, D-19).
- **Swift 6 and MainActor isolation of the seam.**
  - `meProvider` is typed `@MainActor () -> MeData?`, and the owning class is `@MainActor`. The init reads it synchronously, and `currentMe` is a main-actor computed property, so no isolation hop or data race is possible.
  - The default `{ userManager.me }` captures the init parameter, not `self`, so it reads before all stored properties are initialised without error.
  - Shadowing the parameter with `let meProvider = meProvider ?? ...` is legal in an init body.
  - The parameter is an optional closure, so it is implicitly escaping, which is what the stored property needs.
- **Behaviour for real callers.** The only production call sites are `TopicEditorView.swift:55` and `previewSeed`. Neither passes `meProvider`, so both take the default and read `userManager.me` live, exactly as before. A `/me` that lands after the editor opens is still seen by `allowedCurrencies`, the price floor, `isRateBelowMinimum` and `minPriceHint`. `validate()` and the hint still check the floor for the currency selected.
- **Fixture and test isolation.**
  - `MeDataFixtures` is `@MainActor` and decodes `MeData` on the main actor, which matches the main-actor `Decodable` conformance from the app target's default isolation. The three suites that use it are all `@MainActor`.
  - The fixture JSON is valid in both branches (`allowed_currencies` present or omitted, trailing comma handled).
  - `by_currency` keys (`USD`, `CAD`) are unaffected by `convertFromSnakeCase`.
  - The file is picked up automatically because the test group is a file-system-synchronized group.
  - The new assertions are correct: JPY default with `["CAD","USD"]` allowed resolves to `CAD`; USD default resolves to `USD`; no `/me` resolves to `CAD`.
  - The `125` seed and `US$` and `CA$` card labels agree with the editor's `currencySymbol`.
  - The mutation test uses USD so a hidden CAD fallback would fail.

## Info

### IN-08: Other editor tests still depend on the ambient shared `/me`

**File:** `ClickMe2026Tests/Model/TopicCurrencyTests.swift:76-285` (for example the comment at line 81 "The test host has no /me") and `ClickMe2026Tests/Utils/MoneyCallSiteTests.swift:74-142` (comments at lines 72 and 90 "CAD in the test host")
**Issue:** IN-07 is fixed for the two tests it named, and the `meProvider` seam now makes the same fix cheap everywhere. About 25 other `TopicEditorViewModel(topic:)` calls in these two suites still use the default provider and silently assume `UserManager.shared.me` is nil or CAD-default. They are the same coupling IN-07 described, and they pass only while no other suite populates the shared manager.

Separately, every injected call still evaluates the default argument `userManager: UserManager = .shared`. The seam therefore avoids reading `me`, but not constructing the singleton (its private init rewires the shared API client's token refresher and may connect the realtime socket). The new doc comment on `meProvider` says injection avoids the singleton; it avoids the read, not the construction.
**Fix:** Pass `meProvider: { nil }`, or a fixed `MeDataFixtures.me(...)`, in the remaining tests, and have those suites use the shared helper. Optionally reword the `meProvider` comment to "so a test does not depend on whatever `/me` the shared manager holds".

## Carried forward

These are unchanged and out of scope for this review. They are not re-raised, and their IDs are not reused.

Deferred (disposition `deferred`, unchanged):

- **WR-02:** Calendar sheet content is built from the same optional that drives `isPresented`, and the pattern is copy-pasted
- **IN-01:** Production code left unused after the delegation refactor
- **IN-02:** Duplicated `trimmed` helper and a circular dependency between the two content enums
- **IN-04:** Redundant status gate in two views
- **IN-05:** Summary view modifier layout and comment
- **IN-06:** Card currency symbol differs from the editor's for codes other than USD and CAD

Verified status of the three targeted findings:

- **WR-01:** fixed. The price seed and the selected currency both come from one `resolveInitialCurrency` result, and the `defaultCurrency` property uses the same `newTopicDefaultCurrency` rule. Regression rows cover the JPY-default case.
- **IN-03:** fixed. The doc comment at `BookingCalendarEventContent.swift:76-77` now reads "Used by the client Upcoming Booking screen." and has no plan number.
- **IN-07:** fixed for the two tests it named (`cardAndEditorAgreeOnBlankCurrency` and `blankCurrencyFreeTopicSavesARealCurrency`). Both now inject `/me` through `meProvider` and no longer read `UserManager.shared.me`. The wider residual coupling is tracked separately as IN-08.

---

_Reviewed: 2026-11-17T13:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
