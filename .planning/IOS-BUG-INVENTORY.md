# iOS bug inventory from the Android port (2026-11-07)

Scope: the iOS items that the ClickMe Android port found, fixed or chose to do differently, checked against the current iOS code (main `1094897`, which includes every 2026-11-07 commit) and the backend (`master` = `origin/main` `2ec82af`, the deploy branch).

Paths: iOS paths are relative to `ClickMe2026/ClickMe2026/`. `VS/` = `Views/Screens/`, `CM/` = `VS/Client Mode/`, `EM/` = `VS/Expert Mode/`, `SF/` = `VS/Signup Flow/`. Backend paths are relative to `src/`.

Sources: `ST` = `ClickMe_Android/.planning/STATE.md` (the "iOS follow-ups found while porting Phase N" notes, Report-to-iOS todos and Quick 261028), `BUG-NN` = `phases/16-cross-platform-qa/16-BUG-LOG.md`, `Pn` = `phases/NN-*/NN-CONTEXT.md`, RESEARCH, REVIEW-FIX or SUMMARY files (decision ids given), `TODO` = `todos/pending/2026-11-02-sync-android-bug-fixes-to-ios.md`.

Classes: BUG = still present in iOS · LIKELY = probably present, needs a device check · FIXED = already fixed · BY-DESIGN = intentional difference · BACKEND = needs a backend change.

How it was checked: four read-only sub-agents checked about 100 notes against the code. I spot-checked the seed items myself: C1, P1, B14, the decline schema and the HelpView email.

## Calls

| ID | Title | Area | Severity | Class | iOS evidence (file:line) | Source (Android file/phase) | Fix note |
|---|---|---|---|---|---|---|---|
| C1 | Calls force-end 5 min after scheduled end (TEMP value) | calls | critical | BUG | `VS/Call/Calling/MeetingCallViewModel.swift:532` `5 * 60 // TEMP: was 3600` | TODO; BUG-14; ST Phase 9; P09 CALL-07 | Set to 3600 (Android: end + 60 min). The backend auto-completes at end+15 (`cron/expirePastSessions.js:78`) but does not stop the call. Confirmed on a production iPhone 2026-11-02. |
| C2 | Join closes at start+60 min, so it is disabled for the second half of long sessions | calls | major | BUG | `Model/UIModels/UpcomingBooking.swift:62-67` | BUG-15; P09 09-REVIEW-FIX WR-09 | Window `[start-3600, max(start+3600, end)]`. The backend allows end+120 (`call.controller.js:17`). |
| C3 | Join on the Upcoming Booking details screen does nothing (My Bookings card was fixed) | calls | major | BUG | The card is fixed: `CM/My Bookings/MyBookingsView.swift:340` calls `startCall`. No caller passes `onJoinCall` to `UpcomingBookingView` (`MyBookingsView.swift:108-112`, `CM/Home/HomeClientView.swift:253`) | ST Phase 9 / Report-to-iOS ("Join is a no-op from My Bookings"); P09 D-01 | The original note is fixed. The same no-op moved to the details screen. Wire `onJoinCall`. |
| C4 | `/end` with a 0 s leg is a silent 400 | calls | minor | BUG | `MeetingCallViewModel.swift:689-692` `max(0, duration)` | ST Phase 9; P09 09-11-SUMMARY | `schemas/call.schema.js:29` uses `.positive()`. Send `max(1, d)`. |
| C5 | Never reaches Ended from Agora (`didOfflineOfUid uid == 0` never fires) | calls | minor | LIKELY | `Managers/AgoraManager.swift:276-283` | ST Phase 9; P09 RESEARCH | Handle connection failed or aborted. Local end only comes from hangup or `call.ended`. |
| C6 | Skype/Zoom status copy promises an automatic end at the scheduled time | calls | minor | BUG | `VS/Call/Calling/MeetingCallView.swift:236-239` | ST Phase 9; P09 UI-SPEC | Reword. The cutoff is end+5 (C1) and runs only while the screen is alive. |
| C7 | Skype/Zoom hero has no timer | calls | minor | BUG | `VS/Call/Calling/Subviews/SkypeSessionHero.swift:25-39` | ST Phase 9 | Pass `timerString` / `remainingLabel`. |
| C8 | Upcoming Details has no Join/Open for Skype/Zoom | calls | major | BUG | `CM/Upcoming Booking Details/Subviews/UpcomingBookingJoinCard.swift:33,64-110` | ST Phase 9 | Add an Open-meeting button. Only link and copy exist today. |
| C9 | External provider detection is spoofable (`contains` plus raw fallback) | calls | minor | BUG | `VS/Call/Calling/ExternalMeetingProvider.swift:40-50` | P09 09-REVIEW-FIX WR-08 | Match host == domain or `.domain` suffix and drop the fallback. |
| C10 | Expert Booking Summary has no Join | calls | major | BUG | `EM/Booking Summary/*` (no `startCall`) | ST Phase 11 (D-14) | Add Join, gated by C2's window. |

