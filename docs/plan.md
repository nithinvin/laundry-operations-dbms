# Implementation Plan

Each phase ends with a check that can be verified. Phases 1–6 run on
openSUSE (Env A). Phase 7 repeats everything on Windows 11 / WSL Ubuntu 24.04
(Env B). Tick the boxes as work is completed.

## Phase 0 — Documentation (this phase)

- [x] Collect the Oracle reference material into `reference/oracle/`
- [x] README.md
- [x] docs/spec.md — requirements and acceptance criteria
- [x] docs/design.md — graph model, constraints, decisions
- [x] docs/relational-vs-graph.md — mapping and theory
- [x] docs/queries.md — SQL/PLSQL → Cypher/Python drafts with expected output
- [x] docs/runbook.md — environment setup and operations
- [x] docs/demo-script.md — presentation walkthrough
- [x] Review the docs; adjust the design if needed
- [x] First commit

**Done when:** the docs are reviewed and committed.

## Phase 1 — Environment (Env A)

- [x] `.gitignore` (`.env`, `.venv/`, `__pycache__/`)
- [x] `.env.example`
- [x] `docker-compose.yml` (image `neo4j:2026.09.0-community`)
- [x] `docker compose up -d`; log in to Browser at `http://localhost:7474`
- [x] Python venv; `python/requirements.txt` (`neo4j`, `python-dotenv`); `python/db.py`
- [x] Smoke test: `python -c` script that runs `RETURN 1`

**Done when:** both Browser and Python can connect.

## Phase 2 — Schema and data load

- [x] `cypher/01_constraints.cypher` — 14 uniqueness constraints + the status index
- [x] `cypher/02_load_data.cypher` — `MERGE` all nodes from the Oracle INSERTs, then the relationships
- [x] `cypher/00_reset.cypher`
- [x] `scripts/load.sh`, `scripts/reset.sh`, `scripts/common.sh`, `scripts/run_cypher.sh` (read `.env`; call `cypher-shell -f` inside the container)
- [x] Run the load twice and confirm the counts do not change (proves it can be re-run)

**Done when:** 53 nodes, 51 relationships and 14 constraints, after both
loads.

## Phase 3 — Validation suite

- [x] `cypher/04_validation.cypher` — one query per rule, each named `// V-xx-…`:
  - V-NN-*: required properties present, for every label
  - V-CK-*: value ranges / IN lists / date order (15 Oracle CHECKs)
  - V-FK-*: total participation (order → student, service, staff; queue → machine; …)
  - V-11-payment: at most one payment per order
  - V-UQ-queue: queue position unique per machine
  - V-UQ-contains: no duplicate `CONTAINS` between the same order and garment
  - V-UQ-phones: no duplicate entries in a phones list
  - V-DC-total: totalAmount = Σ quantity × unitPrice
- [x] `python/validate.py` — splits the file into named checks and prints `PASS` or `FAIL (n rows)` (42 checks)
- [x] `scripts/validate.sh`
- [x] **Negative test:** break the data on purpose (for example, set a bad status), confirm the check FAILs, then reset

**Done when:** all checks PASS on clean data, and the negative test fails as
expected.

## Phase 4 — Query port

- [x] `cypher/03_queries.cypher` — A1–A5 from queries.md
- [x] Run each one and compare with the expected output; fix queries.md if anything differs
- [x] Save the outputs to `docs/outputs/queries.txt` (like the sqlplus spool)

**Done when:** all 5 outputs match the expected output.

## Phase 5 — PL/SQL equivalents in Python

- [x] `python/plsql_q1_highest_order.py` … `plsql_q5_ready_check.py`
- [x] `python/run_plsql_equivalents.py` — runs all 5, with headers
- [x] Compare with the Oracle expected output; save to `docs/outputs/plsql_equivalents.txt`

**Done when:** the output text matches Oracle (except for the row order note
on B4).

## Phase 6 — Extras (Should/Could)

- [x] `cypher/05_workflow.cypher` + `python/workflow.py` — status transitions, "ready" notification (GR-5)
- [x] `cypher/06_showcase.cypher` — C1–C5 (GR-6)
- [x] Browser style file `cypher/browser-style.grass` — colours and captions per label (GR-7)
- [ ] Screenshots of the Browser graph view in `docs/images/` (schema visualization, order O001 neighbourhood). Take these by hand in the Browser.

**Done when:** the workflow demo works and resets cleanly; the showcase
queries match queries.md.

### Phase 1–6 results (openSUSE, 2026-10-04)

- Neo4j 2026.09.0 Community, Python driver 6.3.1, Python 3.13
- Load: 53 nodes, 51 relationships, 14 constraints; unchanged after a second load
- Validation: 42/42 PASS; negative test (bad status, bad payment, duplicate
  queue position, duplicate phone, wrong total) gave 7 FAILs and exit code 1; reset restored 42/42
- A1–A5 and B1–B5 outputs match Oracle (saved in `docs/outputs/`)
- Bug found and fixed: in B3, `ORDER BY s.studentId` after `count()` is not
  allowed unless `studentId` is returned. The query now returns it.

## Phase 7 — Port to Windows 11 / WSL Ubuntu 24.04 (Env B)

- [ ] Follow runbook §2 from scratch, on the real Windows laptop
- [ ] Clone; `.env`; `docker compose up -d`; `load.sh`; `validate.sh`; queries; Python
- [ ] Open Browser from Windows Edge/Chrome
- [ ] Write down every difference or problem and fold it into runbook.md (Troubleshooting)

**Done when:** spec §6 acceptance criteria 1–6 pass on Env B.

## Phase 8 — Demo readiness

- [ ] Do a dry run of [demo-script.md](demo-script.md) end to end, with a timer
- [ ] Update the README status table
- [ ] Check that docs match the code (spec §6 criterion 7)
- [ ] Prepare likely viva questions (see demo-script.md §7)

## Risks

| Risk | Mitigation |
|------|------------|
| Docker/WSL setup problems on the demo laptop | Do Phase 7 early. Keep screenshots and the saved outputs as a backup. |
| Enterprise-only features assumed by mistake | Validation queries replace them; design.md §5 lists every gap |
| A newer Neo4j version changes Cypher syntax | Image tag pinned to an exact version; 5.26 LTS as fallback |
| Asked "why not just use SQL?" during the viva | relational-vs-graph.md §6 |
