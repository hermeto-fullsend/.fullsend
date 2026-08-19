#!/usr/bin/env bash
# Pre-script for the compat-monitor agent.
# Fetches latest version and release information from package manager
# ecosystems and writes it to ecosystem-data.json for the agent.
set -euo pipefail

OUTPUT_DIR="${FULLSEND_WORKSPACE:-/tmp/workspace}"
OUTPUT_FILE="${OUTPUT_DIR}/ecosystem-data.json"

fetch_json() {
  local url="$1"
  curl -sf --max-time 15 "$url" 2>/dev/null || echo '{}'
}

echo "Fetching ecosystem data..."

# npm (latest version + recent releases)
NPM_DATA=$(fetch_json "https://registry.npmjs.org/npm" | jq '{
  name: "npm",
  latest: .["dist-tags"].latest,
  recent_versions: [."versions" | keys[] | select(startswith("10") or startswith("11") or startswith("12"))] | sort | reverse | .[:5]
}')

# yarn (Berry/v2+)
YARN_DATA=$(fetch_json "https://registry.npmjs.org/@yarnpkg/cli" | jq '{
  name: "yarn",
  latest: .["dist-tags"].latest,
  recent_versions: [."versions" | keys[]] | sort | reverse | .[:5]
}')

# pnpm
PNPM_DATA=$(fetch_json "https://registry.npmjs.org/pnpm" | jq '{
  name: "pnpm",
  latest: .["dist-tags"].latest,
  recent_versions: [."versions" | keys[]] | sort | reverse | .[:5]
}')

# pip (from PyPI)
PIP_DATA=$(fetch_json "https://pypi.org/pypi/pip/json" | jq '{
  name: "pip",
  latest: .info.version,
  recent_versions: [.releases | keys[] | select(test("^2[4-9]|^[3-9]"))] | sort | reverse | .[:5]
}')

# cargo (from crates.io)
CARGO_DATA=$(fetch_json "https://crates.io/api/v1/crates/cargo" | jq '{
  name: "cargo",
  latest: .crate.max_stable_version,
  recent_versions: [.versions[:5][] | .num]
}')

# bundler (from RubyGems)
BUNDLER_DATA=$(fetch_json "https://rubygems.org/api/v1/gems/bundler.json" | jq '{
  name: "bundler",
  latest: .version
}')

# Go (latest release)
GO_DATA=$(fetch_json "https://go.dev/dl/?mode=json" | jq '{
  name: "gomod",
  latest: .[0].version,
  recent_versions: [.[:3][] | .version]
}')

# Combine all data
jq -n \
  --argjson npm "$NPM_DATA" \
  --argjson yarn "$YARN_DATA" \
  --argjson pnpm "$PNPM_DATA" \
  --argjson pip "$PIP_DATA" \
  --argjson cargo "$CARGO_DATA" \
  --argjson bundler "$BUNDLER_DATA" \
  --argjson gomod "$GO_DATA" \
  '{
    fetched_at: now | todate,
    ecosystems: [$npm, $yarn, $pnpm, $pip, $cargo, $bundler, $gomod]
  }' > "$OUTPUT_FILE"

echo "Ecosystem data written to ${OUTPUT_FILE}"
echo "Backends covered: npm, yarn, pnpm, pip, cargo, bundler, gomod"
echo "Note: rpm and vcpkg have no public version API; agent will assess from source only."