## Client bookings

| ID | Title | Area | Severity | Class | iOS evidence (file:line) | Source | Fix note |
|---|---|---|---|---|---|---|---|
| B1 | Request Sent is pushed over the booking form, so Back allows a resubmit | bookings | major | BUG | `CM/Make a Booking/MakeABookingView.swift:128-133`; `CM/Request Sent/BookingRequestSentView.swift` | ST Phase 6 | Replace the stack or hide Back. |
| B2 | Month change doesn't cancel the previous availability load (stale overwrite) | bookings | minor | BUG | `CM/Make a Booking/MakeABookingViewModel.swift:306-353` | ST Phase 6 | Keep and cancel the task, check the month before assigning. |
| B3 | Slots card shows the raw IANA zone id | bookings | minor | BUG | `CM/Make a Booking/Subviews/MakeABookingTimeSlotsCard.swift:20-21` | ST Phase 6 | Use `TimeZone.localizedName`. |
| B4 | Slot and Today's Sessions times use a fixed en_US "h:mm a" | bookings | minor | BUG | `Model/UIModels/BookingTimeSlot.swift:19-20`; `CM/Explore/ExploreClientViewModel.swift:176-177` | ST Phases 5, 6 | Use `timeStyle = .short`. |
| B5 | Request Sent loading copy "Sending your booking…" after the request was sent | bookings | minor | BUG | `BookingRequestSentView.swift:142` | ST Phase 6 | "Loading booking…". |
| B6 | Client cannot answer an expert-proposed reschedule from the upcoming flow | bookings | critical | BUG | `CM/My Bookings/Subviews/UpcomingBookingCard.swift:77` → `MyBookingsView.swift:108` → `UpcomingBookingView` (no Accept/Decline); only `BookingSummaryView` has them | BUG-25 (user rated critical); ST Phase 8 D-01 | Add the response card to Upcoming Details, or route "Tap to review" to the summary. |
| B7 | Cancellation comment collected but dropped | bookings | minor | BUG | `CM/Cancellation/ClientCancellationViewModel.swift:161`; `Network/ClickMeAPI+Booking.swift:224` | ST Phase 8 D-05; Report-to-iOS | Send `"label: comment"` in `reason` (≤500), as Android does. The backend validates `reason` but does not store it (K14). |
| B8 | Cancel refund preview always promises the full price | bookings | major | BUG | `ClientCancellationViewModel.swift:117-134` | ST Phase 8 D-06 | Captured inside 24 h refunds 0 (`clientBooking.controller.js:895-920`, `utils/refund.js`). Mirror refund.js. A held booking is a release, not a refund. |
| B9 | Upcoming Booking status pill hard-coded "Confirmed" | bookings | minor | BUG | `CM/Upcoming Booking Details/Subviews/UpcomingBookingStatusRow.swift:23` | ST Phase 8 D-14; BUG-25 | Bind to the real status. |
| B10 | Money divided by 100 for every currency (JPY wrong), integer division drops cents | bookings/payments | major | BUG | `Model/UIModels/BookingTopic.swift:32`; `CM/Upcoming Booking Details/UpcomingBookingViewModel.swift:185`; `CM/Expert Profile/ExpertProfileViewModel.swift:195`; `ExploreClientViewModel.swift:271`; `CM/Booking Summary/BookingSummaryViewModel.swift:356`; `ClientCancellationViewModel.swift:132`; `EM/Expert Dashboard/ExpertDashboardViewModel.swift:345`; `PayoutsViewModel.swift:259`; `TopicsSetupTopicCard.swift:26` | ST Phases 5, 8 (D-14), 10 (D-09) | One shared formatter using currency minor digits (`CurrencyItem.minorUnitDigits` exists). Reach is low while pickers are CA/US only, but the integer `/100` that drops cents (for example $12.50 shown as $12) matters now. |
| B11 | Past tab shows nothing when empty | bookings | minor | BUG | `MyBookingsView.swift:291-305` | ST Phase 8 D-11 | Add the empty state for tab 1. |
| B12 | Keep Booking pops to the My Bookings root | bookings | minor | BUG | `MyBookingsView.swift:133-135` | ST Phase 8 | Pop one level. |
| B13 | Cancel shown on a booking whose session already ended | bookings | minor | BUG | `CM/Upcoming Booking Details/Subviews/UpcomingBookingSecondaryActions.swift:40` | ST Phase 16.5 WR-01 | Hide once `end < now`. The backend cancel has only a status guard, see K12. |
| B14 | Long-lead paid bookings: falls through to a saved-card confirm the backend now refuses, no 6-day picker cap, missing error codes | bookings/payments | major | BUG | `MakeABookingViewModel.swift:452-462` (catch → `performLongLeadBooking`); `Model/Enums/ErrorCode.swift:120` lacks `LONG_LEAD_NOT_AVAILABLE`, `RESCHEDULE_TOO_FAR_AHEAD` | ST Quick 261028-to1 / ve4; P16.2 RESEARCH | `booking.controller.js:379-382` marks REQUIRES_SAVED_CARD terminal, `:1085` NOT_AVAILABLE, `utils/reschedule.js:82-83`. Cap the booking and reschedule pickers at now+6 d and map both codes. |
| B15 | No handling of the `booking/payment_actions` push, `payment_action_required`, or `/bookings/:id/recover-payment` | bookings/payments | major | BUG | no matches in iOS | ST Quick 261028-to1 | Matters only for long-lead bookings made before 2026-10-28. At minimum route the push to booking detail, as Android does. See decision Q3. |
| B16 | Reschedule picker details: no `exclude_booking_id`, pops to root with no message, stale "Settings > Payment" copy, wrong "cancel and book again" advice for a held booking moved under 24 h | bookings | minor | BUG | `CM/Reschedule/RescheduleViewModel.swift:206,323,355,357`; `Network/ClickMeAPI+Availability.swift:37`; `MyBookingsView.swift:141-144`; `BookingSummaryViewModel.swift:274,286` | P16.2 RESEARCH, D-06, D-09, D-10, A4 | `availability.controller.js:225-232` supports `exclude_booking_id`. Pop to origin plus a "Reschedule request sent" toast are Android choices, so port them only if wanted. |
| B17 | Booking Summary offers Leave a Review for every past status | bookings | minor | BUG | `CM/Booking Summary/BookingSummaryView.swift:200` (the Past card is already gated, `PastBookingCard.swift:115`) | ST Phase 13 D-18 | Gate on `.completed`. Edit and resubmit of a review is BY-DESIGN: the backend upserts (`reviews.controller.js:73`), Android chose read-only (D-19). |
| B18 | `booking.update` with status `rescheduled` fails to decode and is dropped | bookings/realtime | major | BUG | `Realtime/RealtimeEvents.swift:56`; `Model/Enums/BookingStatus.swift:14-24` | ST Report-to-iOS | `services/events.js:58` emits `rescheduled` (SOCKET-CONTRACT.md:141-143). Add the case or an unknown fallback. |
| B19 | Booking started from Favorites leaves Request Sent on the Profile stack | bookings | minor | BUG | `CM/Home/HomeClientView.swift:87-94` (resets only explore and bookings paths) | P16.3 16.3-08-SUMMARY | Also reset `profilePath` and `searchPath`. |

