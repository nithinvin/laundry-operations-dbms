# Laundry Management System — Graph DB Edition (Neo4j)

A 3rd-semester DBMS course project (VIT Chennai). The **Laundry Management
System** was first built as a relational database on **Oracle 26ai Free** using
SQL and PL/SQL. This repository rebuilds **the same system on a graph database
— Neo4j** — using Cypher and the Python `neo4j` driver. It also compares the
two approaches.

The system tracks hostel students' laundry orders (garments, service, staff,
machine queue, payment) and **notifies students when their laundry is ready for
pickup**, which keeps the laundry area less crowded.

## What is in here

| Path | What it is |
|------|------------|
| [docs/spec.md](docs/spec.md) | Requirements: what the graph version must do, and how we know it is done |
| [docs/design.md](docs/design.md) | Graph data model: node labels, relationships, properties, constraints, diagram |
| [docs/relational-vs-graph.md](docs/relational-vs-graph.md) | How each Oracle table maps to the graph, and what changes (keys, FKs, CHECKs, normalization) |
| [docs/queries.md](docs/queries.md) | Each Oracle SQL query and PL/SQL block next to its Cypher / Python equivalent, with expected output |
| [docs/plan.md](docs/plan.md) | Phased implementation plan and checklist |
| [docs/runbook.md](docs/runbook.md) | Install, load, run, reset and troubleshoot (openSUSE first, then Windows 11 + WSL Ubuntu 24.04) |
| [docs/demo-script.md](docs/demo-script.md) | Step-by-step walkthrough for presenting the project in Neo4j Browser |
| [reference/oracle/](reference/oracle/) | The original Oracle design doc, SQL script and sqlplus spool output (read-only reference) |
| `cypher/` *(planned)* | Cypher scripts: constraints, data load, queries, validation |
| `python/` *(planned)* | Python driver scripts that replace the PL/SQL blocks, plus a validation runner |
| `scripts/` *(planned)* | Helper shell scripts: start / load / reset |
| `docker-compose.yml` *(planned)* | Neo4j Community container definition |

## Tech stack

- **Neo4j Community Edition** `2026.09.0` (Docker image `neo4j:2026.09.0-community`)
- **Cypher**, run from Neo4j Browser (`http://localhost:7474`) and `cypher-shell`
- **Python 3** with the official `neo4j` driver package
- **Docker**, on openSUSE Leap 16.0 (for verification) and on Windows 11 → WSL 2 → Ubuntu 24.04 (for the final demo)

## Quick start (once implementation is done)

```bash
cp .env.example .env              # set NEO4J_PASSWORD
docker compose up -d              # start Neo4j
./scripts/load.sh                 # constraints + sample data
./scripts/validate.sh             # integrity checks (expect 0 violations)
python3 python/run_plsql_equivalents.py
```

Then open <http://localhost:7474> and follow [docs/demo-script.md](docs/demo-script.md).
See [docs/runbook.md](docs/runbook.md) for the full details.

## Project status

| Phase | Status |
|-------|--------|
| 0. Documentation and plan | Done |
| 1–7. Implementation | Not started (see [docs/plan.md](docs/plan.md)) |
