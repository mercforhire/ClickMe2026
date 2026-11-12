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

<!-- 04-14 task 2 continues here -->
