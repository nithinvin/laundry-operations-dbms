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
| [cypher/](cypher/) | Cypher scripts: constraints, data load, queries, validation, workflow, showcase, Browser style |
| [python/](python/) | Python driver scripts: PL/SQL equivalents, validation runner, order workflow |
| [scripts/](scripts/) | Helper shell scripts: load, reset, validate, run a Cypher file |
| [docker-compose.yml](docker-compose.yml) | Neo4j Community container definition |
| [docs/outputs/](docs/outputs/) | Saved outputs of the queries and Python scripts |

## Tech stack

- **Neo4j Community Edition** `2026.09.0` (Docker image `neo4j:2026.09.0-community`)
- **Cypher**, run from Neo4j Browser (`http://localhost:7474`) and `cypher-shell`
- **Python 3** with the official `neo4j` driver package
- **Docker**, on openSUSE Leap 16.0 (for verification) and on Windows 11 → WSL 2 → Ubuntu 24.04 (for the final demo)

## Quick start

```bash
cp .env.example .env                          # set NEO4J_PASSWORD
python3 -m venv .venv && .venv/bin/pip install -r python/requirements.txt
docker compose up -d                          # start Neo4j
./scripts/load.sh                             # constraints + sample data (53 nodes, 51 relationships)
./scripts/validate.sh                         # 42 integrity checks, all must PASS
./scripts/run_cypher.sh 03_queries.cypher     # the 5 SQL queries in Cypher
.venv/bin/python python/run_plsql_equivalents.py   # the 5 PL/SQL blocks in Python
# add --show to print each Cypher query, --pause to step through one by one:
./scripts/run_cypher.sh --show --pause 03_queries.cypher
```

Then open <http://localhost:7474> and follow [docs/demo-script.md](docs/demo-script.md).
See [docs/runbook.md](docs/runbook.md) for the full details.

## Project status

| Phase | Status |
|-------|--------|
| 0. Documentation and plan | Done |
| 1–6. Implementation on openSUSE | Done |
| 7. Run on Windows 11 / WSL Ubuntu 24.04 | Not started |
| 8. Demo readiness | Not started |
