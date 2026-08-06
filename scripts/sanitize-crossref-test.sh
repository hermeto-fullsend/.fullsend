#!/usr/bin/env bash
# Tests for sanitize-crossref.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/sanitize-crossref.sh"

failures=0

assert_eq() {
  local test_name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "PASS: $test_name"
  else
    echo "FAIL: $test_name"
    echo "  expected: $expected"
    echo "  actual:   $actual"
    ((failures++))
  fi
}

# --- Bare cross-repo refs ---

assert_eq "bare cross-repo ref" \
  "[org/repo#123](https://redirect.github.com/org/repo/issues/123)" \
  "$(sanitize_crossref "org/repo#123")"

assert_eq "multiple refs" \
  "See [foo/bar#1](https://redirect.github.com/foo/bar/issues/1) and [baz/qux#42](https://redirect.github.com/baz/qux/issues/42)" \
  "$(sanitize_crossref "See foo/bar#1 and baz/qux#42")"

assert_eq "already linked (redirect)" \
  "[org/repo#123](https://redirect.github.com/org/repo/issues/123)" \
  "$(sanitize_crossref "[org/repo#123](https://redirect.github.com/org/repo/issues/123)")"

assert_eq "same-repo ref" "#456" "$(sanitize_crossref "#456")"

assert_eq "dots and hyphens" \
  "[my-org/my.repo#7](https://redirect.github.com/my-org/my.repo/issues/7)" \
  "$(sanitize_crossref "my-org/my.repo#7")"

assert_eq "empty input" "" "$(sanitize_crossref "")"
assert_eq "no refs" "Just a normal string" "$(sanitize_crossref "Just a normal string")"

# --- github.com URL rewrites ---

assert_eq "github.com issue URL" \
  "https://redirect.github.com/org/repo/issues/123" \
  "$(sanitize_crossref "https://github.com/org/repo/issues/123")"

assert_eq "github.com pull URL" \
  "https://redirect.github.com/org/repo/pull/456" \
  "$(sanitize_crossref "https://github.com/org/repo/pull/456")"

assert_eq "github.com discussions URL" \
  "https://redirect.github.com/org/repo/discussions/789" \
  "$(sanitize_crossref "https://github.com/org/repo/discussions/789")"

assert_eq "already redirect.github.com" \
  "https://redirect.github.com/org/repo/issues/123" \
  "$(sanitize_crossref "https://redirect.github.com/org/repo/issues/123")"

assert_eq "github.com URL in markdown link" \
  "[hermetoproject/hermeto#1700](https://redirect.github.com/hermetoproject/hermeto/issues/1700)" \
  "$(sanitize_crossref "[hermetoproject/hermeto#1700](https://github.com/hermetoproject/hermeto/issues/1700)")"

assert_eq "mixed bare ref and github.com URL" \
  "See [org/repo#1](https://redirect.github.com/org/repo/issues/1) and https://redirect.github.com/other/repo/pull/2" \
  "$(sanitize_crossref "See org/repo#1 and https://github.com/other/repo/pull/2")"

# --- stdin mode ---

assert_eq "stdin mode bare ref" \
  "[org/repo#5](https://redirect.github.com/org/repo/issues/5)" \
  "$(echo "org/repo#5" | "$SCRIPT_DIR/sanitize-crossref.sh")"

assert_eq "stdin github.com URL" \
  "https://redirect.github.com/org/repo/issues/99" \
  "$(echo "https://github.com/org/repo/issues/99" | "$SCRIPT_DIR/sanitize-crossref.sh")"

if [[ $failures -gt 0 ]]; then
  echo ""
  echo "$failures test(s) failed"
  exit 1
fi

echo ""
echo "All tests passed"