## Payments

| ID | Title | Area | Severity | Class | iOS evidence (file:line) | Source | Fix note |
|---|---|---|---|---|---|---|---|
| P1 | Dismissing the FlowController sheet with a preselected card still confirms and places a hold | payments | major | BUG | `CM/Make a Booking/Subviews/MakeABookingStripePaymentSheet.swift:101-106` (checks only `paymentOption != nil`) | ST Phase 7 D-18 | Treat dismissal as cancel; confirm only on an explicit tap. The sub-agent rated this critical; see decision Q4. |
| P2 | Confirm timeout plus retry shows "slot taken" for the user's own pending booking | payments | major | BUG | `MakeABookingViewModel.swift:609-614,637-639` | ST Phase 7 D-19; Backend notes Phase 7 | Point to My Bookings. The backend could also replay idempotently (K15). |
| P3 | Lifecycle card always says "A hold is placed" | payments | minor | BUG | `CM/Request Sent/Subviews/PaymentLifecycleCard.swift:61`; `BookingRequestSentView.swift:115-118` | ST Phase 7 (UI-SPEC Open Item 3) | Moot for new bookings once B14 is fixed (long-lead is blocked). Keep correct copy for older long-lead rows. |
| P4 | No alert when 3DS is cancelled | payments | minor | BY-DESIGN | `MakeABookingStripePaymentSheet.swift:216-217`; `MakeABookingViewModel.swift:672-676` | ST Phase 7 D-15 | Silent reset on a user cancel. Android shows "Payment wasn't completed". Optional toast. |
| P5 | Stale "TODO(backend): stripe_account" comment | payments | minor | BUG | `MakeABookingViewModel.swift:184-195`; `StripePaymentSheet.swift:177-180` | ST Phase 7 | Comment-only. The backend sends it (`booking.controller.js:536-538`). |
| P6 | Paid-path slot-taken and meeting-link copy differs from the free path | payments | minor | BUG | `MakeABookingViewModel.swift:614,622` vs `:396` | ST Phase 7 D-14 | One shared error mapper. |
| P7 | Payment Methods optimistic default can show a rejected default | payments | – | FIXED | `VS/Settings/Payment Methods/PaymentMethodsViewModel.swift:170-188` (rolls back on failure) | ST Phase 7 | – |
| P8 | Hard-coded JWT in `Debug/PreviewSecrets.swift` | security | minor | FIXED | `Debug/PreviewSecrets.swift:21-33` is inside `#if DEBUG` and gitignored (`.gitignore:4`) | ST Report-to-iOS | Not in release builds. Still rotate the token if it was ever shared. |
| P9 | `Environments.plist` Current = Production (pk_live) | config | – | BY-DESIGN | `Environments.plist:6`; build-6 config `a48c664` | ST Phase 1 D-05 | Intended for release. All environments point at the production Railway backend. |

