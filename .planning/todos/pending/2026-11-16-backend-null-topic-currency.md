---
created: 2026-11-17T00:00:00.000Z
title: Backend sends price.currency "" (not null) for a topic stored with no currency
area: api
severity: low
files:
  - ClickMe2026 Backend/src/controllers/expertTopics.controller.js
  - ClickMe2026 Backend/tests/expertTopics.test.js
  - ClickMe2026 Backend/openapi/clickme-api.yaml
  - ClickMe2026 Backend/docs/ios/USD-TOPIC-PRICING.md
---

## Problem

The backend sends `price.currency: ""` for a topic stored with no currency (`serializeTopic` in `src/controllers/expertTopics.controller.js`, the `(topic.price_currency || '').toUpperCase()` fallback). OpenAPI `ExpertOwnedTopic.price.currency` says an uppercase ISO 4217 code, and the public topic endpoints already send `null` for the same rows. The new iOS build (plan 06-11) and Android (since `917ab205`) already read a blank or malformed code as "no currency", so this is contract hygiene, not a user-facing bug (gap G-06-1-currency, diagnosed in `.planning/debug/free-topic-blank-currency.md`).

The fix is a value change on an existing field (`""` becomes `null`), not an additive change. Its safety for App Store build 6 (`a48c664`) and the current Android build therefore rests on the client tolerance gate defined in plan 06-17 Task 2, not on the debug notes alone. The debug evidence only gives reasons to expect safety: build 6 and Android both declare `price.currency` optional and already decode `null` for the same rows from the public endpoints.

Two related questions plan 06-17 did not decide:

- Whether to backfill NULL `price_currency` rows in production to CAD. This is a user decision with production data and is not part of this todo's change.
- Whether a free create should require or default a currency. The API still mints NULL rows for callers that omit `hourly_rate` (UAT scripts, direct seed inserts), although `docs/ios/USD-TOPIC-PRICING.md` §2 says the currency is required on create.

## Solution

Decision (plan 06-17 Task 1, user, 2026-11-17): skip. The backend was not changed: no worktree, no branch, no backend command was run. The iOS fix in plan 06-11 closes the gap either way.

If this is revived, the change is, in a fresh worktree based on `origin/main` (one commit, not pushed, never on `master`):

1. In `serializeTopic`, send the stored code uppercased, or `null` when the topic has none, removing the empty-string fallback; update the comment above the function.
2. Three rows in `tests/expertTopics.test.js` next to `describe('serializeTopic price shapes (TOPIC-02)')`, each naming G-06-1-currency: a free row with `price_currency` null returns `price.currency` null (`is_free`, `amount` 0 and label Free unchanged); a paid row stored as `usd` returns `USD`; POST of a free topic with no `hourly_rate` echoes null.
3. OpenAPI `ExpertOwnedTopic` `price.currency` becomes `type: ["string", "null"]` with the description `ISO 4217 currency code, uppercase; null for a free topic stored without a currency (clients use the default currency, see docs/ios/USD-TOPIC-PRICING.md §2)`, key kept in `required`.
4. `docs/ios/USD-TOPIC-PRICING.md` §2: one sentence that such a topic has `price.currency: null` (servers before this change sent `""`; treat a blank or non-3-letter code as no currency).
5. Topic suite and full backend suite pass in the worktree.

Expected client safety facts (as read 2026-11-16, to be re-checked): iOS `ExpertTopicItem.Price.currency` is `String?` at both `a48c664` and HEAD, with no `init(from` or `CodingKeys`; Android `TopicPriceDto.currency` is `String? = null` and `ResponseDecodingTest.expertDetailsDecodesFreeAndPaidTopics` decodes `"currency":null`.

Reviving it means rerunning the client tolerance gate from plan 06-17 Task 2 first, because both clients may have changed by then: the iOS `"currency":null` rows in `TopicsSetupTopicCardLabelTests` (run with `TopicCurrencyTests`), the build 6 `a48c664` `Price` decoder check (identical stored properties, no custom decoder), and the Android decode tests (`ResponseDecodingTest.expertDetailsDecodesFreeAndPaidTopics`, `ExpertTopicDtoTest`). If any part fails, build nothing. Deploying stays a separate user decision: a push of that one commit to `main` as a fast-forward by explicit refspec, never forced, with a read-only check of production `/health` and `origin/main` first, and `master` must later take it in by merging `origin/main` (see `2026-11-11-merge-d12-into-backend-master.md`).
