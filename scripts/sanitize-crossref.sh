#!/usr/bin/env bash
# sanitize-crossref.sh — Rewrite cross-repo GitHub references to use
# redirect.github.com, preventing backlink notifications in upstream repos.
#
# Catches two patterns:
#   1. Bare refs:  org/repo#123
#   2. Direct URLs: https://github.com/org/repo/issues/123
#
# Rewrites both to redirect.github.com equivalents.
#
# Usage:
#   Source the file and call the functions:
#     source sanitize-crossref.sh
#     body="$(sanitize_crossref "$body")"
#     sanitize_crossref_commits "$REPO_DIR"
#
#   Or run directly to filter stdin:
#     echo "See org/repo#42" | ./sanitize-crossref.sh
set -euo pipefail

_CROSSREF_PERL='
  # Pass 1: rewrite github.com URLs to redirect.github.com
  s{https://github\.com/([a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+)/(issues|pull|discussions)/(\d+)}
   {https://redirect.github.com/$1/$2/$3}g;

  # Pass 2: rewrite bare cross-repo refs (org/repo#N)
  s{
    (?<! \[ )            # not already inside a markdown link text
    (?<! / )             # not inside a URL path
    \b
    ( [a-zA-Z0-9._-]+ / [a-zA-Z0-9._-]+ )   # org/repo
    \# ( [0-9]+ )                              # #number
    (?! \] )             # not the end of a markdown link text
  }
  {[$1#$2](https://redirect.github.com/$1/issues/$2)}gx;
'

sanitize_crossref() {
  local input="${1:-}"
  if [[ -z "$input" ]]; then
    return
  fi
  printf '%s' "$input" | perl -pe "$_CROSSREF_PERL"
}

sanitize_crossref_commits() {
  local repo_dir="${1:?usage: sanitize_crossref_commits <repo-dir>}"

  local count
  count=$(git -C "$repo_dir" rev-list --count origin/HEAD..HEAD 2>/dev/null || echo 0)
  if [[ "$count" -eq 0 ]]; then
    return
  fi

  # Check if any commit message contains a bare cross-repo ref or github.com URL.
  if ! git -C "$repo_dir" log --format='%B' origin/HEAD..HEAD \
    | perl -ne 'exit 0 if m{(?<!\[)(?<!/)(?<!\w)[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+#[0-9]+(?!\])} || m{https://github\.com/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+/(?:issues|pull|discussions)/\d+}; END { exit 1 }'; then
    return
  fi

  FILTER_BRANCH_SQUELCH_WARNING=1 \
  git -C "$repo_dir" filter-branch --msg-filter '
    perl -pe '\''
      s{https://github\.com/([a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+)/(issues|pull|discussions)/(\d+)}
       {https://redirect.github.com/$1/$2/$3}g;
      s{
        (?<! \[ )
        (?<! / )
        \b
        ( [a-zA-Z0-9._-]+ / [a-zA-Z0-9._-]+ )
        \# ( [0-9]+ )
        (?! \] )
      }
      {[$1#$2](https://redirect.github.com/$1/issues/$2)}gx;
    '\''
  ' -- origin/HEAD..HEAD
}

sanitize_crossref_file() {
  local file="${1:?usage: sanitize_crossref_file <path>}"
  if [[ ! -f "$file" ]]; then
    return
  fi
  perl -pi -e "$_CROSSREF_PERL" "$file"
}

# When run directly (not sourced), filter stdin.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  perl -pe "$_CROSSREF_PERL"
fi