## Explore, expert profile, favorites, search

| ID | Title | Area | Severity | Class | iOS evidence (file:line) | Source | Fix note |
|---|---|---|---|---|---|---|---|
| X1 | Expert Profile fails silently on 404 (suspended or deleted) and on network errors | explore | major | BUG | `CM/Expert Profile/ExpertProfileViewModel.swift:68-69` (`try?`) | ST Phase 5 | Show "This profile isn't available" plus a retry state (`publicProfile.controller.js:73`). |
| X2 | Empty Expertise, Topics and Reviews sections render bare headers; zero reviews renders oddly | explore | minor | LIKELY | `ExpertProfileView.swift:203-215`; `Subviews/ExpertProfileHero.swift:97-100` | ST Phase 5 D-12 | Hide empty sections. |
| X3 | Featured topic cards ignore `is_free` | explore | minor | BUG | `Model/Responses/ClientHomeData.swift:39-58`; `ExploreClientViewModel.swift:254-271` | ST Phase 5 D-21 | Decode `is_free` and show "Free". |
| X4 | Search result tag pills truncate | search | minor | BUG | `CM/Search/Subviews/SearchExpertCard.swift:84-88` | BUG-16 | User prefers Android's full text. |
| X5 | Favorites: only 20 shown, empty-state buttons do nothing, Pro Tip says "star", list scan instead of details `is_favorite` | favorites | major | BUG | `CM/Favorites/FavoritesViewModel.swift:67`; `Network/ClickMeAPI+Favorites.swift:19`; `CM/Profile/ClientProfileHomeScreen.swift:207`; `Favorites/Subviews/FavoritesProTipCard.swift:31`; `ExpertProfileViewModel.swift:70-75` | P16.3 D-01, D-05, D-06, D-07, D-12 | Page or raise the limit, wire the buttons, fix the copy, decode `is_favorite` (`publicProfile.controller.js:289-299`). |
| X6 | Full reviews list fetches page 1 only (20 max) | reviews | minor | BUG | `CM/Reviews/ExpertReviewsViewModel.swift:102` | P16.3 RESEARCH | Add paging. |

## Signup and mode switch

| ID | Title | Area | Severity | Class | iOS evidence (file:line) | Source | Fix note |
|---|---|---|---|---|---|---|---|
| S1 | Publish allowed without a photo, then the server rejects it | signup | major | BUG | `SF/SignupAccumulator.swift:92-100` | ST Phase 4 D-03 | Require an avatar before Publish (`onboarding.controller.js:176-187` → 422). |
| S2 | Province required on iOS, optional on the server | signup | minor | BY-DESIGN | `SignupAccumulator.swift:96,119` | ST Phase 4 | Android made it optional. Product call (decision Q5). |
| S3 | Verified-email state lost on resume | signup | major | BUG | `SignupAccumulator.swift:38,141-181`; `SF/Verify Email/SignupVerifyEmailViewModel.swift:104,114`; `checkEmailVerified()` has no callers | ST Phase 4 D-09 | Seed from `email_verified` and `GET /auth/email/status` on resume. |
| S4 | Tags sent alphabetically, so the primary tag is accidental | signup | minor | BUG | `SF/Setup Tags/SignupTagsViewModel.swift:87,103-105`; `LanguageSelectionViewModel.swift:70,86` | ST Phase 4 D-14 | Keep tap order (`onboarding.controller.js:127` `is_primary: idx===0`). Language order is not stored server-side. |
| S5 | `country_code` not normalized on publish | signup | minor | BUG | `SignupAccumulator.swift:197` | ST Phase 4 D-05 | Call `Countries.normalize`. Low risk with CA/US pickers (`31121c8`). |
| S6 | Photo zoom slider affects only the preview; the upload is uncropped | signup | minor | BUG | `SF/Profile Photo/Subviews/ProfileAvatarRing.swift:57`; `SignupProfilePhotoViewModel.swift:83,156` | ST Phase 4 D-12 | Render the crop into the upload. |
| S7 | Switching to Expert mode has no setup-status gate | auth/mode | major | BUG | `CM/Home/HomeClientView.swift:243-245`; `ClientProfileHomeScreen.swift:226`; `EM/Home/HomeExpertView.swift:199-200` (only Splash gates, `SplashViewModel.swift:76-80`) | ST Phase 4 D-17 | Open the setup hub when setup is incomplete, as Android does. Pairs with K13. |
| S8 | Signup password rule: Android requires a digit | signup | minor | BY-DESIGN | – | P04 CONTEXT (deviations) | Align if wanted. |

## Expert mode

