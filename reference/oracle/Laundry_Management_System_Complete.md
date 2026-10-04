# Laundry Management System

## Complete DBMS Project Reference

## 1. Project Overview

**Project:** Laundry Management System

The system manages laundry orders placed by students in a hostel/campus
environment. Its main goal is to notify students when laundry is ready
for pickup, reducing congestion in the laundry area.

### Objectives

-   Store students, hostels, staff, services, garment types, machines,
    queues, payments, and notifications.
-   Record laundry orders and their garment items.
-   Track order status, expected completion, and actual completion.
-   Notify students when orders are ready.
-   Maintain normalized relational data through BCNF.
-   Provide SQL and PL/SQL reporting/processing.

### Current business assumption

One `LAUNDRY_ORDER` selects **one service**. Multiple garment types can
belong to that order and use that service.

Example:

``` text
O001
  Normal Wash
  Shirt x 3
  Pants x 2
```

A future design could allow different services per garment, but that is
not part of the current approved schema.

------------------------------------------------------------------------

## 2. Functional Requirements

1.  Register students and associate them with hostels.
2.  Store multiple phone numbers for students.
3.  Register staff and multiple staff phone numbers.
4.  Store laundry services and prices.
5.  Store garment types.
6.  Create laundry orders.
7.  Store multiple garment types in an order.
8.  Assign staff to orders.
9.  Track machines and queue entries.
10. Record one payment per order.
11. Store multiple notifications per order.
12. Track order status and completion times.
13. Run advanced SQL reports.
14. Demonstrate PL/SQL variables, conditions, aggregate functions,
    cursors, and loops.

------------------------------------------------------------------------

# 3. Conceptual ER Design

## Entities / Relations

1.  `HOSTEL`
2.  `STUDENT`
3.  `STUDENT_PHONE`
4.  `STAFF`
5.  `STAFF_PHONE`
6.  `SERVICE`
7.  `GARMENT_TYPE`
8.  `LAUNDRY_ORDER`
9.  `ORDER_ITEM`
10. `MACHINE`
11. `QUEUE_ENTRY`
12. `PAYMENT`
13. `NOTIFICATION`

## Relationships

  -----------------------------------------------------------------------
  Relationship            Cardinality             Participation
  ----------------------- ----------------------- -----------------------
  HOSTEL - LIVES_IN -     1:N                     Student total, Hostel
  STUDENT                                         partial

  STUDENT - PLACES -      1:N                     Order total, Student
  LAUNDRY_ORDER                                   partial

  STAFF - ASSIGNED_TO -   1:N                     Order total, Staff
  LAUNDRY_ORDER                                   partial

  SERVICE -               1:N                     Order total, Service
  USES_SERVICE -                                  partial
  LAUNDRY_ORDER                                   

  LAUNDRY_ORDER -         1:N                     Both total
  CONTAINS - ORDER_ITEM                           

  ORDER_ITEM - OF_TYPE -  N:1                     OrderItem total,
  GARMENT_TYPE                                    GarmentType partial

  LAUNDRY_ORDER -         1:0..1                  QueueEntry total, Order
  IN_QUEUE - QUEUE_ENTRY                          partial

  QUEUE_ENTRY -           N:1                     QueueEntry total,
  FOR_MACHINE - MACHINE                           Machine partial

  LAUNDRY_ORDER -         1:1                     Both total under
  HAS_PAYMENT - PAYMENT                           current assumption

  LAUNDRY_ORDER -         1:N                     Notification total,
  GENERATES -                                     Order partial
  NOTIFICATION                                    

  STUDENT - RECEIVES -    1:N                     Notification total,
  NOTIFICATION                                    Student partial
  -----------------------------------------------------------------------

### Important design decisions

-   There is **no direct STUDENT-PAYMENT relationship**. The path is
    `STUDENT -> LAUNDRY_ORDER -> PAYMENT`.
-   `NOTIFICATION` has `OrderID` but no `StudentID`, because the student
    is derivable through the order. This avoids redundancy and a
    possible BCNF problem.
