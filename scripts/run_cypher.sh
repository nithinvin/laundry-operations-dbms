#!/usr/bin/env bash
# Run a Cypher file from the cypher/ folder, one statement at a time, with a
# title and description before each query.
#
# Usage: ./scripts/run_cypher.sh [--show] [--pause] FILE
#   --show   also print the Cypher of each statement (to copy into Neo4j Browser)
#   --pause  wait for Enter after each statement (q + Enter to stop)
# Example: ./scripts/run_cypher.sh --show --pause 03_queries.cypher
source "$(dirname "$0")/common.sh"

require_venv
exec "$PYTHON" "$REPO_ROOT/python/run_cypher.py" "$@"
