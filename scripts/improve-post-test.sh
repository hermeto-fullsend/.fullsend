#!/usr/bin/env bash
# Tests for improve-post.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

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

assert_contains() {
  local test_name="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "PASS: $test_name"
  else
    echo "FAIL: $test_name"
    echo "  expected to contain: $needle"
    echo "  actual: $haystack"
    ((failures++))
  fi
}

assert_not_contains() {
  local test_name="$1" haystack="$2" needle="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "PASS: $test_name"
  else
    echo "FAIL: $test_name"
    echo "  expected NOT to contain: $needle"
    echo "  actual: $haystack"
    ((failures++))
  fi
}

# --- Fake gh CLI: records calls, returns canned issue-list results ---
FAKE_BIN_DIR="$TMPDIR/bin"
mkdir -p "$FAKE_BIN_DIR"
cat > "$FAKE_BIN_DIR/gh" <<'FAKE_GH_EOF'
#!/usr/bin/env bash
echo "$@" >> "$FAKE_GH_LOG"
case "$1 $2" in
  "issue list")
    if [[ "${FAKE_GH_DUPLICATE:-false}" == "true" ]]; then
      echo '[{"number":1}]'
    else
      echo '[]'
    fi
    ;;
  "issue create")
    echo "https://github.com/fake/repo/issues/99"
    ;;
esac
FAKE_GH_EOF
chmod +x "$FAKE_BIN_DIR/gh"

export PATH="$FAKE_BIN_DIR:$PATH"
export FAKE_GH_LOG="$TMPDIR/gh-calls.log"
export FULLSEND_SOURCE_REPO="myorg/hermeto"

# --- Test 1: action=clean makes no gh calls ---
: > "$FAKE_GH_LOG"
mkdir -p "$TMPDIR/clean-workspace"
cat > "$TMPDIR/clean-workspace/agent-result.json" <<'EOF'
{"action": "clean", "summary": "No improvements found."}
EOF
OUTPUT=$(FULLSEND_WORKSPACE="$TMPDIR/clean-workspace" bash "$SCRIPT_DIR/improve-post.sh")
assert_contains "clean action skips issue creation" "$OUTPUT" "No issues to create"
assert_eq "clean action makes no gh calls" "" "$(cat "$FAKE_GH_LOG")"

# --- Test 2: new finding creates an issue ---
: > "$FAKE_GH_LOG"
export FAKE_GH_DUPLICATE=false
mkdir -p "$TMPDIR/new-workspace"
cat > "$TMPDIR/new-workspace/agent-result.json" <<'EOF'
{
  "action": "improvements",
  "summary": "Found one issue.",
  "findings": [
    {
      "category": "code-quality",
      "title": "Split overly long function in fetchers.py",
      "body": "The fetch() function is 80 lines with deep nesting.",
      "file": "hermeto/core/fetchers.py",
      "line": 42
    }
  ]
}
EOF
OUTPUT=$(FULLSEND_WORKSPACE="$TMPDIR/new-workspace" bash "$SCRIPT_DIR/improve-post.sh")
assert_contains "new finding logs creation" "$OUTPUT" "Creating issue: Split overly long function in fetchers.py"
assert_contains "gh issue create called" "$(cat "$FAKE_GH_LOG")" "issue create"

# --- Test 3: duplicate finding is skipped ---
: > "$FAKE_GH_LOG"
export FAKE_GH_DUPLICATE=true
OUTPUT=$(FULLSEND_WORKSPACE="$TMPDIR/new-workspace" bash "$SCRIPT_DIR/improve-post.sh")
assert_contains "duplicate finding skipped" "$OUTPUT" "Skipping duplicate: Split overly long function in fetchers.py"
assert_not_contains "gh issue create not called for duplicate" "$(cat "$FAKE_GH_LOG")" "issue create"

# --- Test 4: missing findings array degraded gracefully ---
: > "$FAKE_GH_LOG"
mkdir -p "$TMPDIR/no-findings-workspace"
cat > "$TMPDIR/no-findings-workspace/agent-result.json" <<'EOF'
{"action": "improvements", "summary": "Analysis complete."}
EOF
OUTPUT=$(FULLSEND_WORKSPACE="$TMPDIR/no-findings-workspace" bash "$SCRIPT_DIR/improve-post.sh")
assert_contains "missing findings logs zero" "$OUTPUT" "Found 0 finding(s)"
assert_eq "missing findings makes no gh calls" "" "$(cat "$FAKE_GH_LOG")"

if [[ $failures -gt 0 ]]; then
  echo ""
  echo "$failures test(s) failed"
  exit 1
fi

echo ""
echo "All tests passed"
