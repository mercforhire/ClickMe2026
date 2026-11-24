---
phase: 08-release
reviewed: 2026-11-23T00:00:00Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryView.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift
  - ClickMe2026/Views/Screens/Client Mode/Booking Summary/Subviews/BookingSummaryActions.swift
  - ClickMe2026/Debug/PreviewSecrets.swift
  - ClickMe2026/Model/UIModels/ChatDisplayModels.swift
  - ClickMe2026/Utils/AccountDeletionCopy.swift
  - ClickMe2026/Utils/ChatItemMapper.swift
  - ClickMe2026/Utils/Money.swift
  - ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingSystemEventRow.swift
  - ClickMe2026/Views/Screens/Client Mode/Favorites/FavoritesViewModel.swift
  - ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupTopicCard.swift
  - ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift
  - ClickMe2026/Views/Screens/Settings/Delete account/Subviews/DeleteAccountWarningHeader.swift
  - ClickMe2026Tests/Booking/BookingSummaryViewModelTests.swift
  - ClickMe2026Tests/Chat/ChatItemMapperTests.swift
  - ClickMe2026Tests/Model/TopicCurrencyTests.swift
  - ClickMe2026Tests/Utils/AccountDeletionCopyTests.swift
  - ClickMe2026Tests/Utils/ClientProfileBookingCardTests.swift
  - ClickMe2026Tests/Utils/ClientProfileHistoryEarningsTests.swift
  - ClickMe2026Tests/Utils/MoneyCallSiteTests.swift
  - ClickMe2026Tests/Utils/MoneyTests.swift
  - .github/workflows/build.yml
  - .github/workflows/test.yml
  - .github/actions/code-signing-setup/action.yml
  - ExportOptions.plist
  - scripts/release-build-check.sh
  - scripts/run-smoke-tests.sh
  - .gitignore
findings:
  critical: 1
  warning: 7
  info: 7
  total: 15
status: issues_found
---

# Phase 8: Code Review Report

**Reviewed:** 2026-11-23
**Depth:** standard
**Files Reviewed:** 27
**Status:** issues_found

## Summary

I reviewed the Phase 8 iOS-repo changes: the Booking Summary, Money, chat event mapping, Topic Editor and Favorites code, their tests, the release CI and the two shell scripts. Build 1.1 (7) is already submitted, so every finding below is a follow-up for the next build or the next CI change.

Most of the Swift code is sound. `Money` uses unsigned magnitudes and integer arithmetic, so `Int.min` and `Int.max` can't trap. The Favorites removal and revalidation logic is careful. `PreviewSecrets` holds no token, and Release compiles no file or environment read. A scan of tracked files found no JWT-shaped strings. Nothing I found affects what shipped, but one defect gives a false pass on a verification gate.

Main concerns:
- `scripts/run-smoke-tests.sh` exits 0 when the smoke tests fail (CR-01).
- Booking Summary can offer "Leave a Review" on an already-reviewed booking after a transient failure (WR-01).
- A "Message Expert" request keeps running after the user leaves the screen (WR-02).
- The release workflow lacks least-privilege hardening and has an upload-by-default manual trigger (WR-04 to WR-06).
- The "no new warnings" gate can miss warnings (WR-07).

No structural (fallow) findings were provided for this review.

## Critical Issues

### CR-01: `run-smoke-tests.sh` exits 0 when the smoke tests fail

**File:** `scripts/run-smoke-tests.sh:32-38`
**Issue:** The script sets `set -euo pipefail`, then runs `xcodebuild test ... | xcbeautify 2>/dev/null || cat`.
- With `pipefail`, a failing `xcodebuild` (exit 65) or a missing `xcbeautify` (exit 127) makes the pipeline fail, so the `|| cat` fallback runs.
- That `cat` reads stdin, not the lost xcodebuild output. In a terminal it blocks until Ctrl-D. In CI or with stdin closed it returns 0 at once.
- The `||` list takes the status of `cat`, so `set -e` never fires and the script exits 0.
- A broken smoke run therefore reads as a pass for whoever runs it or any wrapper that checks the exit code.
- The "raw output fallback" intent can't work either, because the output has already gone down the pipe.

