// 01_constraints.cypher
// Uniqueness constraints (Neo4j Community) for every Oracle PRIMARY KEY and
// single-column UNIQUE constraint. Each constraint also creates an index.
// Safe to run more than once (IF NOT EXISTS).

// Primary keys
CREATE CONSTRAINT hostel_id       IF NOT EXISTS FOR (n:Hostel)       REQUIRE n.hostelId       IS UNIQUE;
CREATE CONSTRAINT student_id      IF NOT EXISTS FOR (n:Student)      REQUIRE n.studentId      IS UNIQUE;
CREATE CONSTRAINT staff_id        IF NOT EXISTS FOR (n:Staff)        REQUIRE n.staffId        IS UNIQUE;
CREATE CONSTRAINT service_id      IF NOT EXISTS FOR (n:Service)      REQUIRE n.serviceId      IS UNIQUE;
CREATE CONSTRAINT garment_id      IF NOT EXISTS FOR (n:GarmentType)  REQUIRE n.garmentTypeId  IS UNIQUE;
CREATE CONSTRAINT machine_id      IF NOT EXISTS FOR (n:Machine)      REQUIRE n.machineId      IS UNIQUE;
CREATE CONSTRAINT order_id        IF NOT EXISTS FOR (n:LaundryOrder) REQUIRE n.orderId        IS UNIQUE;
CREATE CONSTRAINT queue_id        IF NOT EXISTS FOR (n:QueueEntry)   REQUIRE n.queueId        IS UNIQUE;
CREATE CONSTRAINT payment_id      IF NOT EXISTS FOR (n:Payment)      REQUIRE n.paymentId      IS UNIQUE;
CREATE CONSTRAINT notification_id IF NOT EXISTS FOR (n:Notification) REQUIRE n.notificationId IS UNIQUE;

// UNIQUE columns
CREATE CONSTRAINT hostel_name     IF NOT EXISTS FOR (n:Hostel)       REQUIRE n.hostelName     IS UNIQUE;
CREATE CONSTRAINT student_email   IF NOT EXISTS FOR (n:Student)      REQUIRE n.email          IS UNIQUE;
CREATE CONSTRAINT service_name    IF NOT EXISTS FOR (n:Service)      REQUIRE n.serviceName    IS UNIQUE;
CREATE CONSTRAINT garment_name    IF NOT EXISTS FOR (n:GarmentType)  REQUIRE n.garmentName    IS UNIQUE;

// Index for queries that filter on order status
CREATE INDEX order_status IF NOT EXISTS FOR (n:LaundryOrder) ON (n.status);
