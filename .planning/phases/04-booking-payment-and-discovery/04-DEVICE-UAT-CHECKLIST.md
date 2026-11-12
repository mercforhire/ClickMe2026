# Phase 4 Device UAT Checklist

Every device check Phase 4 (booking, payment and discovery) left open, in one list, plus the D-11 real-money session and the D-14 Android check. Built by plan 04-14 from every `04-*-SUMMARY.md`, the UI-SPEC backstops (T1 to T4, D1 to D4, L5), the planner assumptions K1, K3, K4 and K5, and the "Manual-Only Verifications" table in `04-VALIDATION.md`. Where a SUMMARY recorded a deviation or a superseded wording, the SUMMARY's wording is used and the item says so. All code is merged and unit-tested; nothing on this list has been seen on a device yet. Claude runs only local tests and builds: every production step (the migration check, holds, Stripe Dashboard and Supabase queries) is yours.

## Setup

- **Device:** a real iPhone on iOS 18 or later, not the simulator. Stripe's sheet, 3-D Secure, gestures, push and the 12/24-hour setting need hardware.
- **Build:** a build at or after `c6c3470` (plan 04-12), the last Phase 4 commit that touched app code. Every later Phase 4 commit is docs only.
- **Backend:** production (`https://clickme-backend-production.up.railway.app/api/v1`) with **live Stripe**. Every environment in `Environments.plist` points there, so each paid booking places a real authorization hold.
- **Backend deploy state (plan 04-01):** D-12 is live as backend commit `ae3ec1abcd0bbe9a298ed9f2e2a4a3c2c9eaa45d` (short `ae3ec1a`), pushed by you on 2026-11-12 as the only commit past the rollback base `32fa6ecd97a47409c5e7bf4f730b803f7b2fd7e5` (local backend branch `ios-p4-d12-rollback`; rollback is Railway's redeploy of the previous deployment, or a revert through the same gated route, never a force-push). Production `/health` reported `ae3ec1a`. You also reported the live platform webhook endpoint subscribed to `payment_method.detached`; that is **your report, not independently verified**, and step f of the D-11 session is the first real proof. Backend `master` does **not** contain D-12 (todo `.planning/todos/pending/2026-11-11-merge-d12-into-backend-master.md`). Before the session, `/health` must report a commit that contains `ae3ec1a` (`git merge-base --is-ancestor ae3ec1a <the /health sha>` in the backend repo).
- **Accounts:** client account **A** and expert account **B**, both yours. B needs a **paid CAD topic priced with cents** (for example 12.50, the cheapest you have), and A needs a **saved real card** for the payment items. B also needs a **free topic** for the Explore items.
- **Second device:** another phone (Android is fine) for the D-14 reinstall check and for the second side of the 01-17 and 01-19 checklists.
- **Stripe Dashboard and Supabase SQL editor:** open and signed in. The only Dashboard actions this checklist allows are looking and, where a step says so, cancelling an **uncaptured** payment. Never click Capture or Refund.
- **Recording results:** fill the `Result:` line of each item with `PASS`, `FAIL (what happened)` or `SKIPPED (why)`, and the date. Do not write a `pm_` id, a client secret, an ephemeral key or a card number anywhere in this file; for a PaymentIntent write only the last six characters of its `pi_` id.

## Notes before you start

- **Phase 2's and Phase 3's UAT are still partial.** `02-DEVICE-UAT-CHECKLIST.md` and `03-DEVICE-UAT-CHECKLIST.md` have items nobody has run, and they must run before Phase 8. Several Phase 4 changes touch the screens they cover (Request Sent, slot times, Favorites), so run them on the same build.
- **Six requirements stay Pending until their items pass:** BACK-06, BACK-07, BACK-15 and BACK-19 (the D-11 session) and EXPL-03 and EXPL-07 (items 1 and 2). Nothing in this plan, and nothing you write in this file, ticks a box in `REQUIREMENTS.md`; closing them is a `/gsd-verify-work 04` decision after the Results are filled in.
- **D-12 deploy SHA and rollback target:** `ae3ec1a`, rollback base `32fa6ec` (see Setup). The Dashboard subscription to `payment_method.detached` is your report and is first proved by D-11 step f.
- **Planner assumptions for you to judge (K1, K3, K4, K5).** UI-SPEC left four states unresolved and the plans built the recommended answer. Items 16 to 19 each name the assumption and ask for a `KEEP` or `CHANGE (what)` in Result.
- **EXPL-02 decision record (plan 04-12, Task 2).** Question: confirm the empty-section bug on a device first, or fix from the code evidence. Answer: `fix-now` (your reply, 2026-11-12). Evidence used: the three section views draw their headers for empty input, and a chat-opened profile is seeded with `expertiseTags: []` while the details response has no profile-level tags (RESEARCH Open Question 5, A9). Consequence: the fix shipped without a device or build confirming the bug first; EXPL-02 is **not** closed as not-reproducible, and item 10 is the before/after check.
- **The 120 s request timeout was not changed (plan 04-08).** Three attempts against a black-holed network can take about six minutes. Airplane mode fails in milliseconds, so use airplane mode for every forced failure below.
- **An open decision still applies to D-11 steps c to e (01-13, 01-17 stop condition S2).** If a paid confirm fails and no replay finds a booking, the authorized PaymentIntent is **not** voided by the backend, and no booking links to it, so the app cannot release it. It stays until Stripe's authorization lapses or you cancel it in the Dashboard. STATE.md lists this as an open Phase 4 decision. The D-11 section has a stop condition for it; watch for it after every forced failure.
- **01-17 and 01-19 are run as written, on a newer build.** They were written for App Store build 6 and the current Android build, and their rollback SHAs (`ddfe5bf`, `d356fdc`) are out of date: production is now at `ae3ec1a`. Do not use those SHAs. If a stop condition there says to roll back, stop and tell Claude instead.
- **Items marked *optional* are covered by unit tests** and may be skipped. Items that need data you do not have (more than 20 favorites, an expert with more than 20 reviews, a suspended account) are `SKIPPED (why)`, not a pass.

---

## Items

### 1. EXPL-07 — Explore loads with a free no-currency topic, one bad topic and a failed load (quick 261109-323)

**Status:** PENDING. EXPL-07 stays Pending in `REQUIREMENTS.md` until this item passes.

Precondition (yours to run; Claude does not touch production): **migration `20261109000000_home_feed_null_hourly_rate.sql` is applied in production.** Whether it is applied is unknown (RESEARCH A8). Check it in the Supabase dashboard migration history, or run `supabase migration list` in the backend repo, or run this read-only query in the SQL editor, which must return `true`:

```sql
SELECT pg_get_functiondef('home_feed(uuid,text[],int)'::regprocedure) LIKE '%ft.price_currency IS NULL%';
```

Write the answer in Result. If the migration is **not** applied, a free topic with no currency can still fail the whole Explore load on this build's backend data, and a failure here is the migration, not the app: apply the migration (a separate decision, safe to run before or after any push per the quick task) and rerun.

Steps:
1. As A, open Explore and let it load. Pull to refresh and reopen the app at least ten times: Featured Topics are chosen at random on each request, so a free topic with no currency and a topic with a non-ASCII title (accents, a non-Latin script) only show up some of the time. If B has no such topics, B can create a free topic (price left empty) and one with an accented or non-Latin title; delete them afterward if you do not want them.
2. Look at Trending Categories, Featured Experts and Featured Topics each time.
3. Turn airplane mode on, pull to refresh Explore (or relaunch), read the text, then turn airplane mode off and pull to refresh again.

Expected (quick 261109-323 and the EXPL-07 requirement text):
- Explore loads every time; a free topic with no currency never fails the whole load, and a non-ASCII title renders as written, with no garbled characters and no decode failure.
- A bad featured topic is dropped alone: the rest of Featured Topics, Trending Categories and Featured Experts still show.
- The airplane-mode failure shows a readable sentence (not a Swift type name or a raw error dump), and **no stale Featured Topics sit beside the section error**. After airplane mode is off, a pull to refresh loads normally.
- Empty edge (unit-tested only: `ClientHomeFeedTests` rows "an absent featured_topics decodes to nil", "a null featured_topics decodes to nil", "an array where every topic is bad gives an empty, loaded section"): a home feed with no featured topics loads Explore with an empty, loaded Featured Topics section, not an error. You cannot force this on production data; leave it unmarked unless you see it.
- *Optional, only if you want the before picture:* the App Store build 6 on another phone stops failing once the migration is applied and shows "—" instead of "Free" for these topics (it gains the label only with the new build).

Result:

### 2. EXPL-03 — Free label on featured topic cards (quick 261109-323)

**Status:** PENDING. EXPL-03 stays Pending in `REQUIREMENTS.md` until this item passes. Can run together with item 1.

Steps:
1. On Explore, find a **free** featured topic card (reload until one shows) and a **paid** one (B's CAD topic priced with cents, for example 12.50).
2. Read the price line on each.

Expected:
- The free card reads **Free**.
- The paid card shows the price through `Money` formatting with its cents, for example `CA$12.50`; never `CA$12`, `$12` or `CAD 12`.
- A paid topic with a missing currency shows "—" and never an invented currency (unit-tested row in `ClientHomeFeedTests`; you cannot create one from the app, so leave it unmarked unless you see it).

Result:

### 3. BOOK-01 / BOOK-19 / D2 — Request Sent has no Back and no swipe, and both exits reset the source tab (04-03, 04-10)

**Status:** PENDING (WINDOWS.md #23). No money needed: use B's **free** topic and cancel the free bookings afterward.

Steps: make one free booking from each of the five places a booking can start, one booking per place, each in a different slot:
1. **Explore** (an expert card or Featured Topic).
2. **Search** (search for B).
3. **Profile > Favorite Experts** (B must be a favorite) > B > book.
4. **Bookings** (Book Again on a past or cancelled booking with B).
5. **Chats** (open a chat with B > View Profile > book).

On each Request Sent screen:
- Look for a Back button, then try the **edge swipe** (from the left edge) and, on iOS 26, a swipe from the content area.
- Tap **Back to Home** on two of them and **View My Bookings** on the other three. After each, go back to the tab you started from.
- Afterwards open any other screen (an expert profile, a booking) and swipe back to confirm swipe-back still works elsewhere.

Expected (UI-SPEC section 3 and 4):
- The navigation title stays "Booking Request". There is **no Back button** and **neither swipe pops** the screen.
- **Back to Home**: Explore is shown and the source tab's stack is reset. **View My Bookings**: the Bookings tab is shown, with the source tab reset too. Returning to the source tab shows its root, never the Make a Booking form or Request Sent.
- Swipe-back works again on other screens.
- VoiceOver (optional): there is no Back control, and the two exit buttons are normal buttons.

Result:

### 4. BOOK-05 / L1 / E1 — "Loading booking…" and the Request Sent load error keep both exits (04-03)

**Status:** PENDING (WINDOWS.md #24).

Steps:
1. Settings > Developer > Network Link Conditioner (or any equivalent): choose a very slow profile, then make a free booking. Watch Request Sent while it loads.
2. Switch the profile to **100% Loss** before the load finishes, so the detail request fails. If you cannot land the error state, write `SKIPPED (why)`.
3. Turn the network back on and tap Retry.

Expected:
- While loading: the spinner and **Loading booking…** (not "Sending your booking…"), with **View My Bookings** and **Back to Home** pinned to the bottom, so a stuck load never traps you.
- On failure: the "Couldn't load your booking" error with **Retry**, and the same two exits pinned.
- Retry loads the screen; the entry animation runs only after the copy has loaded.

Result:

### 5. BOOK-02 / T2 / T3 — month changes never show another month's slots, and the failed and empty states keep their copy (04-04)

**Status:** PENDING (WINDOWS.md #25).

Steps, on Make a Booking for B's topic:
1. Tap the next-month and previous-month controls several times, quickly, then stop.
2. Pick a day with slots, then a day with none, then a month with none.
3. Turn airplane mode on and change the month; turn it off and change the month again.

Expected:
- While a month loads the slots card shows its **skeleton row** and never the previous month's slots. After a burst of taps, the slots always match the month shown.
- (T3) A day or month with no slots shows the existing empty copy.
- (T2) A failed month load shows the existing failure copy, and the next month change reloads. Both are unchanged by Phase 4.

Result:

### 6. BOOK-03 / D-18 — the device's time zone is named in words on the slots card and on Today's Sessions (04-04)

**Status:** PENDING (WINDOWS.md #25).

Steps:
1. Open Make a Booking and read the label beside **Available Time Slots**.
2. Go to Explore and read the label beside the **Today's Sessions** title (it needs a booking today; B can create a free one, or skip the title check with a note).
3. Use an expert whose profile zone differs from the phone's (or temporarily set the phone to another zone in Settings > General > Date & Time, then relaunch the app) and read both labels again.
4. At the largest Dynamic Type, read both labels.

Expected (UI-SPEC "Make a Booking: slots", K2, D-18):
- Both labels show the **device** zone's localized generic name, for example `Eastern Time`, and they match each other.
- Never the raw id (`America/Toronto`) and never the expert's zone. The chip times are in the same device zone.
- The labels may wrap onto a second line and are never cut off with an ellipsis. If the zone has no localized name the label is omitted (cannot be forced; leave unmarked).
- If a zone change shows only after a relaunch, write that in Result; it is not a failure.
- Put the phone back on Set Automatically when you finish.

Result:

### 7. BOOK-04 / T1 / T4 — slot times follow the 12/24-hour setting, live, and many slots stay readable (04-04)

**Status:** PENDING (WINDOWS.md #25).

Steps:
1. Settings > General > Date & Time > turn **24-Hour Time** on. Look at the slot chips on Make a Booking, the Today's Sessions time range on Explore, the Reschedule picker (open it on a **free** booking and leave without sending anything), and Request Sent.
2. Leave the app running in the background, turn 24-Hour Time **off**, and come back. Look at the same places without relaunching.
3. (T4) Pick a day with many slots, with 24-Hour Time on and again at the largest Dynamic Type.

Expected:
- 24-hour: `14:00` style on all four. 12-hour: `2:00 PM` style.
- (T1) The toggle shows up on the next render without a relaunch. If it only shows after a relaunch, write FAIL with that detail (assumption A3).
- (T4) Chips size to their text, wrap into the existing grid, and do not clip `12:30 PM` at the largest size.
- Request Sent uses the same style as the chips (see item 17, K3).

Result:

### 8. PAY-03 / D3 — a new paid booking's Request Sent shows the "hold is placed" card (04-09)

**Status:** PENDING (WINDOWS.md #30). Run inside D-11 step b and write the result in both places. Needs a live hold.

Steps: complete a paid booking (D-11 step b) and read the payment card under the booking details. Then make a free booking and check that card is absent.

Expected (UI-SPEC variant A):
- Header **What happens next**, step 1 **A hold is placed on your card** / `No charge yet — funds are just reserved.`, step 2 **Your session runs on {when}** / `You can join the call from My Bookings.`, step 3 **Your card is charged after the session** / `Usually within 15 minutes of the session ending.`
- No amount on the card. A free booking shows **no** payment card.
- Variants B (charge scheduled) and C (already charged), and the hidden "held with no live expiry" row, are reachable only for older or converted rows. They are covered by unit tests and previews, not by a device step.

Result:

### 9. EXPL-01 / L3 / E3 — expert profile load errors: network failure retries, a missing expert says so (04-05)

**Status:** PENDING (WINDOWS.md #26).

Steps:
1. Turn airplane mode on and open an expert profile you have not opened yet (a Search or Explore card). Read the screen, then turn airplane mode off and tap **Retry**.
2. Open a favorited expert's profile and look at the heart.
3. *Optional:* if you have a Favorites row or chat for an expert who is deleted or suspended, open it. You cannot create this case on production, so otherwise leave it unmarked (unit-tested in `ExpertProfileViewModelTests`).

Expected:
- (E3, network) **Couldn't load profile**, the error message, an accent **Retry**, and **no heart or overflow menu** in the toolbar. Retry swaps the capsule for a small spinner in place (L3), keeps the state view up, then shows the profile. A failed retry returns the state view.
- (E3, 404) **This profile isn't available** / `This expert may no longer be on ClickMe. Go back and try someone else.` with a single **Back** that pops one level, no Retry, and no heart or menu.
- The heart is filled for a favorited expert, taken from the details response. It makes no `/client/favorites` call on open (not visible on a device; unit-tested).
- The seeded profile may flash before a 404 (see item 19, K5).

Result:

### 10. EXPL-02 — empty Expertise, Topics and Reviews sections are hidden, and the hero reads "No reviews yet" (04-12)

**Status:** PENDING (WINDOWS.md #35). The fix shipped from code evidence, not from a confirmed device repro (see the decision record in the notes above), so this is the first look. A before picture needs the App Store build 6 on another phone.

Steps:
1. **Before (App Store build, optional but the only way to confirm the original bug):** chat with an expert who has no reviews, tap **View Profile**, and note whether a bare **Expertise** or **Recent Reviews** header, an empty card, or `0.0 (0 reviews)` shows.
2. **After (this build):** open the same profile the same way.
3. Open an expert with exactly one review, then one with two or more.
4. At the largest Dynamic Type, look at the hero rating row and the shortened scroll.

Expected:
- No Expertise header when there are no tags, no empty Topics card, no empty Recent Reviews card, and **no blank gap** where they were. About and the stats bar are unchanged.
- Zero reviews: the hero reads **No reviews yet** with no star glyph and no `0.0`. One review: `{rating} (1 review)`. Two or more: `{rating} ({n} reviews)`. While the summary has not loaded: `— (— reviews)`.
- The rating keeps one decimal, printf style, so a rating of exactly 4.25 reads `4.2`. Android's tie rounding was not checked; a 0.1 difference on an exact tie is known and not a failure.
- A chat-opened profile shows no Expertise at all, because the details response has no profile-level tags. Deriving them is a logged follow-up, not a Phase 4 defect.

Result:

### 11. EXPL-04 / LT1 — search tag pills show their whole text (04-11)

**Status:** PENDING (WINDOWS.md #33).

Steps:
1. Give B (or any expert) a topic with a **60-character tag** and a **non-Latin tag**, then search for that expert.
2. Look at the pills on the result card, at the normal size and at the largest Dynamic Type.
3. Look at the Favorites chips and the topic setup chips (expert mode, topic editor).

Expected:
- Every pill shows its **full text with no ellipsis**. At most three pills show. A pill that does not fit moves to the next line; a pill wider than the row wraps its text inside the pill (12 pt rounded shape).
- Favorites chips and the expert topic setup chips look the way they did before (they share the same wrapping layout, and a unit test pins that fitting chips are placed as before).

Result:

### 12. EXPL-05 / D-07 / D-08 / D-09 — Favorites paging, refresh, empty buttons, Pro Tip and the heart (04-06, 04-10, 04-12)

**Status:** PENDING (WINDOWS.md #27, #31, #35).

Steps:
1. **Paging** (needs more than 20 favorites; favorite more experts from Search if you must, or write `SKIPPED (why)`): scroll Profile > Favorite Experts to the end.
2. Turn airplane mode on before the next page loads. Read the footer, then turn the network back on and tap **Retry**.
3. Pull to refresh. Then unfavorite a row and scroll to the end again.
4. **Empty state** (an account with no favorites, or remove them all after step 3): read the Pro Tip, tap **Explore Experts**, return, then tap **View My History**.
5. **Heart seed:** open a profile from Favorites, and open the same expert from Search.

Expected:
- A centered spinner under the last row while the next page loads, then the rest appear with **no repeats** and **nothing** shown at the end.
- A failed later page shows **Couldn't load more favorites** with a 44 pt **Retry**; the loaded rows stay; Retry after the network is back appends the page.
- Pull to refresh restarts at page 1. After an unfavorite the list reloads from page 1 at the next scroll to the end, and **no favorite is skipped**.
- The Pro Tip reads `Tap the heart icon on any expert's profile to add them to this list instantly.` (it said "star" before).
- **Explore Experts** opens Explore and leaves Profile at its root. **View My History** opens Bookings on the **Past** segment and leaves Profile at its root.
- The profile opened from Favorites has a **filled heart from the first frame**. The same expert opened from Search starts empty and fills when the profile loads.

Result:

### 13. EXPL-06 — the full reviews list pages past 20 (04-11)

**Status:** PENDING (WINDOWS.md #32).

Steps: open an expert with more than 20 reviews (if none exists, write `SKIPPED (why)`), open the full reviews list, scroll to the end, then turn airplane mode on before the next page, read the footer, restore the network and tap Retry. Pull to refresh while offline.

Expected:
- Every review is reachable, with a spinner footer while loading, no repeats, and nothing at the end.
- A failed later page shows **Couldn't load more reviews** and a 44 pt **Retry**; loaded rows stay; Retry appends the page.
- A pull to refresh while offline keeps the rows and shows no alert.
- An expert with no reviews still shows the existing "No reviews yet" view.

Result:

### 14. D-13 / D4 — a suspended account lands on Login with the suspension alert on a cold launch (04-07)

**Status:** PENDING for the **Phase 8 release pass**, not this session. It needs a suspended account, which production does not give you safely. Unit-tested (`AutoLoginOutcomeTests`, `SuspensionNoticeTests`). WINDOWS.md #28.

Steps (for the release pass): force-quit the app on a suspended account's session and relaunch.

Expected:
- The splash routes straight to **Login**, with no home screen flashing first.
- The alert **Your account has been suspended** / `You can't use ClickMe with this account right now. If you think this is a mistake, contact clickmeapp@uptrendinvestments.net.` shows once, with **Close Alert**. Dismissing it clears the flag, so a later fresh sign-in does not show it again.
- Android already does this; its button reads `OK`, which is a logged copy difference, not aligned.

Result: PENDING (Phase 8 release pass)

### 15. L5 — every new state view, status line, footer, alert and wrapped pill reads correctly at the largest Dynamic Type

**Status:** PENDING (WINDOWS.md #33 and the UI-SPEC L5 backstop).

Steps: Settings > Accessibility > Display & Text Size > Larger Text > Larger Accessibility Sizes, drag to the maximum. Visit each block that Phase 4 added or changed:
- the `Confirming your booking…` line and the `We couldn't confirm your booking` and `Couldn't book` alerts (D-11 steps c to e show them);
- Request Sent in the loading, error and loaded states, with the pinned exits;
- the expert profile `Couldn't load profile` and `This profile isn't available` state views, and the hero rating row;
- the Favorites and Reviews paging footers and the Pro Tip;
- the wrapped search pills (item 11) and both zone labels (item 6).

Expected: every block wraps and none is cut off or overlaps; no new block uses a fixed height; the 44 pt and 48 pt controls keep at least that height; nothing needs a horizontal scroll.

Result:

### 16. K1 — Request Sent's status pill stays "Awaiting Approval" (judgment)

**Status:** PENDING. Planner assumption K1 (UI-SPEC): leave the pill as it is. The alternative is the Phase 3 status mapping.

What to look at: the pill on Request Sent after a normal booking, and after the replayed confirm in D-11 steps c and d. A replay can return a booking whose status has already moved (for example the expert accepted before the retry landed), so the pill could be stale. The window is the confirm timeout, so you will probably only see it as a thought experiment.

Judge: is a pill that always reads **Awaiting Approval** acceptable on this screen? Write `KEEP` or `CHANGE (what)` in Result.

Result:

### 17. K3 — Request Sent uses the same short time style as the slot chips (judgment)

**Status:** PENDING. Planner assumption K3 (UI-SPEC): apply the short time style to Request Sent's date and time so a 24-hour user does not see `14:00` on the chip and `2:00 PM` on the confirmation. Plan 04-04 built that: both Request Sent strings use the shared `DateUtil` helper.

What to look at: with 24-Hour Time on, the chip on Make a Booking and both times on Request Sent (item 7): the details card (`Oct 24, 2023 | 14:00 - 15:00`) and step 2 of the payment card (`Oct 24 · 14:00`). The date parts keep their existing forms; only the time follows the 12/24-hour setting.

Judge: does the confirmation read consistently with the chip? Write `KEEP` or `CHANGE (what)` in Result.

Result:

### 18. K4 — the slot is cleared after "You may already have this booking" (judgment)

**Status:** PENDING. Planner assumption K4 (UI-SPEC): after the D-04 alert the slot selection is cleared and a fresh attempt id is made, as for every `SLOT_UNAVAILABLE`, so a taken slot cannot be resubmitted (plan 04-13).

What to look at: if the alert **Couldn't book** / `You may already have this booking. Check My Bookings.` (buttons **Check My Bookings** and **Close Alert**) ever shows during D-11 steps c to e, look at the form after **Close Alert**. It cannot be forced on purpose; if it never shows, write `SKIPPED (not seen)` and keep the design judgment in mind: slot cleared, form otherwise intact.

Judge: would you rather the slot stay selected? Write `KEEP` or `CHANGE (what)` in Result.

Result:

### 19. K5 — the seeded profile can flash before a "profile isn't available" screen (judgment)

**Status:** PENDING. Planner assumption K5 (UI-SPEC): accept the flash to keep the loading state unchanged. The alternative is a full-screen spinner until the first details response.

What to look at: open a profile from Favorites or a chat with the Network Link Conditioner on a slow profile. The seeded profile shows with no spinner, then the details load replaces it (or, for a deleted expert, the not-available screen replaces it).

Judge: is the flash confusing enough to want a spinner? Write `KEEP` or `CHANGE (what)` in Result.

Result:

---

## D-11 real-money session

One combined session on your own client **A** and expert **B** accounts. It places real authorization holds on live Stripe, so the order and the stop conditions below matter. It also closes the deferred Phase 1 real-Stripe checklists (ROADMAP backlog 999.1 and 999.2). Run it **after plan 04-01's D-12 deploy** (done 2026-11-12) and only after `/health` reports a commit that contains `ae3ec1a` (see Setup).

### Setup for the session

- **Topic:** B's cheapest paid CAD topic, priced with cents. One saved real card **S** on A.
- **Booking rule (01-17):** every paid booking in this session starts **2 to 5 days from now** (a paid slot more than 6 days out is refused, with no hold). **Nobody joins a call on it and nobody reschedules it.** A connected call moves it to `in_progress`, which a client cannot cancel and which is captured at end + 15 minutes; a client no-show is also captured; a reschedule can void the hold and convert the booking to a charge at T-24h. B does not need to accept any of them.
- **One hold at a time.** After each paid booking's check, cancel it as A (My Bookings > the booking > Cancel; more than 24 hours out the confirm step says the hold will be released) and **prove the hold is gone from Stripe** before the next step: the app reports success even when the void failed. On the Stripe Dashboard, Connected accounts, B's account, Payments, the PaymentIntent shows **Canceled** and nothing captured or refunded.
- **Read-only queries (Supabase SQL editor).** Run them as you go; Claude does not run them.

  Q1, the booking (replace the email):
  ```sql
  select id, status, payment_status, stripe_payment_method_id, payment_intent_id, stripe_account_id, refund_failed
  from bookings
  where client_id = (select id from auth.users where email = '<client email>')
  order by created_at desc limit 1;
  ```
  Q2, the clone (replace the `pm` id with `stripe_payment_method_id` from Q1):
  ```sql
  select clone_payment_method_id, connected_account_id, connected_customer_id
  from connected_pm_clones
  where platform_payment_method_id = '<pm id from Q1>';
  ```
- **Keep ids out of the repo.** Write clone ids, `pm_` ids and anything secret in your own notes, not in this file. In the table in step h write only the last six characters of each `pi_` id.
- **The only Dashboard action allowed besides looking is cancelling an uncaptured payment.** Never Capture, never Refund.

### Stop conditions for the session

- **S-A, an error after you paid, or an uncaptured payment on B's connected account with no booking.** The backend does not void the PaymentIntent when a confirm fails with no replay, and the app cannot release it (01-17 S2; the open decision in the notes). Cancel that payment yourself in the Dashboard, write it in the step h table as an orphan hold, and tell Claude. Check for orphans after **every** forced failure in steps c to e.
- **S-B, any payment of this session shows Succeeded, Captured or Refunded.** Stop the session. Click nothing. Tell Claude at once: that is a real charge, which this session must never cause.
- **S-C, a session booking shows `in_progress`, or its end time passes.** Stop and tell Claude: the cancel will be refused and a capture may follow at end + 15.
- **S-D, cancel returned success but the PaymentIntent is still uncaptured.** A sweep retries every 30 minutes. Wait one sweep and look again; if it is still uncaptured, cancel it in the Dashboard and tell Claude. Trust the Dashboard over `payment_status`.
- **S-E, a step fails in a way the 01-17 or 01-19 text covers.** Follow that stop condition, except any instruction to roll back to an old SHA (see the notes); stop and tell Claude for those.

#### a. PAY-01 / D1 — closing the card sheet with a saved card preselected places no hold

**Status:** PENDING (WINDOWS.md #22, plan 04-02).

Steps:
1. As A, open Make a Booking for B's paid topic, pick a slot 2 to 5 days out, and tap **Book Now**. The card sheet opens with S preselected.
2. Close the sheet by **swiping it down**. Tap **Book Now** again and close it with the **X**.
3. Look at the sheet for a **Link** option.
4. Look in the Stripe Dashboard (B's connected account, Payments, and the platform account's recent activity) and at My Bookings.

Expected:
- Each close puts you back on the form with the topic and slot still selected, Book Now enabled, **no toast and no alert**.
- No new PaymentIntent in `requires_capture` appears in the Dashboard and no new booking appears in My Bookings.
- Link is not offered (D-16, Android parity).
- Only **Continue** in the sheet proceeds (step b).

Expected end state: no hold. Result:

#### b. BOOK-01 / BOOK-05 / PAY-03 / D3 — complete a paid booking: Loading booking…, the hold card, no Back

**Status:** PENDING (WINDOWS.md #23, #24, #30).

Steps:
1. Same slot as step a (or another 2 to 5 days out). Tap **Book Now**, then **Continue** in the sheet with S. Complete 3-D Secure if asked.
2. Watch Request Sent: the loading text, the details card, the payment card. Try the Back area and the edge swipe.
3. Run Q1. Write the last six characters of `payment_intent_id` in the step h table.
4. **Run Q2 now with the `pm` id from Q1 and save all three values in your own notes.** Step f needs them, because removing the card deletes the only record of the clone.
5. Cancel the booking as A (Setup rules) and prove the hold is gone from Stripe.

Expected:
- **Loading booking…**, then the details card with the **Awaiting Approval** pill and the payment card in variant A (item 8): `A hold is placed on your card` / `No charge yet — funds are just reserved.`
- No Back button and the edge swipe does nothing (item 3).
- Q1 shows `pending_approval` and `requires_capture`. Q2 returns a row (a real clone exists). If Q2 returns no rows, tell Claude: steps f and g then do not test a real clone.
- After cancel, the PaymentIntent is Canceled and Q1 shows `cancelled` / `canceled` with `refund_failed` not true.

Expected end state: booking cancelled, hold released. Result:

#### c. PAY-02 / 999.2 / D1 — a forced timeout, and a retry that succeeds on its own (BACK-15 replay)

**Status:** PENDING (WINDOWS.md #29). Closes backlog 999.2 only if the first request reached the server; see the caveat.

Steps:
1. Book a different slot (2 to 5 days out), **Book Now**, **Continue**.
2. The moment the status line **Confirming your booking…** appears, turn **airplane mode on** (Control Center), wait about one second, then turn it **off**. The app retries after 2 seconds and again after 4, so restore the network before the alert would appear.
3. After Request Sent opens: check My Bookings and the Stripe Dashboard.
4. Run Q1; write the PaymentIntent's last six characters in the table. Then cancel the booking and prove the hold is gone.
5. Look for an orphan hold (S-A).

Expected:
- `Confirming your booking…` stays up through the retries with no extra text, and **no** `That time slot was just taken`.
- Request Sent opens for that booking. My Bookings shows **exactly one** booking for the slot and Stripe shows **exactly one** uncaptured PaymentIntent for it.
- **Caveat on what this proves.** The backend replay path writes no log line and the app cannot tell a replay from a first success (checked in the backend source). The replay happens only if the first confirm reached the server and its reply was lost, which depends on your timing. The result you can observe is "one booking, one hold, Request Sent for that booking", which a normal retry would also give (backlog 999.2's own note). Write in Result when you turned airplane mode on, and whether you believe the first request had already left the phone.
- If airplane mode landed before the card authorization finished, you will see a payment error from Stripe instead. That is not this test: check for an orphan hold (S-A), then repeat.

Expected end state: one booking, cancelled, hold released. Result:

#### d. PAY-02 / D-03 / D1 — retries exhausted, then Try again: one booking, one hold

**Status:** PENDING (WINDOWS.md #29).

Steps:
1. Book another slot, **Book Now**, **Continue**. When **Confirming your booking…** appears, turn airplane mode **on and leave it on**. While it shows, tap a different time slot, the topic row, another day and the next-month arrow (CR-01, plan 04-15).
2. Wait for the alert (about six seconds of retries). Read it, and write the last six characters of the `Payment reference` in the table.
3. Turn airplane mode **off** and tap **Try again**.
4. Check My Bookings and the Stripe Dashboard. Run Q1, then cancel the booking and prove the hold is gone.
5. Look for an orphan hold (S-A).
6. *Optional, a repeat:* get the alert again and tap **Check My Bookings** instead of Try again. It should show the Bookings tab with the Make a Booking form gone from the source tab.

Expected:
- Alert title **We couldn't confirm your booking**; message `Your request may already have been sent. Try again to check, or look in My Bookings before booking again.` then a blank line and `Payment reference: {pi_id}`; buttons **Try again**, **Check My Bookings**, **Not now**.
- **Try again** shows **Confirming your booking…** again with the same payment, then opens Request Sent for the existing booking. **One** booking in My Bookings and **one** hold in Stripe, not two.
- None of the taps in step 1 changes the form while **Confirming your booking…** shows (CR-01, plan 04-15), and after **Try again** Request Sent shows the slot you first chose.

Expected end state: one booking, cancelled, hold released. Result:

#### e. D-15 — Not now, then Book Now again for the same slot opens Request Sent for that booking

**Status:** PENDING (WINDOWS.md #34, plan 04-13).

Steps:
1. Book a slot, get the **We couldn't confirm your booking** alert as in step d, and tap **Not now**.
2. Look at the form, then tap **Book Now** again for the **same slot** and the same card.
3. Check My Bookings and the Stripe Dashboard. Run Q1, then cancel the booking and prove the hold is gone.
4. Look for an orphan hold (S-A).
5. *Optional, needs a second client account on another device:* have the second account hold the same slot first, then try it yourself.

Expected:
- **Not now** closes the alert silently, the form stays intact, Book Now is enabled.
- The second Book Now opens **Request Sent for the existing booking** (the abandoned confirm is remembered for this app session). One booking, one hold.
- If the first confirm never reached the server there is no booking to find: you get a second, fresh payment and **two** uncaptured PaymentIntents. Cancel the stray one in the Dashboard (S-A), write this step `SKIPPED (first confirm never reached the server)` and repeat once.
- (Optional) a slot someone else holds still shows the plain `That time slot was just taken. Please pick another.` with **OK**.
- The `Couldn't book` / `You may already have this booking. Check My Bookings.` alert (buttons **Check My Bookings**, **Close Alert**) is the K4 case in item 18; its layout has not been seen on a device.

Expected end state: one booking, cancelled, hold released. Result:

#### f. D-12 — removing a card inside the payment sheet: the webhook arrives and the clone rows are gone

**Status:** PENDING (plan 04-01; the Dashboard subscription is your report).

Before you start: every booking from steps a to e is cancelled and its hold proved gone, so **no live booking uses S**. You have Q2's three values from step b in your notes, and the `pm` id from Q1.

Steps:
1. As A, open Make a Booking for any paid topic, tap **Book Now**, and in the Stripe sheet **remove S** (the sheet's own edit and remove control, then confirm). Close the sheet without booking.
2. Stripe Dashboard > Developers > Webhooks > the **live platform** endpoint (not the Connect endpoint) > recent deliveries: look for `payment_method.detached`.
3. Supabase: `select count(*) from connected_pm_clones where platform_payment_method_id = '<pm id from Q1>';`
4. Stripe Dashboard, B's connected account: open the saved `connected_customer_id` and check that its payment methods no longer list the clone. If the Dashboard will not open a payment method by id, the customer view is the check (01-17 step 8).
5. Reopen the sheet and look for S.
6. *Optional and riskier:* add a second saved card and place a fresh hold with it (a paid booking 2 to 5 days out), remove **that** card in the sheet while the booking is live, then cancel the booking and prove the hold is released (plan 04-01's assumption about a clone detach and a live hold). If the cancel fails or the payment stays uncaptured, S-D applies. Skip it if you do not want another hold. Waiting a day for a converted long-lead booking to meet the sweep guard is also optional and **not recommended**: it needs a reschedule, which the booking rule forbids. The sweep guard is unit-tested in 04-01.

Expected:
- The delivery list shows `payment_method.detached` delivered with response **200**. If the event is missing, the Dashboard subscription is not in place: record FAIL for delivery and tell Claude. The sweep guard still refuses a detached card, so this is not a charge risk (04-01), but the webhook is the live fix.
- The count is **0**, and the clone no longer lists in the connected account. Q2's saved row proves a clone existed before.
- S is gone from the sheet, so the app cannot book or reschedule with it. No charge attempt is made on live Stripe (01-17: "charging a removed card" is deliberately not attempted); the detach and the unit-tested sweep guard are the evidence.
- If S was A's only card, A now has **no saved card**, which is the starting state 01-17 step 2 requires. If A has other cards, remove them before step g.

Expected end state: no hold, no charge. Result:

#### g. 01-17 / 01-19 / 999.1 — the deferred Phase 1 real-Stripe checklists, as written

**Status:** PENDING. WINDOWS.md #5, #11 (and #3, #6, which record that the code ran on mocked Stripe only).

Steps:
1. Run the **01-17 checklist (BACK-06, BACK-07, BACK-15)** as written: `.planning/phases/01-backend-fixes/01-17-SUMMARY.md`, "Task 2: Deployment done, smoke NOT RUN", part B ("Smoke checklist"): the cost note, the booking rules, queries Q1 and Q2, steps 1 to 9, stop conditions S1 to S5 and the required end state. Step 2 needs an account with no saved card, which step f left you with. BACK-15's confirm replay is also what step c exercised.
2. Then run the **01-19 checklist (BACK-19)** as written: `.planning/phases/01-backend-fixes/01-19-SUMMARY.md`, "Task 2: Deployment done, smoke NOT RUN", part B: the level table (minimum, full D-12, no money), rules for paid booking P, query Q1, steps 1 to 5, stop conditions S1 to S5 and the required end state.
3. Fill the two Results below.

Notes:
- **They were written for App Store build 6 and the current Android build.** Their server paths are the same as this build's. Record which builds you ran (this iPhone build at minimum) and which 01-19 level (minimum is steps 1 to 4 on one build). Whether that is enough to close each requirement is a `/gsd-verify-work` decision.
- **Rollback SHAs in both texts are stale.** See the notes before you start.
- **The 01-19 checklist does not prove the failed-refund retry (backlog 999.1)**, nor a real refund of a captured booking: the checklist's own table says the captured-refund branch and the retry are covered by mocked tests only, and neither client can force them. Closing BACK-19 on this session proves the hold-release path only.
- Each paid booking P in these checklists follows the Setup rules above and goes in the step h table. Cancel every P in the same sitting.

Expected: the 01-17 and 01-19 "Expected" and "Required end state" sections, as written.

Result, 01-17 (per client run: "all passed" or the failed step; "step 9 not run" if so; end state holds yes or no):

Result, 01-19 (level run; "all passed" or the failed step; end state holds yes or no):

#### h. D-11 — end state: every hold released or refunded, nothing charged

**Status:** PENDING. The session passes only when **no hold or charge remains**. Do not close the session while a row is open.

Fill one row per PaymentIntent placed in the whole session (steps b to g, including any orphan or stray hold and the 01-17 and 01-19 bookings). `pi` is the last six characters only.

| Step | Booking (short id) | pi (last 6) | How it ended | Stripe state checked | Date |
|------|--------------------|-------------|--------------|----------------------|------|
| b | | | released / refunded | Canceled / Refunded | |
| c | | | | | |
| d | | | | | |
| e | | | | | |
| f (optional) | | | | | |
| g, 01-17 client run | | | | | |
| g, 01-19 booking P | | | | | |
| Orphan or stray hold (if any) | | | | | |

Then, from the Supabase SQL editor, both of these must return **no rows** and **0** (they cover the whole account, so a row may be an older booking; say which in Result):

```sql
select count(*) from bookings
where client_id = (select id from auth.users where email = '<client email>')
  and payment_status = 'requires_capture';
```
```sql
select id, status, payment_status, refund_failed, payment_intent_id from bookings
where client_id = (select id from auth.users where email = '<client email>')
  and (payment_status = 'requires_capture' or refund_failed = true);
```

Expected end state:
- Every PaymentIntent in the table is **Canceled** (released) or **Refunded**; none is Succeeded unrefunded, and none is still `requires_capture`.
- No charge from this session on your card (a bank's pending line that later drops off is fine).
- Saved cards are how you want them. Removed cards are gone for good; re-adding one creates a new `pm` id with no clone until its next paid booking.
- The free bookings from items 1 to 7 are cancelled if you do not want them.

Result:

*D-17, 409 PAYMENT_IN_PROGRESS, cannot be forced from the app.* It is unit-tested (04-08 `ConfirmOutcomeTests` and `MakeABookingPaidFlowTests`, 04-13 ledger rows). If it shows during this session, record it under item 22 in the "Log if seen" section.

---

## D-14 Android push prompt

A check only, on an Android device. It is not Phase 4 work: a gap becomes a new todo.

### 20. D-14 — Android push prompt after a reinstall (todo 2026-11-08)

**Status:** PENDING.

Steps:
1. On the Android phone, sign in to the current Android build as A or B.
2. **Reinstall the app while signed in** (uninstall, then install the same build). Note whether you are still signed in afterwards.
3. Open the app and note whether the system push-notification prompt appears. Read `PushPermissionRequester.kt` only if the answer surprises you: it prompts once after a login or signup, using a persisted flag.

Expected: record the result, whichever way it goes:
- The prompt appears (the flag did not survive the reinstall, or the session did not), or
- the prompt does not appear while you are signed in and notifications are off. That is a gap: file a **new todo** in the Android area (a separate Android-repo commit later). It is not Phase 4 work.

Either way, **move the todo file** `.planning/todos/pending/2026-11-08-check-the-android-push-prompt-after-a-reinstall.md` to `.planning/todos/completed/` **only after you have recorded the result here**. Plan 04-14 did not move it.

Result:

---

## Log if seen

Two things Phase 4 deliberately did not build or cannot force. If you see either, write it here and file a todo; neither fails Phase 4 by itself unless stated.

### 21. OQ7 — favorites staleness after unfavoriting on a profile

**Status:** NOT EXPECTED TO BE TESTED. Out of scope (RESEARCH Open Question 7).

If seen: open a profile from Favorites, unfavorite it with the heart, and go Back. The row may still be in the list, because `FavoritesViewModel.load()` skips when the list is already loaded. Android refreshes on return. Note it and file a todo.

Result:

### 22. D-17 — "payment still processing" on confirm

**Status:** NOT EXPECTED TO BE TESTED. A `409 PAYMENT_IN_PROGRESS` on the confirm cannot be forced from the app; it is unit-tested only.

If seen during D-11 steps c to e: the expected behavior is the **Confirming your booking…** line staying up, then **Request Sent** or the confirm-unknown alert with **Try again** (the same as a timeout). It must **never** show server error copy and **never** place a second hold. Anything else is a D-17 regression: record exactly what showed and tell Claude.

Result:

---

## What each item closes if it passes

Nothing here changes `REQUIREMENTS.md` or `WINDOWS.md` by itself; `/gsd-verify-work 04` and you decide. This map is only so a PASS reaches the right record.

| Item or step | Requirement or decision | WINDOWS.md entries it answers |
|--------------|-------------------------|-------------------------------|
| 1 | EXPL-07 | none (quick 261109-323) |
| 2 | EXPL-03 | none (quick 261109-323) |
| 3 | BOOK-01, BOOK-19 | #23 |
| 4 | BOOK-05 | #24 |
| 5, 6, 7 | BOOK-02, BOOK-03, BOOK-04, D-18 | #25 |
| 8, steps a to e | PAY-01, PAY-02 (incl. CR-01, 04-15), PAY-03 | #22, #29, #30, #34 |
| 9 | EXPL-01 | #26 |
| 10 | EXPL-02 | #35 |
| 11, 15 | EXPL-04, L5 | #33 |
| 12 | EXPL-05 | #27, #31, #35 |
| 13 | EXPL-06 | #32 |
| 14 | D-13 (Phase 8 release pass) | #28 |
| step f | D-12 live proof | none (04-01) |
| step g | BACK-06, BACK-07, BACK-15, BACK-19, backlog 999.1 and 999.2 | #3, #5, #6, #11 |
| 16 to 19 | K1, K3, K4, K5 | none (judgment) |
| 20 | D-14 | none (todo file) |

