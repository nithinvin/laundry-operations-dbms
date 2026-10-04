#!/usr/bin/env bash
# Run all integrity checks (cypher/04_validation.cypher). Every check must PASS.
source "$(dirname "$0")/common.sh"

PYTHON="$REPO_ROOT/.venv/bin/python"
if [[ ! -x "$PYTHON" ]]; then
  echo "ERROR: .venv not found. Run: python3 -m venv .venv && .venv/bin/pip install -r python/requirements.txt" >&2
  exit 1
fi
"$PYTHON" "$REPO_ROOT/python/validate.py"