-   Multiple notifications of the same type for one order are allowed.
    There is no `UNIQUE(OrderID, NotificationType)`.
-   `ORDER_ITEM` can be treated as a weak entity because it depends on
    `LAUNDRY_ORDER` and uses `(OrderID, GarmentTypeID)` as its key.
-   `GARMENT_TYPE` is a strong entity because it has its own independent
    identifier.

------------------------------------------------------------------------

# 4. Relational Schema

``` text
HOSTEL(HostelID PK, HostelName UNIQUE, Location)

STUDENT(StudentID PK, StudentName, Email UNIQUE, RoomNo, HostelID FK)

STUDENT_PHONE(StudentID PK/FK, PhoneNumber PK)

STAFF(StaffID PK, StaffName, StaffRole)

STAFF_PHONE(StaffID PK/FK, PhoneNumber PK)

SERVICE(ServiceID PK, ServiceName UNIQUE, PricePerItem, EstimatedHours)

GARMENT_TYPE(GarmentTypeID PK, GarmentName UNIQUE, Category)

LAUNDRY_ORDER(
    OrderID PK,
    StudentID FK,
    ServiceID FK,
    StaffID FK,
    OrderDateTime,
    ExpectedCompletion,
    ActualCompletion,
    Status,
    TotalAmount
)

ORDER_ITEM(
    OrderID PK/FK,
    GarmentTypeID PK/FK,
    Quantity,
    UnitPrice
)

MACHINE(MachineID PK, MachineType, Capacity, MachineStatus)

QUEUE_ENTRY(
    QueueID PK,
    OrderID FK,
    MachineID FK,
    QueuePosition,
    AddedAt,
    EstimatedStart
)

PAYMENT(
    PaymentID PK,
    OrderID UNIQUE/FK,
    Amount,
    PaymentDate,
    PaymentMethod,
    PaymentStatus
)

NOTIFICATION(
    NotificationID PK,
    OrderID FK,
    NotificationType,
    Message,
    SentAt,
    ReadStatus
)
```

------------------------------------------------------------------------

# 5. Candidate Keys

  Relation        Candidate Keys
  --------------- ------------------------------------
  HOSTEL          `{HostelID}`
  STUDENT         `{StudentID}`, `{Email}`
  STUDENT_PHONE   `{StudentID, PhoneNumber}`
  STAFF           `{StaffID}`
  STAFF_PHONE     `{StaffID, PhoneNumber}`
  SERVICE         `{ServiceID}`, `{ServiceName}`
  GARMENT_TYPE    `{GarmentTypeID}`, `{GarmentName}`
  LAUNDRY_ORDER   `{OrderID}`
  ORDER_ITEM      `{OrderID, GarmentTypeID}`
  MACHINE         `{MachineID}`
  QUEUE_ENTRY     `{QueueID}`
  PAYMENT         `{PaymentID}`, `{OrderID}`
  NOTIFICATION    `{NotificationID}`

`{StudentID, Email}` is only a superkey, not a candidate key, because
`StudentID` and `Email` each independently identify the student.

------------------------------------------------------------------------

# 6. Normalization

## UNF

The original data can contain multivalued phone numbers and repeating
groups for garments and notifications.

## 1NF

Multivalued/repeating data is separated into:

``` text
STUDENT_PHONE(StudentID, PhoneNumber)
STAFF_PHONE(StaffID, PhoneNumber)
ORDER_ITEM(OrderID, GarmentTypeID, Quantity, UnitPrice)
NOTIFICATION(NotificationID, OrderID, NotificationType, Message, SentAt, ReadStatus)
```

All attributes are atomic.

## 2NF

Single-column-key tables automatically satisfy 2NF.

For composite-key tables: - `STUDENT_PHONE` has no non-key attributes. -
`STAFF_PHONE` has no non-key attributes. - `ORDER_ITEM` has `Quantity`
and `UnitPrice` depending on the complete `(OrderID, GarmentTypeID)`
key.

## 3NF

Hostel information is separated to remove:

``` text
StudentID -> HostelID -> HostelName, Location
```

Thus `STUDENT` stores `HostelID`, while `HOSTEL` stores hostel details.

