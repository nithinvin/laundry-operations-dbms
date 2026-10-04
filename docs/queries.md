# Queries — SQL / PL/SQL vs Cypher / Python

Every query from the Oracle project is listed here next to its graph
version, with the **expected output** for the sample data. These are design
drafts. They are verified and finalized in Phase 4 and Phase 5 of
[plan.md](plan.md), and the final versions live in `cypher/03_queries.cypher`
and `python/`.

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

Common helper (`python/db.py`, sketch):

```python
import os
from dotenv import load_dotenv
from neo4j import GraphDatabase

load_dotenv()

def get_driver():
    return GraphDatabase.driver(
        os.getenv("NEO4J_URI", "bolt://localhost:7687"),
        auth=(os.getenv("NEO4J_USER", "neo4j"), os.environ["NEO4J_PASSWORD"]),
    )
```

### B1. Order with the highest total cost (variables, SELECT INTO, MAX, subquery)

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
RETURN s.studentName AS studentName, count(o) AS orderCount
ORDER BY s.studentId
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
RETURN s.studentName, collect(n.notificationId) AS unread
ORDER BY s.studentName;
```

Expected: Aditya [N008], Nithin [N003], Rahul [N005]

### C2. Whose laundry is queued on machine M001?

```cypher
MATCH (s:Student)-[:PLACED]->(o:LaundryOrder)-[:IN_QUEUE]->(q:QueueEntry)-[:FOR_MACHINE]->(:Machine {machineId: 'M001'})
RETURN q.queuePosition, o.orderId, s.studentName
ORDER BY q.queuePosition;
```

Expected: `1 | O002 | Arjun`, `2 | O003 | Rahul`

### C3. Students who send the same garment types (co-occurrence)

```cypher
MATCH (s1:Student)-[:PLACED]->(:LaundryOrder)-[:CONTAINS]->(g:GarmentType)
      <-[:CONTAINS]-(:LaundryOrder)<-[:PLACED]-(s2:Student)
WHERE s1.studentId < s2.studentId
RETURN s1.studentName, s2.studentName, collect(DISTINCT g.garmentName) AS shared;
```

Expected: Nithin–Arjun [Shirt], Nithin–Aditya [Shirt], Arjun–Aditya [Shirt], Nithin–Karthik [Pants]

### C4. Everything connected to order O001 (visual — run in Browser, Graph view)

```cypher
MATCH p = (o:LaundryOrder {orderId: 'O001'})-[*1..2]-()
RETURN p;
```

### C5. Which hostels does each staff member serve? (three hops)

```cypher
MATCH (st:Staff)-[:ASSIGNED_TO]->(:LaundryOrder)<-[:PLACED]-(:Student)-[:LIVES_IN]->(h:Hostel)
RETURN st.staffName, collect(DISTINCT h.hostelName) AS hostels
ORDER BY st.staffName;
```

---

## Part D — Workflow operations (GR-5)

These operations **change data**. Run `./scripts/reset.sh` afterwards if you
want the Part A/B outputs to match again.

```cypher
// Mark an order ready and notify the student
MATCH (o:LaundryOrder {orderId: $orderId})
WHERE o.status = 'Processing'
SET o.status = 'Ready for Pickup', o.actualCompletion = localdatetime()
CREATE (o)-[:GENERATED]->(:Notification {
  notificationId: $notificationId,
  notificationType: 'Ready for Pickup',
  message: 'Your laundry order ' + o.orderId + ' is ready for pickup.',
  sentAt: localdatetime(),
  readStatus: 'Unread'
})
RETURN o.orderId, o.status;
```

`python/workflow.py` works out the next notification ID (`N009`, …), runs
this inside one transaction, and refuses status changes that are not allowed.
The allowed path is Received → Queued → Processing → Ready for Pickup →
Picked Up, and Cancelled is allowed from any non-final status.