| ID | Title | Area | Severity | Class | iOS evidence (file:line) | Source | Fix note |
|---|---|---|---|---|---|---|---|
| E1 | Topic delete has no confirmation | expert-topics | minor | BUG | `EM/Topics/Subviews/TopicsSetupTopicCard.swift:49-51` | ST Phase 10 D-06 | Confirm dialog "Delete this topic?". |
| E2 | Topic price input whole units ×100, "$" label | expert-topics | major | BUG | `EM/Topics/Topic Editor/TopicEditorViewModel.swift:114,252-270`; `TopicEditorView.swift:100` | ST Phase 10 D-09 | Parse decimals using the currency's digits. A price like 12.50 cannot be entered today. |
| E3 | Topic edit sends the /me default currency, not the topic's | expert-topics | major | BUG | `TopicEditorViewModel.swift:68-69,271` | ST Phase 10 D-10 | Seed from `topic.hourlyRate.currency`. |
| E4 | PATCH cannot clear icon or description (nil omitted) | expert-topics | minor | BUG | `Model/Requests/ExpertTopicRequest.swift:42-54` | ST Phase 10 | Encode explicit `null` (`expertTopics.schema.js:124,128` are nullable). |
| E5 | Time-range picker writes through; Cancel doesn't revert | availability | minor | BUG | `EM/Availability/AvailabilitySettingsView.swift:68-77`; VM `:118-120` | ST Phase 10 | Edit a copy, commit on Done. |
| E6 | "Add hours" can make a 24:00 end the picker can't show; 1440 renders "12:00 PM" | availability | minor | BUG | `Subviews/AvailabilityDayRow.swift:115-116`; `TimeRangePickerSheet.swift:24`; `AvailabilitySettingsView.swift:35-41` | ST Phase 10 (open Q1) | Add 24:00 labelled "12:00 AM", or cap at 23:30. |
| E7 | Off-grid stored times (09:15) have no selected picker row | availability | minor | BUG | `TimeRangePickerSheet.swift:24,109` | ST Phase 10 | Snap on load or insert the value. |
| E8 | Stale 409 comment on `deleteMyTopic` | expert-topics | minor | BUG | `TopicsSetupViewModel.swift:177-178`; `Network/ClickMeAPI+ExpertProfile.swift:66-67` | ST Phase 10 | Comment-only (soft delete, 404 only). |
| E9 | Decline reasons OUTSIDE_EXPERTISE, SCHEDULE_CONFLICT and PRICING rejected with 422 | expert-requests | – | FIXED | `EM/Request decision/RequestDecisionViewModel.swift:288-293` | TODO; ST Phase 11 D-01, 11-12 | Fixed server-side: `schemas/booking.schema.js:159-180` accepts all 7 codes (backend `075fe81`, on `origin/main`). No iOS change needed. |
| E10 | Decline with nil `reason_text` rejected with 422 | expert-requests | – | FIXED | `Network/ClickMeAPI+Booking.swift:363-366` | ST Phase 11 D-02 | Backend `784aa07`: body and note optional. |
| E11 | `BookingConfirmedView` orphaned; accept shows only "Accepted!" | expert-requests | minor | BUG | `EM/Confirmed/BookingConfirmedView.swift` (previews only); `RequestDecisionActionFooter.swift:60` | ST Phase 11 D-04 | Push the confirmed screen after accept. |
| E12 | Calendar event title uses the expert's own name | expert-requests | minor | BUG | `EM/Confirmed/Subviews/CalendarEventEditorSheet.swift:53` | ST Phase 11 D-06 | Use the client's name. Latent until E11 is wired. |
| E13 | Expert cancel always promises the client a full refund | expert-bookings | major | BUG | `EM/Booking Summary/ExpertBookingSummaryView.swift:139`; `Cancellation/ExpertCancellationView.swift:61`; `ExpertCancellationViewModel.swift:49` | ST Phase 11 D-16 | The backend uses refund.js (0 inside 24 h, `expertBooking.controller.js:1063-1071`). Fix the copy, or change the policy (decision Q2). |
| E14 | Expired request cards dimmed to 55% (contrast) | expert-requests | minor | LIKELY | `EM/Incoming Requests/Subviews/IncomingRequestCard.swift:88` | ST Phase 11 (UI-SPEC A5) | Dim only the background or badge. |
| E15 | Expert Upcoming card Reschedule does nothing | expert-bookings | major | BUG | `EM/Home/HomeExpertView.swift:156`; `EM/Expert Dashboard/ExpertDashboardView.swift:235`; default `{ _ in }` at `UpcomingBookingsView.swift:117` | BUG-26 | Pass `onReschedule` → `ExpertRescheduleView` (already used at `HomeExpertView.swift:215`). |
| E16 | Client Profile (expert side) shows "$0" earnings | expert-clients | minor | BUG | `EM/Client Profile/ClientProfileViewModel.swift:108`; `Subviews/ClientProfileBookingCard.swift:33` | P16.4 D-09 | Map `consultationFee` / `earningsBreakdown` and format with the currency. |
| E17 | Expert hub online dot hard-coded | expert-profile | minor | BUG | `EM/Profile/ExpertProfileHomeViewModel.swift:40,69` | ST Phase 14 | Bind to presence or remove. |
| E18 | Private booking note: no discard prompt, no 5000 cap, whitespace saved as typed | expert-notes | minor | BUG | `EM/Booking Note/ExpertBookingNoteViewModel.swift:83-89`; `ExpertBookingNoteView.swift` | P16.4 D-01, D-02, D-04 | Over 5000 characters returns a 422 (`booking.schema.js:150-152`). Add a cap with counter, trim, and a discard dialog. |