## BCNF

Every non-trivial determinant in the final relations is a superkey under
the stated functional dependencies.

A key correction was removing `StudentID` from `NOTIFICATION`.
Otherwise:

``` text
OrderID -> StudentID
```

could hold while `OrderID` was not a key of NOTIFICATION.

------------------------------------------------------------------------

# 7. Oracle CREATE TABLE Statements

``` sql
CREATE TABLE HOSTEL (
    HostelID       VARCHAR2(10) PRIMARY KEY,
    HostelName     VARCHAR2(50) NOT NULL UNIQUE,
    Location       VARCHAR2(100) NOT NULL
);

CREATE TABLE STUDENT (
    StudentID      VARCHAR2(10) PRIMARY KEY,
    StudentName    VARCHAR2(50) NOT NULL,
    Email          VARCHAR2(100) NOT NULL UNIQUE,
    RoomNo         VARCHAR2(10) NOT NULL,
    HostelID       VARCHAR2(10) NOT NULL,
    CONSTRAINT fk_student_hostel
        FOREIGN KEY (HostelID)
        REFERENCES HOSTEL(HostelID)
);

CREATE TABLE STUDENT_PHONE (
    StudentID      VARCHAR2(10),
    PhoneNumber    VARCHAR2(15),
    CONSTRAINT pk_student_phone PRIMARY KEY (StudentID, PhoneNumber),
    CONSTRAINT fk_student_phone
        FOREIGN KEY (StudentID)
        REFERENCES STUDENT(StudentID)
);

CREATE TABLE STAFF (
    StaffID        VARCHAR2(10) PRIMARY KEY,
    StaffName      VARCHAR2(50) NOT NULL,
    StaffRole      VARCHAR2(30) NOT NULL
);

CREATE TABLE STAFF_PHONE (
    StaffID        VARCHAR2(10),
    PhoneNumber    VARCHAR2(15),
    CONSTRAINT pk_staff_phone PRIMARY KEY (StaffID, PhoneNumber),
    CONSTRAINT fk_staff_phone
        FOREIGN KEY (StaffID)
        REFERENCES STAFF(StaffID)
);

CREATE TABLE SERVICE (
    ServiceID       VARCHAR2(10) PRIMARY KEY,
    ServiceName     VARCHAR2(50) NOT NULL UNIQUE,
    PricePerItem    NUMBER(8,2) NOT NULL,
    EstimatedHours  NUMBER(4) NOT NULL,
    CONSTRAINT chk_service_price CHECK (PricePerItem > 0),
    CONSTRAINT chk_service_hours CHECK (EstimatedHours > 0)
);

CREATE TABLE GARMENT_TYPE (
    GarmentTypeID   VARCHAR2(10) PRIMARY KEY,
    GarmentName     VARCHAR2(50) NOT NULL UNIQUE,
    Category        VARCHAR2(30) NOT NULL
);

CREATE TABLE MACHINE (
    MachineID       VARCHAR2(10) PRIMARY KEY,
    MachineType     VARCHAR2(30) NOT NULL,
    Capacity        NUMBER(5,2) NOT NULL,
    MachineStatus   VARCHAR2(20) NOT NULL,
    CONSTRAINT chk_machine_capacity CHECK (Capacity > 0),
    CONSTRAINT chk_machine_status CHECK (
        MachineStatus IN ('Available', 'Running', 'Maintenance', 'Out of Service')
    )
);

CREATE TABLE LAUNDRY_ORDER (
    OrderID             VARCHAR2(10) PRIMARY KEY,
    StudentID           VARCHAR2(10) NOT NULL,
    ServiceID           VARCHAR2(10) NOT NULL,
    StaffID             VARCHAR2(10) NOT NULL,
    OrderDateTime       TIMESTAMP NOT NULL,
    ExpectedCompletion  TIMESTAMP NOT NULL,
    ActualCompletion    TIMESTAMP,
    Status              VARCHAR2(25) NOT NULL,
    TotalAmount         NUMBER(10,2) NOT NULL,
    CONSTRAINT fk_order_student FOREIGN KEY (StudentID) REFERENCES STUDENT(StudentID),
    CONSTRAINT fk_order_service FOREIGN KEY (ServiceID) REFERENCES SERVICE(ServiceID),
    CONSTRAINT fk_order_staff FOREIGN KEY (StaffID) REFERENCES STAFF(StaffID),
    CONSTRAINT chk_order_status CHECK (
        Status IN ('Received','Queued','Processing','Ready for Pickup','Picked Up','Cancelled')
    ),
    CONSTRAINT chk_order_amount CHECK (TotalAmount >= 0),
    CONSTRAINT chk_order_completion CHECK (
        ActualCompletion IS NULL OR ActualCompletion >= OrderDateTime
    ),
    CONSTRAINT chk_order_expected CHECK (ExpectedCompletion >= OrderDateTime)
);

CREATE TABLE ORDER_ITEM (
    OrderID          VARCHAR2(10),
    GarmentTypeID    VARCHAR2(10),
    Quantity         NUMBER(5) NOT NULL,
    UnitPrice        NUMBER(8,2) NOT NULL,
    CONSTRAINT pk_order_item PRIMARY KEY (OrderID, GarmentTypeID),
    CONSTRAINT fk_order_item_order FOREIGN KEY (OrderID) REFERENCES LAUNDRY_ORDER(OrderID),
    CONSTRAINT fk_order_item_garment FOREIGN KEY (GarmentTypeID) REFERENCES GARMENT_TYPE(GarmentTypeID),
    CONSTRAINT chk_order_item_quantity CHECK (Quantity > 0),
    CONSTRAINT chk_order_item_price CHECK (UnitPrice > 0)
);

CREATE TABLE QUEUE_ENTRY (
    QueueID          VARCHAR2(10) PRIMARY KEY,
    OrderID          VARCHAR2(10) NOT NULL,
    MachineID        VARCHAR2(10) NOT NULL,
    QueuePosition    NUMBER(5) NOT NULL,
    AddedAt          TIMESTAMP NOT NULL,
    EstimatedStart   TIMESTAMP NOT NULL,
    CONSTRAINT fk_queue_order FOREIGN KEY (OrderID) REFERENCES LAUNDRY_ORDER(OrderID),
    CONSTRAINT fk_queue_machine FOREIGN KEY (MachineID) REFERENCES MACHINE(MachineID),
    CONSTRAINT chk_queue_position CHECK (QueuePosition > 0),
    CONSTRAINT uq_machine_position UNIQUE (MachineID, QueuePosition)
);

CREATE TABLE PAYMENT (
    PaymentID       VARCHAR2(10) PRIMARY KEY,
    OrderID         VARCHAR2(10) NOT NULL UNIQUE,
    Amount          NUMBER(10,2) NOT NULL,
    PaymentDate     DATE NOT NULL,
    PaymentMethod   VARCHAR2(20) NOT NULL,
    PaymentStatus   VARCHAR2(20) NOT NULL,
    CONSTRAINT fk_payment_order FOREIGN KEY (OrderID) REFERENCES LAUNDRY_ORDER(OrderID),
    CONSTRAINT chk_payment_amount CHECK (Amount > 0),
    CONSTRAINT chk_payment_method CHECK (
        PaymentMethod IN ('UPI', 'Card', 'Cash', 'Net Banking')
    ),
    CONSTRAINT chk_payment_status CHECK (
        PaymentStatus IN ('Paid', 'Pending', 'Failed', 'Refunded')
    )
);

CREATE TABLE NOTIFICATION (
    NotificationID    VARCHAR2(10) PRIMARY KEY,
    OrderID           VARCHAR2(10) NOT NULL,
    NotificationType  VARCHAR2(30) NOT NULL,
    Message           VARCHAR2(200) NOT NULL,
    SentAt            TIMESTAMP NOT NULL,
    ReadStatus        VARCHAR2(10) NOT NULL,
    CONSTRAINT fk_notification_order FOREIGN KEY (OrderID) REFERENCES LAUNDRY_ORDER(OrderID),
    CONSTRAINT chk_notification_status CHECK (ReadStatus IN ('Read', 'Unread'))
);
```

