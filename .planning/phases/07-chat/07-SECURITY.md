---
phase: "07"
slug: "chat"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-11-18"
---

# Phase 07 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| iOS client → REST API (`/chats`, `/chats/:id/messages`, block, report) | Authenticated HTTPS calls; the server enforces participant scope, block state and limits | Message text, block/report actions, report reasons and details (user content, moderate sensitivity) |
| Socket.IO realtime → iOS client | `message.new`, `message.read`, `user.status` events pushed to the signed-in user | Message text and read receipts (user content) |
| Device memory / logs | View-model state for pending and failed bubbles; debug logging | Unsent message text (must not persist or be logged) |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-07-01 | Information disclosure | Message text in debug logs | medium | mitigate | No `print`/`os_log`/`Logger`/`NSLog` in the Chat folder (grep: 0) | closed |
| T-07-02 | Tampering | Duplicate delivery from concurrent or retried sends | low | mitigate | `ChatSendCoordinator.isInFlight` guard; one `client_msg_id` per bubble; server `UNIQUE(thread_id, sender_id, client_msg_id)` | closed |
| T-07-03 | Information disclosure | Failed message text persisted on device | low | mitigate | No UserDefaults/FileManager/Valet/write in the view model or coordinator (grep: 0) | closed |
| T-07-04 | Denial of service | Oversized message rejected after Send | low | mitigate | `ChatComposerRules.limit = 10_000` UTF-16 cap via `UTF16Prefix` | closed |
| T-07-05 | Tampering | Duplicate delivery from repeated retry taps | low | mitigate | `retrySend` returns while `isInFlight(clientMsgId)`; server dedupe | closed |
| T-07-06 | Repudiation | False read receipts for messages never loaded | low | mitigate | `emitPendingReads` emits only `ChatThreadReducer.unreadPeerIds` | closed |
| T-07-07 | Information disclosure | Thread scan holds other threads' metadata in memory | low | accept | See Accepted Risks Log | closed |
| T-07-08 | Elevation of privilege | Unblock by the non-blocker | medium | mitigate | `ChatBlockState.showsUnblock` gates the button; `NOT_BLOCKER` handled; server returns 403 | closed |
| T-07-09 | Tampering | Client banner treated as enforcement | low | accept | See Accepted Risks Log | closed |
| T-07-10 | Tampering | Free-text or label reasons polluting moderation data | medium | mitigate | `ReportChatViewModel` offers `UserReportReason.allCases` and sends `selected.rawValue` | closed |
| T-07-11 | Denial of service | Report details over the server limit | low | mitigate | `maxDetailsLength = 1000` UTF-16 cap | closed |
| T-07-12 | Denial of service | Report spam | low | accept | See Accepted Risks Log | closed |
| T-07-13 | Information disclosure | Report details or reasons in logs | low | mitigate | No logging in the Chat folder (grep: 0) | closed |
| T-07-14 | Tampering | Block sent without consent (accidental tap) | medium | mitigate | `blockAction.block(` has a single call site, inside the `Block {name}?` alert action (`ExpertProfileView.swift`) | closed |
| T-07-15 | Elevation of privilege | Blocking oneself | low | mitigate | `isSameAsCurrentUser` guard; server `CANNOT_BLOCK_SELF` | closed |
| T-07-16 | Denial of service | Repeated block requests from double taps | low | mitigate | `isBlocking` guard, scrim, disabled menu (ProfileBlockActionTests) | closed |
| T-07-17 | Spoofing | Own or spoofed messages inflating the unread count | low | mitigate | `event.senderId != currentUserId()` in `ChatConversationsViewModel`; GET /chats replaces local count | closed |
| T-07-18 | Information disclosure | Visible thread carried into the next account | low | mitigate | `ChatPresence.clearSessionData()` kept and called on logout | closed |
| T-07-19 | Information disclosure | Secrets or real emails in the UAT checklist | low | mitigate | Secret-pattern grep on `07-DEVICE-UAT-CHECKLIST.md`: 0 | closed |
| T-07-20 | Information disclosure | Booking read through the wrong role's endpoint | low | mitigate | `ChatBookingRowRoute` sends the expert shell to `.expertBookingSummary`; endpoints role-scoped server-side | closed |
| T-07-21 | Elevation of privilege | Missing `blocked_by_me` read as blocked by me | low | mitigate | `decodeIfPresent(Bool.self, forKey: .blockedByMe) ?? false` in `ChatThreadItem` | closed |
| T-07-SC | Tampering | npm/pip/cargo installs | low | accept | See Accepted Risks Log | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-07-01 | T-07-07 | The scanned list is the caller's own threads (server participant scope); only the matching row is used and nothing is stored or logged | Plan 07-03 threat model | 2026-11-17 |
| AR-07-02 | T-07-09 | The block banner is a UI hint only; the server rejects sends with `THREAD_BLOCKED` and the client handles that answer | Plan 07-04 threat model | 2026-11-17 |
| AR-07-03 | T-07-12 | Server shared limiter (10/hour, 429); the client shows the server message and never auto-retries | Plan 07-05 threat model | 2026-11-17 |
| AR-07-04 | T-07-SC | No packages were installed or upgraded in this phase | Plans 07-01…07-09 threat models | 2026-11-17 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-11-18 | 22 | 22 | 0 | secure-phase (L1 grep verification, orchestrator) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-11-18
