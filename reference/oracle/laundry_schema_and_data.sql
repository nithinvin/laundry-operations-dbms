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
    CONSTRAINT pk_student_phone
        PRIMARY KEY (StudentID, PhoneNumber),
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
    CONSTRAINT pk_staff_phone
        PRIMARY KEY (StaffID, PhoneNumber),
    CONSTRAINT fk_staff_phone
        FOREIGN KEY (StaffID)
        REFERENCES STAFF(StaffID)
);

CREATE TABLE SERVICE (
    ServiceID       VARCHAR2(10) PRIMARY KEY,
    ServiceName     VARCHAR2(50) NOT NULL UNIQUE,
    PricePerItem    NUMBER(8,2) NOT NULL,
    EstimatedHours  NUMBER(4) NOT NULL,
    CONSTRAINT chk_service_price
        CHECK (PricePerItem > 0),
    CONSTRAINT chk_service_hours
        CHECK (EstimatedHours > 0)
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
    CONSTRAINT chk_machine_capacity
        CHECK (Capacity > 0),
    CONSTRAINT chk_machine_status
        CHECK (MachineStatus IN
        ('Available', 'Running', 'Maintenance', 'Out of Service'))
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
    CONSTRAINT fk_order_student
        FOREIGN KEY (StudentID)
        REFERENCES STUDENT(StudentID),
    CONSTRAINT fk_order_service
        FOREIGN KEY (ServiceID)
        REFERENCES SERVICE(ServiceID),
    CONSTRAINT fk_order_staff
        FOREIGN KEY (StaffID)
        REFERENCES STAFF(StaffID),
    CONSTRAINT chk_order_status
        CHECK (Status IN
        ('Received',
         'Queued',
         'Processing',
         'Ready for Pickup',
         'Picked Up',
         'Cancelled')),
    CONSTRAINT chk_order_amount
        CHECK (TotalAmount >= 0),
    CONSTRAINT chk_order_completion
        CHECK (ActualCompletion IS NULL
               OR ActualCompletion >= OrderDateTime),
    CONSTRAINT chk_order_expected
        CHECK (ExpectedCompletion >= OrderDateTime)
);

CREATE TABLE ORDER_ITEM (
    OrderID          VARCHAR2(10),
    GarmentTypeID    VARCHAR2(10),
    Quantity         NUMBER(5) NOT NULL,
    UnitPrice        NUMBER(8,2) NOT NULL,
    CONSTRAINT pk_order_item
        PRIMARY KEY (OrderID, GarmentTypeID),
    CONSTRAINT fk_order_item_order
        FOREIGN KEY (OrderID)
        REFERENCES LAUNDRY_ORDER(OrderID),
    CONSTRAINT fk_order_item_garment
        FOREIGN KEY (GarmentTypeID)
        REFERENCES GARMENT_TYPE(GarmentTypeID),
    CONSTRAINT chk_order_item_quantity
        CHECK (Quantity > 0),
    CONSTRAINT chk_order_item_price
        CHECK (UnitPrice > 0)
);

CREATE TABLE QUEUE_ENTRY (
    QueueID          VARCHAR2(10) PRIMARY KEY,
    OrderID          VARCHAR2(10) NOT NULL,
    MachineID        VARCHAR2(10) NOT NULL,
    QueuePosition    NUMBER(5) NOT NULL,
    AddedAt          TIMESTAMP NOT NULL,
    EstimatedStart   TIMESTAMP NOT NULL,
    CONSTRAINT fk_queue_order
        FOREIGN KEY (OrderID)
        REFERENCES LAUNDRY_ORDER(OrderID),
    CONSTRAINT fk_queue_machine
        FOREIGN KEY (MachineID)
        REFERENCES MACHINE(MachineID),
    CONSTRAINT chk_queue_position
        CHECK (QueuePosition > 0),
    CONSTRAINT uq_machine_position
        UNIQUE (MachineID, QueuePosition)
);

CREATE TABLE PAYMENT (
    PaymentID       VARCHAR2(10) PRIMARY KEY,
    OrderID         VARCHAR2(10) NOT NULL UNIQUE,
    Amount          NUMBER(10,2) NOT NULL,
    PaymentDate     DATE NOT NULL,
    PaymentMethod   VARCHAR2(20) NOT NULL,
    PaymentStatus   VARCHAR2(20) NOT NULL,
    CONSTRAINT fk_payment_order
        FOREIGN KEY (OrderID)
        REFERENCES LAUNDRY_ORDER(OrderID),
    CONSTRAINT chk_payment_amount
        CHECK (Amount > 0),
    CONSTRAINT chk_payment_method
        CHECK (PaymentMethod IN
        ('UPI', 'Card', 'Cash', 'Net Banking')),
    CONSTRAINT chk_payment_status
        CHECK (PaymentStatus IN
        ('Paid', 'Pending', 'Failed', 'Refunded'))
);