------------------------------------------------------------------------

# 8. Sample Data Insertion

## HOSTEL

``` sql
INSERT INTO HOSTEL VALUES ('H001','Block A Hostel','North Campus');
INSERT INTO HOSTEL VALUES ('H002','Block B Hostel','North Campus');
INSERT INTO HOSTEL VALUES ('H003','Block C Hostel','South Campus');
INSERT INTO HOSTEL VALUES ('H004','Block D Hostel','South Campus');
INSERT INTO HOSTEL VALUES ('H005','Block E Hostel','Main Campus');
```

## STUDENT

``` sql
INSERT INTO STUDENT VALUES ('S001','Nithin','nithin@vit.ac.in','A101','H001');
INSERT INTO STUDENT VALUES ('S002','Arjun','arjun@vit.ac.in','B202','H002');
INSERT INTO STUDENT VALUES ('S003','Rahul','rahul@vit.ac.in','C303','H003');
INSERT INTO STUDENT VALUES ('S004','Karthik','karthik@vit.ac.in','D404','H004');
INSERT INTO STUDENT VALUES ('S005','Aditya','aditya@vit.ac.in','E505','H005');
```

## STUDENT_PHONE

``` sql
INSERT INTO STUDENT_PHONE VALUES ('S001','9876543210');
INSERT INTO STUDENT_PHONE VALUES ('S001','9123456789');
INSERT INTO STUDENT_PHONE VALUES ('S002','9988776655');
INSERT INTO STUDENT_PHONE VALUES ('S003','9876501234');
INSERT INTO STUDENT_PHONE VALUES ('S004','9123405678');
INSERT INTO STUDENT_PHONE VALUES ('S005','9000012345');
```

