#!/usr/bin/env bash
# Shared helpers for the scripts in this folder. Source it, do not run it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ ! -f .env ]]; then
  echo "ERROR: .env not found. Run: cp .env.example .env  (then set NEO4J_PASSWORD)" >&2
  exit 1
fi
set -a; source .env; set +a

CONTAINER="laundry-neo4j"

PYTHON="$REPO_ROOT/.venv/bin/python"

# Stop with a helpful message if the Python virtual environment is missing.
require_venv() {
  if [[ ! -x "$PYTHON" ]]; then
    echo "ERROR: .venv not found. Run: python3 -m venv .venv && .venv/bin/pip install -r python/requirements.txt" >&2
    exit 1
  fi
}

# Run a Cypher file (path relative to cypher/) inside the container.
run_cypher() {
  docker exec -i "$CONTAINER" cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" \
    --format plain -f "/cypher/$1"
}

# Run a single Cypher statement inside the container.
run_query() {
  docker exec -i "$CONTAINER" cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" \
    --format plain "$1"
}

# Wait until Neo4j accepts Bolt connections.
wait_for_neo4j() {
  for _ in $(seq 1 60); do
    if run_query "RETURN 1;" >/dev/null 2>&1; then return 0; fi
    sleep 2
  done
  echo "ERROR: Neo4j did not become ready. Check: docker compose logs neo4j" >&2
  exit 1
}

# Print node and relationship counts.
show_counts() {
  echo "--- Nodes by label ---"
  run_query "MATCH (n) RETURN labels(n)[0] AS label, count(*) AS count ORDER BY label;"
  echo "--- Relationships by type ---"
  run_query "MATCH ()-[r]->() RETURN type(r) AS type, count(*) AS count ORDER BY type;"
  echo "--- Totals ---"
  run_query "MATCH (n) WITH count(n) AS nodes MATCH ()-[r]->() RETURN nodes, count(r) AS relationships;"
  run_query "SHOW CONSTRAINTS YIELD name RETURN count(*) AS constraints;"
}
