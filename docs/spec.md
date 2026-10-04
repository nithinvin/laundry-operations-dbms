# Specification — Laundry Management System on Neo4j

## 1. Background

The Laundry Management System was first built on Oracle 26ai Free. That
version had:

- 13 normalized tables (taken to BCNF), with PK, FK, UNIQUE and CHECK constraints
- Sample data: 5 rows in most tables, 6 phone numbers each for students and
  staff, 8 order items and 8 notifications (73 rows in total)
- 5 "advanced" SQL queries and 5 PL/SQL blocks

All of that is kept in [`reference/oracle/`](../reference/oracle/).

This project builds **the same system on Neo4j**, a graph database. It must
show the same data and the same query results, and explain how the
relational design turns into a graph design.

## 2. Goals

1. Model the laundry domain as a **property graph** (nodes, relationships, properties).
2. Load **exactly the same sample data** as the Oracle version.
3. Answer **all 5 SQL queries** in Cypher with the same results.
4. Rewrite **all 5 PL/SQL blocks** as Python scripts that use the `neo4j`
   driver. Cypher cannot express procedural logic such as variables, cursors,
   loops and IF/ELSE, so Python takes that role.
5. Enforce data integrity as far as Neo4j Community allows, and **report
   explicitly** what it cannot enforce.
6. Document the relational → graph mapping and its trade-offs.
7. Be runnable and demoable on **Windows 11 + WSL 2 + Ubuntu 24.04**, after
   first being verified on **openSUSE Leap 16.0**.

## 3. Non-goals

- No web or GUI application. Neo4j Browser is the user interface.
- No Enterprise-only features (property existence constraints, property type
  constraints, RBAC, clustering).
- No APOC or Graph Data Science plugins. Plain Cypher keeps the demo simple
  and portable.
- No change to the business rules of the Oracle version. In particular, one
  order still uses exactly one service.

## 4. Functional requirements

These are carried over from the Oracle version. The ID used in the Oracle doc
is shown in brackets.

| ID | Requirement | How it is met in the graph |
|----|-------------|---------------------------|
| FR-1 | Register students and link them to a hostel [FR1] | `(:Student)-[:LIVES_IN]->(:Hostel)` |
| FR-2 | Store several phone numbers per student [FR2] | `Student.phones` list property |
| FR-3 | Register staff, with several phone numbers each [FR3] | `:Staff` node, with a `phones` list |
| FR-4 | Store services and prices [FR4] | `:Service` node |
| FR-5 | Store garment types [FR5] | `:GarmentType` node |
| FR-6 | Create laundry orders [FR6] | `:LaundryOrder` node, plus `PLACED` / `USES_SERVICE` / `ASSIGNED_TO` relationships |
| FR-7 | Store several garment types per order [FR7] | `(:LaundryOrder)-[:CONTAINS {quantity, unitPrice}]->(:GarmentType)` |
| FR-8 | Assign staff to orders [FR8] | `(:Staff)-[:ASSIGNED_TO]->(:LaundryOrder)` |
| FR-9 | Track machines and queue entries [FR9] | `:Machine` and `:QueueEntry` nodes |
| FR-10 | Record one payment per order [FR10] | `(:LaundryOrder)-[:HAS_PAYMENT]->(:Payment)`, at most one (checked by a validation query) |
| FR-11 | Store several notifications per order [FR11] | `(:LaundryOrder)-[:GENERATED]->(:Notification)` |
| FR-12 | Track order status and completion times [FR12] | `status`, `orderDateTime`, `expectedCompletion`, `actualCompletion` properties |
| FR-13 | Run advanced reports [FR13] | The 5 Cypher queries in [queries.md](queries.md) |
| FR-14 | Demonstrate procedural logic: variables, conditions, aggregates, cursors, loops [FR14] | The 5 Python scripts in [queries.md](queries.md) |

### Graph-specific requirements

| ID | Priority | Requirement |
|----|----------|-------------|
| GR-1 | Must | Uniqueness constraints for every Oracle PK and UNIQUE column that Community supports |
| GR-2 | Must | A **validation suite** of Cypher queries. Each one returns the rows that break a rule the Oracle version enforced: NOT NULL, CHECK, FK totality, 1:1 payment, unique queue position per machine, total amount = sum of items. A clean database returns 0 rows for every check. |
| GR-3 | Must | The load script can be re-run safely (it uses `MERGE` and `IF NOT EXISTS`) |
| GR-4 | Must | A reset script that wipes and reloads the database |
| GR-5 | Should | Order **workflow operations** written as Cypher/Python: move an order to the next status, and create a "Ready for Pickup" notification when an order becomes ready |
| GR-6 | Should | 3–5 **graph showcase queries** that are natural in Cypher but awkward in SQL (multi-hop traversal, a path from a student to a machine, a visual neighbourhood of an order) |
| GR-7 | Could | Neo4j Browser style (colours and captions per label) to make the demo graph easier to read |

## 5. Data requirements

- The dataset is **identical** to `reference/oracle/laundry_schema_and_data.sql`:
  the same IDs, values and timestamps.
- Oracle `TIMESTAMP` (no time zone) becomes Cypher `localdatetime`. Oracle
  `DATE` (used only for `PaymentDate`) becomes Cypher `date`.
- Oracle `NUMBER(p,2)` money values become Cypher `float`. Oracle `NUMBER(p)`
  counts become `integer`.

### Expected counts after loading

| Item | Count |
|------|-------|
| Nodes | 53 (Hostel 5, Student 5, Staff 5, Service 5, GarmentType 5, Machine 5, LaundryOrder 5, QueueEntry 5, Payment 5, Notification 8) |
| Relationships | 51 (LIVES_IN 5, PLACED 5, ASSIGNED_TO 5, USES_SERVICE 5, CONTAINS 8, IN_QUEUE 5, FOR_MACHINE 5, HAS_PAYMENT 5, GENERATED 8) |
| Phone list entries | 12 (6 student, 6 staff) |

Check: the 73 Oracle rows = 53 nodes + 8 `CONTAINS` relationships + 12 phone
list entries. Rows of the other 11 tables became nodes, ORDER_ITEM rows became
relationships, and phone rows became list entries.

## 6. Acceptance criteria

The project is done when all of the following are true:

1. `docker compose up -d` followed by `./scripts/load.sh` works on a fresh
   machine, with no manual steps beyond setting a password.
2. The node and relationship counts match section 5 exactly.
3. Every validation query returns 0 rows.
4. Each of the 5 Cypher queries returns the expected output listed in
   [queries.md](queries.md). Highlights: O003 / 240; services SV002 and
   SV003; no students with more than one order; garments G001 (3) and
   G002 (2); 5 matching payments.
5. Each of the 5 Python scripts prints the same output as the matching Oracle
   PL/SQL block (for example, `Total Revenue from Paid Orders: 675`).
6. Steps 1–5 pass on openSUSE Leap 16.0 **and** on Windows 11 / WSL Ubuntu
   24.04, with Neo4j Browser opened from the Windows browser.
7. Every document in `docs/` matches what was actually built.

## 7. Constraints and assumptions

- Neo4j **Community Edition** only: free, and enough for a course project.
- Neo4j runs in **Docker**, so the setup is the same on both machines.
- The Python scripts run on the host (or in WSL) inside a virtual
  environment, and connect over `bolt://localhost:7687`.
- Credentials come from a git-ignored `.env` file. Passwords are never
  committed.