## STAFF

``` sql
INSERT INTO STAFF VALUES ('ST001','Ramesh','Laundry Operator');
INSERT INTO STAFF VALUES ('ST002','Suresh','Laundry Operator');
INSERT INTO STAFF VALUES ('ST003','Priya','Supervisor');
INSERT INTO STAFF VALUES ('ST004','Anita','Laundry Operator');
INSERT INTO STAFF VALUES ('ST005','Vijay','Receptionist');
```

## STAFF_PHONE

``` sql
INSERT INTO STAFF_PHONE VALUES ('ST001','9000011111');
INSERT INTO STAFF_PHONE VALUES ('ST001','9000022222');
INSERT INTO STAFF_PHONE VALUES ('ST002','9000033333');
INSERT INTO STAFF_PHONE VALUES ('ST003','9000044444');
INSERT INTO STAFF_PHONE VALUES ('ST004','9000055555');
INSERT INTO STAFF_PHONE VALUES ('ST005','9000066666');
```

## SERVICE

``` sql
INSERT INTO SERVICE VALUES ('SV001','Normal Wash',20,6);
INSERT INTO SERVICE VALUES ('SV002','Wash and Iron',35,8);
INSERT INTO SERVICE VALUES ('SV003','Dry Clean',80,24);
INSERT INTO SERVICE VALUES ('SV004','Ironing',15,3);
INSERT INTO SERVICE VALUES ('SV005','Express Wash',40,3);
```

## GARMENT_TYPE

``` sql
INSERT INTO GARMENT_TYPE VALUES ('G001','Shirt','Clothing');
INSERT INTO GARMENT_TYPE VALUES ('G002','Pants','Clothing');
INSERT INTO GARMENT_TYPE VALUES ('G003','Bedsheet','Bedding');
INSERT INTO GARMENT_TYPE VALUES ('G004','Towel','Linen');
INSERT INTO GARMENT_TYPE VALUES ('G005','Jacket','Clothing');
```

## MACHINE

``` sql
INSERT INTO MACHINE VALUES ('M001','Washing Machine',8,'Running');
INSERT INTO MACHINE VALUES ('M002','Washing Machine',10,'Available');
INSERT INTO MACHINE VALUES ('M003','Dryer',8,'Running');
INSERT INTO MACHINE VALUES ('M004','Dry Cleaner',12,'Maintenance');
INSERT INTO MACHINE VALUES ('M005','Washing Machine',10,'Available');
```

