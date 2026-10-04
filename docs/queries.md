# Queries — SQL / PL/SQL vs Cypher / Python

Every query from the Oracle project is listed here next to its graph
version, with the **expected output** for the sample data. All outputs below
were checked against the running database. The source files are:

| Part | File | Saved output |
|------|------|--------------|
| A. SQL queries | `cypher/03_queries.cypher` | [outputs/queries.txt](outputs/queries.txt) |
| B. PL/SQL blocks | `python/plsql_q1_…py` … `plsql_q5_…py` | [outputs/plsql_equivalents.txt](outputs/plsql_equivalents.txt) |
| C. Graph showcase | `cypher/06_showcase.cypher` | — |
| D. Workflow | `cypher/05_workflow.cypher`, `python/workflow.py` | — |

Run them with `./scripts/run_cypher.sh 03_queries.cypher` and
`python python/run_plsql_equivalents.py`.

Overall average order amount, used by Q2: (100 + 140 + 240 + 75 + 120) / 5 = **135**.

---

## Part A — Advanced SQL queries

### A1. Student with the most expensive order

```sql
SELECT s.studentid, s.studentname, l.orderid, l.totalamount
FROM student s JOIN laundry_order l ON s.studentid = l.studentid
WHERE l.totalamount = (SELECT max(totalamount) FROM laundry_order);
```

```cypher
MATCH (o:LaundryOrder)
WITH max(o.totalAmount) AS maxAmount
MATCH (s:Student)-[:PLACED]->(o:LaundryOrder)
WHERE o.totalAmount = maxAmount
RETURN s.studentId, s.studentName, o.orderId, o.totalAmount;
```

Expected: `S003 | Rahul | O003 | 240.0`

### A2. Services whose average order amount is above the overall average

```sql
SELECT sv.serviceid, sv.servicename, avg(l.totalamount) AS averageamount
FROM service sv JOIN laundry_order l ON sv.serviceid = l.serviceid
GROUP BY sv.serviceid, sv.servicename
HAVING avg(l.totalamount) > (SELECT avg(totalamount) FROM laundry_order);
```

```cypher
MATCH (o:LaundryOrder)
WITH avg(o.totalAmount) AS overallAvg
MATCH (o:LaundryOrder)-[:USES_SERVICE]->(sv:Service)
WITH sv, overallAvg, avg(o.totalAmount) AS averageAmount
WHERE averageAmount > overallAvg
RETURN sv.serviceId, sv.serviceName, averageAmount
ORDER BY sv.serviceId;
```

Expected:

```
SV002 | Wash and Iron | 140.0
SV003 | Dry Clean     | 240.0
```

### A3. Students with more than one order

```sql
SELECT s.studentid, s.studentname, count(l.orderid) AS ordercount
FROM student s JOIN laundry_order l ON s.studentid = l.studentid
GROUP BY s.studentid, s.studentname
HAVING count(l.orderid) > 1;
```

```cypher
MATCH (s:Student)-[:PLACED]->(o:LaundryOrder)
WITH s, count(o) AS orderCount
WHERE orderCount > 1
RETURN s.studentId, s.studentName, orderCount;
```

Expected: **no rows**. Each student has exactly one order, and Oracle also
returns "no rows selected". This is the correct answer for this data, not a
bug.

### A4. Garment types appearing in more than one order

```sql
SELECT g.garmenttypeid, g.garmentname, count(DISTINCT oi.orderid) AS ordercount
FROM garment_type g JOIN order_item oi ON g.garmenttypeid = oi.garmenttypeid
GROUP BY g.garmenttypeid, g.garmentname
HAVING count(DISTINCT oi.orderid) > 1;
```

```cypher
MATCH (o:LaundryOrder)-[:CONTAINS]->(g:GarmentType)
WITH g, count(DISTINCT o) AS orderCount
WHERE orderCount > 1
RETURN g.garmentTypeId, g.garmentName, orderCount
ORDER BY g.garmentTypeId;
```

Expected:

```
G001 | Shirt | 3     (O001, O002, O005)
G002 | Pants | 2     (O001, O004)
```

### A5. Orders whose payment amount matches the order amount

```sql
SELECT l.orderid, l.totalamount, p.amount, p.paymentstatus
FROM laundry_order l JOIN payment p ON l.orderid = p.orderid
WHERE p.amount = l.totalamount;
```

```cypher
MATCH (o:LaundryOrder)-[:HAS_PAYMENT]->(p:Payment)
WHERE p.amount = o.totalAmount
RETURN o.orderId, o.totalAmount, p.amount, p.paymentStatus
ORDER BY o.orderId;
```

Expected: 5 rows. O001 100, O002 140, O003 240, O004 75 and O005 120 all
match, and every status is `Paid`.

---

## Part B — PL/SQL blocks → Python + `neo4j` driver

Cypher has no variables that last across statements, no IF/ELSE blocks, no
cursors and no loops in the PL/SQL sense. Each PL/SQL block therefore becomes
a short Python script. **Cypher does the data work, and Python does the
procedural work.**