## Chat

| ID | Title | Area | Severity | Class | iOS evidence (file:line) | Source | Fix note |
|---|---|---|---|---|---|---|---|
| H1 | Send waits for the ack, with no optimistic bubble or retry | chat | minor | BUG | `VS/Chat/Chatting/ChattingViewModel.swift:254-320` | ST Phase 12 D-01 | Pending bubble keyed by `client_msg_id`, failed state, retry. |
| H2 | Chat report sends display labels, not the enum | chat/moderation | minor | BUG | `VS/Chat/Report and Block/ReportChatViewModel.swift:154,256-263` (the profile report uses `UserReportReason` correctly) | ST Phase 12; Report-to-iOS | No 422: the chat route accepts any string (`schemas/chat.schema.js:46`), so moderation data is mixed. Use `UserReportReason`. |
| H3 | No blocked-thread state; Unblock shown to the blocked side too | chat | major | BUG | `ChattingView.swift:104-127` (composer always shown); `Report and Block/Subviews/ReportChatBlockCard.swift:74-77` | ST Phase 12 (CHAT-UNBLOCK 5, 7); Report-to-iOS | `c8b2f62` added Unblock but not the states. Use `blocked_by_me`: hide the composer, show "You blocked…" / "You can't reply…". |
| H4 | Profile Block opens the combined screen; copy claims profile and bookings are hidden | chat | major | BUG | `CM/Expert Profile/ExpertProfileView.swift:293-301`; `ReportChatBlockCard.swift:93,98` | ST Phase 12 D-05 | The block only sets `chats.is_blocked`. Fix the copy (or enforce it on the backend), and use a confirm dialog from the profile. |
| H5 | Typing and View profile do nothing until a peer message arrives | chat | minor | BUG | `ChattingViewModel.swift:101,221-227,373,429`; `ChattingView.swift:72` | ST Phase 12 | Seed `peerUserId` from `ChatThreadItem.partner.id`. |
| H6 | `loadEarlier` prepends without de-duplication | chat | minor | BUG | `ChattingViewModel.swift:243` | ST Phase 12 | Filter by `serverId`. |
| H7 | No unread count on conversation rows; backend never increments it | chat | major | BACKEND | `VS/Chat/Conversations/Subviews/ChatConversationRow.swift` ignores `unreadCount` | ST Backend notes Phase 12 | Backend: increment on send (`chats.controller.js:446-451` is commented out) and reset on `message.read` (`services/socket.js:303-308`). Then add the iOS badge. |
| H8 | "Read" label doesn't update live in an open chat | chat | minor | LIKELY | Code looks correct: `ChattingViewModel.swift:333,386-399`; `Realtime/RealtimeService.swift:233`; backend `socket.js:319` emits | BUG-13 (seen failing on both apps on device) | The code reads as fixed but the device test failed. Re-test, and trace `message.read` delivery on the backend. |
| H9 | Foreground banner shown for the chat that is on screen | chat/push | minor | BUG | `ClickMe2026AppDelegate.swift:149-158` | ST Phase 13 D-13 | Suppress when `thread_id` matches the open thread. |

## Push

| ID | Title | Area | Severity | Class | iOS evidence (file:line) | Source | Fix note |
|---|---|---|---|---|---|---|---|
| N1 | `PushEvent` parses only chat and booking-request pushes; every other tap does nothing | push | major | BACKEND | `Model/Push/PushEvent.swift:63-85`; nil → no-op at `ClickMe2026AppDelegate.swift:185-189` | TODO; ST Phase 13 D-04 | `services/push.js:272-274` adds `category`/`sub_category` for Android only. Simplest fix is to send them for iOS too (user decision D-04). Alternatively extend the iOS `event_type` map, but reminder, no-show and nudge crons send no `event_type`. Either way, route nil to the notifications list. |
| N2 | Push tap routes into the current mode shell (no mode switch) | push | major | BUG | `CM/Home/HomeClientView.swift:137-171`; `EM/Home/HomeExpertView.swift:81-132` | ST Phase 13 D-05 | Derive the target mode from the category, switch, then route. |
| N3 | `booking/requests` push opens the list, not the request | push | minor | BUG | `Managers/PushRouter.swift` (`.incomingRequests`) | ST Phase 13 D-08 | Use `booking_id` (`services/events.js:262`). |
| N4 | Logout leaves the iOS `device_tokens` row, so the old account keeps getting pushes | push/auth | major | BUG | `Managers/UserManager.swift:293` (Task), `:299` (bearer cleared), `:652` (guard returns) | BUG-24 (SW.1, Supabase 2026-11-04) | Await the unregister before clearing auth, or capture the token first. Privacy issue. |