CREATE TABLE NOTIFICATION (
    NotificationID    VARCHAR2(10) PRIMARY KEY,
    OrderID           VARCHAR2(10) NOT NULL,
    NotificationType  VARCHAR2(30) NOT NULL,
    Message           VARCHAR2(200) NOT NULL,
    SentAt            TIMESTAMP NOT NULL,
    ReadStatus        VARCHAR2(10) NOT NULL,
    CONSTRAINT fk_notification_order
        FOREIGN KEY (OrderID)
        REFERENCES LAUNDRY_ORDER(OrderID),
    CONSTRAINT chk_notification_status
        CHECK (ReadStatus IN ('Read', 'Unread'))
);

INSERT INTO HOSTEL VALUES
('H001', 'Block A Hostel', 'North Campus');

INSERT INTO HOSTEL VALUES
('H002', 'Block B Hostel', 'North Campus');

INSERT INTO HOSTEL VALUES
('H003', 'Block C Hostel', 'South Campus');

INSERT INTO HOSTEL VALUES
('H004', 'Block D Hostel', 'South Campus');

INSERT INTO HOSTEL VALUES
('H005', 'Block E Hostel', 'Main Campus');


INSERT INTO STUDENT VALUES
('S001', 'Nithin', 'nithin@vit.ac.in', 'A101', 'H001');

INSERT INTO STUDENT VALUES
('S002', 'Arjun', 'arjun@vit.ac.in', 'B202', 'H002');

INSERT INTO STUDENT VALUES
('S003', 'Rahul', 'rahul@vit.ac.in', 'C303', 'H003');

INSERT INTO STUDENT VALUES
('S004', 'Karthik', 'karthik@vit.ac.in', 'D404', 'H004');

INSERT INTO STUDENT VALUES
('S005', 'Aditya', 'aditya@vit.ac.in', 'E505', 'H005');

INSERT INTO STUDENT_PHONE VALUES
('S001', '9876543210');

INSERT INTO STUDENT_PHONE VALUES
('S001', '9123456789');

INSERT INTO STUDENT_PHONE VALUES
('S002', '9988776655');

INSERT INTO STUDENT_PHONE VALUES
('S003', '9876501234');

INSERT INTO STUDENT_PHONE VALUES
('S004', '9123405678');

INSERT INTO STUDENT_PHONE VALUES
('S005', '9000012345');

INSERT INTO STAFF VALUES
('ST001', 'Ramesh', 'Laundry Operator');

INSERT INTO STAFF VALUES
('ST002', 'Suresh', 'Laundry Operator');

INSERT INTO STAFF VALUES
('ST003', 'Priya', 'Supervisor');

INSERT INTO STAFF VALUES
('ST004', 'Anita', 'Laundry Operator');

INSERT INTO STAFF VALUES
('ST005', 'Vijay', 'Receptionist');

INSERT INTO STAFF_PHONE VALUES
('ST001', '9000011111');

INSERT INTO STAFF_PHONE VALUES
('ST001', '9000022222');

INSERT INTO STAFF_PHONE VALUES
('ST002', '9000033333');

INSERT INTO STAFF_PHONE VALUES
('ST003', '9000044444');

INSERT INTO STAFF_PHONE VALUES
('ST004', '9000055555');

INSERT INTO STAFF_PHONE VALUES
('ST005', '9000066666');

INSERT INTO SERVICE VALUES
('SV001', 'Normal Wash', 20.00, 6);

INSERT INTO SERVICE VALUES
('SV002', 'Wash and Iron', 35.00, 8);

INSERT INTO SERVICE VALUES
('SV003', 'Dry Clean', 80.00, 24);

INSERT INTO SERVICE VALUES
('SV004', 'Ironing', 15.00, 3);

INSERT INTO SERVICE VALUES
('SV005', 'Express Wash', 40.00, 3);

INSERT INTO GARMENT_TYPE VALUES
('G001', 'Shirt', 'Clothing');

INSERT INTO GARMENT_TYPE VALUES
('G002', 'Pants', 'Clothing');

INSERT INTO GARMENT_TYPE VALUES
('G003', 'Bedsheet', 'Bedding');

