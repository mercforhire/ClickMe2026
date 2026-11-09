---
quick_id: 261108-vrh
status: complete
date: 2026-11-08
commit: 30ca4a9
key-files:
  modified:
    - ClickMe2026/Managers/UserManager.swift
---

# Quick Task 261108-vrh: Prompt for push permission on every signed-in launch

**Code is committed on local `main` and not pushed. It is not in any released build, and the device check below has not been run on this code.**

## The bug

iOS resets notification permission when an app is deleted, but the Valet keychain session survives. After a reinstall the app auto-logged in through `tryAutoLogin`, which only re-registered when permission was already granted. Only manual login and signup prompted, so the user was never asked and got no pushes.

Seen on a real iPhone on TestFlight build 6 on 2026-11-08:

- After a delete and reinstall, the app stayed signed in with no prompt, and test pushes accepted by Firebase did not arrive.
- After logging out and back in, the prompt appeared, the user allowed it, and the FCM token changed.
- A test push to the new token arrived.

The first missed push (booking `b9dee53d`) came before that reinstall. This bug only explains it if the older copy was deleted before TestFlight was first installed, which the user did not confirm.

## The change

- `tryAutoLogin` runs `requestPushPermissionIfNeeded()` and `fetchAndUploadFCMToken()` after the auth outcome is known, on both the `/me` success path and the transient-failure path.
- A rejected token still logs out and returns `false`.
- The calls are guarded by `hasStoredToken`, because a 403 `ACCOUNT_SUSPENDED` logs out and then lands in the transient path. `isLoggedIn` can't be used, because `me` is nil on the transient path for a user who is still signed in.
- `reRegisterPushIfAuthorized()` was dead code after this and is removed. Stale doc comments are updated.

No FCM token code was needed: after a grant, `didRegister...` sets `Messaging.apnsToken`, `MessagingDelegate` calls `registerPushToken`, and `hasStoredToken` is true by then. That comes from reading the code, not from a run on this change.

## Verification

| Check | Result |
|-------|--------|
| Debug `xcodebuild`, iPhone 17 simulator, at baseline | `BUILD SUCCEEDED` |
| Same build after the change | `BUILD SUCCEEDED` |
| Plan's four source checks | Pass |
| `UserManager.swift` warnings, before and after | Same one warning (`describe` main-actor call), none new |
| Unit tests | None added and the suite was not run |
| Device check on a real iPhone | **Not run on this code** |

The warning comparison covers `UserManager.swift` only, as the plan specified. No unit tests were added because `UserManager` has a private init and uses the real API singleton, keychain and `UNUserNotificationCenter`, so a test seam would be larger than the fix.

**Device check still needed:** install a build containing this commit, delete the app, reinstall, open it signed in, confirm the prompt appears, allow it and confirm a test push arrives. Reopen the app and confirm there is no second prompt.

## Deviations

- The executor refused to commit on `main` (`git.allow_default_branch_commits` is not set). The user chose to commit on `main` for this fix, the orchestrator made the commit, and the setting was not changed.
- The workflow's worktree isolation degraded to sequential because local `main` is ahead of `origin`.

## Left alone

- A suspended cold launch still returns `true` from `tryAutoLogin`, so it appears to route to the dashboard with the token cleared. Nothing outside `UserManager` reads `wasSuspended`, so the suspension message appears never to show. This came from reading the code, and it needs its own fix.
- `scripts/run-smoke-tests.sh` defaults to `ClickMe2026.xcodeproj`, which does not exist. The project is `ClickMe.xcodeproj`.
- Android follow-up: `PushPermissionRequester.kt` prompts once after a login or signup, using a persisted flag, so it may have a similar gap. Whether it does depends on whether its session and flag survive a reinstall, which was not checked.
