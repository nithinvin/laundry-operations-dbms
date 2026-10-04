# Demo Script — Presenting in Neo4j Browser

Target length: **10–15 minutes**. Before you start:

1. `docker compose up -d`, then `./scripts/reset.sh`
2. Open <http://localhost:7474> and log in
3. Type `:style` and drag `cypher/browser-style.grass` onto the style panel
   (colours and captions per label)
4. Set the Browser zoom so that queries are readable on a projector
5. In a terminal next to the Browser, keep this ready. It prints each query's
   question, Oracle SQL and Cypher, then waits for Enter:
   `./scripts/run_cypher.sh --show --pause 03_queries.cypher`
   Copy each Cypher block into the Browser to show it there as well.

## 1. Introduce the project (1 min)

- "This is the same Laundry Management System I showed in Oracle, now built
  on a graph database, Neo4j."
- Show the diagram in [design.md](design.md#2-model-diagram): 13 tables
  became 10 node labels and 9 relationship types.

## 2. Show the schema (2 min)

```cypher
CALL db.schema.visualization();
```

Explain three choices:

1. ORDER_ITEM is gone. It is now the `CONTAINS` relationship, with quantity
   and unitPrice on the edge.
2. The phone tables are gone. Phone numbers are now a `phones` list on
   Student and Staff.
3. Notification is not linked directly to Student. That keeps the Oracle
   BCNF decision, and the path through the order gives the student.

```cypher
SHOW CONSTRAINTS;
```

"Primary keys and UNIQUE columns became uniqueness constraints. NOT NULL and
CHECK cannot be enforced in Community Edition, so I wrote validation queries
instead."

## 3. Show the data (2 min)

```cypher
MATCH (n) RETURN labels(n)[0] AS label, count(*) AS nodes ORDER BY label;
```

```cypher
MATCH p = (o:LaundryOrder {orderId: 'O001'})-[*1..2]-()
RETURN p;
```

Use the graph view: start from order O001 and point out the student (and their
hostel), the service, the staff member, the garments with quantities on the
edges, the queue entry and machine, the payment, and the 3 notifications.

## 4. The 5 Oracle queries in Cypher (4 min)

Run A1–A5 one at a time, either with
`./scripts/run_cypher.sh --show --pause 03_queries.cypher` or by pasting the
printed Cypher into the Browser. For each one, give the SQL idea and the
Cypher idea in one sentence:

| Query | Talking point |
|-------|---------------|
| A1 | Subquery → compute `max` with `WITH`, then match |
| A2 | `GROUP BY … HAVING` → implicit grouping + `WITH … WHERE` |
| A3 | No rows, the same as Oracle: each student has one order |
| A4 | `count(DISTINCT o)` over the `CONTAINS` edges |
| A5 | JOIN on OrderID → follow the `HAS_PAYMENT` edge |

## 5. PL/SQL equivalents and integrity (3 min)

In a terminal:

```bash
.venv/bin/python python/run_plsql_equivalents.py --show --pause
./scripts/validate.sh
```

- "Cypher is not procedural, so the PL/SQL logic (variables, cursor loops,
  IF/ELSE) runs in Python with the Neo4j driver."
- "The validation script runs every Oracle CHECK, NOT NULL and FK rule as a
  query. All of them PASS."

## 6. Graph advantage (2 min, optional)

Run `./scripts/run_cypher.sh --show --pause 06_showcase.cypher`: C1 (unread
notifications per student), C2 (whose laundry is on machine M001) and C3
(students who send the same garments). Paste C4 into the Browser to show the
neighbourhood of order O001 as a picture.
"Each of these is a single pattern in Cypher. In SQL they need 3–5 joins."

Optional live workflow:

```bash
.venv/bin/python python/workflow.py advance O002   # Processing -> Ready for Pickup, creates N009
.venv/bin/python python/workflow.py show O002
.venv/bin/python python/workflow.py remind         # pickup reminders for orders still waiting
./scripts/reset.sh                                 # back to the original data
```

"The status change and the notification happen in one transaction. This is
the main goal of the system: telling students when their laundry is ready."

Optional: show that a uniqueness constraint really blocks duplicates:

```cypher
CREATE (:Student {studentId: 'S001', studentName: 'Duplicate'});
// Fails: Property uniqueness constraint violated: Node(...) already exists
//        with label `Student` and property `studentId` = 'S001'
```

## 7. Likely questions

| Question | Short answer |
|----------|--------------|
| Is the graph normalized? | Normal forms are defined for relations, but every redundancy-removal decision was kept. See relational-vs-graph.md §4. |
| How do you enforce foreign keys? | A relationship cannot point to a missing node, so referential integrity is automatic. Mandatory participation is checked by validation queries. |
| Why is Payment a node and not properties on the order? | It has its own ID, method and status, and could allow several payments later. See design decision D4. |
| Why did ORDER_ITEM become a relationship? | It is a weak entity identified only by (Order, Garment). That is exactly what an edge is. |
| What does Community Edition lack? | Existence and type constraints, RBAC and clustering. See design.md §5. |
| When would you pick graph over relational? | Questions about many connected hops, schemas that change often, and visual exploration. See relational-vs-graph.md §6. |
