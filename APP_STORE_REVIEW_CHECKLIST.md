# ClickMe — App Store Review Checklist

Walk this before every App Store submission. Internal TestFlight uploads only need **Section 1** + **Section 7**; external TestFlight needs 1–3 and 7; full App Store review needs everything.

**Last updated:** 2026-10-17

---

## 1. Build & archive

- [ ] `MARKETING_VERSION` is correct for the release (currently `1.0`)
- [ ] `CURRENT_PROJECT_VERSION` has been **bumped** since the last upload (same version+build = auto-rejection)
- [ ] `Environments.plist` → `Current = Production` for the Archive build
- [ ] `Environments.plist` → `StripePublishableKey` is a real `pk_live_...` key (NOT `pk_live_REPLACE_ME`)
- [ ] `aps-environment = production` in `ClickMe2026.entitlements`
- [ ] `ITSAppUsesNonExemptEncryption = false` in `Info.plist`
- [ ] `PrivacyInfo.xcprivacy` ticked under **Target Membership** → ClickMe2026
- [ ] Release-config build passes: `xcodebuild -configuration Release -sdk iphoneos build CODE_SIGNING_ALLOWED=NO`
- [ ] Scheme runs **Release config** when archiving (Product → Scheme → Edit Scheme → Archive → Build Configuration = Release)
- [ ] Product → Archive succeeds on **"Any iOS Device (arm64)"** destination
- [ ] Organizer → **Validate App** returns no errors AND no warnings about missing icons / entitlements / manifest

---

## 2. App Store Connect metadata

### App Information (one-time setup)
- [ ] Primary Category: **Business**
- [ ] Secondary Category: **Education**
- [ ] Age Rating completed (expect 17+ due to user-to-user chat/calls)
- [ ] Content Rights questionnaire completed

### Version-specific metadata
- [ ] **Subtitle** (≤30 chars): e.g. "Book 1:1 calls with experts"
- [ ] **Promotional Text** (≤170 chars)
- [ ] **Description** (≤4000 chars) matches the current build's features
- [ ] **Keywords** (≤100 chars, comma-separated, no spaces around commas)
- [ ] **What's New in This Version** (release notes, ≤4000 chars)
- [ ] **Support URL** returns `200` on a quick `curl -I` check
- [ ] **Marketing URL** returns `200` (if provided; optional)
- [ ] **Privacy Policy URL** → `https://www.uptrendinvestments.net/clickme/privacy.html` returns `200`
- [ ] **Copyright**: `2026 Uptrend Investments Inc.`

### Media
- [ ] Screenshots uploaded for iPhone **6.9"** (min 3, max 10)
- [ ] Screenshots show real app content (no mockups, no device frames)
- [ ] Status bar in screenshots is clean (9:41 AM, full battery, no carrier text)
- [ ] First 3 screenshots are the strongest conversion assets (shown in search results)
- [ ] App Preview video, if provided, is 15–30s, from the real running app

### Build selection
- [ ] Correct build selected (processing complete, no amber warning badges)
- [ ] Export compliance already filed (`ITSAppUsesNonExemptEncryption = false` handles this automatically)

---

## 3. App Review Information

- [ ] **First / Last Name** / **Phone / Email** filled with reachable contact
- [ ] **Sign-in required = Yes**
- [ ] **Demo Account** credentials provided for BOTH a client and an expert account
- [ ] Demo credentials actually work — tested from a fresh phone 10 minutes before submission
- [ ] Demo accounts have **seeded data** reviewers can see (bookings, chat threads, upcoming session)
- [ ] **Notes** field explains:
  - What ClickMe is (marketplace for live human expert sessions)
  - Why no IAP (real-world services, 3.1.5(a))
  - Stripe test card for the payment flow: `4242 4242 4242 4242`, any future expiry, any CVC
  - How to find account deletion (Settings → Delete Account)
  - Both demo accounts' credentials spelled out
- [ ] **Attachment**: skip for v1

---

## 4. Guideline-specific checks

### Guideline 1.2 — User-Generated Content
- [ ] Report user from a **profile** screen (ellipsis menu → "Report This Profile" → one of 6 reasons → submit → success state)
- [ ] Block user from a **profile** screen (ellipsis menu → "Block") OR from a chat
- [ ] Report / Block NEVER shown when viewing own profile (verify `isSameAsCurrentUser` works)
- [ ] Report user from a **chat** screen (toolbar → "Block or Report")
- [ ] Blocked users can't message you (verify both directions)
- [ ] Suspended/terminated users disappear from Explore (backend handles; nothing to verify client-side)

