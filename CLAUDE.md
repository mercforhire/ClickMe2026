# ClickMe iOS

## Related projects

ClickMe spans three separate git repos, checked out side by side. Each has its own branches and commits, so a change across projects means one commit per repo.

| Project | Local path | Stack |
|---------|------------|-------|
| iOS (this repo) | `../ClickMe2026` | SwiftUI |
| Backend | `../ClickMe2026 Backend` | Node.js, Express, Supabase |
| Android | `../ClickMe_Android` | Kotlin, Jetpack Compose |

## How they relate

- **The backend owns the API contract.** Check it rather than guessing at endpoints, fields or error codes:
  - `openapi/clickme-api.yaml`: REST API definition
  - `docs/SOCKET-CONTRACT.md`: WebSocket events
  - `docs/ios/`: specs for individual client features
  - `src/routes`, `src/controllers`, `src/schemas`: the implementation
- **iOS is the source of truth for feature behavior.** Android is a port of this app and mirrors its folder tree, so changes to behavior or business logic here usually need a matching Android change.
- **Android uses the same REST contract as iOS**, so API changes affect both clients.

## Working across projects

- When changing an API call in `ClickMe2026/Network/` or `ClickMe2026/Model/`, read the matching backend route and schema first.
- If a task needs a change in another repo, say so. Don't assume the change was already made there.
- `ClickMe_Android/ios-reference` and `ClickMe_Android/backend-reference` are symlinks to the other two repos, so don't treat them as separate copies.
