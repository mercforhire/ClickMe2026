#!/usr/bin/env bash
# Clean-checkout Release build plus a "no new warnings" diff (D-19, D-25).
#
# Builds two git-archived trees with the identical Release command, so only
# committed files count (no untracked or ignored files can hide a break):
#   - BASELINE: the shipped build 6 code (a48c664)
#   - CANDIDATE: the release candidate (default HEAD)
# Then normalizes the compiler warnings of each log and prints the ones that
# exist only in the candidate. Exits 0 only when both builds succeed and the
# candidate adds no warning.
#
# Usage:
#   scripts/release-build-check.sh
#
# Optional overrides (environment variables):
#   CANDIDATE  — git ref to check (default: HEAD)
#   BASELINE   — git ref of the shipped build (default: a48c664)
#   PROJECT    — Xcode project (default: ClickMe.xcodeproj)
#   SCHEME     — scheme (default: ClickMe2026)
#   WORK       — scratch directory (default: $TMPDIR/clickme-release-check)
#
# Each build uses about 5 GB of DerivedData, which is deleted right after the
# build; the Swift package checkouts in $WORK/spm are shared by both builds.
# Prints only warning lines and the summary, never environment or file contents.

set -euo pipefail

CANDIDATE="${CANDIDATE:-HEAD}"
BASELINE="${BASELINE:-a48c664}"
PROJECT="${PROJECT:-ClickMe.xcodeproj}"
SCHEME="${SCHEME:-ClickMe2026}"
WORK="${WORK:-${TMPDIR:-/tmp}/clickme-release-check}"
WORK="${WORK%/}"
PREVIEW_SECRETS="ClickMe2026/Debug/PreviewSecrets.swift"

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

rm -rf "$WORK/base" "$WORK/cand" "$WORK/dd"
mkdir -p "$WORK/base" "$WORK/cand" "$WORK/spm"

# Archive a ref into a directory (committed files only).
extract() {
    git archive "$1" | tar -x -C "$2"
}

extract "$BASELINE" "$WORK/base"
extract "$CANDIDATE" "$WORK/cand"

# Build 6 predates the tracked PreviewSecrets.swift, so its tree cannot compile
# on a clean checkout. Add the candidate's committed copy (token-free, and
# Release reads nil) so both trees build with the same preview support.
if [[ ! -f "$WORK/base/$PREVIEW_SECRETS" ]]; then
    mkdir -p "$(dirname "$WORK/base/$PREVIEW_SECRETS")"
    git show "$CANDIDATE:$PREVIEW_SECRETS" > "$WORK/base/$PREVIEW_SECRETS"
fi

# build <tree> <log>: identical Release command for both trees.
build() {
    local tree="$1" log="$2"
    rm -rf "$WORK/dd"
    (
        cd "$tree"
        xcodebuild build \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -configuration Release \
            -destination generic/platform=iOS \
            CODE_SIGNING_ALLOWED=NO \
            -derivedDataPath "$WORK/dd" \
            -clonedSourcePackagesDirPath "$WORK/spm" \
            > "$log" 2>&1
    ) || true
    rm -rf "$WORK/dd"
    if ! grep -q 'BUILD SUCCEEDED' "$log"; then
        echo "BUILD FAILED for $tree (log: $log)" >&2
        grep -E 'error:' "$log" | sort -u | head -20 >&2 || true
        echo "RELEASE CHECK FAILED"
        exit 1
    fi
}

# norm <log>: unique warning lines, independent of the checkout path and of
# line/column numbers, so the same warning in both trees compares equal.
norm() {
    { grep -E 'warning:' "$1" || true; } \
        | { grep -v 'appintentsmetadataprocessor' || true; } \
        | sed -E "s#$WORK/(base|cand)/##g" \
        | sed -E 's#^.*/(ClickMe2026[^:]*/)#\1#; s/:[0-9]+:[0-9]+:/:/' \
        | sort -u
}

echo "Building baseline $BASELINE ..."
build "$WORK/base" "$WORK/base.log"
echo "Building candidate $CANDIDATE ..."
build "$WORK/cand" "$WORK/cand.log"

norm "$WORK/base.log" > "$WORK/base.txt"
norm "$WORK/cand.log" > "$WORK/cand.txt"
comm -13 "$WORK/base.txt" "$WORK/cand.txt" > "$WORK/new.txt"

NEW_COUNT="$(wc -l < "$WORK/new.txt" | tr -d ' ')"
echo "BASELINE WARNINGS: $(wc -l < "$WORK/base.txt" | tr -d ' ')"
echo "CANDIDATE WARNINGS: $(wc -l < "$WORK/cand.txt" | tr -d ' ')"
echo "NEW WARNINGS: $NEW_COUNT"

if [[ "$NEW_COUNT" -ne 0 ]]; then
    cat "$WORK/new.txt"
    echo "RELEASE CHECK FAILED"
    exit 1
fi

echo "RELEASE CHECK PASSED"
