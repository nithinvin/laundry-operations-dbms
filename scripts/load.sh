#!/usr/bin/env bash
# Create constraints and load the sample data. Safe to run more than once.
source "$(dirname "$0")/common.sh"

wait_for_neo4j
echo "Creating constraints and indexes..."
run_cypher 01_constraints.cypher
echo "Loading data..."
run_cypher 02_load_data.cypher
show_counts
