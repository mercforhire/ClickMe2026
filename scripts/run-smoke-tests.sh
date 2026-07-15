#!/usr/bin/env bash
# Runs the integration/smoke tests against the real backend by injecting
# credentials into the simulator test process. Env vars set on this shell
# session are picked up by SmokeConfig at runtime.
#
# Usage:
#   CLICKME_TEST_EMAIL=you@example.com \
#   CLICKME_TEST_PASSWORD=hunter2 \
#     scripts/run-smoke-tests.sh
#
# Optional overrides:
#   SIMULATOR      — device name or UDID (default: latest iPhone 17)
#   CONFIGURATION  — Debug/Release (default: Debug)

set -euo pipefail

if [[ -z "${CLICKME_TEST_EMAIL:-}" ]]; then
    echo "error: CLICKME_TEST_EMAIL must be set (CLICKME_TEST_PASSWORD needed for happy-path test)." >&2
    exit 2
fi

SCHEME="${SCHEME:-ClickMe2026}"
PROJECT="${PROJECT:-ClickMe2026.xcodeproj}"
CONFIGURATION="${CONFIGURATION:-Debug}"
SIMULATOR="${SIMULATOR:-iPhone 17}"

# Forwards CLICKME_TEST_* env vars into the simulator process via the
# SIMCTL_CHILD_* prefix (Xcode inherits these when spawning the test host).
export SIMCTL_CHILD_CLICKME_TEST_EMAIL="$CLICKME_TEST_EMAIL"
export SIMCTL_CHILD_CLICKME_TEST_PASSWORD="${CLICKME_TEST_PASSWORD:-}"

xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "platform=iOS Simulator,name=$SIMULATOR,OS=latest" \
    -only-testing:"ClickMe2026Tests/AuthSmokeTests" \
    | xcbeautify 2>/dev/null || cat