## LAUNDRY_ORDER

``` sql
INSERT INTO LAUNDRY_ORDER VALUES
('O001','S001','SV001','ST001',TIMESTAMP '2026-09-01 09:00:00',TIMESTAMP '2026-09-01 15:00:00',TIMESTAMP '2026-09-01 14:30:00','Ready for Pickup',100),
('O002','S002','SV002','ST002',TIMESTAMP '2026-09-02 10:00:00',TIMESTAMP '2026-09-02 18:00:00',NULL,'Processing',140),
('O003','S003','SV003','ST003',TIMESTAMP '2026-09-03 11:00:00',TIMESTAMP '2026-09-04 11:00:00',NULL,'Queued',240),
('O004','S004','SV004','ST004',TIMESTAMP '2026-09-04 12:00:00',TIMESTAMP '2026-09-04 15:00:00',TIMESTAMP '2026-09-04 14:45:00','Picked Up',75),
('O005','S005','SV005','ST005',TIMESTAMP '2026-09-05 13:00:00',TIMESTAMP '2026-09-05 16:00:00',NULL,'Received',120);
```

## ORDER_ITEM

``` sql
INSERT INTO ORDER_ITEM VALUES
('O001','G001',3,20),('O001','G002',2,20),('O002','G001',2,35),
('O002','G003',2,35),('O003','G005',2,80),('O003','G004',1,80),
('O004','G002',5,15),('O005','G001',3,40);
```

## QUEUE_ENTRY

``` sql
INSERT INTO QUEUE_ENTRY VALUES
('Q001','O002','M001',1,TIMESTAMP '2026-09-02 10:15:00',TIMESTAMP '2026-09-02 10:30:00'),
('Q002','O003','M001',2,TIMESTAMP '2026-09-03 11:15:00',TIMESTAMP '2026-09-03 18:30:00'),
('Q003','O005','M002',1,TIMESTAMP '2026-09-05 13:15:00',TIMESTAMP '2026-09-05 13:30:00'),
('Q004','O001','M003',1,TIMESTAMP '2026-09-01 09:15:00',TIMESTAMP '2026-09-01 09:30:00'),
('Q005','O004','M005',1,TIMESTAMP '2026-09-04 12:15:00',TIMESTAMP '2026-09-04 12:30:00');
```

## PAYMENT

``` sql
INSERT INTO PAYMENT VALUES
('P001','O001',100,DATE '2026-09-01','UPI','Paid'),
('P002','O002',140,DATE '2026-09-02','Card','Paid'),
('P003','O003',240,DATE '2026-09-03','UPI','Paid'),
('P004','O004',75,DATE '2026-09-04','Cash','Paid'),
('P005','O005',120,DATE '2026-09-05','Net Banking','Paid');
```

## NOTIFICATION

``` sql
INSERT INTO NOTIFICATION VALUES
('N001','O001','Ready for Pickup','Your laundry order O001 is ready for pickup.',TIMESTAMP '2026-09-01 14:35:00','Read'),
('N002','O001','Pickup Reminder','Please collect your laundry order O001 to avoid congestion.',TIMESTAMP '2026-09-01 18:00:00','Read'),
('N003','O001','Pickup Reminder','Your laundry order O001 is still waiting for pickup.',TIMESTAMP '2026-09-02 10:00:00','Unread'),
('N004','O002','Processing','Your laundry order O002 is currently being processed.',TIMESTAMP '2026-09-02 10:30:00','Read'),
('N005','O003','Order Received','Your laundry order O003 has been received.',TIMESTAMP '2026-09-03 11:20:00','Unread'),
('N006','O004','Ready for Pickup','Your laundry order O004 is ready for pickup.',TIMESTAMP '2026-09-04 14:50:00','Read'),
('N007','O004','Pickup Confirmation','Your laundry order O004 has been picked up.',TIMESTAMP '2026-09-04 15:00:00','Read'),
('N008','O005','Order Received','Your laundry order O005 has been received.',TIMESTAMP '2026-09-05 13:20:00','Unread');
```

