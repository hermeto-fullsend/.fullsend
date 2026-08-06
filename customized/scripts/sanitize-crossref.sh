#!/usr/bin/env bash
# sanitize-crossref.sh — Rewrite bare cross-repo GitHub references to
# redirect.github.com markdown links.
#
# Bare references like org/repo#123 create backlink notifications in
# upstream repositories. This script rewrites them to:
#   [org/repo#123](https://redirect.github.com/org/repo/issues/123)
# which renders as a clickable link without notifying the upstream repo.
#
# Usage:
#   Source the file and call the functions:
#     source sanitize-crossref.sh
#     body="$(sanitize_crossref "$body")"
#     sanitize_crossref_commits "$REPO_DIR"
#
#   Or run directly to filter stdin:
#     echo "See org/repo#42" | ./sanitize-crossref.sh
#
# The rewrite skips references that are already inside markdown links.
set -euo pipefail

# sanitize_crossref rewrites bare cross-repo refs in the given string.
# Already-linked references ([org/repo#N](...)) are left untouched.
sanitize_crossref() {
  local input="${1:-}"
  if [[ -z "$input" ]]; then
    return
  fi
  printf '%s' "$input" | perl -pe '
    s{
      (?<! \[ )            # not already inside a markdown link text
      (?<! / )             # not inside a URL path
      \b
      ( [a-zA-Z0-9._-]+ / [a-zA-Z0-9._-]+ )   # org/repo
      \# ( [0-9]+ )                              # #number
      (?! \] )             # not the end of a markdown link text
    }
    {[$1#$2](https://redirect.github.com/$1/issues/$2)}gx
  '
}

# sanitize_crossref_commits rewrites commit messages on the unpushed
# branch (origin/HEAD..HEAD) to replace bare cross-repo references.
# This must run BEFORE git push — it rewrites commit hashes, which is
# safe because the branch has not been shared yet.
sanitize_crossref_commits() {
  local repo_dir="${1:?usage: sanitize_crossref_commits <repo-dir>}"

  local count
  count=$(git -C "$repo_dir" rev-list --count origin/HEAD..HEAD 2>/dev/null || echo 0)
  if [[ "$count" -eq 0 ]]; then
    return
  fi

  # Check if any commit message actually contains a bare cross-repo ref
  # before running filter-branch (which is expensive).
  if ! git -C "$repo_dir" log --format='%B' origin/HEAD..HEAD \
    | perl -ne 'exit 0 if /(?<!\[)(?<!\/)(?<!\w)[a-zA-Z0-9._-]+\/[a-zA-Z0-9._-]+#[0-9]+(?!\])/; END { exit 1 }'; then
    return
  fi

  FILTER_BRANCH_SQUELCH_WARNING=1 \
  git -C "$repo_dir" filter-branch --msg-filter '
    perl -pe '\''
      s{
        (?<! \[ )
        (?<! / )
        \b
        ( [a-zA-Z0-9._-]+ / [a-zA-Z0-9._-]+ )
        \# ( [0-9]+ )
        (?! \] )
      }
      {[$1#$2](https://redirect.github.com/$1/issues/$2)}gx
    '\''
  ' -- origin/HEAD..HEAD
}

# sanitize_crossref_file rewrites bare cross-repo refs in a file in-place.
sanitize_crossref_file() {
  local file="${1:?usage: sanitize_crossref_file <path>}"
  if [[ ! -f "$file" ]]; then
    return
  fi
  perl -pi -e '
    s{
      (?<! \[ )
      (?<! / )
      \b
      ( [a-zA-Z0-9._-]+ / [a-zA-Z0-9._-]+ )
      \# ( [0-9]+ )
      (?! \] )
    }
    {[$1#$2](https://redirect.github.com/$1/issues/$2)}gx
  ' "$file"
}

# When run directly (not sourced), filter stdin.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  perl -pe '
    s{
      (?<! \[ )
      (?<! / )
      \b
      ( [a-zA-Z0-9._-]+ / [a-zA-Z0-9._-]+ )
      \# ( [0-9]+ )
      (?! \] )
    }
    {[$1#$2](https://redirect.github.com/$1/issues/$2)}gx
  '
fi
