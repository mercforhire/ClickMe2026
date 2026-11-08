---
phase: 01-backend-fixes
plan: 14
subsystem: api
tags: [chat, unread, socket, supabase, jest, openapi, wave-2]

requires:
  - phase: 01-backend-fixes
    provides: "01-09 added postUserMessage in src/services/chatMessages.js, so the send and accept paths share one recount; 01-13 is the prior wave 2 plan on master"
provides:
  - "unread_count_<side> is recomputed from messages.status on send (recipient), message.read (reader) and GET /chats/:id/messages page 1 (caller)"
  - "src/services/unreadCounts.js exports unreadFieldFor, countUnreadFor and recomputeUnreadFor, with no migration"
  - "src/services/socket.js exports handleMessageRead, covered by the first socket handler unit tests"
  - "docs/SOCKET-CONTRACT.md section 6 and openapi/clickme-api.yaml describe unread_count as maintained"
affects: [01-15 (wave 2 gate and push), Phase 7 CHAT-07/08, Android displayUnread follow-up]

# Measured in the BACKEND repo, where all code commits live:
# git -C "<backend>" rev-list --count b982e0b..7fdc7c4 = 3. plan_head_before and plan_head_after
# are backend SHAs. tokens is chars/4 over that diff (45621 bytes). The iOS repo holds planning
# docs only and had no commits at SUMMARY write (iOS HEAD e72b6f7).
actuals:
  tokens: 11405
  tasks: 3
  commits: 3
plan_head_before: b982e0ba506a87e9a260c2199ce6471ac2b8c3e0
plan_head_after: 7fdc7c4b0f1ed667d4de2885a28708ebd50d0d35

tech-stack:
  added: []
  patterns:
    - "Denormalized counters are recomputed from source rows at each event that can change them, rather than incremented"
    - "Socket handlers can be module-level exported functions that take io, userId and data, so tests call them without a server"

key-files:
  created:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/services/unreadCounts.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/services/unreadCounts.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/socket.messageRead.test.js"
  modified:
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/services/chatMessages.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/services/socket.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/src/controllers/chats.controller.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/services/chatMessages.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/tests/chats.test.js"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/docs/SOCKET-CONTRACT.md"
    - "/Users/LeonChen/Documents/ClickMe2026 Backend/openapi/clickme-api.yaml"

key-decisions:
  - "BACK-18 recomputes unread_count from messages.status on send, message.read and page-1 open, with no increment RPC and no migration; simultaneous sends can undercount by one until the next event (RESEARCH A2)"
  - "Opening a thread recomputes the caller's counter and marks nothing read (Open Q6 default); only message.read marks a message read, so partner messages a client never emits for stay in the count; Phase 7 CHAT-07/08 may revisit this"
  - "countUnreadFor throws when a query returns no count, so a missing count can never be written to the counter as 0"

patterns-established:
  - "Recount, do not increment: unreadCounts.js is the single owner of the unread formula and depends only on Supabase and pure utils, which avoids a require cycle with socket.js"

requirements-completed: [BACK-18]

coverage:
  - id: D1
    description: "A new message, through POST /chats/:id/send or the accept message, writes the recipient's recount in the same chats update as last_msg_*; a 23505 duplicate runs no count, and a failed count still writes last_msg_* and resolves"
    requirement: BACK-18
    verification:
      - kind: unit
        ref: "tests/services/chatMessages.test.js#postUserMessage recipient unread count (BACK-18)"
        status: pass
      - kind: integration
        ref: "tests/chats.test.js#send: thread denormalization writes the real last_msg_text/last_msg_sender_id columns (MSG-05, CR-04)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The recount counts only partner messages not yet read, excludes system events, writes only the given user's side, and writes nothing for a non-participant or a self-thread"
    requirement: BACK-18
    verification:
      - kind: unit
        ref: "tests/services/unreadCounts.test.js"
        status: pass
    human_judgment: false
  - id: D3
    description: "message.read recounts the verified reader after a successful status update; empty payloads and non-participants change nothing; a status update error skips the recount and the emit; a failed recount still sends the read receipt"
    requirement: BACK-18
    verification:
      - kind: unit
        ref: "tests/socket.messageRead.test.js#handleMessageRead (BACK-18)"
        status: pass
    human_judgment: false
  - id: D4
    description: "GET /chats/:id/messages page 1 recounts the caller once; page 2 does not; a failed recount returns 200 with the same body; a non-participant gets 404 and no recount"
    requirement: BACK-18
    verification:
      - kind: integration
        ref: "tests/chats.test.js#GET /api/v1/chats/:id/messages — unread recount on open (BACK-18, Open Q6)"
        status: pass
    human_judgment: false
  - id: D5
    description: "SOCKET-CONTRACT section 6 and OpenAPI describe unread_count as maintained, with the 2026-11-07 changelog line, and the old 'is not maintained' statement is gone"
    requirement: BACK-18
    verification:
      - kind: other
        ref: "! grep -q 'is not maintained' docs/SOCKET-CONTRACT.md; grep -n 2026-11-07 docs/SOCKET-CONTRACT.md; npm run check-openapi-coverage reports all 128 endpoints; the YAML parsed"
        status: pass
    human_judgment: false
  - id: D6
    description: "On the deployed backend, the Android chat badge rises on a new message and clears after the thread is read, and build 6 chat is unchanged"
    requirement: BACK-18
    verification: []
    human_judgment: true
    rationale: "Tests mock Supabase and the socket. The code is not deployed, and real count queries and client behavior need the wave 2 smoke check in 01-15."