**Fix:**
```bash
XCODEBUILD_ARGS=(
    test
    -project "$PROJECT"
    -scheme "$SCHEME"
    -configuration "$CONFIGURATION"
    -destination "platform=iOS Simulator,name=$SIMULATOR,OS=latest"
    -only-testing:"ClickMe2026Tests/AuthSmokeTests"
)

if command -v xcbeautify >/dev/null 2>&1; then
    # pipefail makes the pipeline fail when xcodebuild fails.
    xcodebuild "${XCODEBUILD_ARGS[@]}" | xcbeautify
else
    xcodebuild "${XCODEBUILD_ARGS[@]}"
fi
```

## Warnings

### WR-01: A failed review-context fetch on first load offers "Leave a Review" for an already-reviewed booking

**File:** `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift:304-311`
**Issue:** `forceLoad` treats the review context as a soft dependency. When `getReviewContext` throws, it executes `hasSubmittedReview = false`.
- `showsLeaveReview` is `status == .completed && !hasSubmittedReview`. A transient failure (timeout, 5xx) on a completed booking the client already reviewed now shows "Leave a Review" and hides the feedback card.
- `refreshOnce()` handles the same failure by keeping the previous review state, so the two paths disagree.
- Nothing corrects the screen until a `booking.update` socket event arrives or the user reopens it.
- No test covers the `forceLoad` review-context failure path. `failedReviewContextKeepsLoadedAndAppliesDetail` only covers `refresh()`.

**Fix:** Don't assert "not reviewed" when the answer is unknown. Track whether the review state is known and hide the CTA until it is.
```swift
@Published private(set) var reviewStateKnown = false

var showsLeaveReview: Bool { status == .completed && reviewStateKnown && !hasSubmittedReview }

// forceLoad catch block: leave hasSubmittedReview and the feedback fields untouched.
} catch {
    guard reloads.isCurrent(token) else { return }
}
// apply(reviewContext:) sets reviewStateKnown = true
```
Add a test: load a completed booking with a 500 review context and assert `!showsLeaveReview`.

### WR-02: "Message Expert" runs in an unstructured `Task` that is never cancelled, so it can open a chat after the user has left

**File:** `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryView.swift:313-323` (also the doc comment at `BookingSummaryViewModel.swift:414-417`)
**Issue:** `messageExpertTapped()` starts `Task { ... await viewModel.startChat() ... openChatThread(...) }` and keeps no handle.
- The view model's contract says nil is returned when "the task was cancelled (the screen went away, which is not an error)".
- Nothing ties this Task to the view's lifetime, so it is never cancelled when the screen goes away.
- If the user taps Message Expert and then pops back, the request completes and `openChatThread` still switches the shell to the Chats tab and pushes the thread, which is a surprising jump.

**Fix:** Run the work from a lifetime-bound task, or keep the Task and cancel it on disappear.
```swift
@State private var chatTask: Task<Void, Never>?

private func messageExpertTapped() {
    guard let openChatThread, chatTask == nil else { return }
    chatTask = Task {
        defer { chatTask = nil }
        guard let threadId = await viewModel.startChat(), !Task.isCancelled else { return }
        openChatThread(threadId: threadId, peerName: viewModel.expertName, peerAvatarURL: viewModel.expertImageURL)
    }
}
// body: .onDisappear { chatTask?.cancel() }
```

### WR-03: An untouched price is sent back as stored minor units even after the currency picker changed

