#!/usr/bin/env bash
# Run all integrity checks (cypher/04_validation.cypher). Every check must PASS.
source "$(dirname "$0")/common.sh"

require_venv
"$PYTHON" "$REPO_ROOT/python/validate.py"