| PL/SQL concept | Python equivalent |
|----------------|-------------------|
| `DECLARE v_x …%TYPE` | Python variable (dynamically typed) |
| `SELECT … INTO v_x` | `record = session.run(q).single()` then `v_x = record["x"]` |
| `CURSOR c IS SELECT …` + `FOR rec IN c LOOP` | `for rec in session.run(q):` |
| `IF … THEN … ELSE … END IF` | `if …: … else: …` |
| `DBMS_OUTPUT.PUT_LINE` | `print()` |
| `NVL(x, 0)` | `coalesce(x, 0)` in Cypher |
| `SET SERVEROUTPUT ON` | not needed |

Every script connects through `python/db.py` (shown here simplified). It reads `.env` from the repo root:

```python
import os
from dotenv import load_dotenv
from neo4j import GraphDatabase

load_dotenv()  # reads NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD from .env

def get_driver():
    return GraphDatabase.driver(
        os.getenv("NEO4J_URI", "bolt://localhost:7687"),
        auth=(os.getenv("NEO4J_USER", "neo4j"), os.environ["NEO4J_PASSWORD"]),
    )
```

### B1. Order with the highest total cost (variables, SELECT INTO, MAX, subquery)

File: `python/plsql_q1_highest_order.py` (simplified below). B2–B5 follow the same pattern, in `plsql_q2_total_revenue.py`, `plsql_q3_student_orders.py`, `plsql_q4_pending_orders.py` and `plsql_q5_ready_check.py`.

```python
query = """
MATCH (o:LaundryOrder) WITH max(o.totalAmount) AS m
MATCH (s:Student)-[:PLACED]->(o:LaundryOrder)-[:USES_SERVICE]->(sv:Service)
WHERE o.totalAmount = m
RETURN o.orderId AS orderId, s.studentId AS studentId,
       sv.serviceId AS serviceId, o.totalAmount AS totalAmount
"""
with get_driver() as driver, driver.session() as session:
    rec = session.run(query).single()
    v_order_id, v_student_id = rec["orderId"], rec["studentId"]
    v_service_id, v_total_amount = rec["serviceId"], rec["totalAmount"]
    print(f"Order ID: {v_order_id}")
    print(f"Student ID: {v_student_id}")
    print(f"Service ID: {v_service_id}")
    print(f"Highest Total Amount: {v_total_amount:g}")
```

Expected (same as Oracle):

```
Order ID: O003
Student ID: S003
Service ID: SV003
Highest Total Amount: 240
```

### B2. Total revenue from paid orders (SUM, NVL)

```cypher
MATCH (p:Payment {paymentStatus: 'Paid'})
RETURN coalesce(sum(p.amount), 0) AS revenue
```

Python prints `f"Total Revenue from Paid Orders: {revenue:g}"`.
Expected: `Total Revenue from Paid Orders: 675`

### B3. Each student and their order count (cursor, loop, LEFT JOIN, COUNT)

```cypher
MATCH (s:Student)
OPTIONAL MATCH (s)-[:PLACED]->(o:LaundryOrder)
RETURN s.studentId AS studentId, s.studentName AS studentName, count(o) AS orderCount
ORDER BY studentId
```

Python loop: `for rec in result: print(f"Student: {rec['studentName']} | Orders: {rec['orderCount']}")`

Expected:

```
Student: Nithin | Orders: 1
Student: Arjun | Orders: 1
Student: Rahul | Orders: 1
Student: Karthik | Orders: 1
Student: Aditya | Orders: 1
```

`OPTIONAL MATCH` plays the role of the `LEFT JOIN`. A student with no orders
would still appear, with a count of 0.

### B4. Pending laundry orders (cursor, loop, multi-join, filter)

```cypher
MATCH (s:Student)-[:PLACED]->(o:LaundryOrder)-[:USES_SERVICE]->(sv:Service)
WHERE o.status <> 'Picked Up'
RETURN o.orderId AS orderId, s.studentName AS studentName,
       sv.serviceName AS serviceName, o.status AS status
ORDER BY o.orderId
```

Expected:

```
Order: O001 | Student: Nithin | Service: Normal Wash | Status: Ready for Pickup
Order: O002 | Student: Arjun | Service: Wash and Iron | Status: Processing
Order: O003 | Student: Rahul | Service: Dry Clean | Status: Queued
Order: O005 | Student: Aditya | Service: Express Wash | Status: Received
```

(The Oracle cursor had no `ORDER BY`, so its row order was not guaranteed.
The Cypher version sorts by order ID so the output is stable.)

### B5. Is order O001 ready for pickup? (SELECT INTO, IF-ELSE)

```python
rec = session.run(
    "MATCH (o:LaundryOrder {orderId: $id}) RETURN o.status AS status", id="O001"
).single()
v_status = rec["status"]
if v_status == "Ready for Pickup":
    print("Order O001 is ready for pickup.")
else:
    print("Order O001 is not ready for pickup.")
```

Expected: `Order O001 is ready for pickup.`

The same logic in pure Cypher, to show `CASE`:

```cypher
MATCH (o:LaundryOrder {orderId: 'O001'})
RETURN CASE WHEN o.status = 'Ready for Pickup'
            THEN 'Order O001 is ready for pickup.'
            ELSE 'Order O001 is not ready for pickup.' END AS message;
```

---

## Part C — Graph showcase queries (GR-6, optional)

These questions show where a graph is natural to use.

### C1. Unread notifications per student (two hops, no stored Student link)

```cypher
MATCH (s:Student)-[:PLACED]->(:LaundryOrder)-[:GENERATED]->(n:Notification {readStatus: 'Unread'})
RETURN s.studentName AS student, collect(n.notificationId) AS unread
ORDER BY student;
```

Expected: `Aditya [N008]`, `Nithin [N003]`, `Rahul [N005]`

### C2. Whose laundry is queued on machine M001?

```cypher
MATCH (s:Student)-[:PLACED]->(o:LaundryOrder)-[:IN_QUEUE]->(q:QueueEntry)-[:FOR_MACHINE]->(:Machine {machineId: 'M001'})
RETURN q.queuePosition AS position, o.orderId AS orderId, s.studentName AS student
ORDER BY position;
```

Expected: `1 | O002 | Arjun`, `2 | O003 | Rahul`

### C3. Students who send the same garment types (co-occurrence)

```cypher
MATCH (s1:Student)-[:PLACED]->(:LaundryOrder)-[:CONTAINS]->(g:GarmentType)
      <-[:CONTAINS]-(:LaundryOrder)<-[:PLACED]-(s2:Student)
WHERE s1.studentId < s2.studentId
RETURN s1.studentName AS student1, s2.studentName AS student2,
       collect(DISTINCT g.garmentName) AS sharedGarments
ORDER BY student1, student2;
```

Expected:

```
Arjun  | Aditya  | [Shirt]
Nithin | Aditya  | [Shirt]
Nithin | Arjun   | [Shirt]
Nithin | Karthik | [Pants]
```

### C4. Everything within two hops of order O001 (visual: run in Browser, graph view)

```cypher
MATCH p = (o:LaundryOrder {orderId: 'O001'})-[*1..2]-()
RETURN p;
```

Expected: 15 paths. They reach the student and hostel, the staff member, the
service, both garments (and the other orders that share them), the queue entry
and machine, the payment, and the 3 notifications.

### C5. Which hostels does each staff member serve? (three hops)

```cypher
MATCH (st:Staff)-[:ASSIGNED_TO]->(:LaundryOrder)<-[:PLACED]-(:Student)-[:LIVES_IN]->(h:Hostel)
RETURN st.staffName AS staff, collect(DISTINCT h.hostelName) AS hostels
ORDER BY staff;
```

Expected: Anita [Block D], Priya [Block C], Ramesh [Block A], Suresh [Block B],
Vijay [Block E]. With the current data each staff member has one order. As
more orders are added, this list grows without changing the query.

---

## Part D — Workflow operations (GR-5)

These operations **change data**. Run `./scripts/reset.sh` afterwards to get
the Part A/B outputs back.

### D1. Python: `python/workflow.py`

| Command | What it does |
|---------|--------------|
| `show O002` | Order status and its notifications |
| `advance O002` | Moves to the next status: Received → Queued → Processing → Ready for Pickup → Picked Up |
| `cancel O005` | Cancels an order that is not yet ready |
| `remind` | Sends a "Pickup Reminder" for every order still waiting for pickup |

The status change and its notification run in **one write transaction**:
either both happen or neither does. Notifications are created automatically
when an order enters Processing ("Processing"), Ready for Pickup ("Ready for
Pickup", which also sets `actualCompletion`), Picked Up ("Pickup
Confirmation") or Cancelled ("Order Cancelled"). The next notification ID
(`N009`, `N010`, …) is computed from the highest existing one.

Example run on fresh data:

```
$ python python/workflow.py advance O002
Order O002: Processing -> Ready for Pickup
Notification N009 created.
$ python python/workflow.py show O002
Order O002 | Student: Arjun | Status: Ready for Pickup
  N004 Processing (Read)
  N009 Ready for Pickup (Unread)
$ python python/workflow.py advance O004
Order O004 is 'Picked Up'; it cannot move forward.
```

### D2. Cypher in Browser: `cypher/05_workflow.cypher`

The same "mark ready + notify" step in plain Cypher, using Browser parameters:

```cypher
:param orderId => 'O002';
:param notificationId => 'N009';

MATCH (o:LaundryOrder {orderId: $orderId})
WHERE o.status = 'Processing'
SET o.status = 'Ready for Pickup',
    o.actualCompletion = localdatetime.truncate('second', localdatetime())
CREATE (o)-[:GENERATED]->(n:Notification {
  notificationId: $notificationId,
  notificationType: 'Ready for Pickup',
  message: 'Your laundry order ' + o.orderId + ' is ready for pickup.',
  sentAt: localdatetime.truncate('second', localdatetime()),
  readStatus: 'Unread'
})
RETURN o.orderId, o.status, n.notificationId, n.message;
```

The file then shows the student's unread notifications (found by traversal)
and marks the notification as read.