## Settings, profile and account

| ID | Title | Area | Severity | Class | iOS evidence (file:line) | Source | Fix note |
|---|---|---|---|---|---|---|---|
| T1 | Profile language edits never save (auto-save omits languages) | profile | major | BUG | `VS/Settings/Client Profile Settings/ClientProfileSettingsViewModel.swift:261-263` (skipped on purpose), snapshot `:194` | TODO; ST Phase 14 | `schemas/userProfile.schema.js:59-61` accepts `languages.{language_ids, custom_languages}`. Check the expert settings VM for the same gap. |
| T2 | Help "Email Us" uses the wrong support address | settings | major | BUG | `VS/Settings/Help/HelpView.swift:20` `support@clickme.app` | TODO (Phase 17); ST Phase 17 decision | Change to `clickmeapp@uptrendinvestments.net` (Android `b80f99e9`). No other real occurrences; preview defaults only. |
| T3 | Delete Account "Pause Account" card does nothing | settings | minor | BUG | `VS/Settings/Delete account/DeleteAccountView.swift:35,95`; `VS/Settings/Account Security/AccountSecurityView.swift:207` | ST Phase 14; P16.5 D-10; PARITY-AUDIT #14 | No backend pause route. Remove the card (as Android did). |
| T4 | Notification preferences PATCH right after load | settings | minor | BUG | `VS/Settings/Notifications/NotificationSettingsView.swift:59`; VM `:90` | P16.5-12-SUMMARY | Skip auto-save until the first load is applied. |
| T5 | Feedback allows 1-9 characters, then the server rejects it (422) | settings | minor | BUG | `VS/Settings/Feedback/FeedbackViewModel.swift:158` | P16.5 D-05 | `schemas/feedback.schema.js:20` `min(10)`. Validate on the client. Staying on a cleared form vs a thanks dialog (D-06) is BY-DESIGN. |
| T6 | Delete Account copy says all data incl. bookings and payments is removed; the backend keeps or anonymizes them | settings/privacy | major | BUG | `VS/Settings/Delete account/Subviews/DeleteAccountWarningHeader.swift:22` | ST Phase 17 pending todo (Android `delete_account_body`) | `services/accountCascade.js:245-377` keeps bookings (PII scrubbed), messages, reviews, reports and the payment audit. Reword on both apps (store-policy accuracy). |
| T7 | Dead screens: `CancellationPoliciesView`, `ReadyToStartCallView` | cleanup | minor | BUG | `CM/Cancellation Policies/CancellationPoliciesView.swift:42`; `VS/Call/Ready/ReadyToStartCallView.swift` (previews only) | PARITY-AUDIT DEF-7 | Delete or wire them in (decision Q7). |
| T8 | Remember last login email exists only on a branch | auth | minor | BY-DESIGN | `b0629d9` only on `feature/remember-login-email`, not merged | ST Phase 16 batch notes | Not shipped on Android 1.0.0 either. User decision (Q1). |
| T9 | Account suspension and offline auto-login | auth | – | FIXED | `Network/NetworkService.swift:159,201`; `Managers/UserManager.swift:29,132` (`097db7a`, `f43f38d`) | ST Phase 12 notes | Context only. |

## Deliberate Android deviations (BY-DESIGN, port only if wanted)

