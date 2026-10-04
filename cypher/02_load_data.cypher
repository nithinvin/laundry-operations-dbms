// 02_load_data.cypher
// Loads the same sample data as the Oracle version
// (reference/oracle/laundry_schema_and_data.sql).
// Uses MERGE on the ID properties, so it is safe to run more than once.
// Run 01_constraints.cypher first.

// ---------------------------------------------------------------------------
// Nodes
// ---------------------------------------------------------------------------

// HOSTEL
UNWIND [
  {hostelId: 'H001', hostelName: 'Block A Hostel', location: 'North Campus'},
  {hostelId: 'H002', hostelName: 'Block B Hostel', location: 'North Campus'},
  {hostelId: 'H003', hostelName: 'Block C Hostel', location: 'South Campus'},
  {hostelId: 'H004', hostelName: 'Block D Hostel', location: 'South Campus'},
  {hostelId: 'H005', hostelName: 'Block E Hostel', location: 'Main Campus'}
] AS row
MERGE (h:Hostel {hostelId: row.hostelId})
SET h.hostelName = row.hostelName,
    h.location   = row.location;

// STUDENT + STUDENT_PHONE (phones become a list property)
UNWIND [
  {studentId: 'S001', studentName: 'Nithin',  email: 'nithin@vit.ac.in',  roomNo: 'A101', phones: ['9876543210', '9123456789']},
  {studentId: 'S002', studentName: 'Arjun',   email: 'arjun@vit.ac.in',   roomNo: 'B202', phones: ['9988776655']},
  {studentId: 'S003', studentName: 'Rahul',   email: 'rahul@vit.ac.in',   roomNo: 'C303', phones: ['9876501234']},
  {studentId: 'S004', studentName: 'Karthik', email: 'karthik@vit.ac.in', roomNo: 'D404', phones: ['9123405678']},
  {studentId: 'S005', studentName: 'Aditya',  email: 'aditya@vit.ac.in',  roomNo: 'E505', phones: ['9000012345']}
] AS row
MERGE (s:Student {studentId: row.studentId})
SET s.studentName = row.studentName,
    s.email       = row.email,
    s.roomNo      = row.roomNo,
    s.phones      = row.phones;

// STAFF + STAFF_PHONE
UNWIND [
  {staffId: 'ST001', staffName: 'Ramesh', staffRole: 'Laundry Operator', phones: ['9000011111', '9000022222']},
  {staffId: 'ST002', staffName: 'Suresh', staffRole: 'Laundry Operator', phones: ['9000033333']},
  {staffId: 'ST003', staffName: 'Priya',  staffRole: 'Supervisor',       phones: ['9000044444']},
  {staffId: 'ST004', staffName: 'Anita',  staffRole: 'Laundry Operator', phones: ['9000055555']},
  {staffId: 'ST005', staffName: 'Vijay',  staffRole: 'Receptionist',     phones: ['9000066666']}
] AS row
MERGE (st:Staff {staffId: row.staffId})
SET st.staffName = row.staffName,
    st.staffRole = row.staffRole,
    st.phones    = row.phones;

// SERVICE
UNWIND [
  {serviceId: 'SV001', serviceName: 'Normal Wash',   pricePerItem: 20.0, estimatedHours: 6},
  {serviceId: 'SV002', serviceName: 'Wash and Iron', pricePerItem: 35.0, estimatedHours: 8},
  {serviceId: 'SV003', serviceName: 'Dry Clean',     pricePerItem: 80.0, estimatedHours: 24},
  {serviceId: 'SV004', serviceName: 'Ironing',       pricePerItem: 15.0, estimatedHours: 3},
  {serviceId: 'SV005', serviceName: 'Express Wash',  pricePerItem: 40.0, estimatedHours: 3}
] AS row
MERGE (sv:Service {serviceId: row.serviceId})
SET sv.serviceName    = row.serviceName,
    sv.pricePerItem   = row.pricePerItem,
    sv.estimatedHours = row.estimatedHours;

// GARMENT_TYPE
UNWIND [
  {garmentTypeId: 'G001', garmentName: 'Shirt',    category: 'Clothing'},
  {garmentTypeId: 'G002', garmentName: 'Pants',    category: 'Clothing'},
  {garmentTypeId: 'G003', garmentName: 'Bedsheet', category: 'Bedding'},
  {garmentTypeId: 'G004', garmentName: 'Towel',    category: 'Linen'},
  {garmentTypeId: 'G005', garmentName: 'Jacket',   category: 'Clothing'}
] AS row
MERGE (g:GarmentType {garmentTypeId: row.garmentTypeId})
SET g.garmentName = row.garmentName,
    g.category    = row.category;