duration: 5 min
completed: 2026-11-08
status: complete
---

# Phase 1 Plan 14: Server-Maintained Unread Counts Summary

**Chat unread counts are now recomputed on the server from message status on send, on `message.read` and on opening a thread, with no migration, so the count goes back to zero once every partner message is read.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-11-08T17:53:28Z
- **Completed:** 2026-11-08T17:59:12Z
- **Tasks:** 3
- **Files modified:** 10 (backend)

## Accomplishments

- **Recount service:** `src/services/unreadCounts.js` counts partner messages that are not read with one head-only query, then writes only the given user's side. A non-participant or a legacy self-thread maps to no field and writes nothing.
- **On send:** `postUserMessage` counts after the insert and writes the recipient's count in the same `chats` update as `last_msg_*`, so the accept message from 01-09 counts too. The old deferred-increment comment and the unused `unreadField` remnant are gone.
- **On read:** the `message.read` closure is now an exported `handleMessageRead` with the same guards and queries. It recounts the reader after the status update, and a failed recount is logged without costing the sender their read receipt.
- **On open:** `GET /chats/:id/messages` page 1 recounts the caller. The response is unchanged, and nothing is marked read.
- **Contract:** `docs/SOCKET-CONTRACT.md` section 6 and `openapi/clickme-api.yaml` now describe the maintained count and tell clients to emit `message.read` for what they display.

## Task Commits

Backend repo, branch `master`. Nothing was pushed or deployed: `origin/main` is still `a92acba`, and master is 10 commits ahead of it.

1. **Task 1: unreadCounts service and recipient recount on send** - `949b2b7` (fix)
2. **Task 2: Extract the message.read handler and recount the reader's counter** - `fbf8ce7` (fix)
3. **Task 3: Recount on opening a thread (page 1) and rewrite the unread contract** - `7fdc7c4` (fix)

**Plan metadata:** recorded by the iOS repo docs commit for this summary.

Each task wrote its tests first and saw them fail before the code. The plan names one commit per task, so tests and code share a commit. The observed failures were:
- **Task 1:** 2 `chatMessages` assertions failed on the missing unread field or count call. `unreadCounts.test.js` failed to load because the module did not exist yet, which is a load failure and not an assertion failure.
- **Task 2:** all 10 cases failed with `handleMessageRead is not a function`, which is also not an assertion failure.
- **Task 3:** 3 of the 5 new cases failed on assertions. The page 2 and non-participant cases passed before the change, as expected, because no recount existed yet.

## Files Created/Modified

All paths are in `/Users/LeonChen/Documents/ClickMe2026 Backend`.

- `src/services/unreadCounts.js` - new: `unreadFieldFor`, `countUnreadFor`, `recomputeUnreadFor`
- `src/services/chatMessages.js` - recipient recount inside the existing `chats` update
- `src/services/socket.js` - exported `handleMessageRead`, reader recount
- `src/controllers/chats.controller.js` - page 1 recount in `messages`
- `tests/services/unreadCounts.test.js` - new: 13 cases for the recount service
- `tests/services/chatMessages.test.js` - 5 new send cases
- `tests/socket.messageRead.test.js` - new: 10 cases, the first socket handler tests
- `tests/chats.test.js` - 5 new open cases, plus the count step in one send test's mock
- `docs/SOCKET-CONTRACT.md` - section 3 row, section 6 rewrite, changelog line
- `openapi/clickme-api.yaml` - `unread_count` description, page 1 note

## Decisions Made