**File:** `ClickMe2026/Views/Screens/Expert Mode/Topics/Topic Editor/TopicEditorViewModel.swift:408-413`
**Issue:** `validate()` returns `seededRateMinor` whenever `trimmedRate == seededRate`, whatever `currency` is now. The seed text was produced with the digit count of the starting currency.
- `currency` can change for an unlocked topic (free, or paid with a blank code).
- Today the picker offers only 2-digit currencies, so the bug is latent.
- If the server adds a zero-decimal code to `allowed_currencies`, an untouched `125.50` seed switched to JPY would send `12550` JPY while the field reads "125.50".
- The live hint and `validate()` would then disagree about the amount, on a path that feeds real prices.

**Fix:** Take the shortcut only while the currency is still the one the seed was built in.
```swift
private let seededCurrency: String   // resolvedCurrency in init

if let seededRateMinor, trimmedRate == seededRate, currency == seededCurrency {
    rateMinor = seededRateMinor
} else {
    guard let parsed = TopicPriceRules.parseMinor(trimmedRate, currency: currency) else { /* existing error */ }
    rateMinor = parsed
}
```
Add a test with an off-list zero-decimal currency selected on an untouched seed.

### WR-04: Workflows run with default token permissions, and secrets-bearing jobs use mutable third-party action tags

**File:** `.github/workflows/build.yml:1-44`, `.github/workflows/test.yml:1-43`
**Issue:**
- Neither workflow declares `permissions:`, so `GITHUB_TOKEN` takes the repo default, which may be read/write.
- `build.yml` handles a distribution certificate, a provisioning profile and an App Store Connect API key. It uses `maxim-lobanov/setup-xcode@v1` and the `v6`/`v5`/`v7` tags of the first-party actions, all by mutable tag.
- A compromised or retagged action in an earlier step runs on the same runner. It can read the `AuthKey.p8` and certificate files written to disk by the later steps, not just the secrets passed to it.
- `test.yml` uses `cirruslabs/swiftlint-action@v1` with `version: latest`, so CI results change without a commit.

**Fix:** Add least-privilege permissions to both files and pin actions by commit SHA, with a version comment.
```yaml
permissions:
  contents: read
```
```yaml
- uses: maxim-lobanov/setup-xcode@<full-commit-sha> # v1.x
```
Pin the SwiftLint version in `test.yml` as well.

### WR-05: A manual run uploads to TestFlight by default from any ref, and a newer push can cancel an upload in progress

**File:** `.github/workflows/build.yml:9-14, 21-23`
**Issue:**
- `dry_run` defaults to `false`, so clicking "Run workflow" on any branch (or any `release/**` push) archives and uploads to App Store Connect.
- `testFlightInternalTestingOnly` is `false` in `ExportOptions.plist`, so the build is eligible for external testers.
- `manageAppVersionAndBuildNumber` is `false`, so a repeated build number fails safe at upload. A fresh number on a feature branch would succeed.
- `concurrency` uses `cancel-in-progress: true` on a deploy job, so a second push to the same release branch can kill a run during export or upload and leave the outcome unclear.

**Fix:** Default the manual input to the safe path, restrict uploads to release refs, and don't cancel deploys.
```yaml
dry_run:
  type: boolean
  default: true

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false
```
Gate the upload (non-dry-run) with `if: startsWith(github.ref, 'refs/heads/release/')`.

### WR-06: Secrets are inlined into shell scripts, and signing material is never cleaned up

**File:** `.github/workflows/build.yml:94-127`, `.github/actions/code-signing-setup/action.yml:27-57`
**Issue:**
- `${{ secrets.* }}` is expanded straight into `run:` text: the base64 key at line 98, and the key ID and issuer ID unquoted at lines 109-110 and 123-124. Passing secrets through `env:` and quoting `"$VAR"` avoids shell-injection and word-splitting problems.
- `AuthKey.p8` is written with default permissions. The temporary keychain, the `.p12` and the `.mobileprovision` copies in two profile directories are never removed.
- The workflow comment offers a self-hosted runner, where those files persist between jobs and users.
- A missing or empty secret decodes to an empty file silently, and the failure surfaces later as an opaque signing error.

