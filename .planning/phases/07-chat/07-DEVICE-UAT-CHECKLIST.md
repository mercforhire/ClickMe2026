# Phase 7 Device UAT Checklist

Every device check Phase 7 (Chat) left open, in one list, plus the planner and UI-SPEC assumptions you are asked to judge. Built by plan 07-08 from every `07-0[1-7]-SUMMARY.md`, the `<human-check>` blocks in plans 07-01 to 07-07, the "Device-only checks" and "UI Considerations" tables in `07-UI-SPEC.md`, and the "Manual-Only Verifications" table in `07-VALIDATION.md`. All code is merged and unit-tested; nothing on this list has been seen on a device yet. Claude runs only local tests and builds: every step on a device or against production is yours.

## Automated evidence

Run by plan 07-08 on 2026-11-18 at HEAD `003aff8` (the last Phase 7 app commit is `7452bc0`; every later Phase 7 commit is tests or docs), simulator `iPhone 17`, Debug:

- **Phase gate suite (the full unit suite in one xcodebuild invocation, smoke suites and the known flake skipped):** `✔ Test run with 1168 tests in 107 suites passed after 8.784 seconds.` and `** TEST SUCCEEDED **` (log `/tmp/07-08-full.log`). Skipped: `AuthSmokeTests` and `SignupSmokeTests` hit production and were not run; `MakeABookingAvailabilityTests` is the known flaky suite (todo `2026-11-13-flaky-make-a-booking-availability-test.md`) and was run separately below. `LoginTests` is compiled and run in this invocation (it passes; the old STATE.md concern that it does not compile was fixed by `be79868`). This run includes every Phase 7 stubbed `.serialized` suite alongside the others.
- **Known-flaky record run (`MakeABookingAvailabilityTests` alone, not part of the verdict):** run 1 passed: `✔ Test run with 5 tests in 1 suite passed after 0.724 seconds.` and `** TEST SUCCEEDED **`; no second run was needed. No Phase 7 commit touches the Make a Booking folder or its test file (0 commits in `16fe88e..HEAD`). Log `/tmp/07-08-flaky-1.log`; the outcome is appended to the todo.
- **Debug build:** `** BUILD SUCCEEDED **`; the only `warning:` line in the log is the build system's own "Metadata extraction skipped. No AppIntents.framework dependency found." (log `/tmp/07-08-build.log`).
- **Grep gates (all PASS; comment lines filtered out of every whole-tree count):**
  - no block copy claiming profile or booking hiding (`your profile`, `appointment`) in the Chat screens, `ExpertProfileView.swift` or `ExpertProfileBlockViewModel.swift`: 0 matches (3 at the base);
  - no `unblockDenied` latch in `ClickMe2026`: 0 code lines (7 at the base);
  - no `ReportThreadIdentifier` sheet identifier in `ClickMe2026`: 0 code lines (3 at the base);
  - no `print(`, `NSLog`, `os_log` or `Logger(` in the Chat screens, `ChatThreadReducer`, `ChatItemMapper`, `ChatBlockState`, `ChatThreadLookup`, `ChatComposerRules`, `ChatUnreadRules` or `ExpertProfileBlockViewModel`: 0 matches;
  - no `try? await` on `sendChatMessage`, `chatAction` or `initiateChat` in those Phase 7 surfaces plus `ExpertProfileView.swift`: 0 matches (the 5 whole-tree hits outside Phase 7 are out of scope and unchanged);
  - no `items.insert(contentsOf` in `ChattingViewModel.swift` outside comments: 0 (1 at the base);
  - no `Spam or scam` in the Chat screens: 0 (1 at the base);
  - no `UserDefaults`, `FileManager` or `Valet` in `ChattingViewModel.swift`, `ChatSendCoordinator.swift` or `ChatThreadReducer.swift`: 0;
  - no `message.contains`, `message.hasPrefix` or `localizedCaseInsensitiveContains` in `ChattingViewModel.swift`, `ReportChatViewModel.swift` or `ExpertProfileBlockViewModel.swift`: 0;
  - no `.badge(` in `ClickMe2026` outside comments: 0 (D-15);
  - the `toolbarColorScheme(.dark, for: .navigationBar)` pin appears once in `ChattingView.swift` and once in `ReportChatView.swift`.
- **D-17 Read-handler guard:** `ChattingViewModel.handleMessageRead(_:)` is byte-identical to the phase base `16fe88e` (13-line extract compared with `cmp`, PASS). No Phase 7 plan edited the sender-side Read handler.
- **View-model size ceiling:** `ChattingViewModel.swift` is 624 lines, at the ceiling of 624 (its length at the phase base `16fe88e`). Where the new logic went: `ChatSendCoordinator.swift` 123 lines, `ChatItemMapper.swift` 182 lines, `ChatBlockState.swift` 224 lines.
- **Backend and Android:** Phase 7 made no backend change and no Android change (07-RESEARCH "Android parity").
- **What the automation does not cover:** every item below.

---

## Items

(Filled in by Task 2 of plan 07-08.)
