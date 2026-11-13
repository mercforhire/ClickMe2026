---
created: 2026-11-13T00:00:00.000Z
title: Android remember-login-email: port branch 0c9ecc55 the way iOS ported b0629d9 (D-16)
area: auth
severity: low
files:
  - ClickMe_Android (branch feature/remember-login-email, commit 0c9ecc55)
  - ClickMe2026/Managers/UserManager.swift
  - ClickMe2026/Views/Screens/Login Flow/Login/LoginViewModel.swift
  - ClickMe2026/Views/Screens/Settings/Delete account/DeleteAccountViewModel.swift
  - ClickMe2026Tests/Auth/RememberedLoginEmailTests.swift
---

## Problem

iOS now pre-fills the Login email field with the last signed-in email after any sign-out (Phase 5, plan 05-01, T8, D-14). Android has the same feature written but not merged: commit `0c9ecc55` ("feat(login): pre-fill the last email after sign-out", 2026-11-05) on the local Android branch `feature/remember-login-email`, which is not on the default branch. Until it is merged, the two apps behave differently after a sign-out.

iOS did not merge its own equivalent branch (`feature/remember-login-email`, `b0629d9`, 407 commits behind main with conflicts in `UserManager`). Plan 05-01 ported it by hand onto current main. Do the same on Android: read `0c9ecc55`, port it onto the current Android default branch, and do not merge the old branch.

## What to do

Match the iOS behavior (05-UI-SPEC section 7, Login: remembered email):

- Pre-fill the email after any sign-out path (Log Out, forced logout, suspension, a rejected refresh). The password field is always empty. An explicit email passed in (password-reset flow) wins over the remembered one. The field stays editable.
- Remember the email only after a successful login or signup, trimmed; ignore an empty or whitespace-only value.
- Forget it after a successful account deletion. A failed deletion keeps it.
- Never store the password. Use encrypted storage (the Keystore-backed store Android already uses for tokens), never plain preferences, and never log the value.
- Tests: remembers a trimmed email, ignores whitespace-only, pre-fill after sign-out, explicit email wins, deletion forgets, failed deletion keeps. The iOS suite is `ClickMe2026Tests/Auth/RememberedLoginEmailTests.swift` (8 tests).

Verify on an Android device: sign in, sign out, the email is filled and the password is empty; delete a throwaway account, the field is empty.
