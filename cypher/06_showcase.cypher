// 06_showcase.cypher
// Questions that are natural for a graph: multi-hop traversals and
// connection patterns. Expected outputs are in docs/queries.md (Part C).

// C1. Unread notifications per student
// Two hops, Student -> Order -> Notification. No stored Student-Notification
// link is needed (the Oracle BCNF decision is kept).
MATCH (s:Student)-[:PLACED]->(:LaundryOrder)-[:GENERATED]->(n:Notification {readStatus: 'Unread'})
RETURN s.studentName AS student, collect(n.notificationId) AS unread
ORDER BY student;

// C2. Whose laundry is queued on machine M001, in queue order?
MATCH (s:Student)-[:PLACED]->(o:LaundryOrder)-[:IN_QUEUE]->(q:QueueEntry)-[:FOR_MACHINE]->(:Machine {machineId: 'M001'})
RETURN q.queuePosition AS position, o.orderId AS orderId, s.studentName AS student
ORDER BY position;

// C3. Students who send the same garment types (co-occurrence)
MATCH (s1:Student)-[:PLACED]->(:LaundryOrder)-[:CONTAINS]->(g:GarmentType)
      <-[:CONTAINS]-(:LaundryOrder)<-[:PLACED]-(s2:Student)
WHERE s1.studentId < s2.studentId
RETURN s1.studentName AS student1, s2.studentName AS student2,
       collect(DISTINCT g.garmentName) AS sharedGarments
ORDER BY student1, student2;

// C4. Everything within two hops of order O001.
// Best viewed in Neo4j Browser's graph view.
MATCH p = (o:LaundryOrder {orderId: 'O001'})-[*1..2]-()
RETURN p;

// C5. Which hostels does each staff member serve? (three hops)
MATCH (st:Staff)-[:ASSIGNED_TO]->(:LaundryOrder)<-[:PLACED]-(:Student)-[:LIVES_IN]->(h:Hostel)
RETURN st.staffName AS staff, collect(DISTINCT h.hostelName) AS hostels
ORDER BY staff;
