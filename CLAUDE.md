# CLAUDE.md

Guidance for working in this repository.

## Project

3rd-semester DBMS course project (VIT Chennai). It is a Laundry Management
System, first built on Oracle 26ai Free (SQL + PL/SQL), now rebuilt on
**Neo4j Community** with Cypher and the Python `neo4j` driver. Start with these
docs:

- `docs/spec.md`: requirements, expected counts, acceptance criteria
- `docs/design.md`: graph model, constraints, design decisions (D1–D10)
- `docs/queries.md`: every query, with its **expected output**
- `docs/plan.md`: phased checklist. Tick boxes as work completes.
- `docs/runbook.md`: setup and operations
- `reference/oracle/`: the original Oracle files. **Read-only. Never edit.**

## Rules

- **Authorship:** this is the student's own project. Repo content (docs,
  code, comments, commit messages) must not mention AI assistants, ChatGPT,
  Claude, or anyone helping. Write as the student.
- **Commits:** no `Co-Authored-By` or "Generated with" lines. Do not commit
  until the user has reviewed the changes. Push to `origin` after committing.
- **Data:** the sample data must stay identical to
  `reference/oracle/laundry_schema_and_data.sql` (same IDs, values,
  timestamps). Expected totals: 53 nodes, 51 relationships, 14 constraints.
- **Community Edition only.** No existence/type constraints, no APOC, no GDS.
  Rules Neo4j cannot enforce go into `cypher/04_validation.cypher` as queries
  that return violating rows (an empty result means pass).
- **Keep the docs in sync.** If the model, a query, or an output changes,
  update `design.md`, `queries.md`, `spec.md`, and `runbook.md` in the same
  change.
- **Docker image** is pinned to `neo4j:2026.09.0-community`. Change it only on
  purpose, and update the docs to match.
- Docs are written in plain English for a student/teacher audience. No
  jargon without an explanation.

## Conventions

- Labels: PascalCase (`LaundryOrder`, `GarmentType`). Relationship types:
  UPPER_SNAKE (`PLACED`, `HAS_PAYMENT`). Properties: camelCase (`orderId`,
  `totalAmount`).
- Oracle `TIMESTAMP` → `localdatetime`; `DATE` → `date`; money → float;
  counts → integer. Leave properties out rather than storing NULL.
- Cypher scripts are idempotent: `CREATE CONSTRAINT … IF NOT EXISTS` and
  `MERGE` on IDs.
- Validation checks are named `// V-<kind>-<name>: <description>` (kinds: NN,
  CK, FK, 11, UQ, DC). `python/validate.py` splits the file on these headers,
  so each check must be a single statement.
- If a query or script output changes, regenerate `docs/outputs/` too.
- Python: scripts in `python/`, connection through `python/db.py`, credentials
  from `.env` (git-ignored; template in `.env.example`). Never hardcode or
  commit passwords.
- Shell scripts in `scripts/` are bash, with LF line endings, and run from the
  repo root.

## Commands

```bash
python3 -m venv .venv && .venv/bin/pip install -r python/requirements.txt   # once
docker compose up -d                 # start Neo4j (Browser: http://localhost:7474)
./scripts/load.sh                    # constraints + data -> 53 nodes, 51 rels, 14 constraints
./scripts/validate.sh                # 42 checks, all must PASS
./scripts/reset.sh                   # wipe + reload (do this after workflow ops)
./scripts/run_cypher.sh 03_queries.cypher          # any file in cypher/
.venv/bin/python python/run_plsql_equivalents.py   # PL/SQL Q1-Q5 equivalents
.venv/bin/python python/workflow.py show|advance|cancel O002 ; workflow.py remind
```

## Environments

Verified first on openSUSE Leap 16.0 (Docker + Compose v2), then run on
Windows 11 → WSL 2 → Ubuntu 24.04 (Docker Engine inside Ubuntu). Commands
must work unchanged on both.