``` sql
COMMIT;
```

------------------------------------------------------------------------

# 9. Advanced SQL Queries

## 1. Student with the most expensive order

``` sql
select s.studentid, s.studentname, l.orderid, l.totalamount from student s join laundry_order l on s.studentid = l.studentid where l.totalamount = (select max(totalamount) from laundry_order);
```

## 2. Services whose average order amount is above the overall average

``` sql
select sv.serviceid, sv.servicename, avg(l.totalamount) as averageamount from service sv join laundry_order l on sv.serviceid = l.serviceid group by sv.serviceid, sv.servicename having avg(l.totalamount) > (select avg(totalamount) from laundry_order);
```

## 3. Students with more than one order

``` sql
select s.studentid, s.studentname, count(l.orderid) as ordercount from student s join laundry_order l on s.studentid = l.studentid group by s.studentid, s.studentname having count(l.orderid) > 1;
```

## 4. Garment types appearing in more than one order

``` sql
select g.garmenttypeid, g.garmentname, count(distinct oi.orderid) as ordercount from garment_type g join order_item oi on g.garmenttypeid = oi.garmenttypeid group by g.garmenttypeid, g.garmentname having count(distinct oi.orderid) > 1;
```

## 5. Orders whose payment amount matches their order amount

``` sql
select l.orderid, l.totalamount, p.amount, p.paymentstatus from laundry_order l join payment p on l.orderid = p.orderid where p.amount = l.totalamount;
```

------------------------------------------------------------------------

# 10. PL/SQL Programs

## Q1. Find order with highest total cost

``` sql
SET SERVEROUTPUT ON;

DECLARE
    v_order_id      LAUNDRY_ORDER.OrderID%TYPE;
    v_student_id    LAUNDRY_ORDER.StudentID%TYPE;
    v_service_id    LAUNDRY_ORDER.ServiceID%TYPE;
    v_total_amount  LAUNDRY_ORDER.TotalAmount%TYPE;
BEGIN
    SELECT OrderID, StudentID, ServiceID, TotalAmount
    INTO v_order_id, v_student_id, v_service_id, v_total_amount
    FROM LAUNDRY_ORDER
    WHERE TotalAmount = (SELECT MAX(TotalAmount) FROM LAUNDRY_ORDER);

    DBMS_OUTPUT.PUT_LINE('Order ID: ' || v_order_id);
    DBMS_OUTPUT.PUT_LINE('Student ID: ' || v_student_id);
    DBMS_OUTPUT.PUT_LINE('Service ID: ' || v_service_id);
    DBMS_OUTPUT.PUT_LINE('Highest Total Amount: ' || v_total_amount);
END;
/
```

Expected:

``` text
Order ID: O003
Student ID: S003
Service ID: SV003
Highest Total Amount: 240
```

## Q2. Calculate total revenue from paid orders

``` sql
SET SERVEROUTPUT ON;

DECLARE
    v_revenue NUMBER(10,2);
BEGIN
    SELECT NVL(SUM(Amount), 0)
    INTO v_revenue
    FROM PAYMENT
    WHERE PaymentStatus = 'Paid';

    DBMS_OUTPUT.PUT_LINE('Total Revenue from Paid Orders: ' || v_revenue);
END;
/
```

Expected:

``` text
Total Revenue from Paid Orders: 675
```

## Q3. Display each student and order count

``` sql
SET SERVEROUTPUT ON;

DECLARE
    CURSOR student_orders IS
        SELECT S.StudentID, S.StudentName, COUNT(L.OrderID) AS OrderCount
        FROM STUDENT S
        LEFT JOIN LAUNDRY_ORDER L
        ON S.StudentID = L.StudentID
        GROUP BY S.StudentID, S.StudentName;
BEGIN
    FOR rec IN student_orders LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Student: ' || rec.StudentName ||
            ' | Orders: ' || rec.OrderCount
        );
    END LOOP;
END;
/
```

## Q4. Display pending laundry orders