- **Recompute, not increment:** as the plan specified. It needs no migration and heals itself at the next event.
- **Recount placement in `messages`:** after the sender profile read rather than directly after the messages read. A failed profile read therefore returns 500 without a recount, and the file's sequential mocks keep their order.
- **A missing count is an error:** `countUnreadFor` throws when no number comes back, so the counter is never overwritten with 0 by mistake.
- **Changelog date:** the plan and its acceptance check require `2026-11-07`. The work happened on 2026-11-08, so the line says both.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Task 1 commit also includes `tests/chats.test.js`**
- **Found during:** Task 1
- **Issue:** the plan says Task 1 commits exactly four files, but the new count query is an extra `from('messages')` call. It consumed the mock that an existing send test had queued for its `chats` update, so that test failed, and the task's own verify command runs `tests/chats.test.js`.
- **Fix:** added the count step to that test's sequential mock and asserted `unread_count_expert: 1`.
- **Files modified:** `tests/chats.test.js`, which the plan lists for Task 3
- **Verification:** `tests/chats.test.js` passes
- **Committed in:** `949b2b7`

**2. [Rule 1 - Bug] Rewrote the section 6 heading and intro in `docs/SOCKET-CONTRACT.md`, and added a note to the section 3 `message.read` row**
- **Found during:** Task 3
- **Issue:** the plan asks to rewrite item 1 only, but the heading "Known backend gaps" and the intro "Two behaviors are intentionally incomplete" would have stayed false.
- **Fix:** retitled the section "Unread counts and mark-read" and rewrote the intro. Item 2 (mark-read is socket-only) is unchanged.
- **Files modified:** `docs/SOCKET-CONTRACT.md`
- **Verification:** read back; the old statement no longer appears
- **Committed in:** `7fdc7c4`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Both were needed to keep the test suite and the contract accurate. No scope creep.

## Issues Encountered

**Full gate, run three times** (`npm test -- --testPathIgnorePatterns=tests/services/redis.test.js`):

| Run | Code at | Result | Failures |
|-----|---------|--------|----------|
| 1 | Task 2 | 2926 of 2927 passed | `tests/call.test.js`: "returns 200 with join_url null and a message for skype_zoom with no profile link (04-09)" (got 401) |
| 2 | Task 3 | 2917 of 2932 passed | `tests/expertTopics.test.js`: 15 tests, all PATCH, GET or DELETE on `/expert/topics/:id` or tag and price cases |
| 3 | Task 3 | **2932 of 2932 passed, 128 of 128 suites** | None |

Neither failing file was changed by this plan. Each passes alone: `call.test.js` 82 of 82, three runs in a row; `expertTopics.test.js` 97 of 97, two runs in a row. Run 3 was on the same code as run 2, so the final commit is green, but neither file was on the known flake list, so 01-15 should add them. The root cause was not investigated.

## Follow-ups and Things to Watch

- **Backlog on first count:** counting is over the whole thread, and Android only emits `message.read` for loaded messages. A thread with unread partner messages older than the loaded page will keep a non-zero badge after opening until those messages are loaded. This matches the plan's definition, but it could surprise someone in the smoke check, because Android shows `maxOf(server, local)`.
- **Existing threads:** a thread keeps its stored value (typically 0) until its first send, read or page-1 open after deploy.
- **iOS build 6:** checked in the current iOS source, which decodes `unread_count` and shows it nowhere in its views. It already emits `message.read`.
- **Android:** the logged follow-up to switch `displayUnread` to the server count still stands.

## User Setup Required

None. No migration or external service change. `unread_count_client` and `unread_count_expert` already exist.

## Next Phase Readiness

Wave 2 code is complete and committed locally: BACK-09, BACK-12, BACK-14, BACK-15 and BACK-18. Ready for the 01-15 gate and "wave 2 ready to push" handoff. The `Threat Flags` section is omitted: the only new write is the participant-scoped counter already covered by T-01-29 and T-01-30.

## Self-Check: PASSED

- Created files exist: `src/services/unreadCounts.js`, `tests/services/unreadCounts.test.js`, `tests/socket.messageRead.test.js`.
- Commits are ancestors of backend HEAD: `949b2b7`, `fbf8ce7`, `7fdc7c4`.
- `grep -c "unread increment deferred" src/services/chatMessages.js` prints 0. `grep -c handleMessageRead src/services/socket.js` prints 5.
- `npm run check-openapi-coverage` reports all 128 endpoints.

---
*Phase: 01-backend-fixes*
*Completed: 2026-11-08*
