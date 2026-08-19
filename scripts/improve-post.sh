#!/usr/bin/env bash
# Post-script for the improve agent.
# Reads the agent's findings and creates GitHub issues for each one,
# skipping any that already have an open issue with a matching title.
set -euo pipefail

RESULT_FILE="${FULLSEND_WORKSPACE:-/tmp/workspace}/agent-result.json"

if [[ ! -f "$RESULT_FILE" ]]; then
  echo "ERROR: agent-result.json not found"
  exit 1
fi

ACTION=$(jq -r '.action' "$RESULT_FILE")

if [[ "$ACTION" != "improvements" ]]; then
  echo "Agent reported action=${ACTION}. No issues to create."
  exit 0
fi

SOURCE_REPO="${FULLSEND_SOURCE_REPO:-}"
if [[ -z "$SOURCE_REPO" ]]; then
  echo "FULLSEND_SOURCE_REPO not set; skipping issue creation."
  exit 0
fi

FINDINGS=$(jq -c '.findings // []' "$RESULT_FILE")
FINDING_COUNT=$(echo "$FINDINGS" | jq 'length')
echo "Found ${FINDING_COUNT} finding(s)."

echo "$FINDINGS" | jq -c '.[]' | while read -r row; do
  CATEGORY=$(echo "$row" | jq -r '.category')
  TITLE=$(echo "$row" | jq -r '.title')
  BODY_TEXT=$(echo "$row" | jq -r '.body')
  FILE=$(echo "$row" | jq -r '.file')
  LINE=$(echo "$row" | jq -r '.line // empty')

  EXISTING=$(gh issue list \
    --repo "$SOURCE_REPO" \
    --search "\"$TITLE\" in:title" \
    --state open \
    --limit 1 \
    --json number 2>/dev/null | jq 'length')

  if [[ "$EXISTING" -gt 0 ]]; then
    echo "Skipping duplicate: ${TITLE}"
    continue
  fi

  LOCATION="${FILE}"
  if [[ -n "$LINE" ]]; then
    LOCATION="${FILE}:${LINE}"
  fi

  ISSUE_BODY=$(cat <<ISSUE_EOF
## Improvement Suggestion

**Category:** ${CATEGORY}
**Location:** ${LOCATION}

${BODY_TEXT}

---
*Created by the improve agent.*
ISSUE_EOF
)

  echo "Creating issue: ${TITLE}"
  gh issue create \
    --repo "$SOURCE_REPO" \
    --title "$TITLE" \
    --body "$ISSUE_BODY" \
    --label "fullsend-improve" 2>/dev/null || echo "::warning::Failed to create issue: ${TITLE}"
done

echo "Done."

