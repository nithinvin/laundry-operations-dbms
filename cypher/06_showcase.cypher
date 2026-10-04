// 06_showcase.cypher
// Questions that are natural for a graph: multi-hop traversals and
// connection patterns. Expected outputs are in docs/queries.md (Part C).

// C1. Unread notifications per student
// Question: which students have notifications they have not read yet?
// Two hops, Student -> Order -> Notification. No stored Student-Notification
// link is needed (the Oracle BCNF decision is kept).
// Expected: Aditya [N008], Nithin [N003], Rahul [N005]
MATCH (s:Student)-[:PLACED]->(:LaundryOrder)-[:GENERATED]->(n:Notification {readStatus: 'Unread'})
RETURN s.studentName AS student, collect(n.notificationId) AS unread
ORDER BY student;

// C2. Whose laundry is queued on machine M001, in queue order?
// Question: whose laundry is waiting on machine M001, and in what order?
// Path Student -> Order -> QueueEntry -> Machine; in SQL this needs 3 joins.
// Expected: 1 O002 Arjun, 2 O003 Rahul
MATCH (s:Student)-[:PLACED]->(o:LaundryOrder)-[:IN_QUEUE]->(q:QueueEntry)-[:FOR_MACHINE]->(:Machine {machineId: 'M001'})
RETURN q.queuePosition AS position, o.orderId AS orderId, s.studentName AS student
ORDER BY position;

// C3. Students who send the same garment types (co-occurrence)
// Question: which pairs of students sent at least one garment type in common?
// A "people like you" pattern, as used in recommendation systems.
// Expected: Arjun-Aditya [Shirt], Nithin-Aditya [Shirt], Nithin-Arjun [Shirt], Nithin-Karthik [Pants]
MATCH (s1:Student)-[:PLACED]->(:LaundryOrder)-[:CONTAINS]->(g:GarmentType)
      <-[:CONTAINS]-(:LaundryOrder)<-[:PLACED]-(s2:Student)
WHERE s1.studentId < s2.studentId
RETURN s1.studentName AS student1, s2.studentName AS student2,
       collect(DISTINCT g.garmentName) AS sharedGarments
ORDER BY student1, student2;

// C4. Everything within two hops of order O001
// Question: show everything connected to order O001 (student, hostel, staff,
// service, garments, queue, machine, payment, notifications).
// Best viewed in Neo4j Browser's graph view (copy this query with --show).
// Expected: 15 paths
MATCH p = (o:LaundryOrder {orderId: 'O001'})-[*1..2]-()
RETURN p;

// C5. Which hostels does each staff member serve? (three hops)
// Question: Staff -> Order <- Student -> Hostel, i.e. where each staff member's customers live.
// Expected: Anita [Block D], Priya [Block C], Ramesh [Block A], Suresh [Block B], Vijay [Block E]
MATCH (st:Staff)-[:ASSIGNED_TO]->(:LaundryOrder)<-[:PLACED]-(:Student)-[:LIVES_IN]->(h:Hostel)
RETURN st.staffName AS staff, collect(DISTINCT h.hostelName) AS hostels
ORDER BY staff;
