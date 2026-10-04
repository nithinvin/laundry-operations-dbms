// 05_workflow.cypher
// Workflow operations as plain Cypher, for running step by step in Neo4j
// Browser. python/workflow.py does the same thing with status-path checks
// and automatic notification IDs.
//
// These statements CHANGE the data. Run ./scripts/reset.sh afterwards.

// Step 1: choose the order and the new notification ID
:param orderId => 'O002';
:param notificationId => 'N009';

// Step 2: look at the order before the change
MATCH (s:Student)-[:PLACED]->(o:LaundryOrder {orderId: $orderId})
RETURN o.orderId, s.studentName, o.status, o.actualCompletion;

// Step 3: mark the order ready (only if it is Processing) and notify the student
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

// Step 4: the student's unread notifications, found by traversal
MATCH (s:Student)-[:PLACED]->(:LaundryOrder {orderId: $orderId})
MATCH (s)-[:PLACED]->(:LaundryOrder)-[:GENERATED]->(n:Notification {readStatus: 'Unread'})
RETURN s.studentName, n.notificationId, n.notificationType, n.message;

// Step 5: the student reads the notification
MATCH (n:Notification {notificationId: $notificationId})
SET n.readStatus = 'Read'
RETURN n.notificationId, n.readStatus;