// MACHINE
UNWIND [
  {machineId: 'M001', machineType: 'Washing Machine', capacity: 8.0,  machineStatus: 'Running'},
  {machineId: 'M002', machineType: 'Washing Machine', capacity: 10.0, machineStatus: 'Available'},
  {machineId: 'M003', machineType: 'Dryer',           capacity: 8.0,  machineStatus: 'Running'},
  {machineId: 'M004', machineType: 'Dry Cleaner',     capacity: 12.0, machineStatus: 'Maintenance'},
  {machineId: 'M005', machineType: 'Washing Machine', capacity: 10.0, machineStatus: 'Available'}
] AS row
MERGE (m:Machine {machineId: row.machineId})
SET m.machineType   = row.machineType,
    m.capacity      = row.capacity,
    m.machineStatus = row.machineStatus;

// LAUNDRY_ORDER (node + PLACED, USES_SERVICE, ASSIGNED_TO)
// actualCompletion is null for unfinished orders; SET to null leaves the
// property out, which is how Neo4j represents NULL.
UNWIND [
  {orderId: 'O001', studentId: 'S001', serviceId: 'SV001', staffId: 'ST001',
   orderDateTime: '2026-09-01T09:00:00', expectedCompletion: '2026-09-01T15:00:00',
   actualCompletion: '2026-09-01T14:30:00', status: 'Ready for Pickup', totalAmount: 100.0},
  {orderId: 'O002', studentId: 'S002', serviceId: 'SV002', staffId: 'ST002',
   orderDateTime: '2026-09-02T10:00:00', expectedCompletion: '2026-09-02T18:00:00',
   actualCompletion: null, status: 'Processing', totalAmount: 140.0},
  {orderId: 'O003', studentId: 'S003', serviceId: 'SV003', staffId: 'ST003',
   orderDateTime: '2026-09-03T11:00:00', expectedCompletion: '2026-09-04T11:00:00',
   actualCompletion: null, status: 'Queued', totalAmount: 240.0},
  {orderId: 'O004', studentId: 'S004', serviceId: 'SV004', staffId: 'ST004',
   orderDateTime: '2026-09-04T12:00:00', expectedCompletion: '2026-09-04T15:00:00',
   actualCompletion: '2026-09-04T14:45:00', status: 'Picked Up', totalAmount: 75.0},
  {orderId: 'O005', studentId: 'S005', serviceId: 'SV005', staffId: 'ST005',
   orderDateTime: '2026-09-05T13:00:00', expectedCompletion: '2026-09-05T16:00:00',
   actualCompletion: null, status: 'Received', totalAmount: 120.0}
] AS row
MERGE (o:LaundryOrder {orderId: row.orderId})
SET o.orderDateTime      = localdatetime(row.orderDateTime),
    o.expectedCompletion = localdatetime(row.expectedCompletion),
    o.actualCompletion   = localdatetime(row.actualCompletion),
    o.status             = row.status,
    o.totalAmount        = row.totalAmount
WITH o, row
MATCH (s:Student {studentId: row.studentId})
MATCH (sv:Service {serviceId: row.serviceId})
MATCH (st:Staff {staffId: row.staffId})
MERGE (s)-[:PLACED]->(o)
MERGE (o)-[:USES_SERVICE]->(sv)
MERGE (st)-[:ASSIGNED_TO]->(o);

// QUEUE_ENTRY (node + IN_QUEUE, FOR_MACHINE)
UNWIND [
  {queueId: 'Q001', orderId: 'O002', machineId: 'M001', queuePosition: 1, addedAt: '2026-09-02T10:15:00', estimatedStart: '2026-09-02T10:30:00'},
  {queueId: 'Q002', orderId: 'O003', machineId: 'M001', queuePosition: 2, addedAt: '2026-09-03T11:15:00', estimatedStart: '2026-09-03T18:30:00'},
  {queueId: 'Q003', orderId: 'O005', machineId: 'M002', queuePosition: 1, addedAt: '2026-09-05T13:15:00', estimatedStart: '2026-09-05T13:30:00'},
  {queueId: 'Q004', orderId: 'O001', machineId: 'M003', queuePosition: 1, addedAt: '2026-09-01T09:15:00', estimatedStart: '2026-09-01T09:30:00'},
  {queueId: 'Q005', orderId: 'O004', machineId: 'M005', queuePosition: 1, addedAt: '2026-09-04T12:15:00', estimatedStart: '2026-09-04T12:30:00'}
] AS row
MERGE (q:QueueEntry {queueId: row.queueId})
SET q.queuePosition  = row.queuePosition,
    q.addedAt        = localdatetime(row.addedAt),
    q.estimatedStart = localdatetime(row.estimatedStart)
WITH q, row
MATCH (o:LaundryOrder {orderId: row.orderId})
MATCH (m:Machine {machineId: row.machineId})
MERGE (o)-[:IN_QUEUE]->(q)
MERGE (q)-[:FOR_MACHINE]->(m);

