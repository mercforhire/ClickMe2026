---
status: diagnosed
trigger: "UAT Phase 06 Test 1, checklist items 4 and 8: Some topics have a third currency which is invisible. This could be a bug on the backend. By default, all the free topics open with an unknown currency, which causes a problem at save."
created: 2026-11-16T20:00:00Z
updated: 2026-11-16T20:30:00Z
goal: find_root_cause_only
gap_id: G-06-1-currency
---

## Current Focus

bug_class: Bohrbug (deterministic: same row, same result every open and every save)
hypothesis: CONFIRMED (WR-02, extended). A free topic stored with price_currency NULL is serialized by the backend as price.currency "" (expertTopics.controller.js:95). The iOS editor (since 73e729e) treats "" as a real stored currency because `??` only falls through on nil, so it opens on "", appends "" as a blank third picker segment, and sends hourly_rate.currency "" on every save, which the PATCH schema rejects with 422 "Topics can be priced in CAD or USD only."
test: done; code read across all three repos plus local repro of the backend serializer/schema and the iOS resolve logic
expecting: n/a
next_action: return ROOT CAUSE FOUND to the orchestrator (diagnose-only); the user can optionally run the read-only query in blind_spots to size the affected rows

reasoning_checkpoint:
  hypothesis: "The iOS Topic Editor opens a NULL-currency free topic on a blank currency because the backend sends price.currency \"\" for NULL, and resolveInitialCurrency/isCurrencyLocked/init accept \"\" as a stored code (`??` does not treat empty as absent), so pickableCurrencies appends \"\" and saveTopic sends currency \"\", which topicCurrencySchema rejects (length 3)."
  confirming_evidence:
    - "Local run of the real controller: getTopic on a NULL-currency free row returns price {amount:0,currency:\"\",is_free:true,label:\"Free\"}"
    - "Local run of the real patchTopicSchema: currency \"\" REJECTED with 'Topics can be priced in CAD or USD only.'; \"CAD\" ACCEPTED"
    - "Verbatim iOS logic on that wire JSON: currency=\"\", pickable=[CAD, USD, \"\"]; with null instead: CAD, [CAD, USD]"
    - "Android has handled the same \"\" wire value since 917ab205 (storedCurrency skips blanks, validCode, test resolveCurrency(\"\", \"USD\") == \"USD\")"
    - "Build 6 (a48c664) editor always used defaultCurrency, so the bug is new in 73e729e (2026-11-10)"
  falsification_test: "On the UAT build, create a NEW free topic in-app (it is stored with CAD) and reopen it: it must show exactly two segments with CAD selected and save. If it also shows a blank segment, the NULL-row precondition is wrong and something else produces the blank. Second check: a read-only query showing the UAT expert's free topics have non-NULL price_currency would also refute it."
  fix_rationale: "Normalizing a blank or non-3-letter stored code to nil in the iOS seed and lock rule removes the blank segment and the \"\" payload at the source the editor reads; it is what Android already does. A backend null would make the wire value match the OpenAPI intent and the public endpoints, but the iOS guard is still needed because the one iOS release must be robust to whatever the server sends."
  blind_spots: "Production rows were not queried (instruction: no production access), so 'every free topic on the test expert is NULL' is inferred from creation paths, not observed. The iOS logic was reproduced in a standalone Swift script, not via xcodebuild/the app. The exact inline error text on device was not captured in the UAT notes."
  candidate_causes:
    - "code (iOS): resolveInitialCurrency, isCurrencyLocked and init seedCurrency treat \"\" as present; pickableCurrencies appends any non-allowed currency, including \"\" (TopicEditorViewModel.swift:104-107,165-175,208-210)"
    - "code/contract (backend): serializeTopic emits '' for NULL (expertTopics.controller.js:95) while OpenAPI says an ISO code and the public endpoints emit null"
    - "data: free topics with price_currency NULL, created by API callers that omit hourly_rate (UAT scripts) or by direct seed inserts; PATCH never fills it in while the topic is free, so these rows stay NULL"
    - "config/contract (backend): createTopicSchema leaves hourly_rate optional on free create although USD-TOPIC-PRICING.md §2 says the currency is required, so the API keeps creating such rows"
  and_gate: "yes. The failure needs a NULL-currency free row (data) AND the '' serialization (backend) AND iOS accepting '' (client). Removing any one stops it: no NULL rows, or a JSON null, or an iOS blank guard. The iOS guard is the required fix, because it is the only one that also covers rows that already exist and any other server value."

## Symptoms