### Guideline 3.1 — Payments
- [ ] Booking a session uses **Stripe PaymentSheet**, not IAP
- [ ] Reviewer note explicitly cites **3.1.5(a) real-world services** carve-out
- [ ] No in-app language that could be read as "unlocking digital content" or "subscription tier"
- [ ] Expert payouts flow through Stripe Connect (reviewer won't test but documented)

### Guideline 4.0 — Design
- [ ] App is iPhone-only (`TARGETED_DEVICE_FAMILY = 1`) — iPad orientations/scaling not an issue
- [ ] Portrait-only is OK since the app is iPhone-only
- [ ] All screens render on iPhone 16 Pro Max (6.9") — biggest device
- [ ] All screens render on iPhone 13 mini (5.4") — smallest supported, reveals truncation
- [ ] Dynamic Type at Large / Extra Large doesn't clip or hide critical text/CTAs
- [ ] Dark mode works end-to-end (you default to dark; verify no invisible-text crashes if user toggles light)

### Guideline 5.1.1 — Data Collection & Storage
- [ ] **Account deletion** reachable in ≤3 taps from a logged-in state (Settings → Delete Account)
- [ ] Deletion flow actually submits and shows a confirmation screen
- [ ] Deleted accounts can't log back in
- [ ] Privacy manifest declares every data type collected (name, email, phone, photo, audio, UGC, crash, perf, product interaction)
- [ ] Privacy policy URL opens inside the app (Settings → Privacy row → SafariView)
- [ ] App Store Connect "Data Collection" questionnaire matches `PrivacyInfo.xcprivacy`

### Guideline 5.1.5 — Location (if applicable)
- [ ] N/A — ClickMe uses user-entered city/state (coarse); no `CLLocationManager`, no `NSLocationWhenInUseUsageDescription`

### Guideline 2.5.1 — Private APIs
- [ ] No private frameworks (`validate` catches this)
- [ ] No undocumented runtime calls

---

## 5. Functional golden-path tests (do on a real device)

### 5a. Signup → first booking
- [ ] Delete the app from the test phone
- [ ] Install from TestFlight
- [ ] Sign up with a **new email alias** (e.g. `yourname+apple01@...`)
- [ ] Complete email verification
- [ ] Complete / skip expert setup
- [ ] Browse Explore → tap any expert → book a session → pay with Stripe test card `4242 4242 4242 4242`
- [ ] Booking appears in "Upcoming Bookings"

### 5b. Join a scheduled call
- [ ] Seed a booking that starts in the next 5 minutes
- [ ] Tap "Join Session" → Agora voice call connects
- [ ] Both sides can hear each other
- [ ] End call → returns to the bookings list and marks completed

### 5c. Account deletion
- [ ] Settings → Delete Account → fill out reason → confirm → submit
- [ ] Confirmation screen appears
- [ ] Logged out immediately after deletion

### 5d. Report & Block
- [ ] Open an expert's profile → ellipsis → Report This Profile → pick reason + details → Submit → shows "Sent"
- [ ] Open an expert's profile → ellipsis → Block [Name] → confirm action
- [ ] Open a chat → toolbar → Block or Report → verify both actions work
- [ ] Trying to view own profile: ellipsis does NOT appear (`isSameAsCurrentUser` gate)

### 5e. Privacy policy
- [ ] Settings → Privacy row → in-app Safari opens the hosted page

---

## 6. Permission prompts

- [ ] First `Join Session` tap → **microphone** prompt fires with the ClickMe copy ("ClickMe needs microphone access…")
- [ ] Deny microphone → graceful error message, no crash
- [ ] Push permission prompt fires AFTER sign-in, not at splash
- [ ] Deny push → app continues to work normally (no crash, no reduced-function message)
- [ ] **Camera prompt should NEVER fire** — if it does, something linked AVCaptureDevice.video incorrectly

---

## 7. Negative-path tests

- [ ] Airplane mode → open any fetching screen → retry UI, not white screen
- [ ] Background the app for 15+ minutes → return → confirm the token refresh flow silently re-auths
- [ ] Logout → login again → user's bookings/chats/favorites still there
- [ ] Stripe `4000 0000 0000 0002` (card declined) → friendly error, not raw Stripe JSON
- [ ] Stripe `4000 0025 0000 3155` (3DS challenge) → challenge completes end-to-end
- [ ] Try to book a session with yourself → blocked client-side AND server-side (`CANNOT_BOOK_SELF`)
- [ ] Suspended-account 403 on any authed request → clears tokens + logs out silently (verify `UserManager.wasSuspended` flag flips)

---

## 8. Backend contract spot-checks

- [ ] `POST /auth/signup` body: `{ email, password, role }` — NO `username` field (per `SIGNUP-USERNAME-OPTIONAL.md`)
- [ ] `POST /auth/login` 401 shows "Invalid email or password" (server-provided, not hardcoded)
- [ ] `POST /auth/login` 422 shows email-field inline error, not a top alert
- [ ] `POST /users/:id/report` wired on profile report (per `USER-REPORTING.md`)
- [ ] Upcoming-bookings cards show `earnings_breakdown.net_amount` per fee-source branches (per `EXPERT-EARNINGS-BREAKDOWN.md`)

---

## 9. First-rejection recovery

Most common rejection reasons for apps in ClickMe's category:

| Reason | Fix |
|---|---|
| "Account deletion not reachable" | Verify Section 5c; add Settings link clarity to reviewer notes |
| "Report/block not reachable from UGC surface" | Verify Section 5d |
| "Payments bypass IAP" | Reviewer note must cite 3.1.5(a) real-world services exemption |
| "Demo account credentials don't work" | Re-verify from a fresh phone BEFORE resubmitting |
| "Privacy policy URL 404s" | `curl -I` the exact URL; redirect to a working page |
| "Camera purpose string missing" | `NSCameraUsageDescription` already set — if flagged, Apple's scanner found a new linked API |

Fix the specific issue, bump `CURRENT_PROJECT_VERSION`, upload a new build, resubmit. Second-attempt rejections for marketplace apps are rare once the above are solid.

---

## 10. 60-minute minimum (when you're in a hurry)

If you only have one hour before submission, do these in order:

1. Section 5a (fresh install → signup → booking)
2. Section 5b (join call)
3. Section 5d (report & block)
4. Section 5c (account deletion)
5. Section 3 (demo credentials actually work)
6. Section 1 (validate app in Organizer)

Everything else is polish that may or may not matter in your specific review.