// PAYMENT (node + HAS_PAYMENT)
UNWIND [
  {paymentId: 'P001', orderId: 'O001', amount: 100.0, paymentDate: '2026-09-01', paymentMethod: 'UPI',         paymentStatus: 'Paid'},
  {paymentId: 'P002', orderId: 'O002', amount: 140.0, paymentDate: '2026-09-02', paymentMethod: 'Card',        paymentStatus: 'Paid'},
  {paymentId: 'P003', orderId: 'O003', amount: 240.0, paymentDate: '2026-09-03', paymentMethod: 'UPI',         paymentStatus: 'Paid'},
  {paymentId: 'P004', orderId: 'O004', amount: 75.0,  paymentDate: '2026-09-04', paymentMethod: 'Cash',        paymentStatus: 'Paid'},
  {paymentId: 'P005', orderId: 'O005', amount: 120.0, paymentDate: '2026-09-05', paymentMethod: 'Net Banking', paymentStatus: 'Paid'}
] AS row
MERGE (p:Payment {paymentId: row.paymentId})
SET p.amount        = row.amount,
    p.paymentDate   = date(row.paymentDate),
    p.paymentMethod = row.paymentMethod,
    p.paymentStatus = row.paymentStatus
WITH p, row
MATCH (o:LaundryOrder {orderId: row.orderId})
MERGE (o)-[:HAS_PAYMENT]->(p);

// NOTIFICATION (node + GENERATED)
UNWIND [
  {notificationId: 'N001', orderId: 'O001', notificationType: 'Ready for Pickup',    message: 'Your laundry order O001 is ready for pickup.',                    sentAt: '2026-09-01T14:35:00', readStatus: 'Read'},
  {notificationId: 'N002', orderId: 'O001', notificationType: 'Pickup Reminder',     message: 'Please collect your laundry order O001 to avoid congestion.',     sentAt: '2026-09-01T18:00:00', readStatus: 'Read'},
  {notificationId: 'N003', orderId: 'O001', notificationType: 'Pickup Reminder',     message: 'Your laundry order O001 is still waiting for pickup.',            sentAt: '2026-09-02T10:00:00', readStatus: 'Unread'},
  {notificationId: 'N004', orderId: 'O002', notificationType: 'Processing',          message: 'Your laundry order O002 is currently being processed.',           sentAt: '2026-09-02T10:30:00', readStatus: 'Read'},
  {notificationId: 'N005', orderId: 'O003', notificationType: 'Order Received',      message: 'Your laundry order O003 has been received.',                      sentAt: '2026-09-03T11:20:00', readStatus: 'Unread'},
  {notificationId: 'N006', orderId: 'O004', notificationType: 'Ready for Pickup',    message: 'Your laundry order O004 is ready for pickup.',                    sentAt: '2026-09-04T14:50:00', readStatus: 'Read'},
  {notificationId: 'N007', orderId: 'O004', notificationType: 'Pickup Confirmation', message: 'Your laundry order O004 has been picked up.',                     sentAt: '2026-09-04T15:00:00', readStatus: 'Read'},
  {notificationId: 'N008', orderId: 'O005', notificationType: 'Order Received',      message: 'Your laundry order O005 has been received.',                      sentAt: '2026-09-05T13:20:00', readStatus: 'Unread'}
] AS row
MERGE (n:Notification {notificationId: row.notificationId})
SET n.notificationType = row.notificationType,
    n.message          = row.message,
    n.sentAt           = localdatetime(row.sentAt),
    n.readStatus       = row.readStatus
WITH n, row
MATCH (o:LaundryOrder {orderId: row.orderId})
MERGE (o)-[:GENERATED]->(n);

// ---------------------------------------------------------------------------
// Relationships between existing nodes
// ---------------------------------------------------------------------------

// STUDENT.HostelID -> LIVES_IN
UNWIND [
  {studentId: 'S001', hostelId: 'H001'},
  {studentId: 'S002', hostelId: 'H002'},
  {studentId: 'S003', hostelId: 'H003'},
  {studentId: 'S004', hostelId: 'H004'},
  {studentId: 'S005', hostelId: 'H005'}
] AS row
MATCH (s:Student {studentId: row.studentId})
MATCH (h:Hostel {hostelId: row.hostelId})
MERGE (s)-[:LIVES_IN]->(h);

// ORDER_ITEM -> CONTAINS {quantity, unitPrice}
UNWIND [
  {orderId: 'O001', garmentTypeId: 'G001', quantity: 3, unitPrice: 20.0},
  {orderId: 'O001', garmentTypeId: 'G002', quantity: 2, unitPrice: 20.0},
  {orderId: 'O002', garmentTypeId: 'G001', quantity: 2, unitPrice: 35.0},
  {orderId: 'O002', garmentTypeId: 'G003', quantity: 2, unitPrice: 35.0},
  {orderId: 'O003', garmentTypeId: 'G005', quantity: 2, unitPrice: 80.0},
  {orderId: 'O003', garmentTypeId: 'G004', quantity: 1, unitPrice: 80.0},
  {orderId: 'O004', garmentTypeId: 'G002', quantity: 5, unitPrice: 15.0},
  {orderId: 'O005', garmentTypeId: 'G001', quantity: 3, unitPrice: 40.0}
] AS row
MATCH (o:LaundryOrder {orderId: row.orderId})
MATCH (g:GarmentType {garmentTypeId: row.garmentTypeId})
MERGE (o)-[c:CONTAINS]->(g)
SET c.quantity  = row.quantity,
    c.unitPrice = row.unitPrice;
