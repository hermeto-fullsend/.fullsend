#!/usr/bin/env bash
# validate-output-schema.sh — Sanitize cross-repo refs, then validate output.
#
# Drop-in replacement for the upstream validate-output-schema.sh.
# Runs cross-repo reference sanitization on the agent's commit messages
# and output files BEFORE schema validation, so the post-script never
# sees bare org/repo#N references that would create upstream backlinks.
#
# Required env vars:
#   FULLSEND_OUTPUT_SCHEMA — path to the JSON Schema file
#
# Optional env vars:
#   FULLSEND_OUTPUT_FILE  — filename to validate (default: agent-result.json)
#   TARGET_REPO_DIR       — path to the extracted repo checkout
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Cross-repo reference sanitization ---
if [[ -f "${SCRIPT_DIR}/sanitize-crossref.sh" ]]; then
  source "${SCRIPT_DIR}/sanitize-crossref.sh"

  # Sanitize commit messages in the extracted repo.
  if [[ -n "${TARGET_REPO_DIR:-}" && -d "${TARGET_REPO_DIR}" ]]; then
    sanitize_crossref_commits "${TARGET_REPO_DIR}"
  fi

  # Sanitize output JSON files (PR bodies, comments, findings).
  OUTPUT_DIR="output"
  if [[ -d "${OUTPUT_DIR}" ]]; then
    while IFS= read -r -d '' json_file; do
      sanitize_crossref_file "$json_file"
    done < <(find "${OUTPUT_DIR}" -name '*.json' -print0 2>/dev/null)
  fi
fi

# --- Standard schema validation (upstream logic) ---
: "${FULLSEND_OUTPUT_SCHEMA:?FULLSEND_OUTPUT_SCHEMA must be set}"

OUTPUT_DIR="output"
if [[ ! -d "${OUTPUT_DIR}" ]]; then
  echo "FAIL: output directory not found"
  exit 1
fi

_output_file="${FULLSEND_OUTPUT_FILE:-agent-result.json}"
_output_file="$(basename "${_output_file}")"
RESULT_FILE="${OUTPUT_DIR}/${_output_file}"
if [[ ! -f "${RESULT_FILE}" ]]; then
  echo "FAIL: ${RESULT_FILE} not found"
  exit 1
fi
echo "Validating: ${RESULT_FILE} against ${FULLSEND_OUTPUT_SCHEMA}"

if ! python3 -m json.tool "${RESULT_FILE}" > /dev/null 2>&1; then
  echo "FAIL: ${RESULT_FILE} is not valid JSON"
  exit 1
fi

if ! python3 -c "import jsonschema" 2>/dev/null; then
  echo "FAIL: python3 jsonschema package is not installed (required by ADR 0022)"
  exit 1
fi

if ! python3 -c "
import json, sys
from jsonschema import validate, ValidationError

with open(sys.argv[1]) as f:
    instance = json.load(f)
with open(sys.argv[2]) as f:
    schema = json.load(f)
try:
    validate(instance=instance, schema=schema)
    print('PASS: output validated against schema')
except ValidationError as e:
    print(f'FAIL: schema validation error: {e.message}')
    if e.path:
        print(f'  at: {\".\".join(str(p) for p in e.path)}')
    if 'properties' in e.schema:
        allowed = ', '.join(sorted(e.schema['properties'].keys()))
        print(f'  allowed properties: {allowed}')
    sys.exit(1)
" "${RESULT_FILE}" "${FULLSEND_OUTPUT_SCHEMA}"; then
  exit 1
fi
