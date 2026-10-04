# Relational (Oracle) vs Graph (Neo4j)

This document explains how each part of the Oracle design was carried into
Neo4j, and what changes in concept along the way. It is the main "DBMS theory"
part of the graph project.

## 1. Vocabulary mapping

| Relational (Oracle) | Graph (Neo4j) |
|---------------------|---------------|
| Table | Node label (or a relationship type, for link tables) |
| Row | Node (or relationship) |
| Column | Property |
| Primary key | Uniqueness constraint on an ID property |
| Foreign key | Relationship |
| JOIN (computed at query time) | Traversal of a stored relationship |
| Link / junction table | Relationship, carrying properties |
| Multivalued attribute table | List property, or separate nodes |
| NULL | Property absent |
| CHECK / NOT NULL | Not available in Community; replaced by validation queries |
| SQL | Cypher |
| PL/SQL block | Python script using the `neo4j` driver |
| sqlplus | cypher-shell / Neo4j Browser |
| `COMMIT` | Implicit: each Cypher statement is its own transaction (auto-commit) unless grouped in an explicit transaction |

## 2. Table-by-table mapping

| # | Oracle table | Rows | Becomes | Notes |
|---|--------------|------|---------|-------|
| 1 | HOSTEL | 5 | `:Hostel` node | — |
| 2 | STUDENT | 5 | `:Student` node + `LIVES_IN` relationship | The HostelID FK becomes a relationship |
| 3 | STUDENT_PHONE | 6 | `Student.phones` list | Multivalued attribute; this table existed only because of 1NF |
| 4 | STAFF | 5 | `:Staff` node | — |
| 5 | STAFF_PHONE | 6 | `Staff.phones` list | Same as STUDENT_PHONE |
| 6 | SERVICE | 5 | `:Service` node | — |
| 7 | GARMENT_TYPE | 5 | `:GarmentType` node | — |
| 8 | LAUNDRY_ORDER | 5 | `:LaundryOrder` node + `PLACED`, `USES_SERVICE`, `ASSIGNED_TO` | 3 FKs become 3 relationships |
| 9 | ORDER_ITEM | 8 | `CONTAINS {quantity, unitPrice}` relationship | Weak entity becomes a relationship |
| 10 | MACHINE | 5 | `:Machine` node | — |
| 11 | QUEUE_ENTRY | 5 | `:QueueEntry` node + `IN_QUEUE`, `FOR_MACHINE` | Kept as a node (design decision D3) |
| 12 | PAYMENT | 5 | `:Payment` node + `HAS_PAYMENT` | Kept as a node (D4) |
| 13 | NOTIFICATION | 8 | `:Notification` node + `GENERATED` | Kept as a node (D5) |

So 13 tables became **10 node labels and 9 relationship types**, and
**73 rows** became **53 nodes + 51 relationships**. The 12 phone rows became
list entries. Each relationship replaces one FK value, and the 8 `CONTAINS`
relationships replace the ORDER_ITEM rows.

## 3. Keys and constraints

| Oracle constraint kind | Count in Oracle | Neo4j Community |
|------------------------|-----------------|-----------------|
| PRIMARY KEY (single column) | 10 | Uniqueness constraint (10) |
| PRIMARY KEY (composite) | 3 (STUDENT_PHONE, STAFF_PHONE, ORDER_ITEM) | Tables removed. Duplicates prevented by the load logic and checked by validation queries. |
| UNIQUE (single column) | 5 (HostelName, Email, ServiceName, GarmentName, Payment.OrderID) | 4 become uniqueness constraints. Payment.OrderID becomes a validation query, because a 1:1 relationship is not a property. |
| UNIQUE (composite) | 1 (MachineID, QueuePosition) | Validation query |
| FOREIGN KEY | 12 | Relationships. A relationship cannot point to a node that does not exist, so **referential integrity is built in**. *Total participation* (an order must have a student) is not, so a validation query checks it. |
| NOT NULL | many | Validation queries (existence constraints are Enterprise-only) |
| CHECK | 15 | Validation queries |

**Important point for discussion:** a relationship in Neo4j always connects
two real nodes, so a "dangling foreign key" cannot exist. Deleting a node
that still has relationships fails unless you use `DETACH DELETE`. This
behaves like `ON DELETE RESTRICT`, and `DETACH DELETE` behaves like
`ON DELETE CASCADE` for the relationships only. The idea that **cannot** be
expressed in Community is *mandatory* participation.

## 4. What happens to normalization?

Normalization theory (functional dependencies, 1NF–BCNF) is defined for
relations. A graph is not a set of relations, but the same goals still apply:
avoid storing a fact twice, and avoid update anomalies.

| Normal form step in Oracle | Effect in the graph |
|----------------------------|---------------------|
| **1NF** split phones into STUDENT_PHONE / STAFF_PHONE | The graph allows list properties, so the split is unnecessary. A list is not "atomic" in the relational sense. That is acceptable in a property graph, because the phone numbers have no dependencies of their own. |
| **1NF** split repeating garments into ORDER_ITEM | Became `CONTAINS` relationships. The repeating group is now a set of edges. |
| **2NF** ORDER_ITEM's Quantity/UnitPrice depend on the full key | Holds automatically: the properties sit on the edge that *is* the (Order, Garment) pair. |
| **3NF** moved hostel details out of STUDENT (`StudentID → HostelID → HostelName`) | Hostel is its own node, reached by `LIVES_IN`. There is no transitive dependency, because the hostel name is stored once. |
| **BCNF** removed StudentID from NOTIFICATION (`OrderID → StudentID`) | Kept: no `Notification→Student` relationship is stored. The student is reached by the path `Notification ← Order ← Student`. A stored shortcut would be the graph version of the same redundancy. |

Conclusion: **the graph model keeps every redundancy-removal decision of the
BCNF schema**. The only relaxation is the phone lists, which are a deliberate
use of a graph feature with no anomaly risk.

## 5. Query style differences

| Aspect | SQL | Cypher |
|--------|-----|--------|
| Joins | `JOIN … ON a.id = b.id`, computed at query time | Pattern `(a)-[:REL]->(b)`, following stored links |
| Grouping | Explicit `GROUP BY` | Implicit: any non-aggregated item in `RETURN`/`WITH` is the grouping key |
| HAVING | `HAVING count(*) > 1` | `WITH x, count(*) AS c WHERE c > 1` |
| Subqueries | `WHERE x = (SELECT max(…) …)` | Compute first with `WITH max(…) AS m`, then filter; or `CALL { … }` / `COUNT { … }` subqueries |
| LEFT JOIN | `LEFT JOIN` | `OPTIONAL MATCH` |
| NVL | `NVL(x, 0)` | `coalesce(x, 0)` |
| Multi-hop questions | One JOIN per hop; gets longer quickly | One pattern, with optional variable-length hops `[*1..3]` |
| Procedural code | PL/SQL inside the database | Not part of Cypher; done in a client language (Python) |

Side-by-side versions of every project query are in
[queries.md](queries.md).

## 6. When is each model better? (for the viva)

- **Relational is better** at strong declarative integrity (CHECK, NOT NULL,
  composite keys), reporting with heavy aggregation over fixed-shape data,
  and mature transactions and tooling.
- **Graph is better** at relationship-heavy questions: "which machines handled
  laundry for students of Block A?", "which students send similar garments?",
  "show everything connected to order O001". It also handles schema changes
  without migrations and gives a visual picture of the data.
- **For this project:** the data is small and quite tabular, so both models
  work. The graph version makes the *connections* (student → order → queue →
  machine) visible and easy to query. The relational version is stronger at
  enforcing rules.