**Fix:**
```yaml
- name: Install App Store Connect API key
  env:
    API_KEY_B64: ${{ secrets.APP_STORE_CONNECT_API_KEY_BASE64 }}
  run: |
    test -n "$API_KEY_B64" || { echo "APP_STORE_CONNECT_API_KEY_BASE64 is empty" >&2; exit 1; }
    umask 077
    echo -n "$API_KEY_B64" | base64 --decode -o "$RUNNER_TEMP/AuthKey.p8"
    echo "APP_STORE_CONNECT_API_KEY_PATH=$RUNNER_TEMP/AuthKey.p8" >> "$GITHUB_ENV"

- name: Clean up signing material
  if: always()
  run: |
    security delete-keychain "$RUNNER_TEMP/app-signing.keychain-db" || true
    rm -f "$RUNNER_TEMP/AuthKey.p8" "$RUNNER_TEMP/build_certificate.p12" "$RUNNER_TEMP/build_pp.mobileprovision"
    rm -f ~/Library/MobileDevice/Provisioning\ Profiles/build_pp.mobileprovision \
          ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/build_pp.mobileprovision
```
Also quote `$CERTIFICATE_PATH`, `$KEYCHAIN_PATH` and `$PP_PATH` in the composite action.

### WR-07: The "no new warnings" gate has false negatives and breaks on a relative `WORK`

**File:** `scripts/release-build-check.sh:83-91, 98-100`
**Issue:**
- `norm` removes the path prefix and the line and column numbers, then `sort -u`, and `comm -13` compares those sets.
- A new warning whose text matches an existing baseline warning in the same file (for example a second "main actor-isolated ... cannot be referenced" in a file that already has one) is invisible, because uniqueness is checked without a count.
- The script is the stated check for "a clean xcodebuild with no new warnings", so a missed warning is a missed gate.
- `build` does `cd "$tree"` and then uses `$WORK/dd` and `$WORK/spm`. A relative `WORK=` override therefore points at the wrong directory.

**Fix:** Compare counts per normalized line and make `WORK` absolute.
```bash
mkdir -p "$WORK"; WORK="$(cd "$WORK" && pwd)"

norm() { ...same pipeline... | sort | uniq -c | sed -E 's/^ +//'; }   # "<count> <warning>"
# A candidate line is new when its warning text is absent or its count is higher.
```
Report any `<count> <text>` whose count exceeds the baseline's count for the same text.

## Info

### IN-01: Redundant prefix/digits round trip in the topic card price label

**File:** `ClickMe2026/Views/Screens/Expert Mode/Topics/Subviews/TopicsSetupTopicCard.swift:34-36`
**Issue:** `amount >= 0` is guaranteed, so `Money.format` returns `prefix + digits` with no sign. The code strips the prefix by character count and re-adds it, and the result is identical to the input.
**Fix:** `return Money.format(minorUnits: amount, currency: currency) + perSessionSuffix`

### IN-02: `.gitignore` does not cover `.DS_Store` or build and signing artifacts, and four `.DS_Store` files are tracked

**File:** `.gitignore:1-4`
**Issue:**
- The file lists only `xcuserdata` and `PreviewSecrets.local.json`.
- `git ls-files` shows four tracked `.DS_Store` files. `git status` shows the root one modified and five more untracked, so they churn on every commit.
- Nothing ignores `*.xcarchive`, `*.xcresult`, `DerivedData/`, `*.p8`, `*.p12` or `*.mobileprovision`. The workflows write `ClickMe2026.xcarchive` and `TestResults.xcresult` into the checkout, and the release process handles key and profile files.

**Fix:** Add these lines, then untrack the four files with `git rm --cached`.
```
.DS_Store
DerivedData/
*.xcarchive
*.xcresult
*.p8
*.p12
*.mobileprovision
.env
```