INSERT INTO GARMENT_TYPE VALUES
('G004', 'Towel', 'Linen');

INSERT INTO GARMENT_TYPE VALUES
('G005', 'Jacket', 'Clothing');

INSERT INTO MACHINE VALUES
('M001', 'Washing Machine', 8.00, 'Running');

INSERT INTO MACHINE VALUES
('M002', 'Washing Machine', 10.00, 'Available');

INSERT INTO MACHINE VALUES
('M003', 'Dryer', 8.00, 'Running');

INSERT INTO MACHINE VALUES
('M004', 'Dry Cleaner', 12.00, 'Maintenance');

INSERT INTO MACHINE VALUES
('M005', 'Washing Machine', 10.00, 'Available');


INSERT INTO LAUNDRY_ORDER VALUES
('O001','S001','SV001','ST001',TIMESTAMP '2026-09-01 09:00:00',TIMESTAMP '2026-09-01 15:00:00',TIMESTAMP '2026-09-01 14:30:00','Ready for Pickup',100),
('O002','S002','SV002','ST002',TIMESTAMP '2026-09-02 10:00:00',TIMESTAMP '2026-09-02 18:00:00',NULL,'Processing',140),
('O003','S003','SV003','ST003',TIMESTAMP '2026-09-03 11:00:00',TIMESTAMP '2026-09-04 11:00:00',NULL,'Queued',240),
('O004','S004','SV004','ST004',TIMESTAMP '2026-09-04 12:00:00',TIMESTAMP '2026-09-04 15:00:00',TIMESTAMP '2026-09-04 14:45:00','Picked Up',75),
('O005','S005','SV005','ST005',TIMESTAMP '2026-09-05 13:00:00',TIMESTAMP '2026-09-05 16:00:00',NULL,'Received',120);

INSERT INTO ORDER_ITEM VALUES
('O001','G001',3,20),('O001','G002',2,20),('O002','G001',2,35),
('O002','G003',2,35),('O003','G005',2,80),('O003','G004',1,80),
('O004','G002',5,15),('O005','G001',3,40);

INSERT INTO QUEUE_ENTRY VALUES
('Q001','O002','M001',1,TIMESTAMP '2026-09-02 10:15:00',TIMESTAMP '2026-09-02 10:30:00'),
('Q002','O003','M001',2,TIMESTAMP '2026-09-03 11:15:00',TIMESTAMP '2026-09-03 18:30:00'),
('Q003','O005','M002',1,TIMESTAMP '2026-09-05 13:15:00',TIMESTAMP '2026-09-05 13:30:00'),
('Q004','O001','M003',1,TIMESTAMP '2026-09-01 09:15:00',TIMESTAMP '2026-09-01 09:30:00'),
('Q005','O004','M005',1,TIMESTAMP '2026-09-04 12:15:00',TIMESTAMP '2026-09-04 12:30:00');

INSERT INTO PAYMENT VALUES
('P001','O001',100,DATE '2026-09-01','UPI','Paid'),
('P002','O002',140,DATE '2026-09-02','Card','Paid'),
('P003','O003',240,DATE '2026-09-03','UPI','Paid'),
('P004','O004',75,DATE '2026-09-04','Cash','Paid'),
('P005','O005',120,DATE '2026-09-05','Net Banking','Paid');

INSERT INTO NOTIFICATION VALUES
('N001','O001','Ready for Pickup','Your laundry order O001 is ready for pickup.',TIMESTAMP '2026-09-01 14:35:00','Read'),
('N002','O001','Pickup Reminder','Please collect your laundry order O001 to avoid congestion.',TIMESTAMP '2026-09-01 18:00:00','Read'),
('N003','O001','Pickup Reminder','Your laundry order O001 is still waiting for pickup.',TIMESTAMP '2026-09-02 10:00:00','Unread'),
('N004','O002','Processing','Your laundry order O002 is currently being processed.',TIMESTAMP '2026-09-02 10:30:00','Read'),
('N005','O003','Order Received','Your laundry order O003 has been received.',TIMESTAMP '2026-09-03 11:20:00','Unread'),
('N006','O004','Ready for Pickup','Your laundry order O004 is ready for pickup.',TIMESTAMP '2026-09-04 14:50:00','Read'),
('N007','O004','Pickup Confirmation','Your laundry order O004 has been picked up.',TIMESTAMP '2026-09-04 15:00:00','Read'),
('N008','O005','Order Received','Your laundry order O005 has been received.',TIMESTAMP '2026-09-05 13:20:00','Unread');

COMMIT;