expected: A free topic opens on CAD or USD in the Topic Editor and saves without error.
actual: "Some topics have a third currency which is invisible. This could be a bug on the backend. By default, all the free topics open with an unknown currency, which causes a problem at save." (UAT 06 Test 1, items 4 and 8)
errors: none quoted; Save fails (expected 422 from currency allowlist)
reproduction: UAT Test 1, items 4 and 8 in .planning/phases/06-expert-mode/06-DEVICE-UAT-CHECKLIST.md (edit a free topic; picker shows a blank third segment selected; Save fails)
started: discovered during device UAT 2026-11-16; currency picker introduced in Phase 6 plan 06-01

## Eliminated

- hypothesis: list and detail responses serialize currency differently, so the editor gets a different value than the card
  evidence: listTopics, getTopic, createTopic and patchTopic all use serializeTopic; the editor is seeded from GET /expert/topics (TopicsSetupViewModel.forceLoad L83) and from the create/patch echo, all the same shape
  timestamp: 2026-11-16T20:02:00Z

- hypothesis: the hourlyRate field contributes a blank currency
  evidence: the backend has sent no hourly_rate key since 50abd85 (TOPIC-02); ExpertTopicItem.hourlyRate is always nil, so `hourlyRate?.currency ?? price.currency` is always price.currency
  timestamp: 2026-11-16T20:08:00Z

- hypothesis: iOS or Android writes a NULL currency when creating or saving a free topic
  evidence: both always send hourly_rate with a 3-letter code on create (iOS since df8d99e, free-capable since 06ae139; Android since 917ab205); backend create stores it; patchTopic never writes price_currency on a free result and no historical version ever wrote NULL
  timestamp: 2026-11-16T20:12:00Z

- hypothesis: a DB trigger, CHECK or migration nulls price_currency on free topics
  evidence: no trigger/CHECK on discussion_topics; the two data migrations only ever SET 'CAD'
  timestamp: 2026-11-16T20:06:00Z

- hypothesis: allowed_currencies decodes an odd third entry from /me
  evidence: the extra segment is the editor's own `currency` appended by pickableCurrencies; repro shows ["CAD","USD"] + [""]
  timestamp: 2026-11-16T20:22:00Z

## Evidence

- timestamp: 2026-11-16T20:00:00Z
  checked: knowledge base (.planning/debug/knowledge-base.md)
  found: file does not exist; no prior resolutions to match. MemPalace not used.
  implication: no known-pattern candidate; proceed with WR-02 lead as hypothesis H1.

- timestamp: 2026-11-16T20:02:00Z
  checked: backend src/controllers/expertTopics.controller.js (master == origin/main 28da165 for this file, schema, pricing, middleware, routes; git diff --stat empty)
  found: serializeTopic L95 `const currency = (topic.price_currency || '').toUpperCase();` emits `price.currency: ""` for a NULL price_currency. Response has no hourly_rate key (TOPIC-02, removed in 50abd85). listTopics, getTopic, createTopic and patchTopic responses all go through serializeTopic.
  implication: every expert-topic read (list, detail, create/patch echo) for a NULL-currency topic carries "" — there is no list-vs-detail divergence; the same serializer feeds both.

- timestamp: 2026-11-16T20:04:00Z
  checked: backend createTopic L259 and patchTopic L383-440 (and history: a79ad63, 3aad561, 9037865, 989a50d^)
  found: create stores `price_currency = body.hourly_rate ? body.hourly_rate.currency : null` (unchanged since a79ad63, 2026-07-11). patchTopic NEVER writes price_currency for a free result (L438: only `resultingIsFree === false && resultingCurrency !== current.price_currency`); no historical patch version ever wrote NULL.
  implication: a free topic's stored currency is frozen at whatever create stored. A NULL free topic stays NULL through every free save, from any client, until it becomes paid. A client-side currency pick on a free topic is never persisted.

- timestamp: 2026-11-16T20:06:00Z
  checked: supabase migrations touching discussion_topics.price_currency
  found: column is nullable CHAR(3) with FK to currencies(code) (20260603020000, 20260604010000); no trigger or CHECK on it. 20260723010000_normalize_currency_to_cad.sql set EVERY row, NULLs included (`upper(NULL) IS DISTINCT FROM 'CAD'` is true), to 'CAD'. 20261110000000 only remaps non-null non-CAD/USD codes. 20261109000000 (quick 261109-323) states "free topics created with no price have a null price_currency" in production.
  implication: NULL-currency rows that exist today were all written after 2026-07-23 by a create that sent no hourly_rate, or by a direct DB insert. Production is known to have them (261109-323 observed them in home_feed).

