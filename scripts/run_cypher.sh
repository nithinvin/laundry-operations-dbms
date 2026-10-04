#!/usr/bin/env bash
# Run a Cypher file from the cypher/ folder and print the results as tables.
# Usage: ./scripts/run_cypher.sh 03_queries.cypher
source "$(dirname "$0")/common.sh"

if [[ $# -ne 1 || ! -f "cypher/$1" ]]; then
  echo "Usage: $0 <file in cypher/>   e.g. $0 03_queries.cypher" >&2
  exit 1
fi
docker exec -i "$CONTAINER" cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" \
  --format verbose -f "/cypher/$1" | grep -v '^ready to start consuming query'
