// 04_validation.cypher
// Integrity checks for rules that Neo4j Community cannot enforce itself.
//
// Rule: every query returns the rows that BREAK the rule.
//       An empty result means PASS.
//
// Each check starts with a header line "// V-<kind>-<name>: <description>".
// python/validate.py uses these headers to split the file and report results.
// Kinds: NN = NOT NULL, CK = CHECK, FK = mandatory relationship (total
// participation), 11 = one-to-one, UQ = uniqueness, DC = data consistency.

// ===========================================================================
// NOT NULL (Oracle NOT NULL columns; existence constraints are Enterprise-only)
// ===========================================================================

// V-NN-hostel: Hostel has hostelId, hostelName, location
MATCH (n:Hostel)
WHERE n.hostelId IS NULL OR n.hostelName IS NULL OR n.location IS NULL
RETURN elementId(n) AS node, n.hostelId AS id;

// V-NN-student: Student has studentId, studentName, email, roomNo
MATCH (n:Student)
WHERE n.studentId IS NULL OR n.studentName IS NULL OR n.email IS NULL OR n.roomNo IS NULL
RETURN elementId(n) AS node, n.studentId AS id;

// V-NN-staff: Staff has staffId, staffName, staffRole
MATCH (n:Staff)
WHERE n.staffId IS NULL OR n.staffName IS NULL OR n.staffRole IS NULL
RETURN elementId(n) AS node, n.staffId AS id;

// V-NN-service: Service has serviceId, serviceName, pricePerItem, estimatedHours
MATCH (n:Service)
WHERE n.serviceId IS NULL OR n.serviceName IS NULL OR n.pricePerItem IS NULL OR n.estimatedHours IS NULL
RETURN elementId(n) AS node, n.serviceId AS id;

// V-NN-garment: GarmentType has garmentTypeId, garmentName, category
MATCH (n:GarmentType)
WHERE n.garmentTypeId IS NULL OR n.garmentName IS NULL OR n.category IS NULL
RETURN elementId(n) AS node, n.garmentTypeId AS id;

// V-NN-machine: Machine has machineId, machineType, capacity, machineStatus
MATCH (n:Machine)
WHERE n.machineId IS NULL OR n.machineType IS NULL OR n.capacity IS NULL OR n.machineStatus IS NULL
RETURN elementId(n) AS node, n.machineId AS id;

// V-NN-order: LaundryOrder has orderId, orderDateTime, expectedCompletion, status, totalAmount
MATCH (n:LaundryOrder)
WHERE n.orderId IS NULL OR n.orderDateTime IS NULL OR n.expectedCompletion IS NULL
   OR n.status IS NULL OR n.totalAmount IS NULL
RETURN elementId(n) AS node, n.orderId AS id;

// V-NN-queue: QueueEntry has queueId, queuePosition, addedAt, estimatedStart
MATCH (n:QueueEntry)
WHERE n.queueId IS NULL OR n.queuePosition IS NULL OR n.addedAt IS NULL OR n.estimatedStart IS NULL
RETURN elementId(n) AS node, n.queueId AS id;

// V-NN-payment: Payment has paymentId, amount, paymentDate, paymentMethod, paymentStatus
MATCH (n:Payment)
WHERE n.paymentId IS NULL OR n.amount IS NULL OR n.paymentDate IS NULL
   OR n.paymentMethod IS NULL OR n.paymentStatus IS NULL
RETURN elementId(n) AS node, n.paymentId AS id;

// V-NN-notification: Notification has notificationId, notificationType, message, sentAt, readStatus
MATCH (n:Notification)
WHERE n.notificationId IS NULL OR n.notificationType IS NULL OR n.message IS NULL
   OR n.sentAt IS NULL OR n.readStatus IS NULL
RETURN elementId(n) AS node, n.notificationId AS id;

// V-NN-contains: CONTAINS relationship has quantity and unitPrice
MATCH (o:LaundryOrder)-[c:CONTAINS]->(g:GarmentType)
WHERE c.quantity IS NULL OR c.unitPrice IS NULL
RETURN o.orderId, g.garmentTypeId;

// ===========================================================================
// CHECK (one query per Oracle CHECK constraint, same names)
// ===========================================================================

// V-CK-chk_service_price: Service.pricePerItem > 0
MATCH (n:Service) WHERE NOT n.pricePerItem > 0
RETURN n.serviceId, n.pricePerItem;