- timestamp: 2026-11-16T20:08:00Z
  checked: iOS TopicEditorViewModel.swift L104-107, L165-175, L189-222; ExpertTopicItem.swift; TopicEditorView.swift L430-443
  found: `Price.currency: String?` decodes "" as "" (not nil); `hourlyRate` is always nil (backend sends no hourly_rate key). resolveInitialCurrency: `(topic?.hourlyRate?.currency ?? topic?.price.currency ?? default).uppercased()` -> "" because `??` only falls through on nil. pickableCurrencies = ["CAD","USD"] + [""] since "" is not allowed. Picker renders `Text(code)` -> a blank third segment, and it is the selection. isCurrencyLocked = `!isFree && stored != nil` (false for free; would lock a legacy PAID NULL row onto "").
  implication: H1 mechanism confirmed in code for any topic whose price.currency is "".

- timestamp: 2026-11-16T20:10:00Z
  checked: iOS TopicsSetupViewModel.saveTopic L136-180; ExpertTopicRequest.swift; backend expertTopics.schema.js topicCurrencySchema; pricing.js L97-117
  found: PATCH always sends `hourly_rate: {amount: wireAmount, currency: currency}` (currency ""). wireAmount for free = `minMinorUnits(for: "")` (falls to default floor) . patchHourlyRateSchema.currency = topicCurrencySchema.optional(): `z.string().length(3, {message: 'Topics can be priced in CAD or USD only.'})` — "" is present (not undefined) so it fails length(3).
  implication: every save of such a topic is a 422 VALIDATION_ERROR "Topics can be priced in CAD or USD only." before the controller runs — matches "causes a problem at save". Title/icon/description-only edits fail too.

- timestamp: 2026-11-16T20:12:00Z
  checked: who can write a NULL price_currency (backend src grep: only expertTopics.controller inserts/updates discussion_topics); iOS CreateExpertTopicRequest history (df8d99e, 6e56efb, 06ae139, HEAD); Android ExpertRequests.kt (917ab205, 60ebfc20); backend scripts/
  found: iOS `CreateExpertTopicRequest.hourlyRate` has been non-optional since df8d99e (2026-07-14); 06ae139 (2026-10-15, build 6 era) made free create send `is_free:true` + `hourly_rate {floor placeholder, currency}`. Before 06ae139 iOS sent `isFree: false` always, so iOS could not create a free topic at all. Android CreateExpertTopicRequest.hourlyRate is non-null since it was written (2026-10-25). Direct inserts with `price_currency: null, is_free: true` exist in scripts/seed-app-review.js:88 ("Free Intro Chat") and scripts/uat-free-booking-unonboarded.js:193.
  implication: neither shipped client, on any version, creates a free topic with NULL currency through POST /expert/topics today. NULL free rows come from (a) a free topic created by a POST without hourly_rate (a non-app caller: seed/UAT scripts hitting the API, Postman, admin) or (b) direct DB inserts by seed/UAT scripts. Whether EVERY free topic on the UAT expert is NULL cannot be proven from code; it needs a read-only production query (see blind_spots).

- timestamp: 2026-11-16T20:16:00Z
  checked: backend scripts that POST free topics with no hourly_rate
  found: scripts/uat-onboarding-cra.js:358-363 (`{title, description, duration_mins: 30, is_free: true}`), scripts/uat-taxonomy-expansion.js:281,289,316 (`is_free: true`, no hourly_rate). uat-availability.js:365 sends hourly_rate CAD (stores CAD). createTopicSchema has `hourly_rate: hourlyRateSchema.optional()`, so the API accepts these, even though docs/ios/USD-TOPIC-PRICING.md §2 says hourly_rate.currency "is required on create (also for a free topic)".
  implication: the API itself still mints NULL-currency free topics for any caller that omits hourly_rate. Test/UAT expert accounts that ran these scripts, or the app-review/UAT seeds, are exactly where "every free topic" being NULL is expected. Real experts who made free topics in-app (iOS 06ae139+ or Android) have CAD/USD.

- timestamp: 2026-11-16T20:18:00Z
  checked: build 6 (a48c664) TopicEditorViewModel; iOS commit that introduced the picker
  found: build 6 editor used `let currency = defaultCurrency` (L271) and never read the topic's currency, so build 6 always sent CAD and never hit this. resolveInitialCurrency / pickableCurrencies were introduced by 73e729e (2026-11-10, "keep a topic's own currency on edit + CAD/USD picker", backend Phase 34 D-18), extended in 06-01.
  implication: regression introduced in the unreleased iOS build by 73e729e; App Store build 6 is not affected.

- timestamp: 2026-11-16T20:20:00Z
  checked: Android ExpertTopicItem.kt L6-35 (917ab205, 2026-10-25), TopicPrice.kt L140-150, TopicEditorViewModel.kt L73,L99-104, TopicPriceTest.kt L111
  found: Android documents "A free topic created without a currency carries `price.currency == \"\"`"; storedCurrency skips blank values; resolveCurrency/validCode/cleanCode accept only a trimmed 3-letter ASCII code, else the default, else "CAD"; test `resolveCurrency("", "USD") == "USD"`. isLocked also uses cleanCode.
  implication: differential confirmed: Android handled the "" wire value 2 weeks before iOS 73e729e; the iOS port did not carry it. No Android change needed.

