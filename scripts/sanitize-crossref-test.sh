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

# Basic rewrite
assert_eq "bare cross-repo ref" \
  "[org/repo#123](https://redirect.github.com/org/repo/issues/123)" \
  "$(sanitize_crossref "org/repo#123")"

# Multiple refs in one string
assert_eq "multiple refs" \
  "See [foo/bar#1](https://redirect.github.com/foo/bar/issues/1) and [baz/qux#42](https://redirect.github.com/baz/qux/issues/42)" \
  "$(sanitize_crossref "See foo/bar#1 and baz/qux#42")"

# Already-linked refs are left alone
assert_eq "already linked" \
  "[org/repo#123](https://redirect.github.com/org/repo/issues/123)" \
  "$(sanitize_crossref "[org/repo#123](https://redirect.github.com/org/repo/issues/123)")"

# Same-repo refs (no slash) are not touched
assert_eq "same-repo ref" \
  "#456" \
  "$(sanitize_crossref "#456")"

# Refs inside URLs are not touched
assert_eq "ref in URL" \
  "https://github.com/org/repo#123" \
  "$(sanitize_crossref "https://github.com/org/repo#123")"

# Dots and hyphens in org/repo names
assert_eq "dots and hyphens" \
  "[my-org/my.repo#7](https://redirect.github.com/my-org/my.repo/issues/7)" \
  "$(sanitize_crossref "my-org/my.repo#7")"

# Mixed: some linked, some bare
assert_eq "mixed linked and bare" \
  "[org/repo#1](https://redirect.github.com/org/repo/issues/1) and [org/repo#2](https://redirect.github.com/org/repo/issues/2)" \
  "$(sanitize_crossref "[org/repo#1](https://redirect.github.com/org/repo/issues/1) and org/repo#2")"

# Empty input
assert_eq "empty input" "" "$(sanitize_crossref "")"

# No refs
assert_eq "no refs" \
  "Just a normal string with no refs" \
  "$(sanitize_crossref "Just a normal string with no refs")"

# stdin mode
assert_eq "stdin mode" \
  "[org/repo#5](https://redirect.github.com/org/repo/issues/5)" \
  "$(echo "org/repo#5" | "$SCRIPT_DIR/sanitize-crossref.sh")"

if [[ $failures -gt 0 ]]; then
  echo ""
  echo "$failures test(s) failed"
  exit 1
fi

echo ""
echo "All tests passed"