``` sql
SET SERVEROUTPUT ON;

DECLARE
    CURSOR pending_orders IS
        SELECT L.OrderID, S.StudentName, SV.ServiceName, L.Status
        FROM LAUNDRY_ORDER L
        JOIN STUDENT S
        ON L.StudentID = S.StudentID
        JOIN SERVICE SV
        ON L.ServiceID = SV.ServiceID
        WHERE L.Status <> 'Picked Up';
BEGIN
    FOR rec IN pending_orders LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Order: ' || rec.OrderID ||
            ' | Student: ' || rec.StudentName ||
            ' | Service: ' || rec.ServiceName ||
            ' | Status: ' || rec.Status
        );
    END LOOP;
END;
/
```

## Q5. Check whether an order is ready for pickup

``` sql
SET SERVEROUTPUT ON;

DECLARE
    v_status LAUNDRY_ORDER.Status%TYPE;
BEGIN
    SELECT Status
    INTO v_status
    FROM LAUNDRY_ORDER
    WHERE OrderID = 'O001';

    IF v_status = 'Ready for Pickup' THEN
        DBMS_OUTPUT.PUT_LINE('Order O001 is ready for pickup.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Order O001 is not ready for pickup.');
    END IF;
END;
/
```

Expected:

``` text
Order O001 is ready for pickup.
```

------------------------------------------------------------------------

# 11. PL/SQL Coverage

  Question   Main concepts
  ---------- ------------------------------------------------
  Q1         Variables, `%TYPE`, SELECT INTO, MAX, subquery
  Q2         Variables, SELECT INTO, SUM, NVL
  Q3         Cursor, loop, GROUP BY, COUNT
  Q4         Cursor, loop, joins, filtering
  Q5         SELECT INTO, IF-ELSE

This gives two numerical questions, two cursor questions, and one simple
conditional question.

------------------------------------------------------------------------

# 12. Data Consistency Notes

The current data was corrected so that O003 is consistent:

``` text
O003:
Jacket × 2 = 160
Towel × 1 = 80
Total = 240
```

Therefore:

``` text
LAUNDRY_ORDER.O003.TotalAmount = 240
PAYMENT.P003.Amount = 240
```

Q002's queue timing was also corrected:

``` text
AddedAt        = 2026-09-03 11:15
EstimatedStart = 2026-09-03 18:30
```

The queue contains records for completed orders as historical
queue/assignment records. If the project later requires QUEUE_ENTRY to
represent only the current queue, the sample data can be revised without
changing the rest of the core schema.

------------------------------------------------------------------------

# 13. Oracle Notes

-   Use `VARCHAR2` for variable-length text.
-   Oracle SQL does not provide a normal BOOLEAN column type, so status
    values are represented using strings.
-   Use `SET SERVEROUTPUT ON` to display `DBMS_OUTPUT.PUT_LINE`.
-   PL/SQL blocks end with `/`.
-   Use `COMMIT;` after data modifications.
-   `TIMESTAMP` is used for detailed order/queue/notification times.
-   `DATE` is used for payment dates.

------------------------------------------------------------------------

# 14. Overall System Flow

``` text
STUDENT
   |
   | places
   v
LAUNDRY_ORDER
   |
   +---- selects ----> SERVICE
   |
   +---- assigned to -> STAFF
   |
   +---- contains ----> ORDER_ITEM ----> GARMENT_TYPE
   |
   +---- enters -----> QUEUE_ENTRY ----> MACHINE
   |
   +---- paid through -> PAYMENT
   |
   +---- generates ---> NOTIFICATION
                              |
                              v
                           STUDENT
```

The core workflow is:

``` text
Student places laundry order
        ↓
Order is received
        ↓
Order enters queue / processing
        ↓
Laundry is completed
        ↓
Status becomes Ready for Pickup
        ↓
Notification is generated
        ↓
Student collects laundry
        ↓
Status becomes Picked Up
```

This document captures the current Laundry Management System design,
requirements, constraints, ER decisions, relational schema,
normalization, Oracle SQL table creation, sample data, advanced SQL
queries, and PL/SQL programs.