- timestamp: 2026-11-16T20:22:00Z
  checked: local repro, no network, temporary scripts (deleted afterwards). A Node script that loaded the real expertTopics.controller.js and expertTopics.schema.js from the backend checkout with supabaseAdmin stubbed to return one NULL-currency free row; and a Swift script with the iOS ExpertTopicItem DTO and resolveInitialCurrency/isCurrencyLocked/pickableCurrencies copied verbatim, decoding with `.convertFromSnakeCase`
  found: |
    GET /expert/topics/:id -> {"amount":0,"currency":"","is_free":true,"label":"Free"}
    PATCH schema with currency "" -> REJECTED: hourly_rate.currency "Topics can be priced in CAD or USD only."
    PATCH schema with currency "CAD" -> ACCEPTED
    iOS, backend today (""): currency="" pickable=["CAD", "USD", ""] locked=false
    iOS, null:               currency="CAD" pickable=["CAD", "USD"] locked=false
    iOS, "CAD":              currency="CAD" pickable=["CAD", "USD"] locked=false
  implication: full chain reproduced: NULL row -> "" on the wire -> iOS keeps "" -> blank 3rd segment selected -> PATCH sends "" -> 422. Also shows a JSON null (instead of "") would already resolve to CAD on the current iOS code.

- timestamp: 2026-11-16T20:24:00Z
  checked: safety of a backend '' -> null change; other consumers of price.currency
  found: build 6 and HEAD both declare `ExpertTopicItem.Price.currency: String?`; build 6 already decodes `currency: null` for the SAME rows on the SAME DTO from public GET /experts/:id/topics (publicProfile.controller.js:227,416 emit raw `topic.price_currency`). Android TopicPriceDto.currency is `String? = null`. OpenAPI ExpertOwnedTopic.price.currency is `type: string` "ISO 4217 currency code, uppercase" (so "" already violates it; null would need `["string","null"]`). No backend test asserts '' for currency (tests/expertTopics.test.js).
  implication: a backend null is decode-safe for build 6 and Android, but is a documented contract change; it is defense in depth, not a replacement for the iOS fix.

- timestamp: 2026-11-16T20:26:00Z
  checked: incidental, the "hourlyRate vs price" question; TopicsSetupTopicCard.swift L17-25
  found: the card formats with Money only `guard let rate = topic.hourlyRate`, else falls back to server `price.label`; the backend never sends hourly_rate, so the card always shows the server label, which formatPrice.js trims (`replace(/\.?0+$/, '')` -> "CA$50 / session").
  implication: hourlyRate does not contribute to the blank-currency bug (it is nil on every topic, so `??` always falls to price.currency). It is the cause of the sibling gap G-06-1-card-cents; out of scope here.

## Resolution

root_cause: "iOS TopicEditorViewModel (introduced in 73e729e, 2026-11-10) treats an empty-string stored currency as a real currency: resolveInitialCurrency/init use `hourlyRate?.currency ?? price.currency ?? default`, and `??` does not fall through on \"\", so the editor opens on \"\", pickableCurrencies appends \"\" as a blank, selected third segment, and every save sends hourly_rate.currency \"\", rejected by the backend PATCH schema with 422 'Topics can be priced in CAD or USD only.'; contributing: the backend serializeTopic (expertTopics.controller.js:95) sends price.currency \"\" (not null) for a NULL price_currency, contrary to OpenAPI and to the public topic endpoints; precondition: the affected free topics have price_currency NULL, which only API callers that omit hourly_rate on a free create (UAT scripts) or direct seed inserts produce, and patchTopic never fills it in while the topic is free, so these rows stay NULL"
fix: "(diagnose only, not applied) iOS: one helper that returns a trimmed, 3-ASCII-letter, uppercased code or nil, used by resolveInitialCurrency, isCurrencyLocked and the init seedCurrency (Android validCode/cleanCode parity); TopicCurrencyTests rows for a free topic with currency \"\" and \"   \" in the real wire shape (no hourly_rate key, amount 0). Optional backend, additive: serializeTopic emits null for NULL plus an OpenAPI update; optionally require a currency or default it to CAD on a free create; optional data backfill is a user decision."
verification: "Root cause reproduced locally (backend controller + schema run with stubbed Supabase; iOS logic run as a Swift script). Not verified on a device or against production rows."
files_changed: []
oracle_type: specified (USD-TOPIC-PRICING.md §2: a topic with no currency falls back to the default; allowlist CAD/USD)