| ID | Title | Area | Severity | Class | iOS evidence (file:line) | Source | Fix note |
|---|---|---|---|---|---|---|---|
| D1 | Private note on Upcoming Booking Details (neither app has it) | bookings | minor | BY-DESIGN | – | BUG-18 (product request, both apps) | Product request. |
| D2 | Booking ID on Payment History and expert list rows | bookings | minor | BY-DESIGN | – | BUG-29 (Android shipped `33951e9c`) | iOS rows not checked. Port if wanted. |
| D3 | Phase 15 loading standard (skeleton, inline error with Retry, pull-to-refresh, refresh-failed snackbar) instead of spinners or alerts | ux | minor | BY-DESIGN | – | P16.3 D-11; P16.5 D-02, D-04; P15 | iOS shows a spinner and clears lists on reload. |
| D4 | Favorites: optimistic heart with rollback snackbar, confirm before remove | favorites | minor | BY-DESIGN | – | P16.3 D-03, D-12 | – |
| D5 | Search stack reset after booking/cancel | search | minor | BY-DESIGN | – | P16.1-02-SUMMARY | Overlaps B19. |
| D6 | Profile auto-save with status icon and flush on Back; Delete Account as two forms with Farewell | profile | minor | BY-DESIGN | – | ST Phase 14 (14-05, 14-07) | – |
| D7 | Client Reschedule shown except while pending_reschedule | bookings | – | BY-DESIGN | – | P16.2 D-04 (amended, now iOS parity) | No change. |
| D8 | My Bookings loads page 1 only (20 per bucket) | bookings | minor | BY-DESIGN | – | ST D-09 (kept on both apps) | Later improvement for both. |
| D9 | Full Client Profile without a booking | expert-clients | – | BY-DESIGN | – | BUG-33 (closed, won't do, 2026-11-05) | Privacy gate kept. |

## Backend items that affect iOS (BACKEND)

| ID | Title | Area | Severity | Class | iOS evidence (file:line) | Source | Fix note |
|---|---|---|---|---|---|---|---|
| K1 | Accept `message` validated then discarded | expert-requests | minor | BACKEND | iOS sends it: `EM/Request decision/RequestDecisionViewModel.swift:186-190` | ST Backend Phase 11 (C10) | Deliver it (chat or notification), or hide the iOS field. |
| K2 | Decline note (`decline_reason_text`) stored, never returned | bookings | major | BACKEND | no client view reads it | BUG-28 | Expose on client booking detail and notification; then iOS and Android display it. |
| K3 | No review flag on expert booking detail or bookings list | reviews | minor | BACKEND | – | BUG-19; ST Backend Phase 13 (`has_review`) | Add `has_review` / `client_review`. |
| K4 | `meeting_url` cannot be cleared | expert-profile | minor | BACKEND | `VS/Settings/ExpertProfileSettingsViewModel.swift:287-312` | ST Phase 14 | Accept null or ""; iOS sends null when the field is emptied. |
| K5 | `potential_earnings` always /100; `consultation_fee.label` hard-codes "$" | expert | minor | BACKEND | shown at `EM/Booking Summary/ExpertBookingSummaryView.swift:380`; `RequestDecisionEarningsSection.swift:81,208` | ST Backend Phase 11 (C4, C5) | Use currency digits and symbol. |
| K6 | Lone saved card never promoted to default | payments | minor | BACKEND | – | BUG-17 | Promote when none is default. |
| K7 | Deleted card's connected clone can still be charged after a move | payments | major | BACKEND | – | BUG-27 (code reading) | Evict `connected_pm_clones` on delete. Reassess under the money clause. |
| K8 | Stripe tax-ID prompt shown to a client account | payments | minor | BACKEND | – | BUG-03 | Investigate the Connect/Customer setup. |
| K9 | Join window 120/120 min vs docs 10/0; `/bookings/:id/join` has no status check | calls | minor | BACKEND | – | ST Backend Phase 9; Phase 16.5 | Tighten together with C2's client rule. |
| K10 | `POST /bookings/request` trusts `duration_minutes` and accepts a past `scheduled_start` | bookings | minor | BACKEND | – | ST Backend notes (Phase 6) | Validate on the server. |
| K11 | `price_amount` unbounded (INTEGER overflow 500); tag replace uncapped | expert-topics | minor | BACKEND | – | ST Backend Phase 10 | Add zod max. |
| K12 | Client cancel has no time guard | bookings | minor | BACKEND | – | ST Phase 16.5 | Reject after `end_time` (pairs with B13). |
| K13 | Any `/expert/*` call promotes a client to expert server-side | auth/mode | major | BACKEND | `SplashViewModel.swift:65-80,109-110` | ST Phase 4 D-17/D-23 (consequence) | `middleware/ensureExpert.js:65-106`. Promote only on an explicit setup call, or gate on iOS (S7). |
| K14 | Cancel `reason` validated, not stored | bookings | minor | BACKEND | – | ST Backend Phase 8 | Store it, or B7 has no effect. |
| K15 | Confirm retry with the same `booking_attempt_id` returns SLOT_UNAVAILABLE for one's own booking | payments | minor | BACKEND | – | ST Backend Phase 7 | Idempotent replay (pairs with P2). |
| K16 | `GET /chats` hides empty threads; no notifications mark-read; `/feedback/submit` no rate limit | chat/push | minor | BACKEND | – | ST Backend Phases 12, 13, 16.5 | Lower priority. |

## Decisions for the user

- Q1: Merge `feature/remember-login-email` (iOS `b0629d9`, Android `0c9ecc55`)? Neither app ships it on main.
- Q2: E13 and B8. Should an expert cancel always refund the client in full? Today the backend applies the 24 h rule and iOS promises a full refund.
- Q3: B15. Build long-lead SCA recovery on iOS for bookings made before 2026-10-28, or only route the push to the booking, as Android does?
- Q4: P1. Is a dismissed sheet with a preselected card a cancel (Android) or a confirm? It places a real hold. I rated it major; the sub-agent rated it critical.
- Q5: S2 and S7. Should province be optional, and should the Expert mode switch be gated by setup status? Both are Android deviations.
- Q6: N1. Fix the iOS no-op pushes by adding `category` to the iOS payload (one backend change, alters iOS behavior, D-04), or by extending the iOS map?
- Q7: T7. Delete the dead screens or wire them in? CancellationPoliciesView could be linked from the cancel flow.
- Q8: H8 / BUG-13. The code looks fixed but the device test failed. Needs a re-test before planning.