// V-CK-chk_service_hours: Service.estimatedHours > 0
MATCH (n:Service) WHERE NOT n.estimatedHours > 0
RETURN n.serviceId, n.estimatedHours;

// V-CK-chk_machine_capacity: Machine.capacity > 0
MATCH (n:Machine) WHERE NOT n.capacity > 0
RETURN n.machineId, n.capacity;

// V-CK-chk_machine_status: Machine.machineStatus is an allowed value
MATCH (n:Machine)
WHERE NOT n.machineStatus IN ['Available', 'Running', 'Maintenance', 'Out of Service']
RETURN n.machineId, n.machineStatus;

// V-CK-chk_order_status: LaundryOrder.status is an allowed value
MATCH (n:LaundryOrder)
WHERE NOT n.status IN ['Received', 'Queued', 'Processing', 'Ready for Pickup', 'Picked Up', 'Cancelled']
RETURN n.orderId, n.status;

// V-CK-chk_order_amount: LaundryOrder.totalAmount >= 0
MATCH (n:LaundryOrder) WHERE NOT n.totalAmount >= 0
RETURN n.orderId, n.totalAmount;

// V-CK-chk_order_completion: actualCompletion is missing or >= orderDateTime
MATCH (n:LaundryOrder)
WHERE n.actualCompletion IS NOT NULL AND n.actualCompletion < n.orderDateTime
RETURN n.orderId, n.orderDateTime, n.actualCompletion;

// V-CK-chk_order_expected: expectedCompletion >= orderDateTime
MATCH (n:LaundryOrder) WHERE n.expectedCompletion < n.orderDateTime
RETURN n.orderId, n.orderDateTime, n.expectedCompletion;

// V-CK-chk_order_item_quantity: CONTAINS.quantity > 0
MATCH (o:LaundryOrder)-[c:CONTAINS]->(g:GarmentType) WHERE NOT c.quantity > 0
RETURN o.orderId, g.garmentTypeId, c.quantity;

// V-CK-chk_order_item_price: CONTAINS.unitPrice > 0
MATCH (o:LaundryOrder)-[c:CONTAINS]->(g:GarmentType) WHERE NOT c.unitPrice > 0
RETURN o.orderId, g.garmentTypeId, c.unitPrice;

// V-CK-chk_queue_position: QueueEntry.queuePosition > 0
MATCH (n:QueueEntry) WHERE NOT n.queuePosition > 0
RETURN n.queueId, n.queuePosition;

// V-CK-chk_payment_amount: Payment.amount > 0
MATCH (n:Payment) WHERE NOT n.amount > 0
RETURN n.paymentId, n.amount;

// V-CK-chk_payment_method: Payment.paymentMethod is an allowed value
MATCH (n:Payment)
WHERE NOT n.paymentMethod IN ['UPI', 'Card', 'Cash', 'Net Banking']
RETURN n.paymentId, n.paymentMethod;

// V-CK-chk_payment_status: Payment.paymentStatus is an allowed value
MATCH (n:Payment)
WHERE NOT n.paymentStatus IN ['Paid', 'Pending', 'Failed', 'Refunded']
RETURN n.paymentId, n.paymentStatus;

// V-CK-chk_notification_status: Notification.readStatus is Read or Unread
MATCH (n:Notification)
WHERE NOT n.readStatus IN ['Read', 'Unread']
RETURN n.notificationId, n.readStatus;

// ===========================================================================
// FK total participation (Oracle NOT NULL foreign keys)
// ===========================================================================

// V-FK-student-hostel: every Student LIVES_IN exactly one Hostel
MATCH (s:Student)
WITH s, COUNT { (s)-[:LIVES_IN]->(:Hostel) } AS c
WHERE c <> 1
RETURN s.studentId, c AS hostels;

// V-FK-order-student: every LaundryOrder is PLACED by exactly one Student
MATCH (o:LaundryOrder)
WITH o, COUNT { (:Student)-[:PLACED]->(o) } AS c
WHERE c <> 1
RETURN o.orderId, c AS students;

// V-FK-order-service: every LaundryOrder USES_SERVICE exactly one Service
MATCH (o:LaundryOrder)
WITH o, COUNT { (o)-[:USES_SERVICE]->(:Service) } AS c
WHERE c <> 1
RETURN o.orderId, c AS services;