### IN-03: The chat event time formatter comment promises a "·" that the template drops

**File:** `ClickMe2026/Views/Screens/Chat/Chatting/Subviews/ChattingSystemEventRow.swift:16-22, 96`
**Issue:** `setLocalizedDateFormatFromTemplate("EEE, MMM d · h:mm a")` builds the pattern from field symbols, and literal characters in a template are discarded. The output is locale-shaped (for example "Fri, Jul 19, 2:17 PM"), not the "Fri, Jul 19 · 2:17 PM" the comment says. The visible line then reads "topic · Fri, Jul 19, 2:17 PM".
**Fix:** Use the template `"EEEMMMdhmma"` and correct the comment. If the literal separator is wanted, format date and time separately and join them with " · ".

### IN-04: Booking Summary builds two `DateFormatter`s per call and uses fixed patterns

**File:** `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift:388-399`
**Issue:** `formatDateTime` allocates two `DateFormatter`s on every apply or resolution. It uses hard-coded `"MMM d, yyyy"` and `"h:mm a"`, which ignore the device's date style. CLAUDE.md says date formatting goes through `DateUtil` rather than new formatter instances.
**Fix:** Use a shared formatter from `DateUtil`, or cached static formatters set with `setLocalizedDateFormatFromTemplate`.

### IN-05: `ChatItemMapper` repeats the same constructor seven times and can render an event row as a blank bubble

**File:** `ClickMe2026/Utils/ChatItemMapper.swift:33-42, 117-154`
**Issue:**
- `baseBookingEvent` differs between cases only in `icon`, `title` and `isAccepted`. The other seven arguments are copied seven times.
- `chatItem` takes the event path only when `type == .event` and `eventType != nil`. An event row with a nil `eventType` falls through to the message path and renders an empty-body bubble attributed to the peer.

**Fix:** Look up `(icon, title, isAccepted)` in a small `switch` or table and build the `BookingEvent` once. For `type == .event` with a nil `eventType`, return nothing renderable (or a generic row) instead of a message.

### IN-06: Smaller CI and script hygiene items

**File:** `.github/workflows/test.yml:20,35-38`, `scripts/run-smoke-tests.sh:12,36`, `.github/workflows/build.yml:139-143`
**Issue:**
- `test.yml` has no `timeout-minutes` and no `concurrency` group, so superseded PR runs queue for up to the 6-hour default.
- `test.yml` creates an `iPhone 16` simulator while `run-smoke-tests.sh` defaults to `iPhone 17`, so CI and local runs differ.
- `run-smoke-tests.sh` documents `SIMULATOR` as "device name or UDID", but the destination is `name=$SIMULATOR`, so a UDID fails.
- The script checks only `CLICKME_TEST_EMAIL` although its own error text says the password is needed for the happy path.
- `build.yml` uploads the archive only on success. The usual failure point (export) leaves no artifact.

**Fix:** Add `timeout-minutes: 45` and a `concurrency` group to `test.yml`, and align the device name. In the script, choose `id=` or `name=` by pattern, and require the password or document that the happy path is skipped. Add `if: always()` to the artifact upload in `build.yml`, and consider uploading the export logs.

### IN-07: `startChat` treats any HTTP 404 as "expert unavailable", and the second branch is largely redundant

**File:** `ClickMe2026/Views/Screens/Client Mode/Booking Summary/BookingSummaryViewModel.swift:428-434`
**Issue:** The first branch matches on the status code alone, so a 404 from a proxy or a wrong route is shown to the user as "expert unavailable". CLAUDE.md says to branch on `ErrorCode`, not on transport details. The `.notFound` branch only adds the case where the status is not 404, which the contract does not produce.
**Fix:** Use a single branch on `BookingErrorMapper.code(for: error) == .notFound`, and let a bare 404 fall through to `error.userMessage`.

---

_Reviewed: 2026-11-23_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
