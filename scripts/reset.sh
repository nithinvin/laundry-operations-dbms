#!/usr/bin/env bash
# Delete all data, then load it again from scratch.
source "$(dirname "$0")/common.sh"

wait_for_neo4j
echo "Deleting all nodes and relationships..."
run_cypher 00_reset.cypher
"$REPO_ROOT/scripts/load.sh"