// V-FK-order-staff: every LaundryOrder is ASSIGNED_TO exactly one Staff member
MATCH (o:LaundryOrder)
WITH o, COUNT { (:Staff)-[:ASSIGNED_TO]->(o) } AS c
WHERE c <> 1
RETURN o.orderId, c AS staff;

// V-FK-order-items: every LaundryOrder CONTAINS at least one GarmentType
MATCH (o:LaundryOrder)
WHERE NOT EXISTS { (o)-[:CONTAINS]->(:GarmentType) }
RETURN o.orderId;

// V-FK-queue-order: every QueueEntry belongs to exactly one LaundryOrder
MATCH (q:QueueEntry)
WITH q, COUNT { (:LaundryOrder)-[:IN_QUEUE]->(q) } AS c
WHERE c <> 1
RETURN q.queueId, c AS orders;

// V-FK-queue-machine: every QueueEntry is FOR_MACHINE exactly one Machine
MATCH (q:QueueEntry)
WITH q, COUNT { (q)-[:FOR_MACHINE]->(:Machine) } AS c
WHERE c <> 1
RETURN q.queueId, c AS machines;

// V-FK-payment-order: every Payment belongs to exactly one LaundryOrder
MATCH (p:Payment)
WITH p, COUNT { (:LaundryOrder)-[:HAS_PAYMENT]->(p) } AS c
WHERE c <> 1
RETURN p.paymentId, c AS orders;

// V-FK-notification-order: every Notification was GENERATED by exactly one LaundryOrder
MATCH (n:Notification)
WITH n, COUNT { (:LaundryOrder)-[:GENERATED]->(n) } AS c
WHERE c <> 1
RETURN n.notificationId, c AS orders;

// ===========================================================================
// One-to-one rules
// ===========================================================================

// V-11-payment: every LaundryOrder has exactly one Payment (Oracle: PAYMENT.OrderID UNIQUE, 1:1)
MATCH (o:LaundryOrder)
WITH o, COUNT { (o)-[:HAS_PAYMENT]->(:Payment) } AS c
WHERE c <> 1
RETURN o.orderId, c AS payments;

// V-11-queue: a LaundryOrder has at most one QueueEntry (1:0..1)
MATCH (o:LaundryOrder)
WITH o, COUNT { (o)-[:IN_QUEUE]->(:QueueEntry) } AS c
WHERE c > 1
RETURN o.orderId, c AS queueEntries;

// ===========================================================================
// Uniqueness that a node-property constraint cannot express
// ===========================================================================

// V-UQ-queue: queuePosition is unique per Machine (Oracle UNIQUE(MachineID, QueuePosition))
MATCH (q:QueueEntry)-[:FOR_MACHINE]->(m:Machine)
WITH m, q.queuePosition AS position, collect(q.queueId) AS entries
WHERE size(entries) > 1
RETURN m.machineId, position, entries;

// V-UQ-contains: at most one CONTAINS per (order, garment) pair (Oracle ORDER_ITEM primary key)
MATCH (o:LaundryOrder)-[c:CONTAINS]->(g:GarmentType)
WITH o, g, count(c) AS c
WHERE c > 1
RETURN o.orderId, g.garmentTypeId, c AS duplicates;

// V-UQ-student-phones: no duplicate phone numbers within a Student (Oracle STUDENT_PHONE primary key)
MATCH (s:Student)
WHERE s.phones IS NOT NULL
  AND size(s.phones) <> size(reduce(acc = [], p IN s.phones | CASE WHEN p IN acc THEN acc ELSE acc + p END))
RETURN s.studentId, s.phones;

// V-UQ-staff-phones: no duplicate phone numbers within a Staff member (Oracle STAFF_PHONE primary key)
MATCH (st:Staff)
WHERE st.phones IS NOT NULL
  AND size(st.phones) <> size(reduce(acc = [], p IN st.phones | CASE WHEN p IN acc THEN acc ELSE acc + p END))
RETURN st.staffId, st.phones;

// ===========================================================================
// Data consistency
// ===========================================================================

// V-DC-total: totalAmount equals the sum of quantity x unitPrice of its items
MATCH (o:LaundryOrder)-[c:CONTAINS]->(:GarmentType)
WITH o, sum(c.quantity * c.unitPrice) AS itemsTotal
WHERE abs(o.totalAmount - itemsTotal) > 0.001
RETURN o.orderId, o.totalAmount, itemsTotal;
