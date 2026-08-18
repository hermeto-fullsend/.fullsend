#!/usr/bin/env bash
# Post-script for the compat-monitor agent.
# Reads the agent's compatibility report and creates GitHub issues for
# action-required items.
set -euo pipefail

RESULT_FILE="${FULLSEND_WORKSPACE:-/tmp/workspace}/agent-result.json"

if [[ ! -f "$RESULT_FILE" ]]; then
  echo "ERROR: agent-result.json not found"
  exit 1
fi

# Extract recommended actions with priority critical or high
ACTIONS=$(jq -c '[.recommended_actions[] | select(.priority == "critical" or .priority == "high")]' "$RESULT_FILE")
ACTION_COUNT=$(echo "$ACTIONS" | jq 'length')

if [[ "$ACTION_COUNT" -eq 0 ]]; then
  echo "No critical or high-priority actions. No issues to create."
  exit 0
fi

echo "Found ${ACTION_COUNT} high-priority action(s)."

# Get the summary for issue body context
SUMMARY=$(jq -r '.summary' "$RESULT_FILE")

SOURCE_REPO="${FULLSEND_SOURCE_REPO:-}"
if [[ -z "$SOURCE_REPO" ]]; then
  echo "FULLSEND_SOURCE_REPO not set; skipping issue creation."
  exit 0
fi

for row in $(echo "$ACTIONS" | jq -c '.[]'); do
  BACKEND=$(echo "$row" | jq -r '.backend')
  ACTION=$(echo "$row" | jq -r '.action')
  PRIORITY=$(echo "$row" | jq -r '.priority')
  ISSUE_TITLE=$(echo "$row" | jq -r '.issue_title // .action')

  # Check for duplicate issues
  EXISTING=$(gh issue list \
    --repo "$SOURCE_REPO" \
    --search "\"$ISSUE_TITLE\" in:title" \
    --state open \
    --limit 1 \
    --json number 2>/dev/null | jq 'length')

  if [[ "$EXISTING" -gt 0 ]]; then
    echo "Skipping duplicate: ${ISSUE_TITLE}"
    continue
  fi

  BODY=$(cat <<ISSUE_EOF
## Compatibility Monitor Alert

**Backend:** ${BACKEND}
**Priority:** ${PRIORITY}
**Action:** ${ACTION}

### Context

${SUMMARY}

---
*Created by the compatibility monitor agent.*
ISSUE_EOF
)

  LABELS="${BACKEND},enhancement"

  echo "Creating issue: ${ISSUE_TITLE}"
  gh issue create \
    --repo "$SOURCE_REPO" \
    --title "$ISSUE_TITLE" \
    --body "$BODY" \
    --label "$LABELS" 2>/dev/null || echo "::warning::Failed to create issue: ${ISSUE_TITLE}"
done

echo "Done."
